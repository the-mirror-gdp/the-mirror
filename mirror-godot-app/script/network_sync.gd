# Note: In this class, be sure to always use `@rpc("call_remote", ...)`.
# In some cases it is essential to have fine control over when the
# methods are called on the client or server, so keep it explicit.
extends Timer

signal request_sync_variables_to_database(variable_property_data: Dictionary)
signal received_variable_data_change()
signal variables_ready() # called once on setup

# These are exposed to the user.
signal global_variable_changed(variable_name: String, variable_value: Variant)
signal global_variable_tweened(variable_name: String, from_value: Variant, to_value: Variant, duration: float)
signal object_property_changed(object: Object, variable_name: String, variable_value: Variant)
signal object_property_tweened(object: Object, variable_name: String, from_value: Variant, to_value: Variant, duration: float)
signal object_variable_changed(object: Object, variable_name: String, variable_value: Variant)
signal object_variable_tweened(object: Object, variable_name: String, from_value: Variant, to_value: Variant, duration: float)

var _global_variables: Dictionary = {}
# Keep track of all props/vars ever set. Server sends this to new clients,
# and we use this in the variable editor to show which variables are set.
var _all_set_properties_on_nodes: Dictionary = {}
var _all_set_variables_on_nodes: Dictionary = {}
# When entering preview mode, keep a copy of what the space had before.
var _play_preview_space_backup_global_variables: Dictionary = {}
var _play_preview_space_backup_properties_on_nodes: Dictionary = {}
var _play_preview_space_backup_variables_on_nodes: Dictionary = {}
var _is_in_preview_mode: bool = false # Only Preview mode, not Play mode.
# Stores all props/vars set that don't have a node to live on yet.
var _set_queue_properties_on_nodes: Dictionary = {}
var _set_queue_variables_on_nodes: Dictionary = {}
# Queue to only update a variable at most once per frame over the network.
# This prevents two consecutive set calls from updating over the network twice.
var _net_queue_global_variables: Dictionary = {}
var _net_queue_tweened_global_variables: Dictionary = {}
var _net_queue_node_properties: Dictionary = {}
var _net_queue_tweened_node_properties: Dictionary = {}
var _net_queue_node_variables: Dictionary = {}
var _net_queue_tweened_node_variables: Dictionary = {}


func _process(_delta: float) -> void:
	# Look through the list of properties and variables and set them on any
	# nodes if/when they start existing. This keeps properties synced even
	# if the nodes were not initially loaded when the server sent the info.
	if not _set_queue_properties_on_nodes.is_empty():
		_process_set_properties_on_nodes()
	if not _set_queue_variables_on_nodes.is_empty():
		_process_set_variables_on_nodes()
	# Process through the list of queued network transfers.
	_process_queued_network_updates()


func _process_set_properties_on_nodes() -> void:
	# Be sure to cache the keys first to avoid skipping elements.
	var prop_node_keys: Array = _set_queue_properties_on_nodes.keys()
	for prop_node in prop_node_keys:
		if has_node(prop_node):
			var node: Node = get_node(prop_node)
			var prop_value_dict = _set_queue_properties_on_nodes[prop_node]
			for prop in prop_value_dict:
				node.set(prop, prop_value_dict[prop])
			_set_queue_properties_on_nodes.erase(prop_node)


func _process_set_variables_on_nodes() -> void:
	# Be sure to cache the keys first to avoid skipping elements.
	var var_node_keys: Array = _set_queue_variables_on_nodes.keys()
	for var_node in var_node_keys:
		if has_node(var_node):
			var node: Node = get_node(var_node)
			if not node.has_meta(&"MirrorScriptObjectVariables"):
				node.set_meta(&"MirrorScriptObjectVariables", {})
			var object_variables: Dictionary = node.get_meta(&"MirrorScriptObjectVariables")
			var variable_value_dict = _set_queue_variables_on_nodes[var_node]
			for variable_name in variable_value_dict:
				object_variables[variable_name] = variable_value_dict[variable_name]
			_set_queue_variables_on_nodes.erase(var_node)


func _process_queued_network_updates() -> void:
	var is_server: bool = Zone.is_host()
	if not _net_queue_global_variables.is_empty():
		if is_server:
			# To avoid infinite loops, this defers the changed signal to the next frame.
			# We don't want to repeat the set logic in _set_global_variables_network
			# locally, but we still want to ensure the changed signals are emitted.
			for variable_name in _net_queue_global_variables:
				var value: Variant = _net_queue_global_variables[variable_name]
				# For setting, don't set it again here - it was already set immediately.
				global_variable_changed.emit(variable_name, value)
				# Also in this loop, convert it to be transfered over the network.
				_net_queue_global_variables[variable_name] = _convert_value_for_network_transfer(value)
			# If we start from the server, send the data to all clients.
			_set_global_variables_network.rpc(_net_queue_global_variables)
		else:
			# If we start from the client, tell the server about it.
			for variable_name in _net_queue_global_variables:
				var value: Variant = _net_queue_global_variables[variable_name]
				_net_queue_global_variables[variable_name] = _convert_value_for_network_transfer(value)
			_set_global_variables_client_to_server.rpc_id(Zone.SERVER_PEER_ID, _net_queue_global_variables)
		_net_queue_global_variables.clear()
	if not _net_queue_tweened_global_variables.is_empty():
		if is_server:
			for variable_name in _net_queue_tweened_global_variables:
				var tween_array: Array = _net_queue_tweened_global_variables[variable_name]
				var to_value: Variant = tween_array[0]
				var from_value: Variant = _global_variables.get(variable_name, type_convert(null, typeof(to_value)))
				_tween_variable_in_dict(_global_variables, variable_name, from_value, to_value, tween_array[1], tween_array[2], tween_array[3])
				global_variable_tweened.emit(variable_name, from_value, to_value, tween_array[1])
				# For tweening, skip convert value for network transfer because we
				# disallow object tweening (so it will never alter the data).
			_tween_global_variables_network.rpc(_net_queue_tweened_global_variables)
		else:
			_tween_global_variables_client_to_server.rpc_id(Zone.SERVER_PEER_ID, _net_queue_tweened_global_variables)
		_net_queue_tweened_global_variables.clear()
	# Node properties and variables. All four of the if statements below are similar to each other.
	if not _net_queue_node_properties.is_empty():
		if is_server:
			var nodepath_net_queue_node_properties: Dictionary = {}
			for node in _net_queue_node_properties:
				if not is_instance_valid(node):
					continue
				var node_properties: Dictionary = _net_queue_node_properties[node]
				for property_name in node_properties:
					var value: Variant = node_properties[property_name]
					if is_server:
						# For setting, don't set it again here - it was already set immediately.
						object_property_changed.emit(node, property_name, value)
					node_properties[property_name] = _convert_value_for_network_transfer(value)
				nodepath_net_queue_node_properties[node.get_path()] = node_properties
			_set_properties_on_nodes_network.rpc(nodepath_net_queue_node_properties)
		else:
			# Sync properties from server to clients but not clients to server.
			# This allows clients to have properties overridden for just them. See GH-1979
			# _set_properties_on_nodes_client_to_server.rpc_id(Zone.SERVER_PEER_ID, nodepath_net_queue_node_properties)
			pass
		_net_queue_node_properties.clear()
	if not _net_queue_tweened_node_properties.is_empty():
		var nodepath_net_queue_tweened_node_properties: Dictionary = {}
		for node in _net_queue_tweened_node_properties:
			if not is_instance_valid(node):
				continue
			var node_properties: Dictionary = _net_queue_tweened_node_properties[node]
			for property_name in node_properties:
				var tween_array: Array = node_properties[property_name]
				var to_value: Variant = tween_array[0]
				var from_value: Variant = node.get(property_name) # For properties, there is no default value parameter.
				if is_server:
					_tween_property_on_node(node, property_name, to_value, tween_array[1], tween_array[2], tween_array[3])
					object_property_tweened.emit(node, property_name, from_value, to_value, tween_array[1])
				# For tweening, skip convert value for network transfer because we
				# disallow object tweening (so it will never alter the data).
			nodepath_net_queue_tweened_node_properties[node.get_path()] = node_properties
		if is_server:
			_tween_properties_on_nodes_network.rpc(nodepath_net_queue_tweened_node_properties)
		else:
			# Sync properties from server to clients but not clients to server.
			# This allows clients to have properties overridden for just them. See GH-1979
			# _tween_properties_on_nodes_client_to_server.rpc_id(Zone.SERVER_PEER_ID, nodepath_net_queue_tweened_node_properties)
			pass
		_net_queue_tweened_node_properties.clear()
	if not _net_queue_node_variables.is_empty():
		var nodepath_net_queue_node_variables: Dictionary = {}
		for node in _net_queue_node_variables:
			if not is_instance_valid(node):
				continue
			var node_variables: Dictionary = _net_queue_node_variables[node]
			for variable_name in node_variables:
				var value: Variant = node_variables[variable_name]
				if is_server:
					# For setting, don't set it again here - it was already set immediately.
					object_variable_changed.emit(node, variable_name, value)
				node_variables[variable_name] = _convert_value_for_network_transfer(value)
			nodepath_net_queue_node_variables[node.get_path()] = node_variables
		if is_server:
			_set_variables_on_nodes_network.rpc(nodepath_net_queue_node_variables)
		else:
			_set_variables_on_nodes_client_to_server.rpc_id(Zone.SERVER_PEER_ID, nodepath_net_queue_node_variables)
		_net_queue_node_variables.clear()
	if not _net_queue_tweened_node_variables.is_empty():
		var nodepath_net_queue_tweened_node_variables: Dictionary = {}
		for node in _net_queue_tweened_node_variables:
			if not is_instance_valid(node):
				continue
			var node_variables: Dictionary = _net_queue_tweened_node_variables[node]
			for variable_name in node_variables:
				var tween_array: Array = node_variables[variable_name]
				var to_value: Variant = tween_array[0]
				var from_value: Variant = node.get_meta(&"MirrorScriptObjectVariables").get(variable_name, type_convert(null, typeof(to_value)))
				if is_server:
					_tween_variable_on_node(node, variable_name, to_value, tween_array[1], tween_array[2], tween_array[3])
					object_variable_tweened.emit(node, variable_name, from_value, to_value, tween_array[1])
				# For tweening, skip convert value for network transfer because we
				# disallow object tweening (so it will never alter the data).
			nodepath_net_queue_tweened_node_variables[node.get_path()] = node_variables
		if is_server:
			_tween_variables_on_nodes_network.rpc(nodepath_net_queue_tweened_node_variables)
		else:
			_tween_variables_on_nodes_client_to_server.rpc_id(Zone.SERVER_PEER_ID, nodepath_net_queue_tweened_node_variables)
		_net_queue_tweened_node_variables.clear()


func load_variables_from_database(space_variable_data: Dictionary, sync_back_to_database: bool) -> void:
	assert(Zone.is_host())
	# Only the server needs to load variables from the database.
	# The server will sync these to clients after they join.
	if space_variable_data.has("globalVariables"):
		_load_serialized_global_variables(space_variable_data["globalVariables"])
	if space_variable_data.has("nodeProperties"):
		_load_serialized_vars_props(space_variable_data["nodeProperties"], _all_set_properties_on_nodes)
		# Shallow copy. We need this data to be imported into 2 places.
		# We need to store all properties ever set, so that the server
		# can send all property data to new clients. The other is queued to
		# apply to nodes, the key is removed once the node starts existing.
		_set_queue_properties_on_nodes = _all_set_properties_on_nodes.duplicate(false)
	if space_variable_data.has("nodeVariables"):
		_load_serialized_vars_props(space_variable_data["nodeVariables"], _all_set_variables_on_nodes)
		_set_queue_variables_on_nodes = _all_set_variables_on_nodes.duplicate(false)
	variables_ready.emit()
	if sync_back_to_database:
		# Only the build mode server should run the timer to sync variables to the database.
		start(2.0)
	else:
		# In play mode, make a backup of the starting space vars so we have
		# something to revert to if the user clicks the New Match button.
		server_make_play_preview_space_vars_backup()


func server_enter_preview_mode() -> void:
	assert(Zone.is_host())
	_is_in_preview_mode = true
	server_make_play_preview_space_vars_backup()
	stop()


func server_exit_preview_mode() -> void:
	assert(Zone.is_host())
	_is_in_preview_mode = false
	server_restore_play_preview_space_vars_backup()
	# When exiting preview mode, wait a bit and restore again
	# to avoid preview mode data going back into build mode.
	await get_tree().create_timer(1.0)
	if _is_in_preview_mode:
		return # Avoid race condition when entering after exiting too quickly.
	server_restore_play_preview_space_vars_backup()
	# Re-enable the timer to sync variables to the database.
	start(2.0)


func server_make_play_preview_space_vars_backup() -> void:
	assert(Zone.is_host())
	_play_preview_space_backup_global_variables = _global_variables.duplicate(true)
	_play_preview_space_backup_properties_on_nodes = _all_set_properties_on_nodes.duplicate(true)
	_play_preview_space_backup_variables_on_nodes = _all_set_variables_on_nodes.duplicate(true)
	variables_ready.emit()


func server_restore_play_preview_space_vars_backup() -> void:
	assert(Zone.is_host())
	_global_variables = _play_preview_space_backup_global_variables.duplicate(true)
	_all_set_properties_on_nodes = _play_preview_space_backup_properties_on_nodes.duplicate(true)
	_all_set_variables_on_nodes = _play_preview_space_backup_variables_on_nodes.duplicate(true)
	# Shallow copy all variables/properties into the set queue. The set queue
	# will reapply all variables/properties to nodes, and remove when done.
	_set_queue_properties_on_nodes = _all_set_properties_on_nodes.duplicate(false)
	_set_queue_variables_on_nodes = _all_set_variables_on_nodes.duplicate(false)
	for peer_id in get_tree().get_multiplayer().get_peers():
		server_replace_all_data_on_peer(peer_id)
	variables_ready.emit()


func server_replace_all_data_on_peer(peer_id: int) -> void:
	_clean_up_dead_server_data()
	_set_all_variables_and_properties.rpc_id(peer_id, _global_variables,
			_all_set_properties_on_nodes, _all_set_variables_on_nodes)


func get_global_variable(variable_name: String) -> Variant:
	var value: Variant = TMDataUtil.get_variable_by_json_path_string(_global_variables, variable_name)
	# Since GDScript does not have out parameters, the above function
	# returns a special value when the variable does not exist.
	if is_signaling_null(value):
		if Zone.is_host():
			server_script_print_notify("Unable to Get Variable", "The variable " + variable_name + " does not exist.", Enums.NotifyStatus.ERROR)
		else:
			Notify.error("Unable to Get Variable", "The variable " + variable_name + " does not exist.")
		return null
	return value


func has_global_variable(variable_name: String) -> bool:
	return TMDataUtil.has_variable_by_json_path_string(_global_variables, variable_name)


func set_global_variable(variable_name: String, variable_value: Variant) -> void:
	TMDataUtil.set_variable_by_json_path_string(_global_variables, variable_name, variable_value)
	_net_queue_global_variables[variable_name] = variable_value


@rpc("call_remote", "any_peer", "reliable")
func _set_global_variables_client_to_server(variables: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_set_global_variables_network(variables)
	_set_global_variables_network.rpc(variables)


# Note: This function must be call_remote, or else _set_variable_by_json_path would run twice on the server.
@rpc("call_remote", "authority", "reliable")
func _set_global_variables_network(variables: Dictionary) -> void:
	for variable_name in variables:
		var value: Variant = _load_value_from_network_transfer(variables[variable_name])
		TMDataUtil.set_variable_by_json_path_string(_global_variables, variable_name, value)
		global_variable_changed.emit(variable_name, value)
	received_variable_data_change.emit()


func tween_global_variable(variable_name: String, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	_net_queue_tweened_global_variables[variable_name] = [to_value, duration, trans, easing]


@rpc("call_remote", "any_peer", "reliable")
func _tween_global_variables_client_to_server(tweened_variables: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_tween_global_variables_network(tweened_variables)
	_tween_global_variables_network.rpc(tweened_variables)


@rpc("call_remote", "authority", "reliable")
func _tween_global_variables_network(tweened_variables: Dictionary) -> void:
	for variable_name in tweened_variables:
		var tween_array: Array = tweened_variables[variable_name]
		var to_value: Variant = tween_array[0]
		var from_value: Variant = _global_variables.get(variable_name, type_convert(null, typeof(to_value)))
		var duration: float = tween_array[1]
		_tween_variable_in_dict(_global_variables, variable_name, from_value, to_value, duration, tween_array[2], tween_array[3])
		global_variable_tweened.emit(variable_name, from_value, to_value, duration)
	received_variable_data_change.emit()


## Tween a user variable we store inside of a Dictionary using MethodTweener.
func _tween_variable_in_dict(variables_dict: Dictionary, variable_name: String, from_value: Variant, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	var split_path: PackedStringArray = TMDataUtil.split_json_path_string(variable_name)
	var method_callable: Callable = _tween_variable_callback_method.bind(variables_dict, split_path)
	var tween: Tween = get_tree().create_tween()
	var method_tweener: MethodTweener = tween.tween_method(method_callable, from_value, to_value, duration)
	if method_tweener == null:
		Notify.error("Tween Error", "Type mismatch between the from and to values while tweening variable '" + variable_name + "'.")
		return
	method_tweener.set_trans(trans)
	method_tweener.set_ease(easing)


func _tween_variable_callback_method(value: Variant, variables_dict: Dictionary, variable_path: PackedStringArray) -> void:
	TMDataUtil.set_variable_by_json_path(variables_dict, variable_path, value)


func delete_global_variable(variable_name: String) -> void:
	_global_variables.erase(variable_name)
	if Zone.is_host():
		_delete_global_variable_network.rpc(variable_name)
	else:
		_delete_global_variable_client_to_server.rpc_id(Zone.SERVER_PEER_ID, variable_name)


@rpc("call_remote", "any_peer", "reliable")
func _delete_global_variable_client_to_server(variable_name: String) -> void:
	_global_variables.erase(variable_name)
	_delete_global_variable_network.rpc(variable_name)


@rpc("call_remote", "authority", "reliable")
func _delete_global_variable_network(variable_name: String) -> void:
	_global_variables.erase(variable_name)


# Node properties.
func set_property_on_node(node: Node, property: StringName, value: Variant) -> void:
	var net_queue_props: Dictionary = _net_queue_node_properties.get_or_add(node, {})
	net_queue_props[property] = value
	_set_property_on_node(node, property, value)


@rpc("call_remote", "any_peer", "reliable")
func _set_properties_on_nodes_client_to_server(nodes_properties: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_set_properties_on_nodes_network(nodes_properties)
	_set_properties_on_nodes_network.rpc(nodes_properties)
	# Keep track of all properties ever set so that we can send this to new clients.
	for node_path in nodes_properties:
		var node_properties: Dictionary = nodes_properties[node_path]
		_save_for_later(node_path, node_properties, _all_set_properties_on_nodes)


@rpc("call_remote", "authority", "reliable")
func _set_properties_on_nodes_network(nodes_properties: Dictionary) -> void:
	for node_path in nodes_properties:
		var node_properties: Dictionary = nodes_properties[node_path]
		if has_node(node_path):
			var node: Node = get_node(node_path)
			for property_name in node_properties:
				var value: Variant = _load_value_from_network_transfer(node_properties[property_name])
				_set_property_on_node(node, property_name, value)
		else:
			_save_for_later(node_path, node_properties, _set_queue_properties_on_nodes)


func _set_property_on_node(node: Node, property: StringName, value: Variant) -> void:
	if not ScriptPropertyRegistration.has_registered_property(property):
		push_error("You can't set this property it was not registered.")
		return
	# If needed in the future, we could also save this in _all_set_properties_on_nodes.
	node.set(property, value)


func tween_property_on_node(node: Node, property: StringName, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if to_value is Object:
		Notify.error("Tween Failed", "Tweening an object is not a sensible operation. Aborting.")
		return
	var net_queue_props: Dictionary = _net_queue_tweened_node_properties.get_or_add(node, {})
	net_queue_props[property] = [to_value, duration, trans, easing]


@rpc("call_remote", "any_peer", "reliable")
func _tween_properties_on_nodes_client_to_server(nodes_tweened_properties: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_tween_properties_on_nodes_network(nodes_tweened_properties)
	_tween_properties_on_nodes_network.rpc(nodes_tweened_properties)
	# Keep track of all properties ever set so that we can send this to new clients.
	# Note: We save these as the set properties, so new clients will miss out
	# on tweens started before they joined. However this should be fine.
	for node_path in nodes_tweened_properties:
		var node_tweened_properties: Dictionary = nodes_tweened_properties[node_path]
		_save_tween_results_for_later(node_path, node_tweened_properties, _all_set_properties_on_nodes)


@rpc("call_remote", "authority", "reliable")
func _tween_properties_on_nodes_network(nodes_tweened_properties: Dictionary) -> void:
	for node_path in nodes_tweened_properties:
		var node_tweened_properties: Dictionary = nodes_tweened_properties[node_path]
		if has_node(node_path):
			var node: Node = get_node(node_path)
			for property_name in node_tweened_properties:
				var tween_array: Array = node_tweened_properties[property_name]
				_tween_property_on_node(node, property_name, tween_array[0], tween_array[1], tween_array[2], tween_array[3])
		else:
			_save_tween_results_for_later(node_path, node_tweened_properties, _set_queue_properties_on_nodes)


func _tween_property_on_node(node: Node, property: StringName, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if not ScriptPropertyRegistration.has_registered_property(property):
		return
	var tween: Tween = get_tree().create_tween()
	var prop_tweener: PropertyTweener = tween.tween_property(node, NodePath.from_string_name(property), to_value, duration)
	prop_tweener.set_trans(trans)
	prop_tweener.set_ease(easing)


# Node variables.
func get_all_node_paths_with_variables() -> Array:
	return _all_set_variables_on_nodes.keys()


func get_variables_on_node_at_path(node_path: NodePath) -> Dictionary:
	return _all_set_variables_on_nodes[node_path]


func set_variable_on_node_at_path(node_path: NodePath, variable: String, value: Variant) -> void:
	var node: Node = get_node(node_path)
	var net_queue_vars: Dictionary = _net_queue_node_variables.get_or_add(node, {})
	net_queue_vars[variable] = value
	_set_variable_on_node(node, variable, value)


func set_variable_on_node(node: Node, variable: String, value: Variant) -> void:
	var net_queue_vars: Dictionary = _net_queue_node_variables.get_or_add(node, {})
	net_queue_vars[variable] = value
	_set_variable_on_node(node, variable, value)


@rpc("call_remote", "any_peer", "reliable")
func _set_variables_on_nodes_client_to_server(nodes_variables: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_set_variables_on_nodes_network(nodes_variables)
	_set_variables_on_nodes_network.rpc(nodes_variables)
	# Keep track of all variables ever set so that we can send this to new clients.
	for node_path in nodes_variables:
		var node_variables: Dictionary = nodes_variables[node_path]
		_save_for_later(node_path, node_variables, _all_set_variables_on_nodes)


@rpc("call_remote", "authority", "reliable")
func _set_variables_on_nodes_network(nodes_variables: Dictionary) -> void:
	for node_path in nodes_variables:
		var node_variables: Dictionary = nodes_variables[node_path]
		if has_node(node_path):
			var node: Node = get_node(node_path)
			for variable_name in node_variables:
				var value: Variant = _load_value_from_network_transfer(node_variables[variable_name])
				_set_variable_on_node(node, variable_name, value)
				object_variable_changed.emit(node, variable_name, value)
		else:
			_save_for_later(node_path, node_variables, _set_queue_variables_on_nodes)
	received_variable_data_change.emit()


func _set_variable_on_node(node: Node, variable_name: String, variable_value: Variant) -> void:
	if not node.has_meta(&"MirrorScriptObjectVariables"):
		node.set_meta(&"MirrorScriptObjectVariables", {})
	var object_variables: Dictionary = node.get_meta(&"MirrorScriptObjectVariables")
	TMDataUtil.set_variable_by_json_path_string(object_variables, variable_name, variable_value)
	# If this is an exposed script variable, set it in the script.
	if node.has_method(&"get_script_instances") and Zone.is_host():
		var script_instances: Array[ScriptInstance] = node.get_script_instances()
		for script_inst in script_instances:
			if script_inst is GDScriptInstance and is_instance_valid(script_inst.script_instance_object):
				var obj = script_inst.script_instance_object
				if variable_name in obj:
					obj.set(variable_name, variable_value)
	# Keep track of all node variables ever set for use with the variable editor.
	var node_path: NodePath = node.get_path()
	var node_variables_in_all: Dictionary = _all_set_variables_on_nodes.get_or_add(node_path, {})
	TMDataUtil.set_variable_by_json_path_string(node_variables_in_all, variable_name, variable_value)


func tween_variable_on_node(node: Node, variable: String, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if to_value is Object:
		Notify.error("Tween Failed", "Tweening an Object value is not a sensible operation. Aborting.")
		return
	var net_queue_vars: Dictionary = _net_queue_tweened_node_variables.get_or_add(node, {})
	net_queue_vars[variable] = [to_value, duration, trans, easing]


@rpc("call_remote", "any_peer", "reliable")
func _tween_variables_on_nodes_client_to_server(nodes_variables: Dictionary) -> void:
	# When a client tells the server about setting variables, set on the server and send to all clients.
	_tween_variables_on_nodes_network(nodes_variables)
	_tween_variables_on_nodes_network.rpc(nodes_variables)
	# Keep track of all variables ever set so that we can send this to new clients.
	# Note: We save these as the set properties, so new clients will miss out
	# on tweens started before they joined. However this should be fine.
	for node_path in nodes_variables:
		var node_variables: Dictionary = nodes_variables[node_path]
		_save_tween_results_for_later(node_path, node_variables, _all_set_variables_on_nodes)


@rpc("call_remote", "authority", "reliable")
func _tween_variables_on_nodes_network(nodes_tweened_variables: Dictionary) -> void:
	for node_path in nodes_tweened_variables:
		var node_tweened_variables: Dictionary = nodes_tweened_variables[node_path]
		if has_node(node_path):
			var node: Node = get_node(node_path)
			for variable_name in node_tweened_variables:
				var tween_array: Array = node_tweened_variables[variable_name]
				_tween_variable_on_node(node, variable_name, tween_array[0], tween_array[1], tween_array[2], tween_array[3])
		else:
			_save_tween_results_for_later(node_path, node_tweened_variables, _set_queue_variables_on_nodes)
	received_variable_data_change.emit()


func _tween_variable_on_node(node: Node, variable_name: String, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if not node.has_meta(&"MirrorScriptObjectVariables"):
		node.set_meta(&"MirrorScriptObjectVariables", {})
	var object_variables: Dictionary = node.get_meta(&"MirrorScriptObjectVariables")
	var from_value: Variant = object_variables.get(variable_name, type_convert(null, typeof(to_value)))
	_tween_variable_in_dict(object_variables, variable_name, from_value, to_value, duration, trans, easing)
	object_variable_tweened.emit(node, variable_name, from_value, to_value, duration)


func delete_variable_on_node_at_path(node_path: NodePath, variable_name: String) -> void:
	_delete_variable_on_node_at_path_network(node_path, variable_name)
	if Zone.is_host():
		_delete_variable_on_node_at_path_network.rpc(variable_name)
	else:
		_delete_variable_on_node_at_path_client_to_server.rpc_id(Zone.SERVER_PEER_ID, variable_name)


@rpc("call_remote", "any_peer", "reliable")
func _delete_variable_on_node_at_path_client_to_server(node_path: NodePath, variable_name: String) -> void:
	_delete_variable_on_node_at_path_network(node_path, variable_name)
	_delete_variable_on_node_at_path_network.rpc(node_path, variable_name)


@rpc("call_remote", "authority", "reliable")
func _delete_variable_on_node_at_path_network(node_path: NodePath, variable_name: String) -> void:
	var node = get_node(node_path)
	if node and node.has_meta(&"MirrorScriptObjectVariables"):
		var node_variables = node.get_meta(&"MirrorScriptObjectVariables")
		node_variables.erase(variable_name)
	if _all_set_variables_on_nodes.has(node_path):
		var all_set_vars_for_node = _all_set_variables_on_nodes[node_path]
		all_set_vars_for_node.erase(variable_name)


## Run this on disconnect to avoid cross-space interference.
func client_clear_pending_set_properties_and_variables() -> void:
	assert(Zone.is_client())
	_global_variables.clear()
	_set_queue_properties_on_nodes.clear()
	_set_queue_variables_on_nodes.clear()
	_net_queue_global_variables.clear()
	_net_queue_node_properties.clear()
	_net_queue_node_variables.clear()


@rpc("call_remote", "authority", "reliable")
func _set_all_variables_and_properties(set_global_variables: Dictionary,
		set_node_properties: Dictionary, set_node_variables: Dictionary) -> void:
	# Replace all variables and properties, discard all previous data.
	_global_variables = set_global_variables
	_all_set_properties_on_nodes = set_node_properties
	_all_set_variables_on_nodes = set_node_variables
	_set_queue_properties_on_nodes = set_node_properties.duplicate(false)
	_set_queue_variables_on_nodes = set_node_variables.duplicate(false)
	variables_ready.emit()


func _save_tween_results_for_later(node_path: NodePath, node_tweened_properties: Dictionary, on_dict: Dictionary) -> void:
	var node_properties: Dictionary = {}
	for prop_name in node_tweened_properties:
		var tween_array: Array = node_tweened_properties[prop_name]
		node_properties[prop_name] = tween_array[0]
	_save_for_later(node_path, node_properties, on_dict)


func _save_for_later(node_path: NodePath, node_properties: Dictionary, on_dict: Dictionary) -> void:
	if on_dict.has(node_path):
		on_dict[node_path].merge(node_properties, true)
	else:
		on_dict[node_path] = node_properties


## Run this before sending the properties to a client to avoid sending dead properties/variables.
## Note that this will cause issues if a client joints before the server loads in objects.
func _clean_up_dead_server_data() -> void:
	# Be sure to cache the keys first to avoid skipping elements.
	var prop_node_keys: Array = _all_set_properties_on_nodes.keys()
	for prop_node_path in prop_node_keys:
		if not has_node(prop_node_path):
			_all_set_properties_on_nodes.erase(prop_node_path)
	var var_node_keys: Array = _all_set_variables_on_nodes.keys()
	for var_node_path in var_node_keys:
		if not has_node(var_node_path):
			_all_set_variables_on_nodes.erase(var_node_path)


## Not to be confused with serializing for the DB - we still use Godot's types
## here. We just need to ensure we don't try to send object references.
func _convert_value_for_network_transfer(value: Variant) -> Variant:
	if value is Node:
		return value.get_path()
	return value


func _load_value_from_network_transfer(value: Variant) -> Variant:
	if value is NodePath:
		return get_node(value)
	return value


func _serialize_variables_and_emit_sync_to_db() -> void:
	var var_prop_data: Dictionary = {}
	# Set these in alphabetical order to be consistent with how the DB stores them.
	if not _global_variables.is_empty():
		var_prop_data["globalVariables"] = _serialize_global_variables()
	if not _all_set_properties_on_nodes.is_empty():
		var_prop_data["nodeProperties"] = _serialize_node_vars_props(_all_set_properties_on_nodes)
	if not _all_set_variables_on_nodes.is_empty():
		var_prop_data["nodeVariables"] = _serialize_node_vars_props(_all_set_variables_on_nodes)
	request_sync_variables_to_database.emit(var_prop_data)


func _serialize_global_variables() -> Dictionary:
	var destination: Dictionary = {}
	for var_name in _global_variables:
		var value: Variant = _global_variables[var_name]
		destination[var_name] = {
			"type": Serialization.type_enum_to_string(typeof(value)),
			"value": Serialization.type_convert_to_json(value)
		}
	return destination


func _serialize_node_vars_props(input_data: Dictionary) -> Dictionary:
	var serialized_node_data: Dictionary = {}
	for node_path in input_data:
		_serialize_node_vars_props_for_path(node_path, input_data[node_path], serialized_node_data)
	return serialized_node_data


func _serialize_node_vars_props_for_path(node_path: NodePath, input_node_data: Dictionary, destination: Dictionary) -> void:
	for i in range(1, node_path.get_name_count()):
		var path_name: StringName = node_path.get_name(i)
		destination = destination.get_or_add(path_name, {})
	_serialize_var_prop_data(input_node_data, destination)


func _serialize_var_prop_data(input_data: Dictionary, destination: Dictionary) -> void:
	for var_name in input_data:
		var value: Variant = input_data[var_name]
		destination[":" + var_name] = {
			"type": Serialization.type_enum_to_string(typeof(value)),
			"value": Serialization.type_convert_to_json(value)
		}


func _load_serialized_global_variables(serialized_data: Dictionary) -> void:
	_global_variables.clear()
	for var_name in serialized_data:
		var data: Dictionary = serialized_data[var_name]
		_global_variables[var_name] = Serialization.type_convert_from_json(data["value"],
				Serialization.type_string_to_enum(data["type"]))


func _load_serialized_vars_props(input_data: Dictionary, destination: Dictionary, path_string: String = "/root") -> void:
	var node_variables = null # Dictionary?
	for key in input_data:
		var value: Dictionary = input_data[key]
		if key.begins_with(":"):
			if node_variables == null:
				node_variables = {}
				destination[NodePath(path_string)] = node_variables
			var trimmed_name: String = key.trim_prefix(":")
			var data: Dictionary = value
			node_variables[trimmed_name] = Serialization.type_convert_from_json(data["value"],
					Serialization.type_string_to_enum(data["type"]))
		else:
			_load_serialized_vars_props(value, destination, path_string + "/" + key)


# Animation.
func server_play_animation_on_clients(animation_player: AnimationPlayer, animation_name: String, animation_speed: float) -> void:
	var animation_player_path: String = animation_player.get_path()
	_server_play_animation_on_clients_network.rpc(animation_player_path, animation_name, animation_speed)


@rpc("call_remote", "authority", "reliable")
func _server_play_animation_on_clients_network(animation_player_path: String, animation_name: String, animation_speed: float) -> void:
	var animation_player: AnimationPlayer = get_node(animation_player_path)
	if not animation_player:
		return
	if animation_name == &"stop":
		animation_player.stop()
		return
	if animation_name == &"pause":
		animation_player.pause()
		return
	if not animation_player.has_animation(animation_name):
		Notify.error("Failed to play animation", "The AnimationPlayer node does not have the animation '" + animation_name + "' in the list of animations:\n" + str(animation_player.get_animation_list()))
		return
	# Set the entire AnimationPlayer's speed scale, but keep the play method's
	# individual animation scale at 1.0. This allows retrieving the speed later.
	animation_player.set_speed_scale(animation_speed)
	animation_player.play(animation_name, -1.0, 1.0, animation_speed < 0.0)


# Audio.
func server_play_audio_clip_on_clients(at_node: Node, audio_asset_id: String, base_volume_percent: float, speed: float, is_spatial: bool, spatial_range: float, spatial_max_volume_percent: float) -> void:
	_server_play_audio_clip_on_clients_network.rpc(at_node.get_path(), audio_asset_id, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)


@rpc("call_remote", "authority", "reliable")
func _server_play_audio_clip_on_clients_network(at_node_path: NodePath, audio_asset_id: String, base_volume_percent: float, speed: float, is_spatial: bool, spatial_range: float, spatial_max_volume_percent: float) -> void:
	var at_node: Node = get_node(at_node_path)
	if not at_node:
		return
	var audio_player := AudioClipAssetPlayer.new()
	at_node.add_child(audio_player)
	audio_player.play_from_asset_id(audio_asset_id, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)


func server_play_audio_node_custom_settings_on_clients(audio_player_node: TMAudioPlayer3D, loop_audio: bool, base_volume_percent: float, speed: float, is_spatial: bool, spatial_range: float, spatial_max_volume_percent: float) -> void:
	_server_play_audio_node_custom_settings_on_clients_network.rpc(audio_player_node.get_path(), loop_audio, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)
	# We need to play the audio even on the server, to ensure "Is Playing" blocks work and to run the "finished" signals.
	audio_player_node.loop_audio = loop_audio
	audio_player_node.base_volume_percentage = base_volume_percent
	audio_player_node.pitch_scale = speed
	audio_player_node.is_spatial = is_spatial
	audio_player_node.spatial_range = spatial_range
	audio_player_node.spatial_max_volume_percentage = spatial_max_volume_percent
	audio_player_node.play()


@rpc("call_remote", "authority", "reliable")
func _server_play_audio_node_custom_settings_on_clients_network(audio_player_path: NodePath, loop_audio: bool, base_volume_percent: float, speed: float, is_spatial: bool, spatial_range: float, spatial_max_volume_percent: float) -> void:
	var audio_player_node = get_node(audio_player_path)
	if not audio_player_node is TMAudioPlayer3D:
		return
	audio_player_node.loop_audio = loop_audio
	audio_player_node.base_volume_percentage = base_volume_percent
	audio_player_node.pitch_scale = speed
	audio_player_node.is_spatial = is_spatial
	audio_player_node.spatial_range = spatial_range
	audio_player_node.spatial_max_volume_percentage = spatial_max_volume_percent
	audio_player_node.play()


func server_play_audio_node_same_settings_on_clients(audio_player_node: Node) -> void:
	_server_play_audio_node_same_settings_on_clients_network.rpc(audio_player_node.get_path())
	audio_player_node.play()


@rpc("call_remote", "authority", "reliable")
func _server_play_audio_node_same_settings_on_clients_network(audio_player_path: NodePath) -> void:
	var audio_player_node = get_node(audio_player_path)
	if audio_player_node is AudioStreamPlayer or audio_player_node is AudioStreamPlayer3D:
		audio_player_node.play()


func server_stop_audio_node_on_clients(audio_player_node: Node) -> void:
	_server_stop_audio_node_on_clients_network.rpc(audio_player_node.get_path())
	audio_player_node.stop()


@rpc("call_remote", "authority", "reliable")
func _server_stop_audio_node_on_clients_network(audio_player_path: NodePath) -> void:
	var audio_player_node = get_node(audio_player_path)
	if audio_player_node is AudioStreamPlayer or audio_player_node is AudioStreamPlayer3D:
		audio_player_node.stop()


# GDScript runtime error handling.
func handle_tmusergdscript_runtime_error(script_instance: GDScriptInstance, error_message: String, line_number: int) -> void:
	if Zone.is_client():
		_handle_tmusergdscript_runtime_error_on_clients(script_instance, error_message, line_number)
		return
	var target_node_path = script_instance.target_node.get_path()
	_handle_tmusergdscript_runtime_error_server_to_clients.rpc(target_node_path, script_instance.script_id, error_message, line_number)


@rpc("call_remote", "authority", "reliable")
func _handle_tmusergdscript_runtime_error_server_to_clients(target_node_path: NodePath, script_id: String, error_message: String, line_number: int) -> void:
	var target_node: Node = get_node(target_node_path)
	if target_node and target_node.has_method(&"get_script_instances"):
		var script_instances: Array[ScriptInstance] = target_node.get_script_instances()
		for script_inst in script_instances:
			if script_inst.script_id == script_id:
				_handle_tmusergdscript_runtime_error_on_clients(script_inst, error_message, line_number)
				return
	# No matching script on the object? Plan B, do we have any script instance matching this?
	var any_script_inst: ScriptInstance = Net.script_client.get_any_script_instance_for_script_id(script_id)
	if any_script_inst:
		_handle_tmusergdscript_runtime_error_on_clients(any_script_inst, error_message, line_number)
	# Plan C, just print the message bare.
	Notify.error("GDScript Error", error_message)


func _handle_tmusergdscript_runtime_error_on_clients(script_instance: ScriptInstance, error_message: String, line_number: int) -> void:
	if GameUI.creator_ui:
		if GameUI.creator_ui.show_error_in_gd_script_editor_if_open(script_instance, line_number, error_message):
			return
	# If the script editor is not open, display a notification with a link to open.
	var obj_name_error: String = error_message
	if script_instance.target_node is SpaceObject:
		obj_name_error = script_instance.target_node.get_space_object_name() + ": " + error_message
	elif script_instance.target_node is SpaceGlobalScripts:
		obj_name_error = "Global script: " + error_message
	Notify.error("GDScript Error", obj_name_error, GameUI.creator_ui.show_error_in_gd_script_editor_if_open.bind(script_instance, line_number, error_message))


# Physics.
func server_add_force_to_body_over_time(physics_body: JBody3D, force_amount: Vector3, duration: float) -> void:
	_server_add_force_to_body_over_time_network.rpc(physics_body.get_path(), force_amount, duration)


# This method performs the force adding on the client to reduce jitter, but
# it's not vital, and if it fails we want it to stop trying (thus unreliable).
@rpc("call_remote", "authority", "unreliable")
func _server_add_force_to_body_over_time_network(physics_body_path: NodePath, force_amount: Vector3, duration: float) -> void:
	var physics_body = get_node(physics_body_path)
	if physics_body is JBody3D:
		MirrorScriptServer.add_force_to_body_over_time(physics_body, force_amount, duration)


# Player interaction.
func client_to_server_player_interact(interaction_target: Node, player: Player) -> void:
	_client_to_server_player_interact_network.rpc_id(Zone.SERVER_PEER_ID, interaction_target.get_path(), player.name)


@rpc("call_remote", "any_peer", "reliable")
func _client_to_server_player_interact_network(interact_target_path: String, player_id: String) -> void:
	var interaction_target: Node = get_node(interact_target_path)
	var player: Player = Zone.social_manager.get_player(player_id)
	if interaction_target and player and interaction_target.has_user_signal(&"player_interact"):
		interaction_target.emit_signal(&"player_interact", player)
	else:
		printerr("Script network sync error: Player interaction failed.")


# Notify.
func server_script_print_notify(title: String, message: String, status: Enums.NotifyStatus) -> void:
	_server_script_print_notify_network.rpc(title, message, status)


@rpc("call_remote", "authority", "reliable")
func _server_script_print_notify_network(title: String, message: String, status: Enums.NotifyStatus) -> void:
	Notify.status(title, message, status)

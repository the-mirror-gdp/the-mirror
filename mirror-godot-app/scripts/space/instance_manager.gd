class_name InstanceManager
extends Node3D


signal space_objects_created()
signal space_object_created(space_object, uuid)
signal space_object_updated(instance_id)
signal space_object_removed(instance_id)
signal children_cleared()

@export var _space_object_scene: PackedScene

# Ready to simulate controls if the client and server unfreezes the objects
var ready_to_simulate: bool = false
var remotely_selected_nodes: Array
var space_object_validate_selection_time := 0.5
var space_object_validate_selection_timer := 0.0
var _pending_objects = []
var _load_object_start_time = 0


func _process(delta: float) -> void:
	if not Zone.bootup_completed:
		return
	if TMSceneSync.is_server():
		validate_selection(delta)


func validate_selection(delta: float):
	space_object_validate_selection_timer += delta
	if space_object_validate_selection_timer < space_object_validate_selection_time:
		return

	space_object_validate_selection_timer = 0.0

	for selected_node in remotely_selected_nodes:
		if not is_instance_valid(selected_node) or not (selected_node is TMSpaceObjectBase):
			continue
		var so: TMSpaceObjectBase = selected_node
		var peers_to_remove := []
		for peer in so.selected_by_peers:
			var character = Zone.find_player_by_peer(peer)
			if not character:
				# The peer disconnected
				peers_to_remove.push_back(peer)
			elif not character.currently_selected_space_object_ids.has(TMSceneSync.get_node_id(so)):
				# This is a safety and redundant measure in case something
				# breaks with future updates: this will prevent the SpaceObject to remain
				# selected (and so stuck) until the server is restarted.
				peers_to_remove.push_back(peer)

		for peer in peers_to_remove:
			so.notify_peer_selection_end(peer)


func get_all_instances() -> Array: #Array<SpaceObject>
	return get_children()


func reset_all_instances() -> void:
	for space_instance_json_data in Zone.space_objects:
		var instance_id: String = space_instance_json_data.get("_id")
		if not has_node(instance_id):
			continue
		var instance = get_node(instance_id)
		if not is_instance_valid(instance):
			continue
		instance.set_active(false)
		instance.populate(space_instance_json_data)


func clear_children() -> void:
	ready_to_simulate = false
	for space_object in get_children():
		remove_child(space_object)
		space_object.cleanup_and_delete_space_object()
	children_cleared.emit()


func _are_preloaded_space_objects_setup(instances) -> bool:
	for space_obj in instances:
		if not is_instance_valid(space_obj):
			continue # skip this
		if space_obj.is_error():
			continue # skip this
		if (not space_obj.is_ready()) and space_obj.is_preloaded:
			return false
	return true


func _await_assets_preloaded() -> void:
	var instances = get_all_instances()
	var now = Time.get_unix_time_from_system()
	var timeout = now + 240
	var files_preloaded = false
	while now < timeout and not files_preloaded:
		if _are_preloaded_space_objects_setup(instances):
			files_preloaded = true
			break
		await get_tree().create_timer(3).timeout
	if not files_preloaded:
		Zone.space_load_timed_out.emit()
		return

	Zone.space_preload_done = true

func _preload_space_objects() -> void:
	assert(Zone.is_host())
	for space_obj in Zone.space_objects:
		if not space_obj.get("preloadBeforeSpaceStarts", false):
			continue
		var instance_id: String = space_obj["_id"]
		if has_node(instance_id):
			var instance = get_node(instance_id)
			if is_instance_valid(instance):
				instance.populate(space_obj)
				continue
		else:
			create_space_object(space_obj, {})
	_await_assets_preloaded()


func setup_space_objects() -> void:
	assert(Zone.is_host())
	clear_children()
	# preload necessary space_objects on server first
	_preload_space_objects()
	_load_object_start_time = Time.get_unix_time_from_system()
	for space_obj in Zone.space_objects:
		if space_obj.get("preloadBeforeSpaceStarts", false):
			continue
		var instance_id: String = space_obj["_id"]
		if has_node(instance_id):
			var instance = get_node(instance_id)
			if is_instance_valid(instance):
				instance.populate(space_obj)
				continue
		else:
			create_space_object(space_obj, {})
	await wait_until_ready_to_simulate()
	print("Completed loading server objects took %d seconds" % (Time.get_unix_time_from_system() - _load_object_start_time))
	space_objects_created.emit()


func wait_until_ready_to_simulate():
	# set this to one so we can ensure the check runs at least once
	var remaining_objects = count_remaining_objects_to_be_ready()
	var last_objects_to_load = -1

	while remaining_objects > 0:
		remaining_objects = count_remaining_objects_to_be_ready()
		if remaining_objects != last_objects_to_load:
			var loaded_objects_per_second = last_objects_to_load - remaining_objects
			last_objects_to_load = remaining_objects
			print("Space object loading: ", count_loaded_objects(), "/", Zone.space_objects.size())
			print("Objects loaded per second: ", max(0, loaded_objects_per_second))
		# we need a better way of finding the bad entities in the space.
		# we can probably have an is_errored() method on space object for failures in
		# loading glb files this would be handy on the client too for skipping loading
		# broken objects as this can soft lock in a hidden manner right now.
		if remaining_objects == 1:
			count_remaining_objects_to_be_ready()
		await get_tree().create_timer(1).timeout

	# cant be reached on some spaces this is a logic error we should resolve
	# see comment above
	ready_to_simulate_physics_objects()
	ready_to_simulate_physics_objects.rpc()


@rpc("call_remote", "any_peer", "reliable")
func ready_to_simulate_physics_objects() -> void:
	# prevent this running more than once
	if ready_to_simulate:
		return
	print("Physics simulation has begun on the ", Zone.get_instance_type())
	ready_to_simulate = true
	for space_obj in get_children():
		if not is_instance_valid(space_obj):
			continue
		if not (space_obj is SpaceObject):
			continue
		if space_obj.is_error():
			continue
		space_obj.force_refresh_collision_layers()


@rpc("call_remote", "any_peer", "reliable")
func is_local_client_ready():
	assert(Zone.is_host())
	var peer_id: int = get_tree().get_multiplayer().get_remote_sender_id()
	if ready_to_simulate:
		ready_to_simulate_physics_objects.rpc_id(peer_id)


func count_remaining_objects_to_be_ready() -> int:
	var count = 0
	for space_obj in get_children():
		# we can safely skip invalid instances
		# they can be caused by deleted space objects
		if not is_instance_valid(space_obj):
			push_error("invalid instance")
			continue
		if not (space_obj is SpaceObject):
			continue
		if space_obj.is_error():
			push_error(Zone.get_instance_type(), " skipped errored object: ", space_obj.get_space_object_name(), "path", space_obj.get_path())
			continue
		if space_obj.is_ready():
			if _pending_objects.has(space_obj):
				_pending_objects.erase(space_obj)
		else:
			if not _pending_objects.has(space_obj):
				_pending_objects.push_back(space_obj)
			count+=1
	return count


func count_loaded_objects() -> int:
	var count = 0
	for space_obj in get_children():
		# we can safely skip invalid instances
		# they can be caused by deleted space objects
		if not is_instance_valid(space_obj):
			push_error("invalid instance")
			continue
		if not (space_obj is SpaceObject):
			continue
		if space_obj.is_error():
			push_error(Zone.get_instance_type(), " skipped errored object: ", space_obj.get_space_object_name(), "path", space_obj.get_path())
			continue
		if not space_obj.is_ready():
			continue
		count+=1
	return count


func update_space_object(space_obj: Dictionary) -> void:
	var instance_id: String = space_obj["_id"]
	var instance = get_node(instance_id)
	if is_instance_valid(instance):
		instance.populate(space_obj)
		space_object_updated.emit(instance.get_instance_id())
		return
	push_error("No instance found for a space object, corrupt instances")


func remove_space_object_by_id(space_object_id: String) -> void:
	var node_path := NodePath(space_object_id)
	if has_node(node_path):
		remove_space_object(get_node(node_path))


func remove_space_object(space_object: SpaceObject) -> void:
	if not is_instance_valid(space_object):
		return
	space_object.cleanup_and_delete_space_object()
	remove_child(space_object)
	space_object_removed.emit(space_object.get_instance_id())


## This method is used to readd a SpaceObject to scene tree.
## This will retrigger all singals that are executed on `child_entered_tree`
func _readd_space_object(instance: SpaceObject) -> void:
	remove_child(instance)
	add_child(instance)


func create_space_object(space_object_dictionary: Dictionary, receipt: Dictionary) -> void:
	if has_node(space_object_dictionary["_id"]):
		push_error("Trying to create a node again?")
		return
	var instance: SpaceObject = _space_object_scene.instantiate()
	instance.name = space_object_dictionary["_id"]
	add_child(instance)
	var node_name_helper = Node.new()
	node_name_helper.name = space_object_dictionary["name"]
	instance.add_child(node_name_helper)
	instance.populate(space_object_dictionary)
	if instance.is_preloaded and not Zone.is_host() and not instance.is_ready():
		await _await_assets_preloaded()
		if not is_instance_valid(instance):
			return
		_readd_space_object(instance)

	# joining the game should not run this code
	if space_object_dictionary.has("receipt"):
		push_error("The SpaceObject itself should not have a receipt.")
		return

	space_object_created.emit(instance, receipt.get("uuid", ""))
	var extracted_user_id: String = receipt.get("created_by_user", "")
	if Zone.is_client():
		var local_user_id: String = str(PlayerData.get_local_user_id())
		var created_by_local_user: bool = extracted_user_id == local_user_id
		if created_by_local_user:
			var auto_select: bool = receipt.get("auto_select", false)
			if auto_select:
				GameUI.creator_ui.select_object(instance)


# This function is called by the client to load the space objects
# We call this to ensure preloaded objects are loaded correctly
# We skip any errored space objects now too, except for terrain
func client_await_assets_loaded() -> void:
	var now = Time.get_unix_time_from_system()
	var timeout = now + 240
	var files_loaded = false
	while now < timeout and not files_loaded:
		var instances = get_all_instances()
		# if we're the client we need to exit this event if we don't want to finish joining
		# this resolves rejoining breaking
		if Zone.is_client() and not Zone.client.is_client_connected_to_server():
			return
		if _are_preloaded_space_objects_setup(instances):
			Zone.space_preload_done = true
			# We can't break here, as all assets may not be fully loaded, but it's harmless
		else:
			print("%s Waiting for preloaded SpaceObjects.." % Zone.get_instance_type(), " objects: ", _what_spaceobjects_arent_loaded(instances))
		if _are_space_objects_setup(instances):
			files_loaded = true
			break
		await get_tree().create_timer(1).timeout
	if not files_loaded:
		Zone.space_load_timed_out.emit()
		return
	Zone.space_preload_done = true
	Zone.space_ready = true

	# ask server if the client should be made ready
	is_local_client_ready.rpc_id(Zone.SERVER_PEER_ID)


func _what_spaceobjects_arent_loaded(instances) -> Array:
	var waiting_for_objects = []
	for space_obj in instances:
		if not is_instance_valid(space_obj):
			# erasing an entity during iteration is a big no-no.
			# always do it after.
			instances.erase(space_obj)
			waiting_for_objects.push_back("invalid space object in memory was it freed?")
			continue
		if (not space_obj.is_ready()) and space_obj.is_preloaded:
			waiting_for_objects.push_back(space_obj)
	return waiting_for_objects


# setup and ready are different things here
func _are_space_objects_setup(instances) -> bool:
	for space_obj in instances:
		# this actually happens when objects are removed incorrectly or become
		# corrupt so we might want to ignore when this happens, if we know
		# that the preload and setup has been done already with populate()
		if not is_instance_valid(space_obj):
			return false
		if space_obj.is_error():
			continue # we can skip errors
		if not space_obj.is_ready():
			return false
	return true

# TODO: rename to enable_play_mode
func enable_play() -> void:
	for child in get_children():
		child.play_enabled()


func get_instance(id: String) -> Node:
	return get_node_or_null(id)


func get_instance_by_id(id: StringName) -> Node:
	return get_node_or_null(NodePath.from_string_name(id))


func update_selected_nodes(selected_nodes: Array[Node]):
	var nodes = TMSceneSync.local_controller_get_controlled_nodes()
	if nodes.size() != 1:
		return
	var local_character = nodes[0]
	local_character.update_selected_nodes(selected_nodes)

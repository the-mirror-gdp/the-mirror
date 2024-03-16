## Since only the Godot server can control script entities via ZoneSocket,
## this class is used to allow Godot clients to operate on script entities.
## This is ultimately a good thing because it allows us to ensure script
## network updates are propagated to all clients through the Godot server.
class_name ScriptClient
extends Node


signal request_clear_script_editor()
signal request_edit_script_instance(script_instance: ScriptInstance)
signal script_instance_created(created_script_instance: ScriptInstance)

var _client_awaiting_script_entity_create: Dictionary = {}
var _script_id_to_entity_cache: Dictionary = {}
var _script_id_to_instances_using_it: Dictionary = {}

# These pending values are only used on clients to keep track of new scripts.
# When creating a new script, we have to wait for the script entity to be
# created on the database. In the meantime, store the information as pending.
var _pending_script_name: String = ""
var _pending_script_instance: ScriptInstance
var _pending_target_node: Node # SpaceObject or SpaceGlobalScripts


func _ready() -> void:
	Net.zone_socket.script_entity_create.connect(_on_net_create_script_entity)
	Net.zone_socket.script_entity_get.connect(_on_net_get_or_update_script_entity)
	Net.zone_socket.script_entity_update.connect(_on_net_get_or_update_script_entity)
	Zone.client.disconnected.connect(_on_zone_disconnected)


func set_script_instance_is_using_script_id(script_instance: ScriptInstance) -> void:
	var script_id: String = script_instance.script_id
	var instances: Array = _script_id_to_instances_using_it.get_or_add(script_id, [])
	if not script_instance in instances:
		instances.append(script_instance)


func load_script_entities_bulk(script_entities: Array) -> void:
	for script_entity in script_entities:
		var id: String = script_entity["id"]
		_script_id_to_entity_cache[id] = script_entity


func load_script_entities_for_ids(script_ids: Array) -> void:
	if Zone.is_host():
		for script_id in script_ids:
			_request_get_script_entity_godot_server(script_id)
	else:
		for script_id in script_ids:
			_request_get_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, script_id)


func get_script_entity(script_id: String, force: bool = false) -> Dictionary:
	if not force:
		if _script_id_to_entity_cache.has(script_id):
			return _script_id_to_entity_cache[script_id]
	if Zone.is_host():
		_request_get_script_entity_godot_server(script_id)
	else:
		_request_get_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, script_id)
	return {}


func update_script_entity(updated_script_data: Dictionary) -> void:
	if not Util.can_local_user_edit_scripts():
		Notify.warning("Permissions Error", "You don't have permission to edit scripts.")
		return
	_request_update_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, updated_script_data)


func cache_created_script_entity(script_entity: Dictionary) -> void:
	var script_id: String = script_entity["id"]
	_script_id_to_entity_cache[script_id] = script_entity


func get_script_id_to_name_dict() -> Dictionary:
	var ret: Dictionary = {}
	var all_script_entities: Array = _script_id_to_entity_cache.values()
	all_script_entities.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["updatedAt"] > b["updatedAt"])
	for script_entity in all_script_entities:
		var script_id: String = script_entity["id"]
		ret[script_id] = script_entity.get("name", "<Error: Unnamed Script>")
	return ret


func get_any_script_instance_for_script_id(script_id: String) -> ScriptInstance:
	var instances: Array = _get_and_validate_script_instances_using_id(script_id)
	if instances.is_empty():
		return null
	return instances[0]


func get_script_id_usage_count(script_id: String) -> int:
	var instances: Array = _get_and_validate_script_instances_using_id(script_id)
	return instances.size()


func server_send_script_entities_to_peer(peer_id: int) -> void:
	_load_script_id_to_entities_server_to_peer.rpc_id(peer_id, _script_id_to_entity_cache)


@rpc("call_remote", "authority", "reliable")
func _load_script_id_to_entities_server_to_peer(script_id_to_entities: Dictionary) -> void:
	_script_id_to_entity_cache = script_id_to_entities


@rpc("call_remote", "any_peer", "reliable")
func _request_create_script_entity_godot_server(new_script_data: Dictionary, from_user: String) -> void:
	if not _can_rpc_user_edit_scripts():
		return
	var peer_id: int = get_tree().get_multiplayer().get_remote_sender_id()
	_client_awaiting_script_entity_create[new_script_data["name"]] = peer_id
	Net.zone_socket.create_script_entity(new_script_data, from_user)


func _on_net_create_script_entity(script_entity: Dictionary) -> void:
	var script_name: String = script_entity["name"]
	if not script_name in _client_awaiting_script_entity_create:
		return
	var peer_id: int = _client_awaiting_script_entity_create[script_name]
	# Before the script entity has been created, it does not have an ID, so the
	# client that creates it keeps track of it by name. Pass this name back to
	# the client as "create_name" so that it can identify the incoming script.
	script_entity["create_name"] = script_name
	if script_name.contains("_GEN_"):
		script_entity["name"] = _generate_friendly_unique_script_name()
	else:
		script_entity["name"] = script_name + " (copy)"
	_inform_client_script_entity_created.rpc_id(peer_id, script_entity)
	_client_awaiting_script_entity_create.erase(script_name)
	script_entity.erase("create_name")
	request_update_script_entity_to_database(script_entity)


func _generate_friendly_unique_script_name(script_name_base: String = "New Script") -> String:
	var number_suffix: int = 2
	var script_name: String = script_name_base
	while _any_script_has_name(script_name):
		script_name = script_name_base + " " + str(number_suffix)
		number_suffix += 1
	return script_name


func _any_script_has_name(script_name: String) -> bool:
	for script_id in _script_id_to_entity_cache:
		var script_entity_dict: Dictionary = _script_id_to_entity_cache[script_id]
		if script_entity_dict["name"] == script_name:
			return true
	return false


func _on_zone_disconnected() -> void:
	_pending_script_name = ""
	_pending_script_instance = null
	_pending_target_node = null
	for script_id in _script_id_to_instances_using_it:
		var instances: Array = _script_id_to_instances_using_it[script_id]
		for instance in instances:
			if is_instance_valid(instance):
				instance.cleanup_script_instance()
				instance.free()
		instances.clear()
	_script_id_to_instances_using_it.clear()


## Get and update methods.
@rpc("call_remote", "any_peer", "reliable")
func _request_get_script_entity_godot_server(script_id: String) -> void:
	if _script_id_to_entity_cache.has(script_id):
		var recipient: int = multiplayer.get_remote_sender_id()
		_inform_script_entity_get_or_update.rpc_id(recipient, _script_id_to_entity_cache[script_id])
	else:
		Net.zone_socket.get_script_entity(script_id)


@rpc("call_remote", "any_peer", "reliable")
func _request_update_script_entity_godot_server(updated_script_data: Dictionary) -> void:
	if _can_rpc_user_edit_scripts():
		request_update_script_entity_to_database(updated_script_data)


func request_update_script_entity_to_database(updated_script_data: Dictionary) -> void:
	var script_id: String = updated_script_data["id"]
	_script_id_to_entity_cache[script_id] = updated_script_data
	Net.zone_socket.update_script_entity(script_id, updated_script_data)
	# Set the script ID as used in the space, so the space knows about it.
	var zone_space_script_ids: Array = Zone.space.get("scriptIds", [])
	if not script_id in zone_space_script_ids:
		zone_space_script_ids.append(script_id)
		zone_space_script_ids.sort()
		Zone.space["scriptIds"] = zone_space_script_ids
		Net.zone_socket.update_space(Zone.space)


func _on_net_get_or_update_script_entity(script_entity: Dictionary) -> void:
	_inform_script_entity_get_or_update.rpc(script_entity)


@rpc("call_local", "authority", "reliable")
func _inform_script_entity_get_or_update(script_entity: Dictionary) -> void:
	var script_id: String = script_entity["id"]
	_script_id_to_entity_cache[script_id] = script_entity
	var instances: Array = _get_and_validate_script_instances_using_id(script_id)
	for instance in instances:
		instance.update_script_entity_data_from_network(script_entity)


func _get_and_validate_script_instances_using_id(script_id: String) -> Array:
	var instances: Array = _script_id_to_instances_using_it.get_or_add(script_id, [])
	for i in range(instances.size() - 1, -1, -1):
		if not is_instance_valid(instances[i]):
			instances.remove_at(i)
	return instances


## Used by the user-friendly Attach Script visual script block.
func attach_script_name_to_space_object(target_object: SpaceObject, script_name: String, script_instance_data: Dictionary) -> Error:
	var script_entity: Dictionary
	for script_id_cache in _script_id_to_entity_cache:
		var script_entity_cache: Dictionary = _script_id_to_entity_cache[script_id_cache]
		if script_entity_cache["name"] != script_name:
			continue
		if script_entity.is_empty():
			script_entity = script_entity_cache
		else:
			return ERR_DUPLICATE_SYMBOL
	if script_entity.is_empty():
		return ERR_DOES_NOT_EXIST
	_add_new_script_instance_with_script_entity(target_object, script_entity, script_instance_data)
	return OK


# Used by the Add Script dialog. IDs are more robust than names.
func attach_script_id_to_node(target_object: Node, script_id: String) -> void:
	# Before attaching, check if we already have a script with this ID attached.
	for existing_script_instance in target_object.get_script_instances():
		if existing_script_instance.script_id == script_id:
			request_edit_script_instance.emit(existing_script_instance)
			return
	# Get the script entity and attach it.
	var script_entity: Dictionary = await get_script_entity(script_id)
	_add_new_script_instance_with_script_entity(target_object, script_entity)


# These methods are called only on clients when creating a new script entity.
func client_create_new_script_entity(target_node: Node, script_type: String) -> void:
	if not Util.can_local_user_edit_scripts():
		Notify.warning("Permissions Error", "You don't have permission to create scripts.")
		return
	_pending_target_node = target_node
	_pending_script_name = target_node.get_space_object_name() if target_node is SpaceObject else target_node.name
	_pending_script_name += "_" + script_type + "_GEN_" + str(randi() % 1000000)
	var new_script_data: Dictionary = {
		"name": _pending_script_name,
		"type": script_type,
	}
	_request_create_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, new_script_data, Net.user_id)


func client_clone_script_entity(script_instance: ScriptInstance) -> void:
	if not Util.can_local_user_edit_scripts():
		Notify.warning("Permissions Error", "You don't have permission to create scripts.")
		return
	_pending_script_instance = script_instance
	# Clear the ID to instances cache of this script instance.
	var script_instances_for_id: Array = _script_id_to_instances_using_it.get_or_add(script_instance.script_id, [])
	script_instances_for_id.erase(script_instance)
	# Create a new script entity with a copy of the original's data.
	var script_entity: Dictionary = script_instance.serialize_script_entity_data()
	script_entity.erase("id") # The new entity should forget about the ID of the entity it came from.
	_pending_script_name = script_entity["name"]
	_request_create_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, script_entity, Net.user_id)


func client_create_new_script_entity_from_asset(target_node: Node, asset_data: AssetData) -> void:
	if not Util.can_local_user_edit_scripts():
		Notify.warning("Permissions Error", "You don't have permission to create scripts.")
		return
	var asset_promise: Promise = asset_data.get_asset_file_promise()
	var result: Variant
	if asset_promise.has_result():
		result = asset_promise.get_result()
	else:
		result = await asset_promise.wait_till_fulfilled()
	if not result is Dictionary:
		printerr("Tried to create a script Entity from a script Asset, but the asset was not a Dictionary (expected a dict holding the script JSON).")
		return
	result = result.duplicate(false)
	result.erase("id") # The entity should forget about the ID of the asset it came from.
	_pending_target_node = target_node
	_pending_script_name = result.get("name", asset_data.asset_name)
	_request_create_script_entity_godot_server.rpc_id(Zone.SERVER_PEER_ID, result, Net.user_id)


@rpc("call_remote", "authority", "reliable")
func _inform_client_script_entity_created(script_entity: Dictionary) -> void:
	if _pending_script_name != script_entity["create_name"]:
		return
	cache_created_script_entity(script_entity)
	if _pending_script_instance:
		_update_pending_script_instance_with_new_script_entity(script_entity)
	else:
		_add_new_script_instance_with_script_entity(_pending_target_node, script_entity)
	_pending_script_name = ""
	_pending_script_instance = null
	_pending_target_node = null


func _update_pending_script_instance_with_new_script_entity(script_entity: Dictionary) -> void:
	_pending_script_instance.script_id = script_entity["id"]
	_pending_script_instance.setup_script_entity_data(script_entity)
	set_script_instance_is_using_script_id(_pending_script_instance)
	_pending_script_instance.target_node.script_instances_modified()
	request_edit_script_instance.emit(_pending_script_instance)


func _add_new_script_instance_with_script_entity(target_node: Node, script_entity: Dictionary, script_instance_data: Dictionary = {}) -> void:
	script_instance_data["type"] = script_entity["type"]
	script_instance_data["script_id"] = script_entity["id"]
	var new_script_instance: ScriptInstance = ScriptInstance.create(script_instance_data)
	new_script_instance.target_node = target_node
	if not script_entity.is_empty():
		# If it's empty, the data will be loaded later.
		new_script_instance.setup_script_entity_data(script_entity)
	set_script_instance_is_using_script_id(new_script_instance)
	target_node.add_script_instance(new_script_instance)
	script_instance_created.emit(new_script_instance)


# Script asset saving methods.
func save_script_as_asset(script_instance: ScriptInstance) -> void:
	var asset_data_dict: Dictionary = {
		"name": script_instance.script_name,
		"assetType": Enums.ASSET_TYPE.SCRIPT,
	}
	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)
	var promise_create = Net.asset_client.create_asset(asset_data_dict)
	var asset_data = await promise_create.wait_till_fulfilled()
	if promise_create.is_error():
		Notify.error("Failed To Create Asset", promise_create.get_error_message())
		return
	var asset_id: String = asset_data.get("_id")
	var script_data: Dictionary = script_instance.serialize_script_entity_data()
	script_data["id"] = asset_id # The asset should forget about the ID of the entity it came from.
	_upload_script_data_to_asset_file(asset_id, script_data, true)


func update_script_asset_data(updated_script_data: Dictionary) -> void:
	var asset_id: String = updated_script_data["id"]
	_upload_script_data_to_asset_file(asset_id, updated_script_data, false)
	var old_asset_json: Dictionary = Net.asset_client.get_asset_json(asset_id)
	var updated_script_name: String = updated_script_data["name"]
	# If the script name has changed, update the asset name to match the script name.
	if updated_script_name == old_asset_json.get("name", ""):
		return
	var asset_data_dict: Dictionary = {
		"name": updated_script_name,
		"assetType": Enums.ASSET_TYPE.SCRIPT,
	}
	var promise: Promise = Net.asset_client.update_asset(asset_id, asset_data_dict)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error(tr("Script Asset Update Error"), promise.get_error_message())


func _upload_script_data_to_asset_file(asset_id: String, serialized_script_data: Dictionary, success_print: bool) -> void:
	assert(not asset_id.is_empty())
	var file_data: PackedByteArray = JSON.stringify(serialized_script_data).to_utf8_buffer()
	var mime_type: String = "script/mirror-visual-script+json"
	var promise_upload = Net.asset_client.upload_file_public(asset_id, file_data, mime_type)
	var asset_data_file = await promise_upload.wait_till_fulfilled()
	if promise_upload.is_error():
		Notify.error(tr("File Upload Error"), promise_upload.get_error_message())
	elif success_print:
		Notify.success(tr("File Upload Complete"), asset_data_file["name"] + " successfully uploaded!")


func _can_rpc_user_edit_scripts() -> bool:
	var peer_id: int = get_tree().get_multiplayer().get_remote_sender_id()
	var user_id: String = Zone.server.get_user_id(multiplayer.get_remote_sender_id())
	var space_role = Util.get_role_for_user(Zone.space, user_id)
	return space_role > Enums.ROLE.CONTRIBUTOR

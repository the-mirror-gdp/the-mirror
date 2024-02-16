class_name SpaceRestore
extends Node

signal space_restored(save_name: String)
signal space_restore_failed(save_name: String)


@rpc("call_remote", "any_peer", "reliable")
func _notify_client_sucess(save_name: String):
	Notify.success("Space state restored", "Loaded: %s" % save_name)
	space_restored.emit(save_name)


@rpc("call_remote", "any_peer", "reliable")
func _notify_client_failure(save_name: String):
	Notify.error("Space state revert failure", "Failed loading: %s" % save_name)
	space_restore_failed.emit(save_name)


func _find_space_object_in_version(space_version: Dictionary, space_object_id: String) -> Dictionary:
	var space_objects: Array = space_version.get("spaceObjects", [])
	var filtered = space_objects.filter(func(x): return x.get("_id") == space_object_id)
	if filtered.size() == 1:
		var so = filtered[0]
		so["spaceId"] = so["space"]
		if so.has("receipt"):
			so["creator"] = so["receipt"].get("created_by_user", "")
			so.erase("receipt")
		return so
	return {}


@rpc("call_remote", "any_peer", "reliable")
func restore_from_space_version(space_version_id: String) -> void:
	assert(Zone.is_host())
	var promise = Net.zone_socket.get_space_version(space_version_id)
	var space_version = await promise.wait_till_fulfilled()
	if promise.is_error():
		print(promise.get_error_message())
		_notify_client_failure.rpc(space_version_id)
		return

	var space_data = space_version.get("space", {})
	_restore_space_data(space_data)
	_update_environment(space_data.get("environment", {}))

	var objects_ids: Array = space_version.get("spaceObjects", []).map(func(x): return x["_id"])
	var unneeded_so: Array = []
	var to_update_so: Array = []
	for x in Zone.instance_manager.get_all_instances():
		if x.name in objects_ids:
			to_update_so.append(_find_space_object_in_version(space_version, x.name))
		else:
			unneeded_so.append(x.name)
		objects_ids.erase(String(x.name))
	_update_space_objects(to_update_so)
	_remove_space_objects(unneeded_so)
	# object_ids now contain only nodes that didn't exists:
	for new_so_id in objects_ids:
		_create_space_object(_find_space_object_in_version(space_version, new_so_id))

	_update_global_scripts(space_version.get("scriptInstances", []))
	_update_script_entities(space_version.get("scripts", []))
	_restore_space_variables(space_version.get("spaceVariables", {}))

	var display_name: String = space_version.get("name", "")
	if display_name.is_empty():
		display_name = "%s - %s" % [space_version.get("createdAt", ""), space_version.get("mirrorVersion", "")]

	_notify_client_sucess.rpc(display_name)


func _update_space_objects(space_objects_data: Array) -> void:
	# this requests needs "id" field, alongside "_id", otherwise it will not save to db
	space_objects_data = space_objects_data.map(func(x):
		x["id"] = x["_id"]
		return x
	)
	# Update space objects will be divided into smaller packets so its safe
	Zone.server.server_update_space_objects(space_objects_data)


func _create_space_object(space_object_data: Dictionary) -> void:
	Zone.server.server_create_space_object(space_object_data)


func _remove_space_objects(space_object_ids: Array) -> void:
	Zone.server.server_delete_space_objects(space_object_ids)


func _update_environment(envionment: Dictionary) -> void:
	Zone.server.server_update_environment(envionment)


func _update_global_scripts(script_instances: Array) -> void:
	Zone.server.server_update_global_scripts(script_instances)


func _update_script_entities(scripts: Array) -> void:
	for script in scripts:
		Net.script_client.request_update_script_entity_to_database(script)


func _restore_space_variables(space_vars: Dictionary) -> void:
	Zone.script_network_sync.load_variables_from_database(space_vars, true)
	for peer_id in get_tree().get_multiplayer().get_peers():
		Zone.script_network_sync.server_replace_all_data_on_peer(peer_id)


func _restore_space_data(space_data: Dictionary) -> void:
	Zone.space["name"] = space_data["name"]
	Zone.space["description"] = space_data.get("description", "")
	Zone.space["maxUsers"] = space_data.get("maxUsers", 24)
	Zone.space["tags"] = space_data.get("tags", {})
	Net.zone_socket.update_space(Zone.space)

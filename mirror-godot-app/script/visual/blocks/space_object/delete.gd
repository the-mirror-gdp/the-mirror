extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var obj_ids: Array = []
	for input in inputs:
		if input.value is SpaceObject:
			obj_ids.append(input.value.name)
		else:
			log_error.emit("Tried to delete a SpaceObject, but the input was not a SpaceObject.")
			return ERR_INVALID_PARAMETER
	var data: Array = [Packet.TYPE.DELETE_SPACE_OBJECTS, obj_ids]
	if Zone.is_host():
		Zone.send_data_to_all_peer(data)
		Net.zone_socket.delete_space_objects(obj_ids)
	else:
		Zone.send_data_to_server(data)
	return OK


func get_script_block_type() -> String:
	return "delete_space_object"

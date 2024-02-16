extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object
	if inputs[0].connected_block == null:
		target_object = attached_object
	else:
		target_object = type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)
	if not (is_instance_valid(target_object) and target_object is SpaceObject):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	var script_name: String = type_convert(inputs[1].value, ScriptBlock.PortType.STRING)
	var script_instance_data: Dictionary = {
		"execute_in_edit": inputs[2].value,
		"execute_on_client": inputs[3].value,
		"execute_on_server": inputs[4].value,
	}
	for script_instance in target_object.get_script_instances():
		if script_instance.script_name == script_name:
			return OK # A script with this name is already attached, just silently exit.
	var err: Error = Net.script_client.attach_script_name_to_space_object(target_object, script_name, script_instance_data)
	if err == ERR_DUPLICATE_SYMBOL:
		log_error.emit('Tried to attach a script named "' + script_name + '", but there were multiple scripts with that name.')
	elif err == ERR_DOES_NOT_EXIST:
		log_error.emit('Unable to find a script with name "' + script_name + '" to attach.')
	return err


func get_script_block_type() -> String:
	return "attach_script"

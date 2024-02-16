extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var target_object: Object = get_operation_target_object()
	if target_object is Player:
		outputs[0].value = target_object.get_model_rotation_degrees()
	elif target_object is Node3D:
		outputs[0].value = target_object.rotation_degrees
	else:
		log_error.emit("The target object is not a 3D node.")


func get_operation_target_object() -> Object:
	if inputs[0].connected_block == null:
		return attached_object
	return type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)


func get_script_block_type() -> String:
	return "get_rotation_degrees"

extends ScriptBlockOperationBase


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object = get_operation_target_object()
	var rotation_degrees: Vector3 = inputs[1].value
	if target_object is Player:
		log_error.emit("You can't set the rotation of a Player.")
		return ERR_INVALID_PARAMETER
	elif target_object is Node3D:
		target_object.rotation_degrees = rotation_degrees
	else:
		log_error.emit("The target object is not a 3D node.")
		return ERR_INVALID_PARAMETER
	return OK


func get_script_block_type() -> String:
	return "set_rotation_degrees"

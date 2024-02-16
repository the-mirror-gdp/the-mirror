extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if len(inputs) != 1:
		log_error.emit("The script node `is_dead` should receive 1 inputs.")
		return ERR_INVALID_PARAMETER

	var object: Node = inputs[0].value

	if not is_instance_valid(object):
		log_error.emit("The `is_dead` must be called on a valid SpaceObject or Character.")
		return ERR_INVALID_PARAMETER

	if object.has_method("is_dead"):
		outputs[0].value = object.is_dead()
	else:
		log_error.emit("The `is_dead` function is not implemented by the object passed.")
		outputs[0].value = false

	return OK


func get_script_block_type() -> String:
	return "is_dead"

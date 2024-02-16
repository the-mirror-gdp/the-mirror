extends ScriptBlockOperationProperty


func _execute_callback(stack_count: int) -> Error:
	assert(inputs.size() == 2) # Should be exactly two inputs for the target object and value.
	var target_object: Object = get_operation_target_object()
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	if not property_name in target_object:
		log_error.emit("The target object does not have the requested property (" + String(property_name) + ").")
		return ERR_METHOD_NOT_FOUND
	var property_value: Variant = target_object.get(property_name)
	var operation_value: Variant = inputs[1].value
	property_value += operation_value
	set_property_on_target(target_object, property_value)
	if outputs.size() == 1:
		outputs[0].value = property_value
	else:
		outputs[0].value = target_object
		outputs[1].value = property_value
	return OK


func get_script_block_type() -> String:
	return "add_property"

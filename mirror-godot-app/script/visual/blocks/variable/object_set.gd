extends ScriptBlockOperationObjectVariable


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object = get_target_object()
	var variable_name: String = inputs[1].value
	var variable_value: Variant = inputs[2].value
	if target_object == null:
		target_object = attached_object
	Mirror.set_object_variable(target_object, variable_name, variable_value)
	return OK


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	inputs[2].port_type = type
	inputs[2].value = type_convert(inputs[2].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[2].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	inputs[2].port_type = typeof(value)
	inputs[2].value = value


func get_script_block_type() -> String:
	return "set_object_variable"

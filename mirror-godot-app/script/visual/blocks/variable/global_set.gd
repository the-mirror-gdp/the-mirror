extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var variable_name: String = inputs[0].value
	var variable_value: Variant = inputs[1].value
	# This will also set it locally immediately.
	Zone.script_network_sync.set_global_variable(variable_name, variable_value)
	return OK


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	inputs[1].port_type = type
	inputs[1].value = type_convert(inputs[1].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[1].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	inputs[1].port_type = typeof(value)
	inputs[1].value = value


func get_script_block_type() -> String:
	return "set_global_variable"

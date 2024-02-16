extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var variable_name = inputs[0].value
	var value = Zone.script_network_sync.get_global_variable(variable_name)
	var type = outputs[0].port_type
	if type != ScriptBlock.PortType.ANY_DATA:
		value = type_convert(value, type)
	outputs[0].value = value


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if edited_input_port.port_name != "Variable Name":
		return
	var variable_name: String = edited_input_port.value
	var variable_value = Zone.script_network_sync.get_global_variable(variable_name)
	outputs[0].port_type = typeof(variable_value)
	outputs[0].value = variable_value


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[0].port_type = type
	outputs[0].value = type_convert(outputs[0].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	outputs[0].port_type = typeof(value)
	outputs[0].value = value


func get_script_block_type() -> String:
	return "get_global_variable"

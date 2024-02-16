extends ScriptBlock


func evaluate() -> void:
	super()
	var input_value = inputs[0].value
	for i in range(2, inputs.size(), 2):
		var case_value = inputs[i].value
		if input_value == case_value:
			# Ex: If case index 2 is hit, the return value is index 3.
			outputs[0].value = inputs[i + 1].value
			return
	outputs[0].value = inputs[1].value


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[0].port_type = type
	outputs[0].value = type_convert(outputs[0].value, type)
	for i in range(1, inputs.size(), 2):
		var input = inputs[i]
		input.port_type = type
		input.value = type_convert(input.value, type)


func change_secondary_type_selection(type: ScriptBlock.PortType) -> void:
	for i in range(0, inputs.size(), 2):
		var input = inputs[i]
		input.port_type = type
		input.value = type_convert(input.value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func get_secondary_port_type() -> ScriptBlock.PortType:
	return inputs[0].port_type


func add_slot_port() -> void:
	@warning_ignore("integer_division")
	var index_string: String = str(inputs.size() / 2)
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Case " + index_string
	new_input.set_port_type(inputs[0].port_type)
	inputs.append(new_input)
	new_input = ScriptBlockInputPort.new()
	new_input.port_name = "Value " + index_string
	new_input.set_port_type(outputs[0].port_type)
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 3:
		return
	var last_input: ScriptBlockInputPort = inputs.back()
	inputs.erase(last_input)
	last_input.free()
	last_input = inputs.back()
	inputs.erase(last_input)
	last_input.free()


func get_add_remove_slot_port_custom_name() -> String:
	return "Case"


func get_script_block_type() -> String:
	return "match_value"

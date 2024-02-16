extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var ret: Array = []
	for input in inputs:
		ret.append(input.value)
	outputs[0].value = ret


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	for input in inputs:
		input.port_type = type
		input.value = Serialization.type_convert_any(input.value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[0].port_type


func add_slot_port() -> void:
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Index " + str(inputs.size())
	new_input.port_type = inputs[0].port_type
	new_input.value = Serialization.type_convert_any("", new_input.port_type)
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 2:
		return
	var last_input: ScriptBlockInputPort = inputs.pop_back()
	last_input.free()


func get_script_block_type() -> String:
	return "array_construct"

extends ScriptBlockMath


func evaluate() -> void:
	evaluate_inputs()
	var type: ScriptBlock.PortType = outputs[0].port_type
	outputs[0].value = type_convert(inputs[0].value, type)
	for i in range(1, inputs.size()):
		outputs[0].value += type_convert(inputs[i].value, type)


func add_slot_port() -> void:
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Value " + str(inputs.size() + 1)
	new_input.port_type = outputs[0].port_type
	new_input.value = type_convert(0, new_input.port_type)
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 2:
		return
	var last_input: ScriptBlockInputPort = inputs.back()
	inputs.erase(last_input)
	last_input.free()


func get_script_block_type() -> String:
	return "add"

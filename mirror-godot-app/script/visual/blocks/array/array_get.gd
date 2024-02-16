extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var array: Array = inputs[0].value
	for i in range(1, inputs.size()):
		var index: int = inputs[i].value
		var output: ScriptBlockDataPort = outputs[i]
		if -1 < index and index < array.size():
			output.value = Serialization.type_convert_any(array[index], output.port_type)
		else:
			output.value = Serialization.type_convert_any("", output.port_type)
	outputs[0].value = array


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	for i in range(1, outputs.size()):
		outputs[i].port_type = type
		outputs[i].value = Serialization.type_convert_any(outputs[i].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[1].port_type


func add_slot_port() -> void:
	var index_string: String = str(inputs.size())
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Index " + index_string
	new_input.port_type = ScriptBlock.PortType.INT
	new_input.value = Serialization.type_convert_any("", new_input.port_type)
	inputs.append(new_input)
	var new_output := ScriptBlockDataPort.new()
	new_output.port_name = "Value " + index_string
	new_output.port_type = outputs[1].port_type
	new_output.value = Serialization.type_convert_any("", new_output.port_type)
	outputs.append(new_output)


func remove_slot_port() -> void:
	if inputs.size() < 3:
		return
	var last_input: ScriptBlockInputPort = inputs.pop_back()
	last_input.free()
	var last_output: ScriptBlockDataPort = outputs.pop_back()
	last_output.free()


func get_script_block_type() -> String:
	return "array_get"

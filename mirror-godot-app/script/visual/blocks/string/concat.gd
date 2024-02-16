extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = inputs[0].value
	for i in range(1, inputs.size()):
		outputs[0].value += inputs[i].value


func add_slot_port() -> void:
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Value " + str(inputs.size() + 1)
	new_input.port_type = ScriptBlock.PortType.STRING
	new_input.value = ""
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 1:
		return
	var last_input: ScriptBlockInputPort = inputs.back()
	inputs.erase(last_input)
	last_input.free()


func get_script_block_type() -> String:
	return "concatenate_string"

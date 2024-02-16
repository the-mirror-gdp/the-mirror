extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var joiner: String = inputs[0].value
	var strings_to_join := PackedStringArray()
	for i in range(1, inputs.size()):
		strings_to_join.append(inputs[i].value)
	outputs[0].value = joiner.join(strings_to_join)


func add_slot_port() -> void:
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Value " + str(inputs.size())
	new_input.port_type = ScriptBlock.PortType.STRING
	new_input.value = ""
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 2:
		return
	var last_input: ScriptBlockInputPort = inputs.back()
	inputs.erase(last_input)
	last_input.free()


func get_script_block_type() -> String:
	return "join_string"

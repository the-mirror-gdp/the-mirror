extends ScriptBlockSequenced


const MAX_ARRAY_SIZE: int = 1000


func _execute_callback(stack_count: int) -> Error:
	var array: Array = inputs[0].value
	for i in range(1, inputs.size(), 2):
		var index: int = inputs[i].value
		var array_size: int = array.size()
		if index >= array_size:
			if index > MAX_ARRAY_SIZE:
				log_error.emit("Array index is too big! The index (" + str(index) + ") must be less than " + str(MAX_ARRAY_SIZE) + ".")
				return ERR_PARAMETER_RANGE_ERROR
			array.resize(index + 1)
		elif index < 0:
			index = posmod(index, array_size)
		array[index] = inputs[i + 1].value
	outputs[0].value = array
	return OK


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	for i in range(2, inputs.size(), 2):
		inputs[i].port_type = type
		inputs[i].value = Serialization.type_convert_any(inputs[i].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[2].port_type


func add_slot_port() -> void:
	@warning_ignore("integer_division")
	var index_string: String = str(inputs.size() / 2 + 1)
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Index " + index_string
	new_input.port_type = ScriptBlock.PortType.INT
	new_input.value = Serialization.type_convert_any("", new_input.port_type)
	inputs.append(new_input)
	new_input = ScriptBlockInputPort.new()
	new_input.port_name = "Value " + index_string
	new_input.port_type = inputs[2].port_type
	new_input.value = Serialization.type_convert_any("", new_input.port_type)
	inputs.append(new_input)


func remove_slot_port() -> void:
	if inputs.size() < 4:
		return
	var last_input: ScriptBlockInputPort = inputs.pop_back()
	last_input.free()
	last_input = inputs.pop_back()
	last_input.free()


func get_script_block_type() -> String:
	return "array_set"

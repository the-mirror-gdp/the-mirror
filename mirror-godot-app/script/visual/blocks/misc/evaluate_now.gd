class_name ScriptBlockEvaluateNow
extends ScriptBlockSequenced


## ScriptBlockEvaluateNow requires a fully custom execute function.
func execute(stack_count: int = 0) -> Error:
	assert(inputs.size() == outputs.size())
	evaluated = true
	for i in range(inputs.size()):
		# Only use the input's connection. Ignore the input's value.
		var input: ScriptBlockInputPort = inputs[i]
		var block: ScriptBlock = input.connected_block
		if not is_instance_valid(block):
			log_error.emit("Evaluate Now block has an unconnected input. Evaluate Now requires all inputs to be connected.")
			return ERR_INVALID_DATA
		if block is ScriptBlockSequenced:
			log_error.emit("Tried to read data from a run block from an Evaluate Now block. This is not allowed.")
			return ERR_INVALID_PARAMETER
		block.evaluated = false
	for i in range(inputs.size()):
		# Only use the input's connection. Ignore the input's value.
		var input: ScriptBlockInputPort = inputs[i]
		var block: ScriptBlock = input.connected_block
		if not block.evaluated:
			block.evaluate()
		if input.connected_output >= block.outputs.size():
			log_error.emit("Tried to read data from an output that does not exist. This is a bug in The Mirror, please report.")
			return ERR_INVALID_DATA
		outputs[i].value = block.outputs[input.connected_output].value
	var ret: Error = OK
	if flows.size() > 0 and flows[0].connected_block:
		ret = await flows[0].connected_block.execute(stack_count + 1)
	return ret


func add_slot_port() -> void:
	var index_string: String = str(inputs.size() + 1)
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Input " + index_string
	new_input.port_type = ScriptBlock.PortType.CONNECTION
	new_input.value = Serialization.type_convert_any("", new_input.port_type)
	inputs.append(new_input)
	var new_output := ScriptBlockDataPort.new()
	new_output.port_name = "Output " + index_string
	new_output.port_type = ScriptBlock.PortType.ANY_DATA
	new_output.value = Serialization.type_convert_any("", new_output.port_type)
	outputs.append(new_output)


func remove_slot_port() -> void:
	if inputs.is_empty():
		return
	inputs.pop_back().free()
	outputs.pop_back().free()


func get_script_block_type() -> String:
	return "evaluate_now"

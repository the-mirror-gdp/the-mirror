extends ScriptBlockSequenced


const MAX_LOOP_ITERATIONS: int = 1000


func setup(block_json: Dictionary) -> void:
	var flow := ScriptBlockFlowPort.new()
	flow.port_name = "Done"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "Action"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	_setup_base(block_json)
	if inputs.is_empty():
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Times"
		inputs.append(input_port)
	inputs[0].port_type = ScriptBlock.PortType.INT
	if outputs.is_empty():
		var output_port = ScriptBlockDataPort.new()
		output_port.port_name = "Index"
		outputs.append(output_port)
	outputs[0].port_type = ScriptBlock.PortType.INT


func _execute_callback(stack_count: int) -> Error:
	assert(flows.size() == 2) # Loop has 2 flows: Done and Action.
	var times: int = inputs[0].value
	if times > MAX_LOOP_ITERATIONS:
		log_error.emit("Too many loop iterations! The amount of times (" + str(times) + ") must be less than 1000.")
		return ERR_PARAMETER_RANGE_ERROR
	var ret: Error = OK
	if flows[1].connected_block:
		for i in times:
			outputs[0].value = i
			request_reset_unsequenced_blocks_evaluation_state.emit()
			ret = await flows[1].connected_block.execute(stack_count)
			if ret:
				break
	return ret


func get_script_block_type() -> String:
	return "loop"

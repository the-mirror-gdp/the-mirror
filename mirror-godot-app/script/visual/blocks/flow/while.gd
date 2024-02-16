extends ScriptBlockSequenced


const MAX_LOOP_ITERATIONS: int = 1000


func setup(block_json: Dictionary) -> void:
	var flow := ScriptBlockFlowPort.new()
	flow.port_name = "Done"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "True"
	flows.append(flow)
	_setup_base(block_json)
	if inputs.is_empty():
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Condition"
		inputs.append(input_port)
	inputs[0].port_type = ScriptBlock.PortType.BOOL


func _execute_callback(stack_count: int) -> Error:
	assert(flows.size() == 2) # While has 2 flows: Done and True.
	var ret: Error = OK
	var iterations: int = 0
	while inputs[0].value:
		if flows[1].connected_block:
			ret = await flows[1].connected_block.execute(stack_count)
		if ret:
			break
		iterations += 1
		if iterations > MAX_LOOP_ITERATIONS:
			log_error.emit("Too many loop iterations! Did you make an infinite loop?")
			return ERR_PARAMETER_RANGE_ERROR
	return ret


func get_script_block_type() -> String:
	return "while"

extends ScriptBlockSequenced


func setup(block_json: Dictionary) -> void:
	var flow := ScriptBlockFlowPort.new()
	flow.port_name = "Done"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "True"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "False"
	flows.append(flow)
	_setup_base(block_json)
	if inputs.is_empty():
		var input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Condition"
		inputs.append(input_port)
	inputs[0].port_type = ScriptBlock.PortType.BOOL


func _execute_callback(stack_count: int) -> Error:
	assert(flows.size() == 3) # If has 3 flows: Done, True, and False.
	var ret: Error = OK
	if inputs[0].value:
		if flows[1].connected_block:
			ret = await flows[1].connected_block.execute(stack_count)
	else:
		if flows[2].connected_block:
			ret = await flows[2].connected_block.execute(stack_count)
	return ret


func get_script_block_type() -> String:
	return "if"

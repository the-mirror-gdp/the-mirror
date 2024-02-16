extends ScriptBlockSequenced


func setup(block_json: Dictionary) -> void:
	var flow = ScriptBlockFlowPort.new()
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


func execute(stack_count: int = 0) -> Error:
	evaluate_inputs()
	var ret: Error = OK
	if inputs[0].value:
		if flows[0].connected_block:
			ret = await flows[0].connected_block.execute(stack_count + 1)
	else:
		if flows[1].connected_block:
			ret = await flows[1].connected_block.execute(stack_count + 1)
	return ret


func get_script_block_type() -> String:
	return "branch"

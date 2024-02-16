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
		input_port.port_name = "Left"
		inputs.append(input_port)
		input_port = ScriptBlockInputPort.new()
		input_port.port_name = "Right"
		inputs.append(input_port)


func _execute_callback(stack_count: int) -> Error:
	assert(flows.size() == 3) # If has 3 flows: Done, True, and False.
	var ret: Error = OK
	if ScriptBlockEquals.compare_inputs_for_equality(inputs[0], inputs[1]):
		if flows[1].connected_block:
			ret = await flows[1].connected_block.execute(stack_count)
	else:
		if flows[2].connected_block:
			ret = await flows[2].connected_block.execute(stack_count)
	return ret


func get_script_block_type() -> String:
	return "if_equals"

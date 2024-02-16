extends ScriptBlockSequenced


func setup(block_json: Dictionary) -> void:
	_setup_base(block_json)
	var flow := ScriptBlockFlowPort.new()
	flow.port_name = "Done"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "Default"
	flows.append(flow)
	for i in range(1, inputs.size()):
		flow = ScriptBlockFlowPort.new()
		flow.port_name = "Flow " + str(i)
		flows.append(flow)


func _execute_callback(stack_count: int) -> Error:
	var input_value = inputs[0].value
	for i in range(1, inputs.size()):
		var case_value = inputs[i].value
		if input_value == case_value:
			# Value input index 1 corresponds to flow index 2.
			return await flows[i + 1].connected_block.execute(stack_count)
	# Default case is index 1 (0 is done, 2+ are other cases)
	return await flows[1].connected_block.execute(stack_count)


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	for input in inputs:
		input.port_type = type
		input.value = type_convert(input.value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[0].port_type


func add_slot_port() -> void:
	var index_string: String = str(inputs.size())
	var new_input := ScriptBlockInputPort.new()
	new_input.port_name = "Case " + index_string
	new_input.set_port_type(inputs.back().port_type)
	inputs.append(new_input)
	var new_flow := ScriptBlockFlowPort.new()
	new_flow.port_name = "Flow " + index_string
	flows.append(new_flow)


func remove_slot_port() -> void:
	if inputs.size() < 2:
		return
	var last_input: ScriptBlockInputPort = inputs.back()
	inputs.erase(last_input)
	last_input.free()
	var last_flow: ScriptBlockFlowPort = flows.back()
	flows.erase(last_flow)
	last_flow.free()


func get_add_remove_slot_port_custom_name() -> String:
	return "Case"


func get_script_block_type() -> String:
	return "match_flow"

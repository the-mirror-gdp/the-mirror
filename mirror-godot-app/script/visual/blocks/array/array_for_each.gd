class_name ScriptBlockArrayForEach
extends ScriptBlockSequenced


const MAX_LOOP_ITERATIONS: int = 1000


func setup(block_json: Dictionary) -> void:
	var flow := ScriptBlockFlowPort.new()
	flow.port_name = "Done"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	flow.port_name = "Each"
	flows.append(flow)
	flow = ScriptBlockFlowPort.new()
	_setup_base(block_json)


func _execute_callback(stack_count: int) -> Error:
	assert(flows.size() == 2) # Array For Each has 2 flows: Done and Each.
	var array: Array = inputs[0].value
	var item_count: int = array.size()
	if item_count > MAX_LOOP_ITERATIONS:
		log_error.emit("Too many items in the array! The amount of items (" + str(item_count) + ") must be less than " + str(MAX_LOOP_ITERATIONS) + ".")
		return ERR_PARAMETER_RANGE_ERROR
	var ret: Error = OK
	if flows[1].connected_block:
		var output_type: ScriptBlock.PortType = outputs[1].port_type
		for i in item_count:
			outputs[0].value = i
			outputs[1].value = Serialization.type_convert_any(array[i], output_type)
			request_reset_unsequenced_blocks_evaluation_state.emit()
			ret = await flows[1].connected_block.execute(stack_count)
			if ret:
				break
	return ret


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[1].port_type = type
	outputs[1].value = Serialization.type_convert_any(outputs[1].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[1].port_type


func get_script_block_type() -> String:
	return "array_for_each"

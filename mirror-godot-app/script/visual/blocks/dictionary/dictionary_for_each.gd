class_name ScriptBlockDictionaryForEach
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
	assert(flows.size() == 2) # Dictionary For Each has 2 flows: Done and Each.
	var dictionary: Dictionary = inputs[0].value
	var item_count: int = dictionary.size()
	if item_count > MAX_LOOP_ITERATIONS:
		log_error.emit("Too many items in the dictionary! The amount of items (" + str(item_count) + ") must be less than " + str(MAX_LOOP_ITERATIONS) + ".")
		return ERR_PARAMETER_RANGE_ERROR
	var ret: Error = OK
	if flows[1].connected_block:
		var key_type: ScriptBlock.PortType = outputs[0].port_type
		var value_type: ScriptBlock.PortType = outputs[1].port_type
		for key in dictionary:
			outputs[0].value = Serialization.type_convert_any(key, key_type)
			outputs[1].value = Serialization.type_convert_any(dictionary[key], value_type)
			request_reset_unsequenced_blocks_evaluation_state.emit()
			ret = await flows[1].connected_block.execute(stack_count)
			if ret:
				break
	return ret


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[1].port_type = type
	outputs[1].value = Serialization.type_convert_any(outputs[1].value, type)


func change_secondary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[0].port_type = type
	outputs[0].value = Serialization.type_convert_any(outputs[0].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[1].port_type


func get_secondary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func get_script_block_type() -> String:
	return "dictionary_for_each"

extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var array: Array = inputs[0].value
	var index: int = randi() % array.size()
	outputs[0].value = Serialization.type_convert_any(index, outputs[1].port_type)
	outputs[1].value = Serialization.type_convert_any(array[index], outputs[1].port_type)


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	var output = outputs[1]
	output.port_type = type
	output.value = Serialization.type_convert_any(output.value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[1].port_type


func get_script_block_type() -> String:
	return "array_pick_random"

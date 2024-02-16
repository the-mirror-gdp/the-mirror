extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var dict: Dictionary = inputs[0].value
	var key = dict.keys().pick_random()
	outputs[0].value = Serialization.type_convert_any(key, outputs[0].port_type)
	outputs[1].value = Serialization.type_convert_any(dict[key], outputs[1].port_type)


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	var output = outputs[1]
	output.port_type = type
	output.value = Serialization.type_convert_any(output.value, type)


func change_secondary_type_selection(type: ScriptBlock.PortType) -> void:
	var output = outputs[0]
	output.port_type = type
	output.value = Serialization.type_convert_any(output.value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[1].port_type


func get_secondary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func get_script_block_type() -> String:
	return "dictionary_pick_random"

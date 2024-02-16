extends ScriptBlockMath


func evaluate() -> void:
	evaluate_inputs()
	var type: ScriptBlock.PortType = outputs[0].port_type
	outputs[0].value = type_convert(inputs[0].value, type)
	for i in range(1, inputs.size()):
		outputs[0].value -= type_convert(inputs[i].value, type)


func get_script_block_type() -> String:
	return "subtract"

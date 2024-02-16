extends ScriptBlockDyadic


func evaluate() -> void:
	super()
	var result: bool = type_convert(inputs[0].value, ScriptBlock.PortType.BOOL)
	for i in range(1, inputs.size()):
		var input: bool = type_convert(inputs[i].value, ScriptBlock.PortType.BOOL)
		result = result or input
	outputs[0].value = result


func get_script_block_type() -> String:
	return "or"

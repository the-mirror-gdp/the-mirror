extends ScriptBlockDyadic


func evaluate() -> void:
	super()
	var input1: float = type_convert(inputs[0].value, ScriptBlock.PortType.FLOAT)
	var input2: float = type_convert(inputs[1].value, ScriptBlock.PortType.FLOAT)
	outputs[0].value = input1 < input2


func get_script_block_type() -> String:
	return "less"

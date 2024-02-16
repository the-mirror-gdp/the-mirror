extends ScriptBlockMath


func evaluate() -> void:
	evaluate_inputs()
	var type: ScriptBlock.PortType = outputs[0].port_type
	outputs[0].value = type_convert(inputs[0].value, type)
	for i in range(1, inputs.size()):
		if inputs[i].port_type == type:
			outputs[0].value *= inputs[i].value
		else:
			var input: float = type_convert(inputs[i].value, ScriptBlock.PortType.FLOAT)
			outputs[0].value *= input


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	if inputs[0].port_type == ScriptBlock.PortType.FLOAT \
			and inputs[1].port_type == ScriptBlock.PortType.FLOAT and (
			type == ScriptBlock.PortType.VECTOR2
			or type == ScriptBlock.PortType.VECTOR3
			or type == ScriptBlock.PortType.COLOR):
		if type == ScriptBlock.PortType.COLOR:
			graph_name = "Color Multiplied By Float"
		else:
			graph_name = "Vector Multiplied By Float"
		inputs[0].port_type = type
		inputs[0].value = type_convert(inputs[0].value, type)
		outputs[0].port_type = type
		outputs[0].value = type_convert(outputs[0].value, type)
	else:
		graph_name = "Multiply"
		super(type)


func get_script_block_type() -> String:
	return "multiply"

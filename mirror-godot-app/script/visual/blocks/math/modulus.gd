extends ScriptBlockMath


func evaluate() -> void:
	evaluate_inputs()
	var type: ScriptBlock.PortType = outputs[0].port_type
	var o = type_convert(inputs[0].value, type)
	# Unlike other math ops, Godot doesn't provide a consistent API for modulus :(
	match type:
		ScriptBlock.PortType.INT:
			for i in range(1, inputs.size()):
				var input: int = type_convert(inputs[i].value, type)
				o = posmod(o, input)
		ScriptBlock.PortType.FLOAT:
			for i in range(1, inputs.size()):
				var input: float = type_convert(inputs[i].value, type)
				o = fposmod(o, input)
		ScriptBlock.PortType.VECTOR2:
			for i in range(1, inputs.size()):
				if inputs[i].port_type == ScriptBlock.PortType.VECTOR2:
					o = o.posmodv(inputs[i].value)
				else:
					var input: float = type_convert(inputs[i].value, ScriptBlock.PortType.FLOAT)
					o = o.posmod(input)
		ScriptBlock.PortType.VECTOR3:
			for i in range(1, inputs.size()):
				if inputs[i].port_type == ScriptBlock.PortType.VECTOR3:
					o = o.posmodv(inputs[i].value)
				else:
					var input: float = type_convert(inputs[i].value, ScriptBlock.PortType.FLOAT)
					o = o.posmod(input)
		ScriptBlock.PortType.COLOR:
			for i in range(1, inputs.size()):
				if inputs[i].port_type == ScriptBlock.PortType.COLOR:
					var input: Color = inputs[i].value
					o = Color(fposmod(o.r, input.r), fposmod(o.g, input.g), fposmod(o.b, input.b), fposmod(o.a, input.a))
				else:
					var input: float = type_convert(inputs[i].value, ScriptBlock.PortType.FLOAT)
					o = Color(fposmod(o.r, input), fposmod(o.g, input), fposmod(o.b, input), fposmod(o.a, input))
	outputs[0].value = o


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	if inputs[0].port_type == ScriptBlock.PortType.FLOAT \
			and inputs[1].port_type == ScriptBlock.PortType.FLOAT and (
			type == ScriptBlock.PortType.VECTOR2
			or type == ScriptBlock.PortType.VECTOR3
			or type == ScriptBlock.PortType.COLOR):
		if type == ScriptBlock.PortType.COLOR:
			graph_name = "Color Modulus By Float"
		else:
			graph_name = "Vector Modulus By Float"
		inputs[0].port_type = type
		inputs[0].value = type_convert(inputs[0].value, type)
		outputs[0].port_type = type
		outputs[0].value = type_convert(outputs[0].value, type)
	else:
		graph_name = "Modulus"
		super(type)


func get_script_block_type() -> String:
	return "modulus"

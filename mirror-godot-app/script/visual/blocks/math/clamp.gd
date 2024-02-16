extends ScriptBlockMath


func evaluate() -> void:
	evaluate_inputs()
	var type: ScriptBlock.PortType = outputs[0].port_type
	var value = inputs[0].value
	var minimum = inputs[1].value
	var maximum = inputs[2].value
	if type == ScriptBlock.PortType.INT:
		outputs[0].value = clampi(value, minimum, maximum)
	elif type == ScriptBlock.PortType.FLOAT:
		outputs[0].value = clampf(value, minimum, maximum)
	else:
		outputs[0].value = value.clamp(minimum, maximum)


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	if type == ScriptBlock.PortType.INT:
		inputs[2].value = 100
	elif type == ScriptBlock.PortType.FLOAT:
		inputs[2].value = 1.0
	elif type == ScriptBlock.PortType.VECTOR2:
		inputs[2].value = Vector2.ONE
	elif type == ScriptBlock.PortType.VECTOR3:
		inputs[2].value = Vector3.ONE
	elif type == ScriptBlock.PortType.COLOR:
		inputs[2].value = Color.WHITE
	super(type)


func get_script_block_type() -> String:
	return "clamp"

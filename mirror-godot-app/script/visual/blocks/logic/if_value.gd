class_name ScriptBlockIfValue
extends ScriptBlock


func evaluate() -> void:
	super()
	if inputs[0].value:
		outputs[0].value = inputs[1].value
	else:
		outputs[0].value = inputs[2].value


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	outputs[0].port_type = type
	outputs[0].value = type_convert(outputs[0].value, type)
	inputs[1].port_type = type
	inputs[1].value = type_convert(inputs[1].value, type)
	inputs[2].port_type = type
	inputs[2].value = type_convert(inputs[2].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type


func get_script_block_type() -> String:
	return "if_value"

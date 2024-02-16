## Base class for math functions. Should work with many types.
class_name ScriptBlockMath
extends ScriptBlockDyadic


const MATH_PORT_TYPES: Array[ScriptBlock.PortType] = [
	ScriptBlock.PortType.INT,
	ScriptBlock.PortType.FLOAT,
	ScriptBlock.PortType.STRING,
	ScriptBlock.PortType.VECTOR2,
	ScriptBlock.PortType.VECTOR3,
	ScriptBlock.PortType.COLOR,
]


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	for input in inputs:
		input.port_type = type
		input.value = type_convert(input.value, type)
	outputs[0].port_type = type
	outputs[0].value = type_convert(outputs[0].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return outputs[0].port_type

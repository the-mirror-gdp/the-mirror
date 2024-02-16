class_name ScriptBlockEquals
extends ScriptBlockDyadic


## Allow comparing float and int with approximate equality.
const _NUMBERS = [TYPE_INT, TYPE_FLOAT]
## String and StringName can be compared using the == operator.
const _STRINGS = [TYPE_STRING, TYPE_STRING_NAME]
## Any struct with an is_equal_approx instance method.
const _STRUCTS = [TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR]


func evaluate() -> void:
	super()
	for i in range(inputs.size() - 1):
		var input1: ScriptBlock.ScriptBlockDataPort = inputs[i]
		var input2: ScriptBlock.ScriptBlockDataPort = inputs[i + 1]
		if not compare_inputs_for_equality(input1, input2):
			outputs[0].value = false
			return
	outputs[0].value = true


static func compare_inputs_for_equality(input1: ScriptBlock.ScriptBlockDataPort, input2: ScriptBlock.ScriptBlockDataPort) -> bool:
	var type1 = typeof(input1.value)
	var type2 = typeof(input2.value)
	if type1 == TYPE_INT and type2 == TYPE_INT:
		return input1.value == input2.value
	if type1 in _NUMBERS and type2 in _NUMBERS:
		return is_equal_approx(input1.value, input2.value)
	if type1 in _STRINGS and type2 in _STRINGS:
		return input1.value == input2.value
	if type1 != type2:
		return false
	if type1 in _STRUCTS:
		return input1.value.is_equal_approx(input2.value)
	return input1.value == input2.value


func get_script_block_type() -> String:
	return "equals"

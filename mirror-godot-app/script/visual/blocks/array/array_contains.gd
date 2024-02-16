extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var array: Array = inputs[0].value
	var value: Variant = inputs[1].value
	var index: int = array.find(value)
	outputs[0].value = array
	outputs[1].value = index != -1
	outputs[2].value = index


func get_script_block_type() -> String:
	return "array_contains"

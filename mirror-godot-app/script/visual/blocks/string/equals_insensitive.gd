extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var left: String = inputs[0].value
	var right: String = inputs[1].value
	outputs[0].value = left.nocasecmp_to(right) == 0


func get_script_block_type() -> String:
	return "string_equals_case_insensitive"

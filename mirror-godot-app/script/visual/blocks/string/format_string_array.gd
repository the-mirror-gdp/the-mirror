extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var template: String = inputs[0].value
	var array: Array = inputs[1].value
	outputs[0].value = template % array


func get_script_block_type() -> String:
	return "format_string_array"

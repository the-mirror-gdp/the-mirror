extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var dict = JSON.parse_string(inputs[0].value)
	if not dict is Dictionary:
		log_error.emit("The input " + str(inputs[0].value) + " is not valid JSON.")
		return
	var template: String = str(inputs[1].value)
	outputs[0].value = template.format(dict)


func get_script_block_type() -> String:
	return "format_string"

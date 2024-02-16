extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var result: Dictionary = {}
	for input in inputs:
		var dict = JSON.parse_string(input.value)
		if dict is Dictionary:
			result.merge(dict)
		else:
			log_error.emit("The input " + str(input.value) + " is not valid JSON.")
	outputs[0].value = JSON.stringify(result)


func get_script_block_type() -> String:
	return "json_merge"

extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var dict = JSON.parse_string(inputs[0].value)
	var key: String = str(inputs[1].value)
	if not dict is Dictionary:
		log_error.emit("The input " + str(inputs[0].value) + " is not valid JSON.")
		return
	var result = dict.get(key)
	if result is Dictionary:
		result = JSON.stringify(result)
	outputs[0].value = result


func get_script_block_type() -> String:
	return "get_json_key"

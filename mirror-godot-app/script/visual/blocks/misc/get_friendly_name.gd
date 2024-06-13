extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var value = inputs[0].value
	outputs[0].value = Mirror.get_friendly_name(value)


func get_script_block_type() -> String:
	return "get_friendly_name"

extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = str(inputs[0].value)


func get_script_block_type() -> String:
	return "to_string"

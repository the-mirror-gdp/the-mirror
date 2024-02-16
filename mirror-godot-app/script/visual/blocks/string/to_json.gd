extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var json_dict = {str(inputs[0].value): inputs[1].value}
	outputs[0].value = JSON.stringify(json_dict)


func get_script_block_type() -> String:
	return "to_json"

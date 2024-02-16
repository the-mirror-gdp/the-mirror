extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var input_color: Color = inputs[0].value
	outputs[0].value = input_color[0]
	outputs[1].value = input_color[1]
	outputs[2].value = input_color[2]
	outputs[3].value = input_color[3]


func get_script_block_type() -> String:
	return "color_split"

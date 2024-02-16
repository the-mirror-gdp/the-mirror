extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = Color.from_hsv(inputs[0].value, inputs[1].value, inputs[2].value, inputs[3].value)


func get_input_limits(_input_port: ScriptBlock.ScriptBlockInputPort) -> Vector2:
	return Vector2(0.0, 1.0)


func get_script_block_type() -> String:
	return "color_from_hsv"

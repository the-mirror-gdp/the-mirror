extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = Vector2(inputs[0].value, inputs[1].value)


func get_script_block_type() -> String:
	return "vector2_construct"

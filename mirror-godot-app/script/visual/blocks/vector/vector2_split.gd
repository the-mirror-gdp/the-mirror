extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var input_vector: Vector2 = inputs[0].value
	outputs[0].value = input_vector[0]
	outputs[1].value = input_vector[1]


func get_script_block_type() -> String:
	return "vector2_split"

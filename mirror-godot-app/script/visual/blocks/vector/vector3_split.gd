extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var input_vector: Vector3 = inputs[0].value
	outputs[0].value = input_vector[0]
	outputs[1].value = input_vector[1]
	outputs[2].value = input_vector[2]


func get_script_block_type() -> String:
	return "vector3_split"

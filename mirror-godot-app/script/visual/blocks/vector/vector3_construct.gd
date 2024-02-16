extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = Vector3(inputs[0].value, inputs[1].value, inputs[2].value)


func get_script_block_type() -> String:
	return "vector3_construct"

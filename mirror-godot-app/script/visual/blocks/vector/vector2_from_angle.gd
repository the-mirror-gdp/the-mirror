extends ScriptBlock


const _DEG_TO_RAD = 0.0174532925199432957692369077


func evaluate() -> void:
	evaluate_inputs()
	var angle_radians: float = inputs[0].value * _DEG_TO_RAD
	var from_angle: Vector2 = Vector2.from_angle(angle_radians)
	outputs[0].value = from_angle
	outputs[1].value = from_angle.x
	outputs[2].value = from_angle.y


func get_script_block_type() -> String:
	return "vector2_from_angle"

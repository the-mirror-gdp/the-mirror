extends ScriptBlockOperationBase


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object = get_operation_target_object()
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	if not target_object is Node3D:
		log_error.emit("The target object is not a 3D node.")
		return ERR_INVALID_PARAMETER
	if target_object is Player:
		log_error.emit("You can't tween the rotation of a Player.")
		return ERR_INVALID_PARAMETER
	var final_value: Vector3 = inputs[1].value
	var duration: float = inputs[2].value
	var transition: Tween.TransitionType = ScriptBlockTweenProperty.TRANSITION_NAMES_TO_VALUES.get(inputs[3].value, Tween.TRANS_LINEAR)
	var easing: Tween.EaseType = ScriptBlockTweenProperty.EASING_NAMES_TO_VALUES.get(inputs[4].value, Tween.EASE_IN_OUT)
	# This will also tween it locally immediately.
	if target_object is Player:
		Zone.script_network_sync.tween_property_on_node(target_object, "model_rotation_degrees", final_value, duration, transition, easing)
	else:
		Zone.script_network_sync.tween_property_on_node(target_object, "rotation_degrees", final_value, duration, transition, easing)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[3] or input_port == inputs[4]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[3]:
		return ScriptBlockTweenProperty.TRANSITION_NAMES_TO_VALUES.keys()
	if input_port == inputs[4]:
		return ScriptBlockTweenProperty.EASING_NAMES_TO_VALUES.keys()
	assert(false, "Should not be reached, the code should never try to get the enum values from a non-enumerated port.")
	return []


func get_script_block_type() -> String:
	return "tween_rotation_degrees"

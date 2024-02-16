extends ScriptBlockTweenProperty


func _execute_callback(stack_count: int) -> Error:
	var target_object: Object = get_operation_target_object()
	if not target_object is SpaceObject:
		log_error.emit("The target object needs to be a SpaceObject.")
		return ERR_INVALID_PARAMETER
	var scroll_offset: Vector2 = inputs[1].value
	var duration: float = inputs[2].value
	var transition: Tween.TransitionType = TRANSITION_NAMES_TO_VALUES.get(inputs[3].value, Tween.TRANS_LINEAR)
	var easing: Tween.EaseType = EASING_NAMES_TO_VALUES.get(inputs[4].value, Tween.EASE_IN_OUT)
	var final_value: Vector3 = target_object.object_texture_offset + Vector3(scroll_offset.x, scroll_offset.y, 0.0)
	# This will also tween it locally immediately.
	Zone.script_network_sync.tween_property_on_node(target_object, &"object_texture_offset", final_value, duration, transition, easing)
	return OK


func get_script_block_type() -> String:
	return "scroll_texture"

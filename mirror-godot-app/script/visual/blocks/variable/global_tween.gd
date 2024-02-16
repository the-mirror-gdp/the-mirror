extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var variable_name: String = inputs[0].value
	var final_value: Variant = inputs[1].value
	if final_value is Object:
		log_error.emit("Cannot tween an Object value.")
		return ERR_INVALID_PARAMETER
	var duration: float = inputs[2].value
	var transition: Tween.TransitionType = ScriptBlockTweenProperty.TRANSITION_NAMES_TO_VALUES.get(inputs[3].value, Tween.TRANS_LINEAR)
	var easing: Tween.EaseType = ScriptBlockTweenProperty.EASING_NAMES_TO_VALUES.get(inputs[4].value, Tween.EASE_IN_OUT)
	# Note: Unlike setting a variable, this does not apply immediately.
	# Since tweening does not have an effect on the same frame anyway,
	# we can afford to wait for the server to only do a synced tween.
	Zone.script_network_sync.tween_global_variable(variable_name, final_value, duration, transition, easing)
	return OK


func change_primary_type_selection(type: ScriptBlock.PortType) -> void:
	inputs[1].port_type = type
	inputs[1].value = type_convert(inputs[1].value, type)


func get_primary_port_type() -> ScriptBlock.PortType:
	return inputs[1].port_type


func set_primary_port_type_and_value(value: Variant) -> void:
	inputs[1].port_type = typeof(value)
	inputs[1].value = value


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
	return "tween_global_variable"

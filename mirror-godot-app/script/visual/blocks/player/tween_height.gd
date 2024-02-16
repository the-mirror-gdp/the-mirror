extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var player = inputs[0].value
	if not player is Player:
		log_error.emit("The target object is not a Player.")
		return ERR_INVALID_PARAMETER
	var final_value: float = inputs[1].value
	var height_type: String = inputs[2].value
	if height_type == "Meters":
		# Convert the meters value into a multiplier.
		final_value /= player.model.head_top_height_meters
	var duration: float = inputs[3].value
	var transition: Tween.TransitionType = ScriptBlockTweenProperty.TRANSITION_NAMES_TO_VALUES.get(inputs[4].value, Tween.TRANS_LINEAR)
	var easing: Tween.EaseType = ScriptBlockTweenProperty.EASING_NAMES_TO_VALUES.get(inputs[5].value, Tween.EASE_IN_OUT)
	# This will also tween it locally immediately.
	Zone.script_network_sync.tween_property_on_node(player, "player_height_multiplier", final_value, duration, transition, easing)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[2] or input_port == inputs[4] or input_port == inputs[5]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[2]:
		return ["Meters", "Multiplier"]
	if input_port == inputs[4]:
		return ScriptBlockTweenProperty.TRANSITION_NAMES_TO_VALUES.keys()
	if input_port == inputs[5]:
		return ScriptBlockTweenProperty.EASING_NAMES_TO_VALUES.keys()
	assert(false, "Should not be reached, the code should never try to get the enum values from a non-enumerated port.")
	return []


func get_script_block_type() -> String:
	return "tween_player_height"

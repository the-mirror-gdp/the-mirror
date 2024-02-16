extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	if not GameplaySettings.is_microphone_enabled:
		outputs[0].value = false
		return
	var player = inputs[0].value
	var is_valid_player: bool = is_instance_valid(player) and player is Player
	if is_valid_player:
			outputs[0].value = player.is_audio_input_detected()
	else:
		log_error.emit("The target object is not a Player.")


func get_script_block_type() -> String:
	return "audio_input_detect"

extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var player = inputs[0].value
	var new_height: float = inputs[1].value
	var height_type: String = inputs[2].value
	if player is Player:
		if height_type == "Multiplier":
			player.set_player_height_multiplier(new_height)
		else:
			player.set_player_height_meters(new_height)
		return OK
	log_error.emit("The target object is not a Player.")
	return ERR_INVALID_PARAMETER


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port.port_name == "Height Type"


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return ["Meters", "Multiplier"]


func get_script_block_type() -> String:
	return "set_player_height"

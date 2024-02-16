extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player = inputs[0].value
	var height_type: String = inputs[1].value
	if player is Player:
		if height_type == "Multiplier":
			outputs[0].value = player.get_player_height_multiplier()
		else:
			outputs[0].value = player.get_player_height_meters()
	else:
		log_error.emit("The target object is not a Player.")


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port.port_name == "Height Type"


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return ["Meters", "Multiplier"]


func get_script_block_type() -> String:
	return "get_player_height"

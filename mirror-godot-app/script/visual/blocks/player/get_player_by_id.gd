extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player_id: String = inputs[0].value
	var player = Zone.social_manager.get_player(player_id)

	var is_valid_player: bool = is_instance_valid(player) and player is Player
	outputs[0].value = player if is_valid_player else null
	outputs[1].value = is_valid_player


func get_script_block_type() -> String:
	return "get_player_by_id"

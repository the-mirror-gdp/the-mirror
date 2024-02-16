extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var player: Player
	if inputs[0].value is Player:
		player = inputs[0].value
	elif Zone.is_client() and PlayerData.has_local_player():
		player = PlayerData.get_local_player()
	else:
		outputs[0].value = null
		return
	outputs[0].value = player.model.head_bone_node


func get_script_block_type() -> String:
	return "get_player_head"

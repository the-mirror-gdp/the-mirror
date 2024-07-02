extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var target_player = inputs[0].value
	if Zone.is_host():
		if target_player is Player:
			var player_peer_id = target_player.get_peer_id()
			GameUI.instance.scoreboard_window.set_scoreboard_shown_network.rpc_id(player_peer_id, false, false, false)
		else:
			GameUI.instance.scoreboard_window.set_scoreboard_shown(false, false, false)
	else:
		if target_player is Player and target_player != PlayerData.get_local_player():
			log_error.emit("Cannot hide the scoreboard on " + target_player.get_player_name() + " from a client-side script.")
		# On client-side scripts, only hide locally.
		GameUI.instance.scoreboard_window.set_scoreboard_shown_network(false, false, false)
	return OK


func get_script_block_type() -> String:
	return "hide_scoreboard"

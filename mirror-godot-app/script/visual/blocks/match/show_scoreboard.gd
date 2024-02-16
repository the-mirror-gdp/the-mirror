extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var target_player = inputs[0].value
	var allow_close: bool
	var allow_new_match: bool = inputs[2].value
	# Don't let users soft-lock themselves with a scoreboard in Build mode.
	# If we show the new match button or it's play mode, respect the allow
	# close input. If new match is hidden and it's build mode, force-show.
	if allow_new_match or Zone.is_in_play_mode():
		allow_close = inputs[1].value
	else:
		allow_close = true
	if Zone.is_host():
		if target_player is Player:
			var player_peer_id = target_player.get_peer_id()
			GameUI.scoreboard_window.set_scoreboard_shown_network.rpc_id(player_peer_id, true, allow_close, allow_new_match)
		else:
			GameUI.scoreboard_window.set_scoreboard_shown(true, allow_close, allow_new_match)
	else:
		if target_player is Player and target_player != PlayerData.get_local_player():
			log_error.emit("Cannot show the scoreboard on " + target_player.get_player_name() + " from a client-side script.")
		# On client-side scripts, only show locally.
		GameUI.scoreboard_window.set_scoreboard_shown_network(true, allow_close, allow_new_match)
	return OK


func get_script_block_type() -> String:
	return "show_scoreboard"

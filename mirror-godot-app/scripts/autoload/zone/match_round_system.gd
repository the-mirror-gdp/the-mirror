class_name MatchRoundSystem
extends Node


signal match_start(freeze_time: float)
signal match_end(winning_team_name: String)
signal round_start(freeze_time: float)
signal round_end(winning_team_name: String)
signal team_score_changed(team_name: String, team_score: int)

var _is_match_running: bool = false
var _is_round_running: bool = false


func start_match(freeze_time: float = -1.0) -> void:
	if Zone.is_in_play_mode():
		Zone.script_network_sync.server_restore_play_preview_space_vars_backup()
	freeze_time = _get_real_freeze_time(freeze_time)
	var teams: Array = Zone.script_network_sync.get_global_variable("teams")
	for team in teams:
		team["score"] = 0
	Zone.script_network_sync.set_global_variable("teams", teams)
	_is_match_running = true
	match_start.emit(freeze_time)
	start_round(freeze_time)


func start_round(freeze_time: float = -1.0) -> void:
	if not _is_match_running:
		Zone.script_network_sync.server_script_print_notify("Match Not Running", "Tried to start a round, but no match was running.", Enums.NotifyStatus.WARNING)
		return
	freeze_time = _get_real_freeze_time(freeze_time)
	var all_players: Array = Zone.social_manager.get_all_players()
	if freeze_time > 0.0:
		for player in all_players:
			player.set_player_input_allowed(false)
	for player in all_players:
		player.respawn_player()
	_is_round_running = true
	round_start.emit(freeze_time)
	if freeze_time > 0.0:
		await get_tree().create_timer(freeze_time).timeout
	for player in all_players:
		player.set_player_input_allowed(true)


func end_round(winning_team_name: String, auto_start_next: bool, auto_start_wait_time: float, auto_start_freeze_time: float) -> void:
	if not _is_round_running:
		Zone.script_network_sync.server_script_print_notify("Round Not Running", "Tried to end the round, but no round was running.", Enums.NotifyStatus.WARNING)
		return
	if add_score_to_team(winning_team_name, 1):
		return
	# If we did not return, the match is still going but we need to end the round and start the next.
	_is_round_running = false
	round_end.emit(winning_team_name)
	if auto_start_next:
		if auto_start_wait_time > 0.0:
			await get_tree().create_timer(auto_start_wait_time).timeout
		start_round(auto_start_freeze_time)


func end_match(winning_team_name: String) -> void:
	if not _is_match_running:
		Zone.script_network_sync.server_script_print_notify("Match Not Running", "Tried to end the match, but no match was running.", Enums.NotifyStatus.WARNING)
		return
	if GameUI and GameUI.scoreboard_window:
		# This is naive but it works for now.
		var win_plurality: String = " win!" if winning_team_name.ends_with("s") else " wins!"
		GameUI.scoreboard_window.set_scoreboard_title_text(winning_team_name + win_plurality)
		GameUI.scoreboard_window.set_scoreboard_shown(true, false, true)
		var all_players: Array = Zone.social_manager.get_all_players()
		for player in all_players:
			player.set_player_input_allowed(false)
	_is_match_running = false
	match_end.emit(winning_team_name)


func terminate_match() -> void:
	_is_match_running = false
	_is_round_running = false
	GameUI.scoreboard_window.set_scoreboard_title_text("Scoreboard")
	GameUI.scoreboard_window.set_scoreboard_shown(false, false, false)
	var all_players: Array = Zone.social_manager.get_all_players()
	for player in all_players:
		player.set_player_input_allowed(true)


func terminate_round() -> void:
	if not _is_match_running:
		Zone.script_network_sync.server_script_print_notify("Match Not Running", "Tried to terminate a round, but no match was running.", Enums.NotifyStatus.WARNING)
		return
	_is_round_running = false
	var all_players: Array = Zone.social_manager.get_all_players()
	for player in all_players:
		player.set_player_input_allowed(true)


func is_match_running() -> bool:
	return _is_match_running


func is_round_running() -> bool:
	return _is_round_running


func get_team_names() -> Array[String]:
	var teams: Array = Zone.script_network_sync.get_global_variable("teams")
	var team_names: Array[String] = []
	for team in teams:
		team_names.append(team.get("team_name", "ERROR"))
	return team_names


func get_score_for_team(team_name: String) -> int:
	var teams: Array = Zone.script_network_sync.get_global_variable("teams")
	for team in teams:
		if team_name.nocasecmp_to(team.get("team_name", "_ERROR_")) == 0: # 0 if equal.
			var score: int = team.get_or_add("score", 0)
			return score
	return -1


## Returns true if the match has ended.
func set_score_for_team(team_name: String, new_score: int) -> bool:
	if not _is_match_running:
		Zone.script_network_sync.server_script_print_notify("Match Not Running", "Tried to set the score for a team, but no match was running.", Enums.NotifyStatus.WARNING)
		return true
	var score_needed_to_win = Zone.script_network_sync.get_global_variable("match_settings/win_conditions/score")
	if not score_needed_to_win is int:
		score_needed_to_win = 3
		Zone.script_network_sync.server_script_print_notify("Winning Score Not Found", "Defaulting to 3. Use Set Win Conditions to control this.", Enums.NotifyStatus.WARNING)
		Zone.script_network_sync.set_global_variable("match_settings/win_conditions/score", score_needed_to_win)
	var teams: Array = Zone.script_network_sync.get_global_variable("teams")
	for team in teams:
		if team_name.nocasecmp_to(team.get("team_name", "_ERROR_")) == 0: # 0 if equal.
			team["score"] = new_score
			team_score_changed.emit(team_name, new_score)
			break
	if new_score >= score_needed_to_win:
		_is_round_running = false
		round_end.emit(team_name)
		end_match(team_name)
		return true
	return false


func add_score_to_team(team_name: String, score_to_add: int) -> bool:
	var score: int = get_score_for_team(team_name)
	return set_score_for_team(team_name, score + score_to_add)


func _get_real_freeze_time(input_freeze_time: float) -> float:
	if input_freeze_time < 0.0:
		var freeze_time_var = Zone.script_network_sync.get_global_variable("match_settings/freeze_time")
		if not freeze_time_var is float:
			freeze_time_var = 1.0
		input_freeze_time = freeze_time_var
		Zone.script_network_sync.set_global_variable("match_settings/freeze_time", freeze_time_var)
	return input_freeze_time

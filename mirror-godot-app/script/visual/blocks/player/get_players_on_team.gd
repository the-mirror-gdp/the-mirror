extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var team_name: String = inputs[0].value
	var all_players: Array = Zone.social_manager.get_all_players()
	var players_on_team: Array = []
	for player in all_players:
		if team_name.nocasecmp_to(player.get_player_team()) == 0:
			players_on_team.append(player)
	outputs[0].value = players_on_team


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port.port_name == "Team Name"


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	var global_teams: Array = Zone.get_global_teams()
	var team_names: Array = []
	for team in global_teams:
		if team.has("team_name"):
			team_names.append(team["team_name"])
	return team_names


func get_script_block_type() -> String:
	return "get_players_on_team"

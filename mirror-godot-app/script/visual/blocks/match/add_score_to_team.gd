extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var team_name: String = inputs[0].value
	var score_to_add: int = inputs[1].value
	Zone.match_system.add_score_to_team(team_name, score_to_add)
	return OK


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
	return "add_score_to_team"

extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if not Zone.is_host():
		log_error.emit("Match/round blocks are only allowed on the server.")
		return ERR_UNAUTHORIZED
	var winning_team_name: String = inputs[0].value
	Zone.match_system.end_match(winning_team_name)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[0]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[0]:
		return Zone.match_system.get_team_names()
	return []


func get_script_block_type() -> String:
	return "match_end"

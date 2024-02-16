extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if not Zone.is_host():
		log_error.emit("Match/round blocks are only allowed on the server.")
		return ERR_UNAUTHORIZED
	var winning_team_name: String = inputs[0].value
	var auto_start_next: bool = inputs[1].value
	var auto_start_wait_time: float = inputs[2].value
	var auto_start_freeze_time: float = inputs[3].value
	Zone.match_system.end_round(winning_team_name, auto_start_next, auto_start_wait_time, auto_start_freeze_time)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[0]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[0]:
		return Zone.match_system.get_team_names()
	return []


func get_script_block_type() -> String:
	return "round_end"

extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if not Zone.is_host():
		log_error.emit("Match/round blocks are only allowed on the server.")
		return ERR_UNAUTHORIZED
	var freeze_time: float = inputs[0].value
	Zone.match_system.start_match(freeze_time)
	return OK


func get_script_block_type() -> String:
	return "match_start"

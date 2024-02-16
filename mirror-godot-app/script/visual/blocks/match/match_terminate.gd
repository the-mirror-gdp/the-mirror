extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if not Zone.is_host():
		log_error.emit("Match/round blocks are only allowed on the server.")
		return ERR_UNAUTHORIZED
	Zone.match_system.terminate_match()
	return OK


func get_script_block_type() -> String:
	return "match_terminate"

extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var score_needed_to_win: int = inputs[0].value
	Zone.script_network_sync.set_global_variable("match_settings/win_conditions/score", score_needed_to_win)
	return OK


func get_script_block_type() -> String:
	return "set_win_conditions"

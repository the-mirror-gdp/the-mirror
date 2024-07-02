extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var new_title: String = inputs[0].value
	if Zone.is_host():
		GameUI.instance.scoreboard_window.set_scoreboard_title_text(new_title)
	else:
		GameUI.instance.scoreboard_window.set_scoreboard_title_text_network(new_title)
	return OK


func get_script_block_type() -> String:
	return "set_scoreboard_title"

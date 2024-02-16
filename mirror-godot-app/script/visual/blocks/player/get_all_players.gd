extends ScriptBlock


func evaluate() -> void:
	outputs[0].value = Zone.social_manager.get_all_players()


func get_script_block_type() -> String:
	return "get_all_players"

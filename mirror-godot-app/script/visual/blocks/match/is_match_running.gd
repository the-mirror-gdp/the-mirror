extends ScriptBlock


func evaluate() -> void:
	outputs[0].value = Zone.match_system.is_match_running()


func get_script_block_type() -> String:
	return "is_match_running"

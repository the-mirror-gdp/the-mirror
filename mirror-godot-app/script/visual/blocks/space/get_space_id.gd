extends ScriptBlock


func evaluate() -> void:
	outputs[0].value = Zone.space.get("_id", "unknown")


func get_script_block_type() -> String:
	return "get_space_id"

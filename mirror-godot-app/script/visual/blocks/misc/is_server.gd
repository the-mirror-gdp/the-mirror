extends ScriptBlock


func evaluate() -> void:
	outputs[0].value = Zone.is_host()


func get_script_block_type() -> String:
	return "is_server"

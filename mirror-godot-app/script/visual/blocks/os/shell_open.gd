extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_host() or not ProjectSettings.get_setting("feature_flags/os_shell", false):
		return ERR_UNAUTHORIZED
	var uri: String = inputs[0].value
	return OS.shell_open(uri)


func get_script_block_type() -> String:
	return "os_shell_open"

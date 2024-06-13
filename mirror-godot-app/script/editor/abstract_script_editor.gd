class_name AbstractScriptEditor
extends Control


signal request_save_script_as_asset(script_instance: ScriptInstance)
signal request_show_entry_creation_dialog(target_node: Node)
signal request_show_custom_entry_creation_dialog(target_node: Node)
signal request_toggle_variable_editor()
signal request_script_editor_visibility(is_visible: bool)
signal request_track_recently_used_space_script(script_instance: ScriptInstance)


func create_entry_from_dialog(block_json: Dictionary) -> void:
	assert(false, "This method must be overridden in a derived class.")


func request_close() -> bool:
	assert(false, "This method must be overridden in a derived class.")
	return false # Unreachable


func copy_selection() -> void:
	assert(false, "This method must be overridden in a derived class.")


func paste_copied_data() -> void:
	assert(false, "This method must be overridden in a derived class.")


func duplicate_selection() -> void:
	assert(false, "This method must be overridden in a derived class.")


func delete_selection() -> void:
	assert(false, "This method must be overridden in a derived class.")

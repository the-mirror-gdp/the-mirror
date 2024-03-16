extends AbstractScriptEditor


const _SCRIPT_UPDATE_DELAY_FRAMES := 20

var _script_instance: GDScriptInstance
var _queue_update_network_script_frames: int = -1
var _last_user_input_ticks_msec: int

@onready var _toolbar_buttons: Control = $VBoxContainer/GDScriptToolbarButtons
@onready var _code_edit: CodeEdit = $VBoxContainer/CodeEdit
@onready var _error_bar: Label = $VBoxContainer/ErrorBar


func _ready() -> void:
	_toolbar_buttons.connect_gdscript_editor_signals(self)


func _process(_delta: float) -> void:
	if _script_instance:
		_validate_script_instance()
		_queue_update_network_script_frames -= 1
		if _queue_update_network_script_frames == 0:
			_script_instance.set_source_code(_code_edit.text)
			_script_instance.script_data_contents_changed()


func load_from_script_instance(script_instance: GDScriptInstance) -> void:
	_validate_script_instance()
	if _script_instance != null:
		_script_instance.gdscript_compile_error.disconnect(_on_gdscript_compile_error)
		_script_instance.gdscript_compile_success.disconnect(_on_gdscript_compile_success)
		_script_instance.script_contents_changed.disconnect(refresh_script_text_editor)
		_script_instance.script_entity_data_updated_from_network.disconnect(on_script_entity_data_updated_from_network)
	_script_instance = script_instance
	_toolbar_buttons.setup_for_script_instance(script_instance)
	_code_edit.text = script_instance.get_source_code()
	_script_instance.gdscript_compile_error.connect(_on_gdscript_compile_error)
	_script_instance.gdscript_compile_success.connect(_on_gdscript_compile_success)
	_script_instance.reload_source_code()
	_script_instance.script_contents_changed.connect(refresh_script_text_editor)
	_script_instance.script_entity_data_updated_from_network.connect(on_script_entity_data_updated_from_network)


func create_entry_from_dialog(entry_json: Dictionary) -> void:
	_script_instance.create_entry(entry_json)
	_script_instance.script_data_contents_changed()
	_last_user_input_ticks_msec = Time.get_ticks_msec()


func request_close() -> bool:
	_script_instance = null
	request_script_editor_visibility.emit(false)
	return true


func copy_selection() -> void:
	_code_edit.copy()


func paste_copied_data() -> void:
	_code_edit.paste()


func duplicate_selection() -> void:
	_code_edit.copy()
	_code_edit.paste()
	_code_edit.paste()


func delete_selection() -> void:
	_code_edit.delete_selection()


func close_script_editor_pressed() -> void:
	request_script_editor_visibility.emit(false)


func create_new_script_entry_pressed() -> void:
	request_show_entry_creation_dialog.emit(_script_instance.target_node)


func focus_line_in_script(script_instance: ScriptInstance, line_number: int, error_text: String) -> void:
	if _script_instance != script_instance:
		load_from_script_instance(script_instance)
	_error_bar.add_theme_color_override(&"font_color", Color.RED)
	_error_bar.text = error_text


func refresh_script_text_editor() -> void:
	_toolbar_buttons.setup_for_script_instance(_script_instance)
	request_track_recently_used_space_script.emit(_script_instance) # It might have changed.
	var source_code: String = _script_instance.get_source_code()
	if _code_edit.text == source_code:
		return # The displayed code is already correct.
	_code_edit.set_code_text_but_keep_navigation(source_code)


func save_script_as_asset_pressed() -> void:
	request_save_script_as_asset.emit(_script_instance)


func on_script_entity_data_updated_from_network() -> void:
	if _last_user_input_ticks_msec < Time.get_ticks_msec() - 1000:
		refresh_script_text_editor()


func script_name_text_changed(new_text: String) -> void:
	if not _script_instance:
		return
	_script_instance.script_name = new_text
	_script_instance.script_contents_changed.emit()
	_queue_update_network_script_frames = _SCRIPT_UPDATE_DELAY_FRAMES * 3


func show_error_if_script_open(script_instance: GDScriptInstance, line_number: int, error_text: String) -> bool:
	if _script_instance != script_instance:
		return false
	_error_bar.add_theme_color_override(&"font_color", Color.RED)
	_error_bar.text = error_text
	return true


func toggle_variable_editor_pressed() -> void:
	request_toggle_variable_editor.emit()


func _validate_script_instance() -> void:
	if not is_instance_valid(_script_instance):
		# If the script event is no longer valid, clear the script editor.
		request_close()
		_script_instance = null


func _on_code_edit_text_changed() -> void:
	_queue_update_network_script_frames = _SCRIPT_UPDATE_DELAY_FRAMES
	_last_user_input_ticks_msec = Time.get_ticks_msec()


func _on_gdscript_compile_error(error_code: int, error_messages: Array) -> void:
	var error_text: String = ""
	if error_messages.is_empty():
		if error_code == ERR_PARSE_ERROR:
			error_text = "Unknown parse error."
		elif error_code == ERR_COMPILATION_FAILED:
			error_text = "Unknown compile error."
		else:
			error_text = "Unknown error " + str(error_code) + ". Please report this as a bug to The Mirror."
	else:
		var first_error: Dictionary = error_messages[0]
		error_text = _error_message_dict_to_string(first_error)
	_error_bar.add_theme_color_override(&"font_color", Color.RED)
	_error_bar.text = error_text
	_code_edit.clear_entry_connection_decoration()


func _on_gdscript_compile_success() -> void:
	_error_bar.add_theme_color_override(&"font_color", Color.GREEN)
	_error_bar.text = "This code compiles, no errors detected."
	_code_edit.load_entry_connection_decoration(_script_instance)


func _error_message_dict_to_string(error: Dictionary) -> String:
	return "Line " + str(error["line"]) + " col " + str(error["column"]) + ": " + error["message"]

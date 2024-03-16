extends Control


@onready var _h_flow = $HFlow
@onready var _script_name_line_edit: LineEdit = $HFlow/ScriptNameLineEdit
@onready var _save_as_asset_button: Button = $HFlow/SaveAsAssetButton
@onready var _add_entry_button: Button = $HFlow/AddEntryButton
@onready var _v_separator_2: VSeparator = $HFlow/VSeparator2
@onready var _variables_button: Button = $HFlow/VariablesButton
@onready var _script_usage: HBoxContainer = $HFlow/ScriptUsage
@onready var _close_button: Button = $CloseButton


func _process(_delta: float) -> void:
	custom_minimum_size.y = _h_flow.size.y


# Not the nicest API but it avoids unnecessary bouncing methods.
func connect_gdscript_editor_signals(gdscript_editor: AbstractScriptEditor) -> void:
	_script_name_line_edit.text_changed.connect(gdscript_editor.script_name_text_changed)
	_save_as_asset_button.pressed.connect(gdscript_editor.save_script_as_asset_pressed)
	_add_entry_button.pressed.connect(gdscript_editor.create_new_script_entry_pressed)
	_variables_button.pressed.connect(gdscript_editor.toggle_variable_editor_pressed)
	_close_button.pressed.connect(gdscript_editor.close_script_editor_pressed)


func setup_for_script_instance(script_instance: ScriptInstance) -> void:
	_script_usage.setup_for_script_instance(script_instance)
	if _script_name_line_edit.text != script_instance.script_name:
		_script_name_line_edit.text = script_instance.script_name
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	_set_script_toolbar_editable(Util.can_local_user_edit_scripts() or script_instance.is_script_asset)


func _set_script_toolbar_editable(is_editable: bool) -> void:
	_script_name_line_edit.editable = is_editable
	_add_entry_button.visible = is_editable
	_v_separator_2.visible = is_editable
	_script_usage.set_script_toolbar_editable(is_editable)

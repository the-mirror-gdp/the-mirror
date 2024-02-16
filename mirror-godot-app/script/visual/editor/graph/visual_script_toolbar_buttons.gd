extends Control


@onready var _h_flow = $HFlow
@onready var _script_name_line_edit: LineEdit = $HFlow/ScriptNameLineEdit
@onready var _save_as_asset_button: Button = $HFlow/SaveAsAssetButton
@onready var _add_script_block_button: Button = $HFlow/AddScriptBlockButton
@onready var _add_entry_button: Button = $HFlow/AddEntryButton
@onready var _add_comment_button: Button = $HFlow/AddCommentButton
@onready var _v_separator_2 = $HFlow/VSeparator2
@onready var _variables_button: Button = $HFlow/VariablesButton
@onready var _spacer = $HFlow/Spacer
@onready var _script_usage: Control = $HFlow/ScriptUsage
@onready var _close_button: Button = $CloseButton


func _process(_delta: float) -> void:
	_spacer.visible = _h_flow.size.y < 50.0


# Not the nicest API but it's the best considering we have to add this through code.
func connect_script_graph_edit_signals(script_graph_edit: GraphEdit) -> void:
	_script_name_line_edit.text_changed.connect(script_graph_edit.script_name_text_changed)
	_save_as_asset_button.pressed.connect(script_graph_edit.save_script_as_asset)
	_add_script_block_button.pressed.connect(script_graph_edit.create_new_script_block_dialog)
	_add_entry_button.pressed.connect(script_graph_edit.create_new_script_entry_dialog)
	_add_comment_button.pressed.connect(script_graph_edit.create_new_comment_pressed)
	_variables_button.pressed.connect(script_graph_edit.toggle_variable_editor_pressed)
	_close_button.pressed.connect(script_graph_edit.close_script_editor_pressed)


func setup_for_script_instance(script_instance: ScriptInstance) -> void:
	_script_usage.setup_for_script_instance(script_instance)
	if _script_name_line_edit.text != script_instance.script_name:
		_script_name_line_edit.text = script_instance.script_name
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	_set_script_toolbar_editable(Util.can_local_user_edit_scripts() or script_instance.is_script_asset)


func _set_script_toolbar_editable(is_editable: bool) -> void:
	_script_name_line_edit.editable = is_editable
	_add_script_block_button.visible = is_editable
	_add_comment_button.visible = is_editable
	_v_separator_2.visible = is_editable
	_script_usage.set_script_toolbar_editable(is_editable)

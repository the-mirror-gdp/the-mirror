extends Window


var _edited_script_block: ScriptBlockGDScriptCode
var _recompile_delay: float = INF

@onready var _script_editor: Control = get_parent()
@onready var _gdscript_code_edit: CodeEdit = $GDScriptCodeEdit

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if self.visible:
		GameUI.instance.add_visible_window(self)
	else:
		GameUI.instance.remove_visible_window(self)


func _process(delta: float) -> void:
	if _edited_script_block == null:
		return
	elif not is_instance_valid(_edited_script_block):
		close_editor()
		return
	# Recompile after the editor has been inactive for a short time.
	_recompile_delay -= delta
	if _recompile_delay < 0.0:
		_edited_script_block.compile()
		_recompile_delay = INF


func close_editor():
	if is_instance_valid(_edited_script_block):
		_edited_script_block.compile()
		_recompile_delay = INF
	_edited_script_block = null
	hide()


func edit_script_block(script_block: ScriptBlockGDScriptCode) -> void:
	_edited_script_block = script_block
	_gdscript_code_edit.text = script_block.gdscript_code
	popup_centered(_script_editor.size)


func _on_code_edit_text_changed():
	assert(is_instance_valid(_edited_script_block))
	_edited_script_block.gdscript_code = _gdscript_code_edit.text
	_recompile_delay = 1.0


func _on_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.instance.release_input_lock(self)

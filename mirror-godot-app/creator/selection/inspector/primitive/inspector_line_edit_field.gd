@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: String)

@export var reset_value: String = ""
@export var current_value: String = "":
	get:
		return _line_edit_node.text
	set(value):
		_line_edit_node.text = value
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _line_edit_node:
			_line_edit_node.editable = value

@onready var _line_edit_node: LineEdit = $LineEditHolder/LineEdit


func _ready() -> void:
	super()
	if reset_value != "":
		_update_reset_visibility(current_value != reset_value)
	_line_edit_node.editable = enabled


func _on_text_changed(new_text: String) -> void:
	if reset_value != "":
		_update_reset_visibility(new_text != reset_value)
	value_changed.emit(new_text)


func _on_value_dropped(value) -> void:
	current_value = type_convert(value, TYPE_STRING)
	_on_text_changed(current_value)


func _on_focus_entered() -> void:
	await get_tree().process_frame
	# This is done declaratively by LineEdit.select_all_on_focus = true
	# _line_edit_node.select_all()
	GameUI.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.release_input_lock(self)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	_update_reset_visibility(false)
	value_changed.emit(current_value)

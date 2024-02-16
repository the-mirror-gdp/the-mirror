@tool
extends "res://creator/selection/inspector/primitive/inspector_property_base.gd"


signal value_changed(new_value: String)

@onready var _main_button = $MainButton
@onready var _window: Window = $Window
@onready var _code_edit = $Window/CodeEdit
@export var current_value: String = "":
	get:
		if not is_instance_valid(_code_edit):
			return ""
		return _code_edit.text
	set(value):
		if is_instance_valid(_code_edit):
			if _code_edit.text == value:
				return
			_code_edit.safe_set_text(value)


func _ready() -> void:
	pass # override parent


func _on_main_button_pressed() -> void:
	_window.popup_centered_ratio(0.7)


func refresh() -> void:
	_code_edit.text = current_value



func _on_value_dropped(value) -> void:
	current_value = type_convert(value, TYPE_STRING)
	refresh()


func _on_code_edit_text_changed() -> void:
	if _window.visible:
		value_changed.emit(_code_edit.text)


func _on_window_close_requested() -> void:
	_window.visible = false

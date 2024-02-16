@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: Color)

@export var reset_value := Color.WHITE
@export var current_value := Color.WHITE:
	get:
		if _color_node == null:
			return Color()
		return _color_node.color
	set(value):
		if _color_node == null:
			return
		_color_node.color = value
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _color_node:
			_color_node.disabled = not value

@onready var _color_node = $ColorPickerButton


func _on_color_picker_button_color_changed(new_value: Color) -> void:
	_update_reset_visibility(not new_value.is_equal_approx(reset_value))
	value_changed.emit(new_value)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	_update_reset_visibility(false)
	value_changed.emit(current_value)

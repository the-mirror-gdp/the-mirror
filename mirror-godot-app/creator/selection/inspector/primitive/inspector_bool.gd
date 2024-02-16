@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: bool)

@export var reset_value := false
@export var current_value := false:
	get:
		if _check_box == null:
			return false
		return _check_box.button_pressed
	set(value):
		if _check_box == null:
			return
		_check_box.set_pressed_no_signal(value)
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		if is_instance_valid(_check_box):
			enabled = value
			_check_box.disabled = not enabled

@onready var _check_box: CheckBox = $CheckBox


func _on_check_box_toggled(button_pressed: bool) -> void:
	_update_reset_visibility(button_pressed != reset_value)
	value_changed.emit(button_pressed)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	value_changed.emit(current_value)

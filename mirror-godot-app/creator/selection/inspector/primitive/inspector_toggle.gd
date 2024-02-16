@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: bool)

@export var reset_value := false
@export var current_value := false:
	get:
		if _button_enable == null or _button_disable == null:
			return false
		return _button_enable.button_pressed
	set(value):
		if _button_enable == null or _button_disable == null:
			return
		_button_enable.set_pressed_no_signal(value)
		_button_disable.set_pressed_no_signal(not value)
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		if is_instance_valid(_button_disable) and is_instance_valid(_button_enable):
			enabled = value
			_button_disable.disabled = not enabled
			_button_enable.disabled = not enabled

@onready var _button_disable: Button = %ButtonDisable
@onready var _button_enable: Button = %ButtonEnable


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	value_changed.emit(current_value)


func _on_button_enable_toggled(button_pressed: bool) -> void:
	_update_reset_visibility(button_pressed != reset_value)
	value_changed.emit(button_pressed)


func _on_button_disable_toggled(button_pressed: bool) -> void:
	_update_reset_visibility(button_pressed == reset_value)
	value_changed.emit(not button_pressed)

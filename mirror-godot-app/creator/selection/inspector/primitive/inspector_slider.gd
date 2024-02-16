@tool
extends "inspector_property_base.gd"

const _DISABLED_LABEL_COLOR_DARKENED = 0.2

signal value_changed(new_value: float)

# export_exp_easing allows to put values below 0.001 in inspector
@export_exp_easing var reset_value: float = 0.0
@export_exp_easing var current_value: float = 0.0

@export var unit_suffix: String = ""
@export_exp_easing var min_value: float = 0.0
@export_exp_easing var max_value: float = 1.0
@export_exp_easing var step: float = 0.01
@export var exp_edit: bool = false
@export var allow_greater: bool = false
@export var allow_lesser: bool = false
@export var enabled: bool = true:
	set = set_enabled
@export var units_multiplier: float = 1.0

@onready var _slider_node: HSlider = $SliderHolder/Slider
@onready var _value = $SliderHolder/Value


func _ready():
	super()
	refresh_full()


func refresh_full():
	_slider_node.step = step
	_slider_node.exp_edit = exp_edit
	_slider_node.min_value = min_value
	_slider_node.max_value = max_value
	refresh()


func _get_display_value():
	var value = current_value * units_multiplier
	return  "%d%s" % [value, unit_suffix]


func refresh():
	_slider_node.value = current_value
	_value.text = _get_display_value()
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))


func cleanup_and_delete() -> void:
	queue_free()


func _on_slider_value_changed(new_value: float):
	if is_equal_approx(current_value, new_value):
		return
	current_value = new_value
	_value.text = _get_display_value()
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))
	value_changed.emit(new_value)


func set_enabled(in_is_enabled: bool):
	enabled = in_is_enabled
	_slider_node.editable = enabled
	var new_label_color = label_color if enabled else label_color.darkened(_DISABLED_LABEL_COLOR_DARKENED)
	_label_node.add_theme_color_override(&"font_color", new_label_color)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	refresh()
	value_changed.emit(current_value)

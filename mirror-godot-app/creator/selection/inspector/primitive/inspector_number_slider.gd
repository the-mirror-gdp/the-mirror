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

@onready var _spin_box_node: SpinBox = $Content/SpinBoxHolder/SpinBox
@onready var _slider_node: HSlider = $Content/SliderHolder/Slider
@onready var _line_edit_node: LineEdit = _spin_box_node.get_line_edit()


func _ready():
	super()
	_line_edit_node.focus_entered.connect(_on_focus_entered)
	_line_edit_node.focus_exited.connect(_on_focus_exited)
	_line_edit_node.text_submitted.connect(emit_value_submitted)
	refresh_full()


func refresh_full():
	_spin_box_node.allow_greater = allow_greater
	_spin_box_node.allow_lesser = allow_lesser
	_spin_box_node.suffix = unit_suffix
	_spin_box_node.step = step
	_spin_box_node.min_value = min_value
	_spin_box_node.max_value = max_value
	if step == int(step):
		_spin_box_node.remove_theme_icon_override(&"updown")
	_slider_node.step = step
	_slider_node.exp_edit = exp_edit
	_slider_node.min_value = min_value
	_slider_node.max_value = max_value
	refresh()


func refresh():
	if get_viewport() and get_viewport().gui_get_focus_owner() == _line_edit_node:
		return
	_spin_box_node.value = current_value
	_slider_node.value = current_value
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))


func cleanup_and_delete() -> void:
	_spin_box_node.free()
	queue_free()


func _on_spin_box_value_changed(new_value: float):
	if is_equal_approx(current_value, new_value):
		return
	current_value = new_value
	_slider_node.value = current_value
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))
	value_changed.emit(new_value)


func _on_slider_value_changed(new_value: float):
	if is_equal_approx(current_value, new_value):
		return
	current_value = new_value
	_spin_box_node.value = current_value
	_update_reset_visibility(not is_equal_approx(current_value, reset_value))
	value_changed.emit(new_value)


func set_enabled(in_is_enabled: bool):
	enabled = in_is_enabled
	_spin_box_node.editable = enabled
	_slider_node.editable = enabled
	var new_label_color = label_color if enabled else label_color.darkened(_DISABLED_LABEL_COLOR_DARKENED)
	_label_node.add_theme_color_override(&"font_color", new_label_color)


func _on_focus_entered():
	GameUI.grab_input_lock(self)


func _on_focus_exited():
	refresh()
	GameUI.release_input_lock(self)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	refresh()
	value_changed.emit(current_value)

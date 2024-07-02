@tool
extends "inspector_submittable_base.gd"


signal value_changed(new_value: float)
signal value_preview(new_value: float)

@export var label_text: String = "E"
@export var label_color := Color.WHITE
@export var unit_suffix: String = ""
@export var current_value: float = 0.0
@export var step: float = 0.001

@onready var _label_node: Label = $LabelHolder/Label
@onready var _spin_box_node: SpinBox = $SpinBoxHolder/SpinBox
@onready var _line_edit_node: LineEdit = _spin_box_node.get_line_edit()
@export var enabled: bool = true:
	set(value):
		if is_instance_valid(_spin_box_node):
			enabled = value
			_spin_box_node.editable = enabled

var _grabbing_spinner_attempt := false
var _grabbing_spinner_dist_cache := 0.0
var _pre_grab_value  := 0.0
var _grabbing_spinner := false
var _grabbing_spinner_mouse_pos := Vector2.ZERO


func _ready() -> void:
	_label_node.text = label_text
	_label_node.add_theme_color_override(&"font_color", label_color)
	_line_edit_node.text_changed.connect(_on_spin_box_text_changed)
	_line_edit_node.focus_exited.connect(_on_focus_exited)
	_line_edit_node.gui_input.connect(_on_gui_input)
	_line_edit_node.text_submitted.connect(emit_value_submitted)
	refresh_full()


func refresh_full() -> void:
	_spin_box_node.suffix = unit_suffix
	_spin_box_node.step = step
	_spin_box_node.value = current_value
	_spin_box_node.apply()
	if step == int(step):
		_spin_box_node.remove_theme_icon_override(&"updown")


func refresh() -> void:
	if get_viewport() and get_viewport().gui_get_focus_owner() == _line_edit_node:
		return
	if not is_equal_approx(_spin_box_node.value, current_value):
		_spin_box_node.value = current_value


func cleanup_and_delete() -> void:
	if is_instance_valid(_spin_box_node):
		_spin_box_node.free()
	queue_free()


## Listening to value changed allows us to detect if the value was changed
## when exiting focus of the widget and not just on-confirm-pressed.
func _on_spin_box_value_changed(val: float) -> void:
	current_value = val
	# even though CONNECT_ONE_SHOT has been used, this will fire twice unless disconnected.
	if _spin_box_node.value_changed.is_connected(_on_spin_box_value_changed):
		_spin_box_node.value_changed.disconnect(_on_spin_box_value_changed)
	value_changed.emit(current_value)


func _on_spin_box_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		current_value = new_text.to_float()
		value_changed.emit(current_value)


func _on_key_focus_entered() -> void:
	if not _spin_box_node.value_changed.is_connected(_on_spin_box_value_changed):
		_spin_box_node.value_changed.connect(_on_spin_box_value_changed, CONNECT_ONE_SHOT)
	GameUI.instance.grab_input_lock(self)
	await get_tree().process_frame
	_line_edit_node.select_all()


func _on_focus_exited():
	refresh_full()
	GameUI.instance.release_input_lock(self)


func _on_gui_input(event: InputEvent):
	# Based on Godot C++ sources
	if not _spin_box_node.editable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_grabbing_spinner_attempt = true
			_grabbing_spinner_dist_cache = 0
			_pre_grab_value = _spin_box_node.value
			_grabbing_spinner = false
			_grabbing_spinner_mouse_pos = get_viewport().get_mouse_position() * \
					get_viewport().content_scale_factor
		else:
			if _grabbing_spinner_attempt:
				if _grabbing_spinner:
					GameUI.instance.creator_ui.ui_request_captured = false
					# This is needed to avoid process frame issues race conditions
					# free_camera.gd will try to handle CAPTURED before input
					# handlin of mouse_capture.gd
					Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
					Input.warp_mouse(_grabbing_spinner_mouse_pos)
					_on_spin_box_value_changed(_spin_box_node.value)
					_line_edit_node.release_focus()
				else:
					_line_edit_node.grab_focus()
					_on_key_focus_entered()
				_grabbing_spinner = false
				_grabbing_spinner_attempt = false
	elif event is InputEventMouseMotion:
		accept_event()
		if _grabbing_spinner_attempt:
			var diff_x = event.relative.x
			if event.shift_pressed:
				diff_x *= 0.1
			_grabbing_spinner_dist_cache += diff_x
			if not _grabbing_spinner and absf(_grabbing_spinner_dist_cache) > 4 * GameplaySettings.ui_scale:
				GameUI.instance.creator_ui.ui_request_captured = true
				_grabbing_spinner = true
			if _grabbing_spinner:
				# Don't make the user scroll all the way back to 'in range' if they went off the end.
				if _pre_grab_value < _spin_box_node.get_min() and not _spin_box_node.allow_lesser:
					_pre_grab_value = _spin_box_node.get_min()
				if _pre_grab_value > _spin_box_node.get_max() and not _spin_box_node.allow_greater:
					_pre_grab_value = _spin_box_node.get_max()
				if event.is_command_or_control_pressed():
					# If control was just pressed, don't make the value do a huge jump in magnitude.
					if _grabbing_spinner_dist_cache != 0:
						_pre_grab_value += _grabbing_spinner_dist_cache * _spin_box_node.get_step()
						_grabbing_spinner_dist_cache  = 0
					_spin_box_node.value = roundf(_pre_grab_value + _spin_box_node.get_step() * _grabbing_spinner_dist_cache * 10)
				else:
					_spin_box_node.value = _pre_grab_value + _spin_box_node.get_step() * _grabbing_spinner_dist_cache
				value_preview.emit(_spin_box_node.value)
	elif event is InputEventMouseButton and event.pressed and _line_edit_node.has_focus():
		var value_change := 0.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			value_change = _spin_box_node.get_step()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			value_change = -_spin_box_node.get_step()
		else:
			return
		if not event.shift_pressed:
			value_change *= 10.0
		if event.is_command_or_control_pressed():
			value_change *= 10.0
		_spin_box_node.value += value_change
		_on_spin_box_text_changed(_line_edit_node.text)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_line_edit_node.release_focus()

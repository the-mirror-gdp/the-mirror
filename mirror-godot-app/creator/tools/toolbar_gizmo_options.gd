extends Control


signal gizmo_button_pressed(gizmo_part: int)
signal snap_check_pressed(is_checked: bool)
signal relative_check_pressed(is_checked: bool)
signal snap_value_changed(amount: float)

@export var _grab_button: Button
@export var _move_button: Button
@export var _rotate_button: Button
@export var _scale_button: Button
@export var _relative_checkbox: CheckBox
@export var _snap_checkbox: CheckBox
@export var _snap_amount: SpinBox

var _gizmo_type: Enums.GIZMO_TYPE


func _ready() -> void:
	if _snap_amount:
		_snap_amount.get_line_edit().text_changed.connect(_on_snap_amount_value_changed)
		_snap_amount.get_line_edit().focus_entered.connect(_on_snap_amount_focus_entered)
		_snap_amount.get_line_edit().focus_exited.connect(_on_snap_amount_focus_exited)


func set_gizmo_type(new_type: int, snap_step: float = _snap_amount.value) -> void:
	match new_type:
		Enums.GIZMO_TYPE.GRAB:
			_grab_button.button_pressed = true
		Enums.GIZMO_TYPE.MOVE:
			_move_button.button_pressed = true
		Enums.GIZMO_TYPE.ROTATE:
			_rotate_button.button_pressed = true
		Enums.GIZMO_TYPE.SCALE:
			_scale_button.button_pressed = true
	if _gizmo_type == new_type or not _snap_amount:
		return
	_gizmo_type = new_type as Enums.GIZMO_TYPE
	match new_type:
		Enums.GIZMO_TYPE.GRAB:
			_snap_amount.suffix = "m"
		Enums.GIZMO_TYPE.MOVE:
			_snap_amount.suffix = "m"
		Enums.GIZMO_TYPE.ROTATE:
			_snap_amount.suffix = "°"
			snap_step = rad_to_deg(snap_step)
		Enums.GIZMO_TYPE.SCALE:
			_snap_amount.suffix = "%"
			snap_step = snap_step * 100
	if not is_equal_approx(_snap_amount.value, snap_step):
		_snap_amount.value = snap_step


func set_gizmo_relative(new_relative: bool) -> void:
	if _relative_checkbox:
		_relative_checkbox.button_pressed = new_relative


func set_gizmo_snap_checked(is_snap_checked: bool) -> void:
	if _snap_checkbox:
		_snap_checkbox.button_pressed = is_snap_checked


func set_buttons_as_not_pressed() -> void:
	_grab_button.button_pressed = false
	_move_button.button_pressed = false
	_rotate_button.button_pressed = false
	_scale_button.button_pressed = false


func _on_relative_check_box_toggled(button_pressed) -> void:
	relative_check_pressed.emit(button_pressed)


func _on_snap_check_box_toggled(button_pressed) -> void:
	snap_check_pressed.emit(button_pressed)


func _on_snap_amount_value_changed(string_value: String) -> void:
	var value: float = clamp(string_value.to_float(), _snap_amount.min_value, _snap_amount.max_value)
	match PlayerData.currently_selected_tool:
		Enums.GIZMO_TYPE.ROTATE:
			value = deg_to_rad(value)
		Enums.GIZMO_TYPE.SCALE:
			value /= 100
	# We need to wait 2 frames for Godot to update the SpinBox's value. :(
	await get_tree().process_frame
	await get_tree().process_frame
	snap_value_changed.emit(value)


func _on_grab_button_pressed() -> void:
	gizmo_button_pressed.emit(Enums.GIZMO_TYPE.GRAB)


func _on_move_button_pressed() -> void:
	gizmo_button_pressed.emit(Enums.GIZMO_TYPE.MOVE)


func _on_rotate_button_pressed() -> void:
	gizmo_button_pressed.emit(Enums.GIZMO_TYPE.ROTATE)


func _on_scale_button_pressed() -> void:
	gizmo_button_pressed.emit(Enums.GIZMO_TYPE.SCALE)


func _on_snap_amount_focus_entered():
	GameUI.instance.grab_input_lock(self)


func _on_snap_amount_focus_exited():
	GameUI.instance.release_input_lock(self)

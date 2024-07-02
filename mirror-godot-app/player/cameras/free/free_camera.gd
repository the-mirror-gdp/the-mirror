extends CameraHolder


signal scroll_speed_changed(value)

enum CAMERA_MODE { FREE_MOVEMENT = 0, FOCUS_ON_POINT }

const _15TH_ROOT_OF_10 = 1.16591440117983174 # this^15 is 10, and this^-15 is 0.1.

@export var _slow_speed_modifier: float = 0.5
@export var _fast_speed_modifier: float = 4.0
@export var _stationary_zoom_amount: float = 2.0

@export var _movement_speed_level: int = 20
var _free_movement_speed: float = 15.0

var _focus_point: Vector3
var _camera_mode = CAMERA_MODE.FREE_MOVEMENT


func enter(target_transform: Transform3D) -> void:
	global_transform = target_transform
	clear_focus_point()
	super(target_transform)


func change_focus_point(new_focus_point: Vector3):
	if _camera_mode == CAMERA_MODE.FOCUS_ON_POINT:
		if new_focus_point == _focus_point:
			return
	else:
		_camera_mode = CAMERA_MODE.FOCUS_ON_POINT
	_focus_point = new_focus_point
	_camera.change_focus_point(new_focus_point)


func change_focus_point_zoom(new_zoom: float):
	if _camera_mode != CAMERA_MODE.FOCUS_ON_POINT:
		return
	_camera.target_zoom = new_zoom


func clear_focus_point():
	if _camera_mode == CAMERA_MODE.FREE_MOVEMENT:
		return
	_camera_mode = CAMERA_MODE.FREE_MOVEMENT
	global_transform.origin = _camera.global_transform.origin
	_camera.position.z = 0.0


func handle_asset_placement_input(input_event: InputEvent):
	super.handle_asset_placement_input(input_event)
	if _camera_mode == CAMERA_MODE.FOCUS_ON_POINT:
		if Input.is_action_just_pressed(&"build_mode_camera_clear_focus"):
			clear_focus_point()
			get_viewport().set_input_as_handled()
		elif input_event is InputEventMouseMotion:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				if Input.is_action_pressed(&"build_mode_camera_orbit"):
					_process_rotation(input_event.relative)
					get_viewport().set_input_as_handled()
	elif _camera_mode == CAMERA_MODE.FREE_MOVEMENT:
		if input_event is InputEventMouseMotion:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				_process_rotation(input_event.relative)
				get_viewport().set_input_as_handled()
		if input_event is InputEventMouseButton:
				_process_mouse_scroll(input_event)


func update(delta):
	super.update(delta)
	if _camera_mode == CAMERA_MODE.FOCUS_ON_POINT:
		var lerp_strength = clamp(delta * _camera.CAMERA_ZOOM_SPEED, 0.0, 1.0)
		global_transform.origin = global_transform.origin.lerp(_focus_point, lerp_strength)
	if _camera_mode == CAMERA_MODE.FREE_MOVEMENT:
		process_movement(delta)


func process_movement(delta):
	if GameUI.instance.is_keyboard_needed_for_ui() or (not Input.is_action_pressed(&"build_mode_camera_orbit") and not GameUI.instance.is_cinematic_mode_enabled()):
		return
	var desired_movement_speed = _free_movement_speed
	if Input.is_action_pressed(&"player_sprint"):
		desired_movement_speed *= _fast_speed_modifier
	if Input.is_action_pressed(&"player_crouch"):
		desired_movement_speed *= _slow_speed_modifier
	var horizontal_movement: Vector2 = Input.get_vector(&"player_move_left", \
		&"player_move_right", &"player_move_forward", &"player_move_back")
	var vertical_movement = Input.get_axis(&"player_move_down", &"player_move_up")
	vertical_movement += Input.get_axis(&"build_mode_camera_down", &"build_mode_camera_up")
	vertical_movement = clamp(vertical_movement, -1.0, 1.0)
	var movement: Vector3 = Vector3(horizontal_movement.x, vertical_movement, horizontal_movement.y)
	position += _camera.global_transform.basis.get_rotation_quaternion() * \
		movement * desired_movement_speed * delta


func _process_rotation(mouse_input: Vector2) -> void:
	clamped_camera_rotation(Vector2(mouse_input.y, mouse_input.x) *
			GameplaySettings.camera_mouse_sensitivity)


func _process_mouse_scroll(input_event: InputEvent) -> void:
	if not input_event.is_pressed():
		return
	if input_event.is_action_pressed(&"build_mode_camera_zoom_in"):
		_adjust_scroll_speed(true)
		_add_stationary_zoom(-_stationary_zoom_amount)
	elif input_event.is_action_pressed(&"build_mode_camera_zoom_out"):
		_adjust_scroll_speed(false)
		_add_stationary_zoom(_stationary_zoom_amount)


func _adjust_scroll_speed(zoom_in: bool) -> void:
	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		return
	_movement_speed_level += 1 if zoom_in else -1
	# Use the 15th root of 10 since it's similar to what Godot uses,
	# and therefore use multiples of 15 for the clamp bounds.
	_movement_speed_level = clampi(_movement_speed_level, -30, 60)
	_free_movement_speed = pow(_15TH_ROOT_OF_10, _movement_speed_level)
	scroll_speed_changed.emit(_free_movement_speed)


func _add_stationary_zoom(value: float) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or not GameUI.instance.drag_detector.hovering_game_view:
		return
	position += transform.basis.z * value

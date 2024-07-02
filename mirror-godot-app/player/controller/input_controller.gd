# class_name InputController
extends Node


## User-exposed boolean for enabling or disabling player input.
var is_player_input_allowed: bool = true
## Internal state to keep track of the game mode and app focus.
var does_game_mode_accept_input: bool = false

var _mouse_position := Vector2.ZERO
var _look_axis := Vector2.ZERO

var _joy_h_sensitivity: float = 0.06
var _joy_v_sensitivity: float = 0.05
var _can_jump: bool = true
var _can_interact: bool = true


func _input(event: InputEvent) -> void:
	if not is_avatar_input_enabled():
		return
	if event is InputEventMouseMotion:
		_mouse_position = event.relative


func _process(delta: float) -> void:
	if not is_avatar_input_enabled():
		return
	# Mouse Look
	_look_axis.x = _mouse_position.y * GameplaySettings.camera_mouse_sensitivity
	_look_axis.y = _mouse_position.x * GameplaySettings.camera_mouse_sensitivity
	_mouse_position = Vector2.ZERO
	# Controller Look
	_look_axis.x += _joy_v_sensitivity * Input.get_axis(&"player_look_up", &"player_look_down")
	_look_axis.y += _joy_h_sensitivity * Input.get_axis(&"player_look_left", &"player_look_right")


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		if GameUI.instance.creator_ui.is_game_mode(GameMode.Mode.NORMAL) or Zone.is_in_play_mode():
			does_game_mode_accept_input = true
	elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		does_game_mode_accept_input = false


func is_avatar_input_enabled() -> bool:
	if GameUI.instance.is_keyboard_needed_for_ui() or GameUI.instance.is_mouse_needed_for_ui():
		return false
	return is_player_input_allowed and does_game_mode_accept_input


func get_intended_movement_direction() -> Vector3:
	if not is_avatar_input_enabled():
		return Vector3.ZERO
	var _move_axis = Vector3.ZERO
	if Input.is_action_pressed(&"player_move_forward"):
		_move_axis += Vector3.FORWARD
	if Input.is_action_pressed(&"player_move_back"):
		_move_axis += Vector3.BACK
	if Input.is_action_pressed(&"player_move_left"):
		_move_axis += Vector3.LEFT
	if Input.is_action_pressed(&"player_move_right"):
		_move_axis += Vector3.RIGHT
	return _move_axis


func get_intended_camera_rotation_change() -> Vector2:
	if not is_avatar_input_enabled():
		return Vector2.ZERO
	return _look_axis


func is_intent_to_jump() -> bool:
	if not is_avatar_input_enabled():
		return false
	if Input.is_action_pressed(&"player_jump"):
		if _can_jump:
			# Make sure the character can't jump untit it releases the jump button
			_can_jump = false
			return true
		else:
			return false
	else:
		_can_jump = true
		return false


func is_intent_to_run() -> bool:
	if not is_avatar_input_enabled():
		return false
	return Input.is_action_pressed(&"player_sprint")


func is_intent_to_interact() -> bool:
	if not is_avatar_input_enabled():
		return false
	if Input.is_action_pressed(&"player_interact"):
		if _can_interact:
			# Make sure the character can't interact untit it releases the interact button
			_can_interact = false
			return true
		else:
			return false
	else:
		_can_interact = true
		return false

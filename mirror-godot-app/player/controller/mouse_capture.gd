extends Node

var _last_mouse_position := Vector2.ZERO
var is_app_focused = true


func _ready() -> void:
	# if the application is the host, we should not process mouse capture.
	# in headless mode, this throws warnings every frame.
	disable()
	# Make the priority of process high, so other nodes have updated data
	process_priority = -1


func enable() -> void:
	set_process(true)


func disable() -> void:
	set_process(false)


func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_IN:
			is_app_focused = true
		NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# the game window just lost focus from the operating system
			is_app_focused = false


func _process(_delta: float) -> void:
	var mouse_captured_last_frame = (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
	var mouse_captured = is_capturing()
	var mouse_mode = (
			Input.MOUSE_MODE_CAPTURED
			if mouse_captured and is_app_focused
			else Input.MOUSE_MODE_VISIBLE
	)
	if not mouse_captured_last_frame and mouse_captured:
		_last_mouse_position = get_viewport().get_mouse_position() * \
			get_viewport().content_scale_factor
	Input.set_mouse_mode(mouse_mode)
	if mouse_captured_last_frame and not mouse_captured:
		Input.warp_mouse(_last_mouse_position)


func is_capturing() -> bool:
	return not GameUI.is_mouse_needed_for_ui()

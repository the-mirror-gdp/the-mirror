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
	var was_mouse_captured_last_frame: bool = (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)
	var is_mouse_needed_by_ui: bool = GameUI.instance.is_mouse_needed_for_ui()
	var new_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
	if not is_mouse_needed_by_ui:
		if is_app_focused:
			new_mouse_mode = Input.MOUSE_MODE_CAPTURED
		if not was_mouse_captured_last_frame:
			var window: Window = get_viewport()
			_last_mouse_position = window.get_mouse_position() * window.content_scale_factor
	Input.set_mouse_mode(new_mouse_mode)
	if was_mouse_captured_last_frame and is_mouse_needed_by_ui:
		Input.warp_mouse(_last_mouse_position)

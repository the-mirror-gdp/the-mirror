extends CanvasLayer


@onready var _camera_shutter_sound: AudioStreamPlayer = %CameraShutterSound
@onready var _screenshot_path_label: Label = %ScreenshotPathLabel

var _game_ui: Node = null


func setup(game_ui: Node) -> void:
	_game_ui = game_ui
	set_process(true)


func _ready() -> void:
	_screenshot_path_label.text = "Saves to: %s" % [Util.get_screenshots_directory_path()]
	set_process(false)


func _process(delta) -> void:
	if Input.is_action_just_pressed(&"cinematic_mode_toggle"):
		toggle_cinematic_mode()
	if Input.is_action_just_pressed(&"primary_action"):
		take_screenshot()


func toggle_cinematic_mode() -> void:
	if _game_ui.is_any_full_screen_or_modal_ui_visible() or get_viewport().gui_get_focus_owner():
		return
	set_visible(not visible)
	_game_ui.set_visible(not visible)
	if visible and _game_ui.creator_ui:
		_game_ui.creator_ui.object_selection.clear_selection()


func disable_cinematic_mode() -> void:
	set_visible(false)
	_game_ui.set_visible(true)


func take_screenshot() -> void:
	if not visible:
		return
	set_visible(false)
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	Util.save_screenshot(image)
	_camera_shutter_sound.play()
	set_visible(true)

extends CanvasLayer


@onready var drag_detector = $DragDetector
@onready var notifications_ui: NotificationsUI = $NotificationsUI
@onready var chat_ui: Chat = $ChatUI
@onready var hotbar: Control = $Hotbar
@onready var creator_ui: CreatorUI = $CreatorUI
@onready var loading_ui: LoadingUI = $LoadingUI
@onready var main_menu_ui: MainMenuUI = $MainMenuUI
@onready var login_ui: LoginUI = $LoginUI
@onready var fps_label: Label = $FPSLabel
@onready var menu_ambience: AudioStreamPlayer = $MenuAmbience
@onready var object_outlines: Node = $ObjectOutlines
@onready var floating_text: Node = $FloatingText
@onready var user_tutorial: UserTutorial = $UserTutorial
@onready var cinematic_mode: CanvasLayer = $CinematicMode
@onready var teams_handler: TeamsWindowContainer = $TeamHandler
@onready var scoreboard_window: Control = $ScoreboardWindow
@onready var health_display: HealthDisplay = $HealthDisplay
@onready var crosshair: Control = $Crosshair
@onready var file_search: FileDialog = $FileSearch
@onready var _global_menu: Node = $GlobalMenu
@onready var _hover_text = $HoverText

var ui_node_grabbing_input = null

var should_display_space_listings = ProjectSettings.get_setting("feature_flags/enable_space_listing_pages", false)

var visible_windows: Dictionary = {}

var _is_configured = false
signal ready_called

func wait_till_ready():
	if _is_configured:
		return
	await ready_called


func _ready() -> void:
	assert(teams_handler)
	main_menu_ui.setup(self)
	creator_ui.setup(drag_detector)
	hotbar.setup(creator_ui)
	cinematic_mode.setup(self)
	_is_configured = true
	ready_called.emit()


func _process(_delta) -> void:
	if not Zone.is_client():
		return
	if Input.is_action_just_pressed("open_main_menu"):
		if ProjectSettings.get_setting("feature_flags/escape_directly_closes_app", false):
		# I checked and the process kill is okay to do as the OS will clean up allocated blocks from the malloc/new.
		# Any kind of leak checker will see this as a memory leak
		# UBSAN/ASAN - Debugging tools won't work with this specific exit case.
		# It can trigger UBSAN on clang so its worth pointing out this will trigger it.
			OS.kill(OS.get_process_id())
	# # For visual debugging and demonstrations
	# Cursors.set_cursor( Cursors.NOT_ALLOWED
	# 		if self.is_mouse_hovering_any_control()\
	# 		# or self.is_mouse_hovering_any_window()
	# 		else Cursors.ASSET_MOVE
	# )
	if Input.is_action_just_pressed(&"ui_fullscreen_toggle"):
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func can_toggle_main_menu() -> bool:
	if (
			login_ui.visible
			or loading_ui.visible
			or user_tutorial.window.visible
	):
		return false
	if teams_handler.visible:
		return false

	if main_menu_ui.visible:
		return true

	if (
			creator_ui
			and creator_ui.visible
			and not creator_ui.can_toggle_main_menu()
	):
		return false
	return true


# In some cases you might want to contextually ignore if something is visible already
# i.e. the build menu should be able to let you chat
# but the team window should not let you chat unless closed.
func is_any_full_screen_or_modal_ui_visible(ignored_contexts: Array = []) -> bool:
	if scoreboard_window.requires_mouse_for_ui():
		return true
	var visible_properties = {}
	# We could make this register from the actual UI elements themselves
	# for now I just made this a static list so you can see the data and types
	# clearly.
	# the key is the object
	# the value is the property to read for the value of "visible" etc.
	if main_menu_ui:
		visible_properties[main_menu_ui] = "visible"
	visible_properties[loading_ui] = "visible"
	visible_properties[login_ui] = "visible"
	visible_properties[user_tutorial.window] =  "visible"
	visible_properties[chat_ui] = "is_typing_in_chat"
	visible_properties[teams_handler] = "visible"
	visible_properties[creator_ui.asset_detail_window] = "visible"

	var or_value = false
	for ui_element in visible_properties.keys():
		if ignored_contexts.has(ui_element):
			continue
		var str = visible_properties[ui_element]
		# key is being used to find a godot property
		var value: bool = ui_element[str]
		or_value = or_value or value
	return or_value


func is_mouse_needed_for_ui() -> bool:
	var state = is_any_full_screen_or_modal_ui_visible() \
		or creator_ui.is_mouse_needed_for_ui()
	GameUI.set_vr_mouse_state(state)
	return state


func is_keyboard_needed_for_ui() -> bool:
	return (
		is_any_full_screen_or_modal_ui_visible()
		or _is_input_grabbed_by_ui_node()
	)


func _is_input_grabbed_by_ui_node():
	if ui_node_grabbing_input == null:
		# We return early, when we don't need to fetch the node
		return false
	var is_grabbed_by_valid_node = (
		is_instance_valid(ui_node_grabbing_input)
		and get_viewport().gui_get_focus_owner() == ui_node_grabbing_input
		and ui_node_grabbing_input.is_visible_in_tree()
	)
	if not is_grabbed_by_valid_node:
		ui_node_grabbing_input = null
	return is_grabbed_by_valid_node


func grab_input_lock(ui_node) -> void:
	ui_node_grabbing_input = ui_node


func release_input_lock(ui_node) -> void:
	ui_node_grabbing_input = null


func on_enter_space(is_creator: bool) -> void:
	if main_menu_ui:
		main_menu_ui.hide()
	chat_ui.clear_chat()
	chat_ui.show()
	hotbar.show()
	health_display.try_show()
	if is_instance_valid(_global_menu):
		_global_menu.on_enter_space()
	if is_creator:
		drag_detector.show()
		creator_ui.show()
	else:
		# If a user loses connection to the server while working on a block
		# model, we want to keep that model in memory, so that they can
		# reconnect and avoid losing work. However, we want to get rid of
		# the model if the user joins a space without creator permissions.
		creator_ui.block_manager.clear_children()


func on_exit_space() -> void:
	if not login_ui.visible and not loading_ui.visible:
		main_menu_ui.show()

	health_display.try_hide()
	drag_detector.hide()
	chat_ui.hide()
	hotbar.hide()
	teams_handler.hide()
	creator_ui.hide()
	creator_ui.clear()
	cinematic_mode.disable_cinematic_mode()
	menu_ambience.check_update_stream()
	file_search.hide()
	if is_instance_valid(_global_menu):
		_global_menu.on_exit_space()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func logout() -> void:
	drag_detector.hide()
	chat_ui.hide()
	creator_ui.hide()
	loading_ui.hide()
	main_menu_ui.hide()
	login_ui.show()
	teams_handler.hide()


## NOTE: If you are calling this from _input(), not is _unhandled_input(),
## you might want to also call is_mouse_hovering_any_window()
func is_mouse_hovering_any_control() -> bool:
	# TODO: When we have gamepad support
	# if using_gamepad:
	# 	return false
	return is_any_full_screen_or_modal_ui_visible()\
			or not get_safe_area().has_point(get_viewport().get_mouse_position())\
			or is_hovering_any_notification()
	# TODO with upload, variables, scripting_panel, etc


func is_hovering_any_notification() -> bool:
	return notifications_ui.is_hovering_any_notification()


func add_visible_window(ui_element) -> void:
	visible_windows[ui_element.get_path()] = ui_element


func remove_visible_window(ui_element) -> void:
	visible_windows.erase(ui_element.get_path())


func set_hover_tooltip_text(primary_text: String, secondary_text: String = "") -> void:
	_hover_text.show()
	_hover_text.set_text(primary_text, secondary_text)


func hide_hover_tooltip_text() -> void:
	_hover_text.hide()


func is_cinematic_mode_enabled() -> bool:
	return cinematic_mode.visible


## Should often be used with is_mouse_hovering_any_control()
## For when we are using _input instead of _unhandled_input
##  Because window is acting like a modal and handling all input until closed
func is_mouse_hovering_any_window() -> bool:
	return visible_windows.values().any(func (window):
		return window.get_visible_rect().has_point(window.get_mouse_position())
	)


func get_safe_area() -> Rect2:
	if main_menu_ui and main_menu_ui.visible:
		return main_menu_ui.get_rect()
	if creator_ui and creator_ui.visible:
		return creator_ui.get_safe_area()
	return get_viewport().get_visible_rect()

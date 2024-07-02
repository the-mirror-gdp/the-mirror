extends Node


signal app_mode_updated(new_app_mode)

const VALID_MODES = ["MENU", "SPACE"]

var _current_app_mode: Dictionary = { mode = "MENU", sub_mode = "LOGIN" }:
	set(new_val):
		if VALID_MODES.has(new_val.mode):
			_current_app_mode = new_val
			app_mode_updated.emit(_current_app_mode)
		else:
			push_error("%s is not part of VALID_MODES: cannot set current_app_mode" % new_val.mode)
	get:
		return _current_app_mode


func _ready() -> void:
	await GameUI.ui_ready()
	Zone.client.join_server_start.connect(_on_joining_server)
	Zone.client.join_server_complete.connect(_on_server_joined)
	Zone.mode_changed.connect(_on_zone_mode_changed)
	if GameUI.instance.main_menu_ui:
		GameUI.instance.main_menu_ui.visibility_changed.connect(_on_main_menu_ui_visibility_changed)
		GameUI.instance.main_menu_ui.page_changed.connect(main_menu_ui_analytics_update_current_page)
	GameUI.instance.login_ui.visibility_changed.connect(_on_login_ui_visibility_changed)



func set_app_mode(mode: String, sub_mode: String) -> void:
	_current_app_mode = {
		mode = mode.to_upper(),
		sub_mode = sub_mode.to_upper()
	}


func change_app_mode_to_space_mode(new_mode: ZoneClass.ZONE_MODE) -> void:
	match new_mode:
		ZoneClass.ZONE_MODE.EDIT:
			set_app_mode("SPACE", "BUILD")
		ZoneClass.ZONE_MODE.PLAY:
			if Zone.is_play_zone():
				set_app_mode("SPACE", "PLAY")
			else:
				set_app_mode("SPACE", "PREVIEW")


func get_current_app_mode_as_string() -> String:
	return "%s_%s" % [_current_app_mode.mode, _current_app_mode.sub_mode]


func is_user_currently_connected_to_a_space() -> bool:
	return get_current_app_mode_as_string().begins_with("SPACE_")


func _on_joining_server() -> void:
	set_app_mode("SPACE", "LOADING")


func join_server_stop() -> void:
	main_menu_ui_analytics_update_current_page()


func main_menu_ui_analytics_update_current_page(page_name: String = GameUI.instance.main_menu_ui._current_page.name) -> void:
	set_app_mode("MENU", page_name.to_upper())


func _on_server_joined() -> void:
	if Zone.is_play_zone():
		set_app_mode("SPACE", "PLAY")
	else:
		set_app_mode("SPACE", "BUILD")


func _on_zone_mode_changed(new_mode: ZoneClass.ZONE_MODE) -> void:
	change_app_mode_to_space_mode(new_mode)


# This is so that when we open the main menu from being in a space:
# 1. It correctly says that we are in the main menu always,
#      not only when we automatically change page to Home
# 2. When we close it, it correctly puts us back in the correct SPACE_* AppMode
# TODO MAYBE: listen on a signal on GameUI.instance for when it switches which UI is on top/visible
#   Something like : GameUI.instance.main_ui_changed ====> "LOGIN", "MAIN_MENU", etc
func _on_main_menu_ui_visibility_changed() -> void:
	if GameUI.instance.main_menu_ui.visible:
		main_menu_ui_analytics_update_current_page()
	# If in a space: TODO, find a better check than UI visibility of player label container.
	elif GameUI.instance.chat_ui.visible:
		change_app_mode_to_space_mode(Zone.current_mode)


func _on_login_ui_visibility_changed() -> void:
	if GameUI.instance.login_ui.visible:
		set_app_mode("MENU", "LOGIN")

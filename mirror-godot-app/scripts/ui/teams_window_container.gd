extends Control
class_name TeamsWindowContainer

@onready var teams_window: TeamWindow = $TeamsWindow
@onready var play_mode_teams_window: TeamWindowPlayMode = $TeamsWindowPlayMode


func _ready():
	Zone.mode_changed.connect(zone_mode_changed)
	zone_mode_changed(Zone.current_mode)


func _is_teams_shortcut_enabled():
	var teams_shortcut_enabled = Zone.script_network_sync.get_global_variable("teams_shortcut_enabled")
	if teams_shortcut_enabled == null:
		Zone.script_network_sync.set_global_variable("teams_shortcut_enabled", true)
		return true
	return teams_shortcut_enabled


func _process(_delta) -> void:
	if not Zone.client or not Zone.client or not Zone.client.is_client_connected_to_server():
		return
	if Input.is_action_just_pressed(&"team_menu_toggle"):
		if GameUI.is_any_full_screen_or_modal_ui_visible([self]):
			return
		if get_viewport().gui_get_focus_owner() != null:
			return
		if not _is_teams_shortcut_enabled():
			hide()
			return
		toggle_teams_editor()
	if Input.is_action_just_pressed(&"ui_close"):
		hide()


func zone_mode_changed(mode: ZoneClass.ZONE_MODE) -> void:
	if Zone.is_host():
		return
	match mode:
		ZoneClass.ZONE_MODE.PLAY:
			play_mode_teams_window.visible = true
			teams_window.visible = false
			show()
		ZoneClass.ZONE_MODE.EDIT:
			play_mode_teams_window.visible = false
			teams_window.visible = true
			hide()


func toggle_teams_editor() -> void:
	if visible:
		hide()
	else:
		show()

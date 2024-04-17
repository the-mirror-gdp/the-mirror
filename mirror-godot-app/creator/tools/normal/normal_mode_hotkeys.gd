extends HBoxContainer


# Only show these during build mode.
@onready var ui_build_mode_only: Array[Control] = [
	$BuildMode as Control,
	$AssetBrowser as Control,
]


func _ready() -> void:
	if visible:
		push_error("Normal Mode Hotkeys should be hidden when the app starts.")
	Zone.mode_changed.connect(refresh_ui_new_mode)
	Zone.client.connected.connect(refresh_ui)
	Zone.client.disconnected.connect(hide)


func set_build_mode_ui_hint_state(state: bool) -> void:
	var scoreboard_shortcut_enabled: bool = GameUI.instance.scoreboard_window.is_scoreboard_shortcut_enabled()
	var team_shortcut_enabled: bool = GameUI.instance.teams_handler.is_teams_shortcut_enabled()
	var build_shortcuts_enabled: bool = ProjectSettings.get_setting("feature_flags/enable_build_shortcuts", true)
	$TeamSelection.visible = team_shortcut_enabled
	$Scoreboard.visible = scoreboard_shortcut_enabled
	$Chat.visible = true
	$CinematicMode.visible = true
	for ui_element in ui_build_mode_only:
		ui_element.visible = state and build_shortcuts_enabled


# duplicated because signal will never fire due to having an argument we must ignore.
func refresh_ui_new_mode(_new_zone_mode: int) -> void:
	refresh_ui()


func refresh_ui() -> void:
	show()
	if Zone.is_in_play_mode():
		set_build_mode_ui_hint_state(false)
	else:
		set_build_mode_ui_hint_state(true)

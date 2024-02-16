extends HBoxContainer


# Only show these during build mode.
@onready var ui_build_mode_only: Array[Control] = [
	$BuildMode as Control,
	$AssetBrowser as Control,
]


func _ready() -> void:
	assert(not visible, "Normal Mode Hotkeys should be hidden when the app starts.")
	Zone.mode_changed.connect(refresh_ui_new_mode)
	Zone.client.connected.connect(refresh_ui)
	Zone.client.disconnected.connect(hide)


func set_build_mode_ui_hint_state(state: bool) -> void:
	for ui_element in ui_build_mode_only:
		ui_element.visible = state


# duplicated because signal will never fire due to having an argument we must ignore.
func refresh_ui_new_mode(_new_zone_mode: int) -> void:
	refresh_ui()


func refresh_ui() -> void:
	show()
	if Zone.is_in_play_mode():
		set_build_mode_ui_hint_state(false)
	else:
		set_build_mode_ui_hint_state(true)

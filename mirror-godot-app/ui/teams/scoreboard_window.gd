extends Control


var _force_shown: bool = false

@onready var _window_header = $Control/body/window_header
@onready var _team_table: Table = $Control/body/table_container

@onready var _bottom_buttons = $Control/body/BottomButtons
@onready var _close = $Control/body/BottomButtons/Close
@onready var _new_match = $Control/body/BottomButtons/NewMatch


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Bottom buttons are hidden when _force_shown is false, which it is by default.
	# Do this in _ready() to allow the buttons to be visible in the editor.
	_bottom_buttons.visible = false
	# The data mapping
	# This is used to extract the properties and reset the input row
	# An example is provided with the correct columns for teams
	_team_table.default_data_mapping = {
		"player_name": {
			"mapping": "text"
		},
		"team_name": {
			"mapping": "text"
		},
		"team_color": {
			"mapping": "color"
		},
		"player_kills": {
			"mapping": "text"
		},
		"player_deaths": {
			"mapping": "text"
		},
		"player_score": {
			"mapping": "text"
		},
		"player_latency": {
			"mapping": "text"
		},
	}
# This lets you edit the scoreboard without opening the game so just enable this and comment out the refresh below.
#	team_table.add_row({
#		"id": 0,
#		"player_name": "Gordo",
#		"team_name": "RED",
#		"team_color": Color.RED,
#		"player_kills": "20",
#		"player_deaths": "100",
#		"player_score": "200",
#		"player_latency": "96 ms"
#	})
#	team_table.add_row({
#		"id": 1,
#		"player_name": "Jason - The Man Of Lego",
#		"team_name": "BLUE",
#		"team_color": Color.BLUE,
#		"player_kills": "100",
#		"player_score": "1000",
#		"player_deaths": "20",
#		"player_latency": "10 ms"
#	})


func is_scoreboard_shortcut_enabled():
	if not ProjectSettings.get_setting("feature_flags/enable_scoreboard_shortcut", true):
		return false
	var scoreboard_enabled = Zone.script_network_sync.get_global_variable("scoreboard_shortcut_enabled")
	if scoreboard_enabled == null:
		Zone.script_network_sync.set_global_variable("scoreboard_shortcut_enabled", true)
		return true
	return scoreboard_enabled


func _process(_delta: float) -> void:
	if Zone.is_host() or not Zone.client or not Zone.client.is_client_connected_to_server():
		visible = false
		return
	visible = _force_shown or (
		not GameUI.instance.is_keyboard_needed_for_ui()
		and Input.is_action_pressed(&"scoreboard_visible")
		and is_scoreboard_shortcut_enabled()
	)
	# we don't care about the actual data inside the player id's we're
	# just using it as a mechanism to know the players are different
	var players: Array = Zone.get_all_players()
	var valid_row_ids: Array = []
	for player in players:
		var profile = player.get_profile()
		var id = player.get_user_id().hash()
		_team_table.update_or_add_row({
			"id": id, # table id is int casted.. dayum
			"player_name": profile.get("displayName", "something went wrong"),
			"team_name": player.get_player_team(),
			"team_color": player.get_player_team_color(),
			"player_kills": str(player.data_store.get_value("kills", 0)),
			"player_score": str(player.data_store.get_value("points", 0)),
			"player_deaths": str(player.data_store.get_value("deaths", 0)),
			# If we ever give multiplayer authority to the server,
			#  but the player's client is still connected,
			#  We might need to use `player._peer_id` here instead
			"player_latency": Zone.get_readable_latency(player.get_multiplayer_authority()),
		})
		valid_row_ids.push_back(id)
	for row_id in _team_table.get_rows().duplicate():
		if valid_row_ids.has(row_id):
			continue
		_team_table.remove_row(row_id)


func requires_mouse_for_ui() -> bool:
	return _force_shown


func set_scoreboard_shown(is_force_shown: bool, is_close_allowed: bool, is_new_match_allowed: bool) -> void:
	# Server doesn't actually need to see the UI, but keep this bool synced for checking.
	_force_shown = is_force_shown
	set_scoreboard_shown_network.rpc(is_force_shown, is_close_allowed, is_new_match_allowed)


@rpc("call_remote", "authority", "reliable")
func set_scoreboard_shown_network(is_force_shown: bool, is_close_allowed: bool, is_new_match_allowed: bool) -> void:
	_force_shown = is_force_shown
	_bottom_buttons.visible = is_force_shown and (is_close_allowed or is_new_match_allowed)
	_close.visible = is_close_allowed
	_new_match.visible = is_new_match_allowed
	visible = is_force_shown


func set_scoreboard_title_text(new_text: String) -> void:
	set_scoreboard_title_text_network.rpc(new_text)


@rpc("call_remote", "authority", "reliable")
func set_scoreboard_title_text_network(new_text: String) -> void:
	_window_header.set_title_text(new_text)


func _on_close_pressed() -> void:
	_force_shown = false
	_bottom_buttons.visible = false
	visible = false


func _on_new_match_pressed() -> void:
	_new_match_client_to_server.rpc_id(Zone.SERVER_PEER_ID)
	_new_match_network() # Run locally so the user has instant feedback.


@rpc("call_remote", "any_peer", "reliable")
func _new_match_client_to_server() -> void:
	if not _force_shown:
		printerr("A client tried to start a new match at an invalid time.")
		return
	# Server doesn't actually need to see the UI, but keep this bool synced for checking.
	_force_shown = false
	Zone.match_system.start_match()
	_new_match_network.rpc()


@rpc("call_remote", "authority", "reliable")
func _new_match_network() -> void:
	_force_shown = false
	_bottom_buttons.hide()
	_window_header.set_title_text("Scoreboard")
	hide()


func _on_visibility_changed() -> void:
	if _force_shown and not visible:
		show()

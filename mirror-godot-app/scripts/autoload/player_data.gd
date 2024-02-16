extends Node


signal game_mode_changed(new_mode, previous_mode)

const USER_ID_UNKNOWN = StringName()

var currently_selected_tool: int = Enums.GIZMO_TYPE.GRAB

var _cached_local_user_id: StringName = USER_ID_UNKNOWN

var game_mode: GameMode


func _init():
	game_mode = GameMode.new()
	game_mode.game_mode_changed.connect(_on_game_mode_changed)
	add_child(game_mode)


func _ready():
	Zone.client.connected.connect(enter_normal_mode, CONNECT_DEFERRED)
	Zone.client.disconnected.connect(enter_normal_mode, CONNECT_DEFERRED)
	Zone.mode_changed.connect(_on_zone_mode_changed)


func _on_zone_mode_changed(mode: int) -> void:
	if mode == Zone.ZONE_MODE.EDIT:
		enter_normal_mode()


func enter_normal_mode():
	game_mode.set_game_mode(GameMode.Mode.NORMAL, true)


func acknowledge_local_user_id(in_local_user_id: StringName) -> void:
	# cannot be called on the server, all players are local from perspective of the server
	assert(not Zone.is_host())
	_cached_local_user_id = in_local_user_id


func has_local_user_id() -> bool:
	# cannot be called on the server, all players are local from perspective of the server
	assert(not Zone.is_host())
	return _cached_local_user_id != USER_ID_UNKNOWN


# It's ok to call it for logic which is not directly related to gameplay simulation (like ui),
# but logic related to gameplay simulation must be performed on the server!
# Will return id of local user, or USER_ID_UNKNOWN if user id is not set
func get_local_user_id() -> StringName:
	# cannot be called on the server, all players are local from perspective of the server
	assert(not Zone.is_host())
	return _cached_local_user_id


func _on_game_mode_changed(new_mode, previous_mode):
	game_mode_changed.emit(new_mode, previous_mode)


func get_local_player() -> Player:
	return Zone.get_player(get_local_user_id())


func has_local_player() -> bool:
	return Zone.has_player(get_local_user_id())

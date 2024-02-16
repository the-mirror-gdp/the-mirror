extends Sprite3D

var audio_input_active = false
var _player: Player


func setup(player: Player, is_local: bool) -> void:
	_player = player
	visible = false
	if Zone.is_host() or not is_local:
		return
	Util.safe_signal_connect(GameplayTools.audio_input_detector.audio_input_detection_state_changed, _audio_input_state_changed)


func _is_player_audio_indicator_enabled() -> bool:
	var audio_detector_enabled = Zone.script_network_sync.get_global_variable("audio_input_indicator_enabled")
	if audio_detector_enabled == null:
		Zone.script_network_sync.set_global_variable("audio_input_indicator_enabled", false)
		return false
	return audio_detector_enabled


func _audio_input_state_changed(state: bool) -> void:
	set_player_audio_detector_indicator(state)


func set_player_audio_detector_indicator(state: bool) -> void:
	if Zone.is_host():
		_set_player_audio_detector_indicator.rpc(state)
	else:
		_set_player_height_multiplier_client_to_server.rpc_id(Zone.SERVER_PEER_ID, state)


@rpc("any_peer", "call_local", "reliable")
func _set_player_height_multiplier_client_to_server(state: bool) -> void:
	audio_input_active = state
	_set_player_audio_detector_indicator.rpc(state)


@rpc("any_peer", "call_remote", "reliable")
func _set_player_audio_detector_indicator(state: bool) -> void:
	position = _player.model.get_eyes_position() + Vector3(0, 0.7, 0)
	audio_input_active = state


func _should_show_name() -> bool:
	var local_player: Player = PlayerData.get_local_player()
	if local_player == null:
		return false
	var eyes_pos: Vector3 = _player.get_global_eyes_position()
	var head_transform: Transform3D = local_player.get_head_global_transform()
	var distance_sq: float = eyes_pos.distance_squared_to(head_transform.origin)
	return distance_sq < 144 # 12^2


func _process(_delta):
	if Zone.is_host():
		return
	var audio_activity = _is_player_audio_indicator_enabled() and audio_input_active
	visible = audio_activity and _should_show_name() and not _player.is_local_player()

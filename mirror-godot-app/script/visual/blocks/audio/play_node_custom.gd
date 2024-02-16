extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var audio_player_node: Node = ScriptBlockAudio.get_audio_player_node(self)
	if audio_player_node == null:
		log_error.emit("Unable to find the AudioPlayer node.")
		return ERR_INVALID_PARAMETER
	if not audio_player_node is TMAudioPlayer3D:
		log_error.emit("This AudioPlayer node cannot be played with custom settings.")
		return ERR_INVALID_PARAMETER
	var loop_audio: bool = inputs[1].value
	var base_volume_percent: float = inputs[2].value
	var speed: float = inputs[3].value
	var speed_randomness: float = inputs[4].value
	var speed_limit: float = maxf(speed_randomness + 1.0, 0.01)
	speed *= randf_range(1.0 / speed_limit, speed_limit)
	var is_spatial: bool = inputs[5].value
	var spatial_range: float = inputs[6].value
	var spatial_max_volume_percent: float = inputs[7].value
	if Zone.is_host():
		# Server-side scripts should play audio on all clients.
		Zone.script_network_sync.server_play_audio_node_custom_settings_on_clients(audio_player_node, loop_audio, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)
	else:
		# Client-side scripts should only play audio locally.
		audio_player_node.loop_audio = loop_audio
		audio_player_node.base_volume_percentage = base_volume_percent
		audio_player_node.pitch_scale = speed
		audio_player_node.is_spatial = is_spatial
		audio_player_node.spatial_range = spatial_range
		audio_player_node.spatial_max_volume_percentage = spatial_max_volume_percent
		audio_player_node.play()
	return OK


func get_script_block_type() -> String:
	return "play_audio_node_custom"

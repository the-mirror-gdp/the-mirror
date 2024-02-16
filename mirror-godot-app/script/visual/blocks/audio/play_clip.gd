extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	if not attached_object is Node:
		log_error.emit("Unable to play an audio clip because no node was found.")
		return ERR_INVALID_DATA
	var audio_asset_id: String = inputs[0].value
	var base_volume_percent: float = inputs[1].value
	var speed: float = inputs[2].value
	var speed_randomness: float = inputs[3].value
	var speed_limit: float = maxf(speed_randomness + 1.0, 0.01)
	speed *= randf_range(1.0 / speed_limit, speed_limit)
	var is_spatial: bool = inputs[4].value
	var spatial_range: float = inputs[5].value
	var spatial_max_volume_percent: float = inputs[6].value
	if Zone.is_host():
		# Server-side scripts should play audio on all clients.
		Zone.script_network_sync.server_play_audio_clip_on_clients(attached_object, audio_asset_id, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)
	else:
		# Client-side scripts should only play audio locally.
		var audio_player := AudioClipAssetPlayer.new()
		attached_object.add_child(audio_player)
		audio_player.play_from_asset_id(audio_asset_id, base_volume_percent, speed, is_spatial, spatial_range, spatial_max_volume_percent)
	return OK


func get_script_block_type() -> String:
	return "play_audio_clip"

extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var audio_player_node: Node = ScriptBlockAudio.get_audio_player_node(self)
	if audio_player_node == null:
		log_error.emit("Unable to find the AudioPlayer node.")
		return ERR_INVALID_PARAMETER
	if Zone.is_host():
		# Server-side scripts should play audio on all clients.
		Zone.script_network_sync.server_play_audio_node_same_settings_on_clients(audio_player_node)
	else:
		# Client-side scripts should only play audio locally.
		audio_player_node.play()
	return OK


func get_script_block_type() -> String:
	return "play_audio_node_same"

extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var audio_player_node: Node = ScriptBlockAudio.get_audio_player_node(self)
	if audio_player_node == null:
		log_error.emit("Unable to find the AudioPlayer node.")
		return ERR_INVALID_PARAMETER
	if Zone.is_host():
		# Server-side scripts should stop audio on all clients.
		Zone.script_network_sync.server_stop_audio_node_on_clients(audio_player_node)
	else:
		# Client-side scripts should only stop audio locally.
		audio_player_node.stop()
	return OK


func get_script_block_type() -> String:
	return "stop_audio_node"

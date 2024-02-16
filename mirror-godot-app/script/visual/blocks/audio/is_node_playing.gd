extends ScriptBlockAudio


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var audio_player_node: Node = get_audio_player_node(self)
	if audio_player_node == null:
		log_error.emit("Unable to find the AudioPlayer node.")
		return
	outputs[0].value = audio_player_node.playing


func get_script_block_type() -> String:
	return "is_audio_node_playing"

extends ScriptBlockAnimation


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var animation_node: AnimationPlayer = get_animation_player_node(self)
	if animation_node == null:
		log_error.emit("Unable to find the AnimationPlayer node.")
		return
	var animation_name: String = inputs[1].value
	if animation_name.is_empty():
		outputs[0].value = animation_node.is_playing()
	else:
		outputs[0].value = animation_name == animation_node.current_animation


func get_script_block_type() -> String:
	return "is_animation_playing"

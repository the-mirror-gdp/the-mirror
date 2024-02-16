extends ScriptBlockAnimation


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var animation_node: AnimationPlayer = get_animation_player_node(self)
	if animation_node == null:
		log_error.emit("Unable to find the AnimationPlayer node.")
		return
	outputs[0].value = animation_node.get_speed_scale()


func get_script_block_type() -> String:
	return "get_animation_speed"

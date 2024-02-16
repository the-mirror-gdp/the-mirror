extends ScriptBlockSequenced


var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var animation_node: AnimationPlayer = ScriptBlockAnimation.get_animation_player_node(self)
	if animation_node == null:
		log_error.emit("Unable to find the AnimationPlayer node.")
		return ERR_INVALID_PARAMETER
	var animation_name: StringName = inputs[1].value
	var animation_speed: float = inputs[2].value
	if animation_name == &"stop":
		animation_node.stop()
	elif animation_name == &"pause":
		animation_node.pause()
	elif not animation_node.has_animation(animation_name):
		log_error.emit("The AnimationPlayer node does not have the animation '" + animation_name + "' in the list of animations:\n" + str(animation_node.get_animation_list()))
		return ERR_INVALID_PARAMETER
	else:
		# If it's not stop, not pause, and it is in the list, then play it.
		# Set the entire AnimationPlayer's speed scale, but keep the play method's
		# individual animation scale at 1.0. This allows retrieving the speed later.
		animation_node.set_speed_scale(animation_speed)
		animation_node.play(animation_name, -1.0, 1.0, animation_speed < 0.0)
	if Zone.is_host():
		Zone.script_network_sync.server_play_animation_on_clients(animation_node, animation_name, animation_speed)
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	if input_port != inputs[1]:
		return false
	var animation_node: AnimationPlayer = ScriptBlockAnimation.get_animation_player_node(self)
	return is_instance_valid(animation_node)


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	var animation_list: Array = ["stop", "pause"]
	var animation_node: AnimationPlayer = ScriptBlockAnimation.get_animation_player_node(self)
	if animation_node:
		animation_list.append_array(animation_node.get_animation_list())
	return animation_list


func get_script_block_type() -> String:
	return "play_animation"

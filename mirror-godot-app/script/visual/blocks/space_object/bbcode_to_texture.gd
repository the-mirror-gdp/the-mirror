extends ScriptBlockAsync


var attached_object: Object
var _space_object: SpaceObject = null


func _execute_callback(_stack_count: int) -> Error:
	if inputs[0].value is SpaceObject:
		_space_object = inputs[0].value
	elif attached_object is SpaceObject:
		_space_object = attached_object
	else:
		_space_object = null
		log_error.emit("Provided object in not a SpaceObject.")
		return ERR_INVALID_PARAMETER
	var saved_state = save_execution_state(self)
	var bbcode: String = inputs[1].value
	var bg_color: Color = inputs[2].value
	var tex_promise: Promise = GameplayTools.bbcode_renderer.bbcode_to_texture(bbcode, bg_color)
	tex_promise.connect_func_to_fulfill(_on_texture_generated.bind(tex_promise))
	await tex_promise.wait_till_fulfilled()
	load_execution_state(saved_state)
	return OK


func _on_texture_generated(tex_promise: Promise) -> void:
	if not tex_promise.is_error() and _space_object != null:
		_space_object.object_local_texture = tex_promise.get_result()
	else:
		log_error.emit("Unable to set BBCode texture.")


func get_script_block_type() -> String:
	return "bbcode_to_texture"

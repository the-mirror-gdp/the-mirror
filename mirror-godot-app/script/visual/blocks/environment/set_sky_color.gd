extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var top_color: Color = inputs[0].value
	var horizon_color: Color = inputs[1].value
	var bottom_color: Color = inputs[2].value
	var environment: SpaceEnvironment = Zone.Scene.get_space_template().get_child(0)
	environment.set_sky_color(top_color, horizon_color, bottom_color)
	environment.request_change()
	return OK


func get_script_block_type() -> String:
	return "set_environment_sky_color"

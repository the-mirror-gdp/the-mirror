extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var sun_count: int = inputs[0].value
	var global_illumination: bool = inputs[1].value
	var environment: SpaceEnvironment = Zone.Scene.get_space_template().get_child(0)
	environment.set_sun_count(sun_count)
	environment.environment.sdfgi_enabled = global_illumination
	environment.request_change()
	return OK


func get_script_block_type() -> String:
	return "set_environment_properties"

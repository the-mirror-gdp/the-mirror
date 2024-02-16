extends ScriptBlockSequenced


func _execute_callback(_stack_count: int) -> Error:
	var fog_enabled: bool = inputs[0].value
	var fog_volumetric: bool = inputs[1].value
	var fog_density: float = inputs[2].value
	var fog_color: Color = inputs[3].value
	var environment: SpaceEnvironment = Zone.Scene.get_space_template().get_child(0)
	environment.set_fog_properties(fog_enabled, fog_volumetric, fog_density, fog_color)
	environment.request_change()
	return OK


func get_script_block_type() -> String:
	return "set_environment_fog"

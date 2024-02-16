extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var index: int = inputs[0].value
	if index < 1:
		log_error.emit("Sun index is on a range of 1 to 4.")
		return
	var environment: SpaceEnvironment = Zone.Scene.get_space_template().get_child(0)
	# The environment has the child index 0 storing hidden nodes, so suns start at index 1.
	var sun_count: int = environment.get_child_count() - 1
	if index > sun_count:
		log_error.emit("Requested sun with index " + str(index) + " but there are only " + str(sun_count) + " suns.")
		return
	outputs[0].value = environment.get_child(index)
	environment.request_change()


func get_script_block_type() -> String:
	return "get_environment_sun"

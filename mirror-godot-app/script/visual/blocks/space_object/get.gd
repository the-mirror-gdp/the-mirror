extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	outputs[0].value = null
	var target_name: String = inputs[0].value
	var all_space_objects: Array = Zone.instance_manager.get_all_instances()
	for space_object in all_space_objects:
		assert(space_object is SpaceObject)
		if space_object.name == target_name or space_object.get_space_object_name() == target_name:
			outputs[0].value = space_object
			return


func get_script_block_type() -> String:
	return "get_space_object"

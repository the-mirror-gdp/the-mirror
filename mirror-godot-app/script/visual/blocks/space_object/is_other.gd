extends ScriptBlock


var attached_object: Object


func evaluate() -> void:
	evaluate_inputs()
	var space_object = inputs[0].value
	var is_other_space_object: bool = space_object != attached_object and \
			is_instance_valid(space_object) and space_object is SpaceObject
	outputs[0].value = is_other_space_object
	outputs[1].value = space_object if is_other_space_object else null


func get_script_block_type() -> String:
	return "is_other_space_object"

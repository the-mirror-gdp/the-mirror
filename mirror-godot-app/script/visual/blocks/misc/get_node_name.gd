extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var value = inputs[0].value
	if value is Node:
		outputs[0].value = value.name
	elif value == null:
		outputs[0].value = "<null>"
	elif not is_instance_valid(value):
		outputs[0].value = "<invalid instance>"
	else:
		# For non-Node objects, str() is the best we can do.
		outputs[0].value = str(value)


func get_script_block_type() -> String:
	return "get_node_name"

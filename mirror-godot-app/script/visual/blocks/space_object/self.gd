extends ScriptBlock


var attached_object: Object


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if outputs.is_empty():
		_setup_new_output(["Self", ScriptBlock.PortType.OBJECT, null])
	outputs[0].value = attached_object


func get_script_block_type() -> String:
	return "self"

class_name ScriptBlockVariableEntryBase
extends ScriptBlockEntryBase


var listening_for_variable_path: PackedStringArray


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if not inputs.is_empty():
		listening_for_variable_path = TMDataUtil.split_json_path_string(inputs[0].value)


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	listening_for_variable_path = TMDataUtil.split_json_path_string(inputs[0].value)

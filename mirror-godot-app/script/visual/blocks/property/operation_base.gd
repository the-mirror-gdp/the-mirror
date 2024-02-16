class_name ScriptBlockOperationBase
extends ScriptBlockSequenced


var attached_object: Object


func get_operation_target_object() -> Object:
	if inputs[0].connected_block == null:
		return attached_object
	return type_convert(inputs[0].value, ScriptBlock.PortType.OBJECT)

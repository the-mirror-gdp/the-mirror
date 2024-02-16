# @abstract
class_name ScriptBlockPhysicsSequenced
extends ScriptBlockSequenced


var attached_object: Object


func get_physics_body_node() -> JBody3D:
	var node
	if inputs[0].connected_block == null:
		node = attached_object
	else:
		node = inputs[0].value
	if node is JBody3D or node == null:
		return node
	return TMNodeUtil.recursive_get_node_by_type(node, JBody3D)

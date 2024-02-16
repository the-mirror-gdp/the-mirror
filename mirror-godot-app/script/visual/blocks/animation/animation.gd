# @abstract
class_name ScriptBlockAnimation
extends ScriptBlock


static func get_animation_player_node(script_block: ScriptBlock) -> AnimationPlayer:
	var node = script_block.inputs[0].value
	if node is AnimationPlayer:
		return node
	if not node is Node:
		node = script_block.attached_object
	if node is SpaceObject:
		node = node.animation_player
	else:
		node = TMNodeUtil.recursive_get_node_by_type(node, AnimationPlayer)
	return node

# @abstract
class_name ScriptBlockAudio
extends ScriptBlock


static func get_audio_player_node(script_block: ScriptBlock) -> Node:
	# Check the input node, or fall back to the attached object.
	var node = script_block.inputs[0].value
	if node is Node:
		if node is AudioStreamPlayer3D:
			return node
		if node is AudioStreamPlayer:
			return node
	else:
		node = script_block.attached_object
	# At this point, we have a node of some kind. Look for the audio player.
	if node is SpaceObject and node.audio_player:
		return node.audio_player
	var player_3d: AudioStreamPlayer3D = TMNodeUtil.recursive_get_node_by_type(node, AudioStreamPlayer3D)
	if player_3d:
		return player_3d
	return TMNodeUtil.recursive_get_node_by_type(node, AudioStreamPlayer)

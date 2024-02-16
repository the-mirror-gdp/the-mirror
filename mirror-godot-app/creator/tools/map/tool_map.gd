extends Node

signal map_node_changed

var _creator_ui: CreatorUI
var _map_build_node: Heightmap


func setup(creator_ui: CreatorUI) -> void:
	_creator_ui = creator_ui


func get_build_node():
	return _map_build_node


func change_build_node(active_build_node: Heightmap) -> void:
	if not is_instance_valid(active_build_node):
		return
	_map_build_node = active_build_node
	map_node_changed.emit()

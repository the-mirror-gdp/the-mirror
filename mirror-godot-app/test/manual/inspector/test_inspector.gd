extends Node


var _selected_nodes: Array[Node]

@onready var _inspector = $Inspector


func _enter_tree():
	# TODO: Instead of just deleting this when running the test scene,
	# we should make GameUI only instanced when needed on clients.
	# TODO: Also, if this was free instead of queue_free, ToolManager
	# would currently break, we should make it a child of CreatorUI.
	GameUI.queue_free()


func _ready():
	var new_nodes: Array[Node] = [$PlainBox]
	_inspector.select_nodes(new_nodes)


func _select(nodes: Array[Node]) -> void:
	if not Input.is_action_pressed(&"object_multi_select"):
		_selected_nodes = []
	for node in nodes:
		if not node in _selected_nodes:
			_selected_nodes.append(node)
	_inspector.select_nodes(_selected_nodes)


func _on_environment_pressed():
	_select([$Environment])


func _on_omni_light_pressed():
	_select([$OmniLight])


func _on_plain_box_pressed() -> void:
	_select([$PlainBox])


func _on_rigid_box_pressed() -> void:
	_select([$RigidBox])


func _on_floor_pressed():
	_select([$Floor])


func _on_none_pressed() -> void:
	_select([])


func _on_suns_pressed():
	_select($Environment.get_children())


# Copied from SceneHierarchyTree. We don't need the whole hierarchy, just this method.
func _prevent_selecting_child_of_selection(selected_nodes: Array) -> Array[Node]:
	return selected_nodes.filter(
		func(node1):
			for node2 in selected_nodes:
				if node2.is_ancestor_of(node1):
					return false
			return true
	)

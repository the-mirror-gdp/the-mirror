class_name ModelSceneTree
extends DraggableTree


signal request_open_extra_node_create_dialog(selected_node_name: StringName)

var selected_node_name: StringName
var edited_root_node: Node


func _gui_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"secondary_action"):
		var tree_item: TreeItem = get_item_at_position(_mouse_position)
		if not tree_item:
			return
		tree_item.select(0)
		selected_node_name = tree_item.get_text(0)
		GameUI.instance.creator_ui.open_context_menu(self)
	else:
		super(input_event)


func request_create_extra_node() -> void:
	request_open_extra_node_create_dialog.emit(selected_node_name)


func populate_model_scene_tree(root_node: Node) -> void:
	clear()
	edited_root_node = root_node
	_populate_subtree_recursive(root_node, null)


func _populate_subtree_recursive(node: Node, parent_item: TreeItem) -> void:
	var tree_item: TreeItem = create_item(parent_item)
	_setup_tree_item_for_node(node, tree_item)
	for child_node in node.get_children():
		_populate_subtree_recursive(child_node, tree_item)


func _setup_tree_item_for_node(node: Node, tree_item: TreeItem) -> void:
	tree_item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	tree_item.set_text(0, node.name)
	tree_item.set_text(1, node.get_class())
	if node.has_meta(&"MirrorExtraNode"):
		tree_item.set_custom_color(0, Color(1.0, 0.9, 0.5))
		tree_item.set_meta(&"MirrorExtraNode", node.get_meta(&"MirrorExtraNode"))


func _get_drag_data(drag_position := Vector2.ZERO) -> Variant:
	var tree_item: TreeItem = get_item_at_position(drag_position)
	if tree_item == null:
		return null
	return {
		"drag_type": "dragged_model_node",
		"string_to_drop": tree_item.get_text(0),
	}


func _get_drag_icon(_drag_position := Vector2.ZERO) -> Texture2D:
	return null

extends VBoxContainer


var _context_menu: PanelContainer = null
var _model_scene_tree: ModelSceneTree
var _target_json_dict: Dictionary

@onready var _visual_node_editor = $VisualNodeEditor
@onready var _create_extra_node = $CreateExtraNode
@onready var _delete_node = $DeleteNode


func setup(context_menu: PanelContainer) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(hide)


func open(model_scene_tree: ModelSceneTree) -> void:
	_model_scene_tree = model_scene_tree
	var selected = _model_scene_tree.get_selected()
	var has_edit_permission: bool = Util.can_edit_object_in_space(model_scene_tree.edited_root_node)
	_create_extra_node.visible = has_edit_permission
	if has_edit_permission:
		var has_extra_node: bool = selected.has_meta(&"MirrorExtraNode")
		if has_extra_node:
			_target_json_dict = selected.get_meta(&"MirrorExtraNode")
		else:
			_target_json_dict = {}
		_visual_node_editor.visible = has_extra_node
		_delete_node.visible = has_extra_node
	else:
		_visual_node_editor.visible = false
		_delete_node.visible = false
	show()


func _get_inspector_for_dict() -> Node:
	for insp in _model_scene_tree.owner.get_parent().get_children():
		if &"target_json_dict" in insp:
			if insp[&"target_json_dict"] == _target_json_dict:
				return insp
	return null


func _on_copy_node_name_pressed() -> void:
	var selected_node_name: String = _model_scene_tree.selected_node_name
	DisplayServer.clipboard_set(selected_node_name)
	Notify.info("Node Name Copied", selected_node_name)
	_context_menu.close()


func _on_visual_node_editor_pressed() -> void:
	var insp = _get_inspector_for_dict()
	if insp:
		insp.toggle_visual_editor()
	_context_menu.close()


func _on_create_extra_node_pressed() -> void:
	_model_scene_tree.request_create_extra_node()
	_context_menu.close()


func _on_delete_node_pressed() -> void:
	var insp = _get_inspector_for_dict()
	if insp:
		insp.delete_extra_node()
	_context_menu.close()

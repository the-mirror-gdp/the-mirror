extends "../categories/inspector_category_base.gd"


signal request_open_extra_node_create_dialog(selected_node_name: StringName)

var target_node: Node

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _tree = _property_list.get_node(^"ModelSceneTree")


func populate_model_scene_tree(root_node: Node) -> void:
	_tree.populate_model_scene_tree(root_node)


func _on_request_open_extra_node_create_dialog(selected_node_name: StringName) -> void:
	request_open_extra_node_create_dialog.emit(selected_node_name)

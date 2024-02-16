extends VBoxContainer

var _context_menu: PanelContainer = null
var _map_build_scene_tree: Heightmap


func setup(context_menu: PanelContainer) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(hide)


func open(model_scene_tree: Heightmap) -> void:
	_map_build_scene_tree = model_scene_tree
	show()


func _on_copy_node_name_pressed() -> void:
	var selected_node_name: String = _map_build_scene_tree.name
	DisplayServer.clipboard_set(selected_node_name)
	Notify.info("Map Name Copied", selected_node_name)
	_context_menu.close()


func _on_create_extra_node_pressed() -> void:
	_map_build_scene_tree.request_create_extra_node()
	_context_menu.close()

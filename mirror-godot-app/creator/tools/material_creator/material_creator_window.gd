extends Window


@onready var material_creator = $MaterialCreator


func _ready() -> void:
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if self.visible:
		GameUI.instance.add_visible_window(self)
	else:
		GameUI.instance.remove_visible_window(self)


func _sub_windows_visible(node: Node) -> bool:
	if node is Window and node.visible:
		return true
	for child in node.get_children(true):
		if _sub_windows_visible(child):
			return true
	return false


# TODO: this is temporary workaround for a Godot bug:
# https://github.com/godotengine/godot/issues/72215
func _on_focus_exited() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	if not _sub_windows_visible(material_creator):
		hide()


func _on_close_requested() -> void:
	hide()


func edit_material_for_mesh(space_object: SpaceObject = null, mesh_instance: MeshInstance3D = null, surface_id: int = -1) -> void:
	material_creator.setup_mesh_target(space_object, mesh_instance, surface_id)
	popup_centered_ratio(0.4)

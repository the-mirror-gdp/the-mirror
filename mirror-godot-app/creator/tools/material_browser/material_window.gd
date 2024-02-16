extends Window

@onready var material_browser = $MaterialBrowser


func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


func _on_visibility_changed() -> void:
	if self.visible:
		GameUI.add_visible_window(self)
	else:
		GameUI.remove_visible_window(self)


func sub_windows_visible(node: Node) -> bool:
	if node is Window and node.visible:
		return true
	for child in node.get_children(true):
		if sub_windows_visible(child):
			return true
	return false


func hide_and_disconnect():
	for connection in material_browser.selected_material_slot_changed.get_connections():
		material_browser.selected_material_slot_changed.disconnect(connection.get("callable"))
	hide()


# TODO: this is temporary workaround for a Godot bug:
# https://github.com/godotengine/godot/issues/72215
func _on_focus_exited():
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	if not sub_windows_visible(material_browser):
		hide_and_disconnect()


func _on_close_requested():
	hide_and_disconnect()


func _on_about_to_popup():
	material_browser.clean_selected_slot()
	material_browser.clean_search_bar()
	material_browser.search_field.focus()
	material_browser.search()

extends VBoxContainer


signal request_attach_existing_script(existing_script_id: String)
signal request_gd_script_creation()
signal request_visual_script_creation()
signal script_id_selected()


var _selected_script_id: String = ""
@onready var _create_new_script: Control = $CreateNewScript
@onready var _filter_menu: DropdownFilterMenu = $FilterMenu


func populate_menu() -> void:
	_selected_script_id = ""
	var can_create_new: bool = Util.can_local_user_edit_scripts()
	_create_new_script.visible = can_create_new
	_filter_menu.delete_filter_menu_items()
	var id_to_name: Dictionary = Net.script_client.get_script_id_to_name_dict()
	for script_id in id_to_name:
		_filter_menu.add_filter_menu_item(id_to_name[script_id], script_id)


func hide_create_new_script_buttons() -> void:
	_create_new_script.hide()


func focus_add_script_filter_menu() -> void:
	_filter_menu.show()
	_filter_menu.focus_filter_menu_search()


func hide_add_script_filter_menu() -> void:
	_filter_menu.hide()


func get_desired_script_id() -> String:
	return _selected_script_id


func _on_create_gd_script_pressed() -> void:
	request_gd_script_creation.emit()


func _on_create_visual_script_pressed() -> void:
	request_visual_script_creation.emit()


func _on_filter_menu_item_activated(_title: String, metadata: String) -> void:
	_selected_script_id = metadata
	request_attach_existing_script.emit(_selected_script_id)


func _on_filter_menu_item_selected(_title: String, metadata: String) -> void:
	_selected_script_id = metadata
	script_id_selected.emit()

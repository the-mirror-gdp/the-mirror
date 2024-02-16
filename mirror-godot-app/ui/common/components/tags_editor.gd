extends PanelContainer


@export var tag_panel: PackedScene
@export var editable: bool:
	set(can_edit):
		editable = can_edit
		if is_instance_valid(_tags_search_line_edit):
			_tags_search_line_edit.visible = can_edit

@onready var tag_filter_menu = $TagFilterMenu
@onready var _tags_search_line_edit = %TagsSearchLineEdit
@onready var _tags_list = %TagsList

var _is_dirty = false


func populate(tags_dict: Dictionary) -> void:
	cleanup_tags()
	tag_filter_menu.hide()
	_tags_search_line_edit.clear()
	_is_dirty = false
	for tag_category in tags_dict:
		var sub_tags = tags_dict[tag_category]
		for tag in sub_tags:
			var tag_data: Dictionary
			if tag is String:
				tag_data = {
					"name": tag,
					"__t": tag_category
				}
			elif tag is Dictionary:
				tag_data = tag
				tag_data["__t"] = tag_category
			create_tag_pill(tag_data.get("name", ""), tag_data, editable)


func cleanup_tags() -> void:
	for child in _tags_list.get_children():
		if child != _tags_search_line_edit:
			child.queue_free()


func is_dirty() -> bool:
	return _is_dirty


func _on_tags_search_line_edit_gui_input(event: InputEvent) -> void:
	tag_filter_menu._on_search_field_search_gui_input(event)


func _show_tags_filter() -> void:
	var filter_position_offset = Vector2(0, size.y)
	tag_filter_menu.custom_minimum_size.x = size.x
	var items_cnt = tag_filter_menu.get_items_count()
	tag_filter_menu.size.y = clamp(items_cnt, 1, 10) * 30
	tag_filter_menu.global_position = global_position + filter_position_offset
	tag_filter_menu.get_combined_minimum_size()
	tag_filter_menu.show()


func _on_tags_search_line_edit_focus_entered():
	if _tags_search_line_edit.text.length() > 0:
		_show_tags_filter()


func _on_tags_search_line_edit_text_changed(new_text: String) -> void:
	tag_filter_menu._on_search_field_text_changed(new_text)
	if _tags_search_line_edit.text.length() > 0:
		_show_tags_filter()


func create_tag_pill(title: String, metadata: Dictionary, show_close = true) -> void:
	var tag_name = metadata.get("name")
	var new_tag = tag_panel.instantiate()
	new_tag.text = title
	var tag_type = metadata.get("__t", "").trim_suffix("Tag").to_camel_case()
	new_tag.tooltip_text = tag_type
	new_tag.show_close = show_close
	new_tag.set_meta("name", tag_name)
	new_tag.set_meta("type", tag_type)
	new_tag.close_pressed.connect(_remove_tag.bind(new_tag))
	_tags_list.add_child(new_tag)
	_tags_list.move_child(new_tag, -2)


func _on_tag_filter_menu_item_selected(title: String, metadata) -> void:
	var tag_name = metadata.get("name")
	for badge in _tags_list.get_children():
		if badge.get_meta("name") == tag_name:
			return
	create_tag_pill(title, metadata)
	tag_filter_menu.hide()
	_tags_search_line_edit.clear()
	_is_dirty = true


func _remove_tag(tag_badge: Control) -> void:
	if not editable:
		return
	_tags_list.remove_child(tag_badge)
	_is_dirty = true


func get_tags() -> Array:
	var tags := []
	for child in _tags_list.get_children():
		if child == _tags_search_line_edit:
			continue
		var tag_type = child.get_meta("type", "unknown")
		var tag_name = child.get_meta("name", null)
		if tag_name == null:
			printerr("Tag on list but no name!")
			continue
		tags.append({
			"name": tag_name,
			"type": tag_type
		})
	return tags


func _on_tags_search_line_edit_text_submitted(new_text: String) -> void:
	tag_filter_menu._on_search_field_text_submitted(new_text)
	_tags_search_line_edit.clear()

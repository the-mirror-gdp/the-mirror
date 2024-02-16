class_name DropdownFilterMenu
extends PanelContainer


signal item_activated(title: String, metadata: Variant)
signal item_selected(title: String, metadata: Variant)

@export var search_item: PackedScene
@export var auto_hide: bool = true

@onready var search_field = $MarginContainer/FilterMenu/SearchField
@onready var search_result_container = $MarginContainer/FilterMenu/ScrollContainer/MarginContainer/SearchResultContainer

var _virtual_focused_item: Control = null


func _input(input_event: InputEvent) -> void:
	if auto_hide and is_visible_in_tree() and input_event is InputEventMouseButton and input_event.pressed:
		var local = make_input_local(input_event)
		if not Rect2(Vector2.ZERO, get_rect().size).has_point(local.position):
			hide()


func clear() -> void:
	for child in search_result_container.get_children():
		child.queue_free()


func add_filter_menu_item(title: String, metadata: Variant) -> void:
	var item = search_item.instantiate()
	item.text = title
	item.metadata = metadata
	item.pressed.connect(_on_item_selected.bind(item))
	item.button_double_clicked.connect(_on_item_activated.bind(item))
	search_result_container.add_child(item)


func delete_filter_menu_items() -> void:
	for item in search_result_container.get_children():
		item.queue_free()


func focus_filter_menu_search() -> void:
	search_field.focus()


func get_items_count() -> int:
	return search_result_container.get_children().filter(func(x): return x.visible).size()


func _move_virtual_focus(move_up = false) -> void:
	var visible_items = search_result_container.get_children().filter(
		func(item: Control):
			return item.visible
	)
	if visible_items.size() <= 1:
		return
	if move_up:
		visible_items.reverse()
	var is_previous_item_selected = false
	for item in visible_items:
		if is_previous_item_selected:
			item.virtual_focus = true
			_virtual_focused_item = item
			break
		if _virtual_focused_item == item:
			is_previous_item_selected = true
			item.virtual_focus = false
			_virtual_focused_item = null
	if _virtual_focused_item == null:
		_virtual_focused_item = visible_items[0]
		_virtual_focused_item.virtual_focus = true


func _on_search_field_search_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_DOWN:
			_move_virtual_focus()
			accept_event()
		elif event.pressed and event.keycode == KEY_UP:
			_move_virtual_focus(true)
			accept_event()


func _on_search_field_text_changed(new_text: String) -> void:
	_virtual_focused_item = null
	var first_focused = false
	for item in search_result_container.get_children():
		item.visible = new_text.to_lower() in item.text.to_lower() or new_text == ""
		item.virtual_focus = item.visible and not first_focused
		if item.visible and first_focused == false:
			first_focused = true
			_virtual_focused_item = item


func _on_search_field_text_submitted(_text) -> void:
	if not _virtual_focused_item:
		return
	item_selected.emit(_virtual_focused_item.text, _virtual_focused_item.metadata)


func _on_item_activated(item: Button) -> void:
	item_activated.emit(item.text, item.metadata)


func _on_item_selected(item: Button) -> void:
	item_selected.emit(item.text, item.metadata)

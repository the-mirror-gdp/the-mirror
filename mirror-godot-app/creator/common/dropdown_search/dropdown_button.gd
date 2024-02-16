extends Button


signal item_selected(title: String, metadata: Variant)

@export var default_text = "Dropdown"

@onready var _popup_panel = $PopupPanel
@onready var _filter_menu = $PopupPanel/FilterMenu

var selected_metadata = null


func _ready() -> void:
	text = default_text


func add_dropdown_filter_menu_item(title: String, metadata: Variant) -> void:
	_filter_menu.add_filter_menu_item(title, metadata)


func clear_dropdown_search() -> void:
	text = default_text
	selected_metadata = null


func delete_dropdown_filter_menu_items() -> void:
	_filter_menu.delete_filter_menu_items()


func _on_pressed() -> void:
	var pos := Vector2i(global_position)
	var root: Window = get_tree().get_root()
	if get_window() != root:
		pos += get_window().position
	var main_viewport_rect_size := Vector2i(root.get_visible_rect().size)
	if pos.x > main_viewport_rect_size.x - 200:
		pos.x -= _popup_panel.size.x
	if pos.y > main_viewport_rect_size.y - 300:
		pos.y -= _popup_panel.size.y
	else:
		pos.y += size.y
	_popup_panel.position = pos
	_popup_panel.visible = true
	_filter_menu.search_field.focus()


func _on_filter_menu_item_selected(title: String, metadata: Variant) -> void:
	_popup_panel.visible = false
	text = title
	selected_metadata = metadata
	item_selected.emit(title, metadata)

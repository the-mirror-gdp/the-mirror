extends Button

@export var _filter_empty_text: String
@export var _filter_inuse_text: String

@onready var _popup_panel = $PopupPanel
@onready var filter_menu = $PopupPanel/FilterMenu

const POPUP_OFFSET = Vector2i(10, 0)

func show_menu():
	var pos = Vector2i(global_position) + POPUP_OFFSET
	if get_window() != get_tree().get_root():
		pos += get_window().position
	_popup_panel.size = _popup_panel.get_contents_minimum_size()
	_popup_panel.position = Vector2i(pos.x - _popup_panel.size.x + size.x, pos.y + size.y)
	_popup_panel.visible = true


func _on_pressed():
	show_menu()


func _on_filter_menu_changed(sort_by, order, tags, asset_type):
	if filter_menu.is_default():
		text = _filter_empty_text
	else:
		text = _filter_inuse_text

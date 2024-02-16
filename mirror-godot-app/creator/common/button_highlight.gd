class_name ButtonHighlight
extends Button


@export var _item_paths: Array[NodePath] = []
@export var _hover_color := Color.WHITE

var _items: Dictionary = {}


func _ready() -> void:
	_set_items_normal_color()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)


func _set_items_normal_color() -> void:
	var array: Array = _item_paths.map(get_node)
	for item in array:
		_items[item] = item.get_modulate()


func _set_items_color(color: Color) -> void:
	for item in _items:
		item.set_modulate(_hover_color)


func _reset_items_color() -> void:
	for item in _items:
		item.set_modulate(_items[item])


func _on_mouse_entered() -> void:
	_set_items_color(_hover_color)


func _on_mouse_exited() -> void:
	_reset_items_color()


func _on_visibility_changed() -> void:
	_reset_items_color()

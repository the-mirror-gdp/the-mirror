@tool
extends "inspector_property_base.gd"


signal value_changed(new_index: int)

@export var values: Array
@export var reset_value: int = 0
@export var current_value: int:
	get:
		if _option_button_node == null:
			return -1
		return _option_button_node.selected
	set(value):
		if _option_button_node == null:
			return
		if _option_button_node.selected == value:
			return
		_option_button_node.selected = value
		_update_reset_visibility(value != reset_value)
		value_changed.emit(value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _option_button_node:
			_option_button_node.disabled = not value

@onready var _option_button_node: OptionButton = $OptionButton


func _ready():
	values = values.duplicate()
	super()
	for value in values:
		_option_button_node.add_item(value)


func add_item(new_item: Variant) -> void:
	if values.has(new_item):
		return
	values.append(new_item)
	_option_button_node.add_item(new_item)


func get_value_at_index(index: int) -> Variant:
	return values[index]


func select_value(value: Variant) -> void:
	current_value = values.find(value)


func select_value_no_signal(value: Variant) -> void:
	var index: int = values.find(value)
	_option_button_node.selected = index
	_update_reset_visibility(index != reset_value)


func select_index_no_signal(index: int) -> void:
	_option_button_node.selected = index
	_update_reset_visibility(index != reset_value)


func _on_option_button_item_selected(new_index: int) -> void:
	_update_reset_visibility(new_index != reset_value)
	value_changed.emit(new_index)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	_update_reset_visibility(false)
	value_changed.emit(current_value)

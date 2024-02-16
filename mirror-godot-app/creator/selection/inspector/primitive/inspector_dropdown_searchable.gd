@tool
extends "inspector_property_base.gd"


signal value_changed(new_index: int)

@export var values: Array
@export var reset_value: String = ""
@export var current_value: String:
	get:
		if _dropdown_button == null:
			return reset_value
		return _dropdown_button.text
	set(value):
		if _dropdown_button == null:
			return
		select_value(value)

@onready var _dropdown_button: Button = $DropdownButton


func _ready():
	values = values.duplicate()
	super()
	for value in values:
		_dropdown_button.add_dropdown_filter_menu_item(value, value)


func add_item(new_item: Variant) -> void:
	if values.has(new_item):
		return
	values.append(new_item)
	_dropdown_button.add_dropdown_filter_menu_item(new_item, new_item)


func select_value(value_string: String) -> void:
	_dropdown_button.default_text = value_string
	_dropdown_button.text = value_string
	_dropdown_button.selected_metadata = value_string
	_update_reset_visibility(value_string != reset_value)
	value_changed.emit(value_string)


func _on_reset_button_pressed() -> void:
	current_value = reset_value
	_update_reset_visibility(false)
	value_changed.emit(current_value)


func _on_dropdown_button_item_selected(title: String, metadata: Variant) -> void:
	current_value = metadata
	value_submitted.emit()

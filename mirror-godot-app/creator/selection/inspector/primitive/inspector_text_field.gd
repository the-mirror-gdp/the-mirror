@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: String)

@export var reset_value: String = ""
@export var current_value: String = "":
	get:
		return _text_edit_node.text
	set(value):
		_text_edit_node.text = value

@onready var label_node: Label = $LabelHolder/Label
@onready var _text_edit_node: TextEdit = $TextEditHolder/TextEdit


func _ready():
	super()
	refresh()
	if reset_value != "":
		_update_reset_visibility(current_value != reset_value)


func refresh():
	_text_edit_node.text = current_value


func _on_text_changed() -> void:
	var new_text: String = _text_edit_node.text
	if reset_value != "":
		_update_reset_visibility(new_text != reset_value)
	value_changed.emit(new_text)


func _on_value_dropped(value) -> void:
	current_value = type_convert(value, TYPE_STRING)
	refresh()


func _on_reset_button_pressed() -> void:
	pass # Do nothing, text field is not resettable.

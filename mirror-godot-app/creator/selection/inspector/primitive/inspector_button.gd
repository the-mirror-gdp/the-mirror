@tool
extends "inspector_property_base.gd"


signal inspector_button_pressed()

@export var button_text: String = "Push the button":
	set(value):
		button_text = value
		if is_instance_valid(_main_button):
			_main_button.text = value
@export var enabled: bool:
	set(value):
		if is_instance_valid(_main_button):
			_main_button.disabled = not value
	get:
		return is_instance_valid(_main_button) and not _main_button.disabled

@onready var _main_button = $MainButton


func _ready() -> void:
	super()
	_main_button.text = button_text


func _on_main_button_pressed() -> void:
	inspector_button_pressed.emit()

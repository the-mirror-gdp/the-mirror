@tool
extends "inspector_submittable_base.gd"


@export var label_text: String = "E":
	set(value):
		label_text = value
		if _label_node:
			_label_node.text = value
@export var label_color := Color.WHITE

@onready var _label_node: Label = $LabelHolder/Label
@onready var _reset_button: Button = $ResetButton


func _ready() -> void:
	super()
	_label_node.text = label_text
	_label_node.add_theme_color_override(&"font_color", label_color)
	_update_reset_visibility(false)


func _update_reset_visibility(is_reset_visible: bool) -> void:
	if is_reset_visible:
		_reset_button.self_modulate.a = 1.0
		_reset_button.focus_mode = Control.FOCUS_ALL
	else:
		_reset_button.self_modulate.a = 0.0
		_reset_button.focus_mode = Control.FOCUS_NONE


func _on_reset_button_pressed() -> void:
	printerr("This method should be overridden in derived classes.")

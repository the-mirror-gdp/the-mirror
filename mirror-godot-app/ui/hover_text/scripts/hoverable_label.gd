class_name HoverableLabel
extends Label


## The text to show as a tooltip when hovering.
## Use this instead of Godot's tooltip_text property.
@export var hover_tooltip_text: String = ""


func _on_hoverable_label_mouse_entered() -> void:
	if hover_tooltip_text == "":
		return
	GameUI.instance.set_hover_tooltip_text(hover_tooltip_text)


func _on_hoverable_label_mouse_exited() -> void:
	GameUI.instance.hide_hover_tooltip_text()

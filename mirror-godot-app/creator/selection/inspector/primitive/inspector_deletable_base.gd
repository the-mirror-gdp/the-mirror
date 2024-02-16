@tool
extends HBoxContainer


## The text to show as a tooltip when hovering.
## Use this instead of Godot's tooltip_text property.
@export var hover_tooltip_text: String = ""


func _ready() -> void:
	if not hover_tooltip_text.is_empty():
		mouse_entered.connect(_on_hoverable_inspector_item_mouse_entered)
		mouse_exited.connect(_on_hoverable_inspector_item_mouse_exited)


func cleanup_and_delete() -> void:
	queue_free()


func _on_hoverable_inspector_item_mouse_entered() -> void:
	if hover_tooltip_text == "":
		return
	GameUI.set_hover_tooltip_text(hover_tooltip_text)


func _on_hoverable_inspector_item_mouse_exited() -> void:
	GameUI.hide_hover_tooltip_text()

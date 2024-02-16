@tool
class_name EmojiButton
extends Button


signal emoji_pressed(emoji: String)

@export var emoji_symbol: String = "😆"
@export var rotated: bool = false

@onready var _circle: TextureRect = $Circle
@onready var _label: Label = $Label


func _ready() -> void:
	_set_display_emoji(emoji_symbol)
	_label.pivot_offset = Vector2(_label.size.x / 2, _label.size.y / 2)
	_label.rotation_degrees = -45 if rotated else 0


func _set_display_emoji(emoji: String) -> void:
	_label.text = "%s " % emoji


func _on_mouse_entered() -> void:
	_circle.show()


func _on_mouse_exited() -> void:
	_circle.hide()


func _on_pressed() -> void:
	emoji_pressed.emit(emoji_symbol)

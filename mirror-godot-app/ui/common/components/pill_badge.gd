@tool
extends PanelContainer

signal badge_pressed
signal close_pressed

@export var title: String:
	set(value):
		title = value
		%Title.text = value
@export var text: String:
	set(value):
		text = value
		%Text.text = value
@export var show_close: bool:
	set(value):
		show_close = value
		%CloseButton.visible = value


func _ready():
	%Title.text = title
	%Text.text = text
	%CloseButton.visible = show_close


func _on_close_button_pressed():
	close_pressed.emit()


func _on_pressed():
	badge_pressed.emit()

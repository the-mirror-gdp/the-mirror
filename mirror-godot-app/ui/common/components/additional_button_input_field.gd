@tool
extends Control

# In this context the component is a button for addition to a generic table
# We call this the button place holder because we are showing to the user
# this is actually meant to be a type of button
@export var button_placeholder = "Example Text Placeholder"

func _ready():
	var line_edit : LineEdit = $Panel/HBoxContainer/LineEdit
	line_edit.placeholder_text = button_placeholder

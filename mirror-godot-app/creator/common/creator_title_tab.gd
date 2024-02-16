extends VBoxContainer


signal close_button_pressed()

@export var primary_name: String = "Creator Title Tab"
@export var secondary_name: String = ""
@export var show_close_button: bool = false:
	set (value):
		if _close_button:
			_close_button.visible = value

@onready var _title_hbox := $Title/HBoxContainer
@onready var _primary_name_label := _title_hbox.get_node(^"PrimaryName")
@onready var _secondary_name_label := _title_hbox.get_node(^"SecondaryName")
@onready var _close_button := _title_hbox.get_node(^"CloseButton")


func _ready() -> void:
	refresh()


func refresh() -> void:
	_primary_name_label.text = primary_name
	_secondary_name_label.text = secondary_name


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()

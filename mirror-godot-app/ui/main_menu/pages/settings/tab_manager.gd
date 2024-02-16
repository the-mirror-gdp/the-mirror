extends Control


@export var tab_button: PackedScene

@onready var pages: Array[Node] = $HBoxContainer/Pages.get_children()
@onready var tab_container = $HBoxContainer/SettingsTabs/MarginContainer/Tabs


func _ready() -> void:
	_populate_tab_buttons()
	_hide_pages()
	pages[0].show()


func _hide_pages() -> void:
	for page in pages:
		page.hide()


func _populate_tab_buttons() -> void:
	for page in pages:
		if page.name == &"Advanced":
			if not ProjectSettings.get_setting("feature_flags/show_advanced_settings", false):
				continue
		var button = tab_button.instantiate()
		button.text = str(page.name).to_upper()
		button.pressed.connect(_on_tab_button_pressed.bind(page))
		tab_container.add_child(button)


func _on_tab_button_pressed(page: Control) -> void:
	_hide_pages()
	page.show()

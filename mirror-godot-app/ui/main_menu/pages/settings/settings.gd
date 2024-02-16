extends Control


@onready var _tab_manager := $VBoxContainer/TabManager


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	_prepare_ui()


func _prepare_ui():
	for page in _tab_manager.pages:
		page.prepare_ui()

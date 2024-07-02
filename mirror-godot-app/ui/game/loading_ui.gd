class_name LoadingUI
extends Control


@onready var _status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var _loading_title: Label = $Panel/MarginContainer/VBoxContainer/LoadingTitle
@onready var _loading_subtext: RichTextLabel = $Panel/MarginContainer/VBoxContainer/LoadingSubtext
@onready var _loading_background: TextureRect = $Background
@onready var _progress_animation: AnimationPlayer = $Panel/MarginContainer/VBoxContainer/Progress/ProgressAnimation


func _ready() -> void:
	var image_override = ProjectSettings.get_setting("application/config/loading_image", "")
	if not image_override.is_empty():
		_loading_background.texture = load(image_override)

	Zone.client.join_server_start.connect(_on_join_server_start)
	Zone.client.join_server_complete.connect(_on_join_server_complete)
	Zone.client.join_server_info_updated.connect(_on_join_server_info_updated)
	Zone.client.join_server_status_changed.connect(_on_join_server_status_changed)


func populate(space_data: Dictionary) -> void:
  # TODO: this should pull the description from the space data (not currently present on the dictionary for some reason). Task: https://themirrorspace.atlassian.net/browse/ENG-971
	_loading_title.text = space_data.get("name", "The Mirror: Beam Space")
	_loading_subtext.text = str(space_data.get("description", ""))


func populate_status(status_text: String) -> void:
	_status_label.text = status_text


func set_loading_image(image: Texture2D) -> void:
	_loading_background.texture = image


func _on_join_server_start() -> void:
	_progress_animation.play("Loading")
	if GameUI.instance.main_menu_ui:
		GameUI.instance.main_menu_ui.hide()
	show()

func _on_join_server_complete() -> void:
	hide()
	_progress_animation.stop()


func _on_join_server_info_updated(space: Dictionary) -> void:
	populate(space)


func _on_join_server_status_changed(text: String) -> void:
	populate_status(text)


func _on_cancel_button_pressed() -> void:
	Zone.client.cancel_join_request()
	GameUI.instance.main_menu_ui.show()
	hide()

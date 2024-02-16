class_name StaticPopup
extends Panel


signal notification_clicked()


@onready var title_label: Label = %Title
@onready var description_label: RichTextLabel = %Description
@onready var close_button: TextureButton = %CloseButton
@onready var top_border: ColorRect = $TopBorder
@onready var icon: TextureRect = $ContentContainer/HBoxContainer/Icon/Circle
@onready var large_text_size = ProjectSettings.get_setting("feature_flags/large_text_size", false)

func _gui_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"primary_action"):
		notification_clicked.emit()


func create_popup(title: String, description: String, is_closable: bool = true) -> void:
	title_label.text = title
	if description.is_empty():
		description_label.text = ""
	else:
		description_label.text = "[center]" + description + "[/center]"
	close_button.visible = is_closable


func set_notification_theme(color: Color, texture: Texture2D) -> void:
	top_border.color = color
	icon.texture = texture


func _close_popup() -> void:
	self.queue_free()


func _clicked_url_handler(meta):
	print(meta)
	OS.shell_open(meta)

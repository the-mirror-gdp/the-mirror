extends Button

@onready var _upload_icon = $CornerClipContainer/UploadIcon
@onready var _space_image: UrlTextureRect = $CornerClipContainer/SpaceImage


func _on_mouse_entered():
	_upload_icon.show()


func _on_mouse_exited():
	_upload_icon.hide()


func set_image(image: Texture2D):
	_space_image.texture = image


func set_image_from_url(url: String) -> void:
	_space_image.set_image_from_url(url)

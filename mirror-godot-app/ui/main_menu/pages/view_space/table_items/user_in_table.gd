extends PanelContainer


@onready var _user_icon = $HBoxContainer/user_icon
@onready var _user_name = $HBoxContainer/user_name
@onready var _url_texture_rect = $HBoxContainer/user_icon/UrlTextureRect

var _name = "Unknown"
var _avatar_url = ""

@export var user_data: Dictionary:
	set(value):
		if not is_instance_valid(_user_name):
			return
		_name = value.get("name", "Unknown")
		_avatar_url = value.get("image")
		update_data()


func update_data():
		if not is_instance_valid(_user_name):
			return
		_user_name.text = _name
		if not is_instance_valid(_url_texture_rect):
			print("TEXTURE RECT IS NOT VALID")
			return
		_url_texture_rect.set_image_from_url(_avatar_url)


func _ready():
	update_data()

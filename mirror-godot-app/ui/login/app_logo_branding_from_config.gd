extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	var logo = ProjectSettings.get_setting("application/config/game_ui_icon", null)
	if logo:
		texture = load(logo)
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

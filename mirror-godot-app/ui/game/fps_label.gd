extends Label

@export var _fps_text_format = "%s FPS "

func _process(_delta):
	if not self.is_visible_in_tree():
		return
	text = _fps_text_format % str(Engine.get_frames_per_second())

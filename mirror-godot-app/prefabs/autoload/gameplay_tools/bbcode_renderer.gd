class_name BBcodeRenderer
extends SubViewport


var _render_queue: Array[Dictionary] = []
var _renderer_available = true

@onready var _panel = $Panel
@onready var _text = $Panel/Text


func _process(_delta: float) -> void:
	if _render_queue.size() == 0 or not _renderer_available:
		return
	var queue_item = _render_queue.pop_front()
	_render_texture(queue_item["bbcode"], queue_item["bg_color"],
			queue_item["size"], queue_item["promise"])


func bbcode_to_texture(bbcode: String, bg_color: Color, tex_size := Vector2i(512, 512)) -> Promise:
	var data := {"bbcode": bbcode, "bg_color": bg_color, "size": tex_size}
	var previously_queued = _render_queue.filter(func(x):
			return x["bbcode"] == bbcode and x["bg_color"] == bg_color and x["size"] == tex_size)
	if not previously_queued.is_empty():
		data = previously_queued[0]
	else:
		data["promise"] = Promise.new()
		_render_queue.append(data)
	return data["promise"]


func _render_texture(bbcode: String, bg_color: Color, tex_size: Vector2i, promise: Promise) -> void:
	_renderer_available = false
	var panel_style = _panel.get("theme_override_styles/panel")
	panel_style.set_bg_color(bg_color)
	size = tex_size
	_panel.size = tex_size
	_text.text = bbcode
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	# Copy Texture from GPU
	var texture = ImageTexture.create_from_image(get_texture().get_image())
	promise.set_result(texture)
	_renderer_available = true

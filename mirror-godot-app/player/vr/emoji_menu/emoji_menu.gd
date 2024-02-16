extends JBody3D


@onready var _render_panel: MeshInstance3D = $RenderPanel
@onready var _sub_viewport: SubViewport = $SubViewport

var _local_player: Player = null
var _camera: XRCamera3D = null
var _panel_mouse_location = Vector2.ZERO


func setup(player: Player, camera: XRCamera3D) -> void:
	_local_player = player
	_camera = camera
	VRManager.vr_ended.connect(_on_vr_exit)


func _ready() -> void:
	var _emoji_children: Array = Util.recursive_find_nodes_of_type(self, EmojiButton)
	for emoji in _emoji_children:
		emoji.emoji_pressed.connect(on_emoji_pressed)
	desired_body_id = TMSceneSync.fetch_free_unsync_body_id()
	body_mode = JBody3D.KINEMATIC
	create_body()
	close()


func _process(_delta) -> void:
	if not _render_panel.visible or not _camera:
		return
	look_at(_camera.global_transform.origin, Vector3.UP)
	rotate_object_local(Vector3.UP, deg_to_rad(180))


func hover_panel(hit: Vector3) -> void:
	var event = InputEventMouseMotion.new()
	var mesh_size: Vector2 = _render_panel.mesh.size
	var hit_inverse = _render_panel.global_transform.affine_inverse() * hit
	var hit_2d: Vector2 = Vector2(hit_inverse.x, -hit_inverse.y)
	hit_2d += mesh_size / 2
	hit_2d /= mesh_size
	hit_2d *= _sub_viewport.size as Vector2
	_panel_mouse_location = hit_2d
	event.position = _panel_mouse_location
	event.global_position = _panel_mouse_location
	_sub_viewport.push_input(event, true)


func click_panel() -> void:
	var event = InputEventMouseButton.new()
	event.button_index = 1
	event.pressed = true
	event.position = _panel_mouse_location
	event.global_position = _panel_mouse_location
	_sub_viewport.push_input(event, true)
	event.pressed = false
	_sub_viewport.push_input(event, true)


func toggle_menu(open_position: Vector3 = Vector3.ZERO) -> void:
	if _render_panel.visible:
		close()
	else:
		_open(open_position)


func _open(open_position: Vector3 = Vector3.ZERO) -> void:
	set_layer_name(&"KINEMATIC")
	_render_panel.show()
	global_position = open_position


func close() -> void:
	set_layer_name(&"")
	_render_panel.hide()


func is_open() -> bool:
	return _render_panel.visible


func on_emoji_pressed(emoji: String) -> void:
	_local_player.create_emoji.rpc(emoji)
	close()


func _on_vr_exit() -> void:
	close()

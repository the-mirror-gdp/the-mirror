extends Control


const _MESSAGE_BUBBLE_SCENE: PackedScene = preload("res://player/ui/social/message_bubble.tscn")
const _EMOJI_SCENE: PackedScene = preload("res://player/ui/social/emoji.tscn")

@onready var name_label: Label = $VBoxContainer/Name
@onready var _message_container: VBoxContainer = $VBoxContainer/Messages

var _player: Player = null
var _hidden: bool = false
var _large_text_size: int = 22
var _use_large_text_size: bool = false


func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	GameUI.instance.chat_ui.chat_message_sent.connect(_on_chat_message_sent)
	_use_large_text_size = ProjectSettings.get_setting("feature_flags/large_text_size", false)
	if _use_large_text_size:
		name_label.label_settings.font_size = _large_text_size


func _physics_process(delta: float) -> void:
	if Zone.is_host():
		return
	var local_player: Player = PlayerData.get_local_player()
	if local_player == null:
		return
	var fade = 1.0 if _should_show_name(local_player) else 0.0
	if modulate.a <= 0.1:
		modulate.a = 0.0
	modulate.a = lerpf(modulate.a, fade, delta * 10)
	var screen_position: Vector2 = local_player.camera_unproject_position_to_screen(_player.get_global_eyes_position() + Vector3(0, 0.25, 0))
	position = position.lerp(screen_position, delta * 40)


func _should_show_name(local_player: Player) -> bool:
	if _hidden:
		return false
	var eyes_pos: Vector3 = _player.get_global_eyes_position()
	if local_player.camera_is_position_behind(eyes_pos):
		return false
	var head_transform: Transform3D = local_player.get_head_global_transform()
	var distance_sq: float = eyes_pos.distance_squared_to(head_transform.origin)
	return distance_sq < 144 # 12^2


func show_social() -> void:
	_hidden = false


func hide_social() -> void:
	_hidden = true


func _on_chat_message_sent(text: String, user_id: String = "") -> void:
	if user_id != _player.get_user_id():
		return
	var message: PanelContainer = _MESSAGE_BUBBLE_SCENE.instantiate()
	_message_container.add_child(message)
	message.set_text(text)
	if _use_large_text_size:
		message.set_text_size(_large_text_size)


func create_emoji(emoji: String) -> void:
	var emoji_node: Label3D = _EMOJI_SCENE.instantiate()
	add_child(emoji_node)
	emoji_node.global_position = _player.global_position + (Vector3.UP * 1.5) - (_player.get_model_global_basis().z * 0.5)
	emoji_node.text = emoji
	var tween = create_tween()
	tween.tween_property(emoji_node, "position", emoji_node.global_position + Vector3.UP - _player.get_model_global_basis().z * 2, 4)
	tween.parallel().tween_property(emoji_node, "modulate:a", 0, 4)
	tween.tween_callback(emoji_node.queue_free)

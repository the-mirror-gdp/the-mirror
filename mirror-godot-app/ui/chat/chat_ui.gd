class_name Chat
extends Control


signal chat_message_sent(text: String, user_id: String)

const _CHAT_MESSAGE_SCENE: PackedScene = preload("res://ui/chat/chat_message.tscn")
const _EMOJI_BUTTON_SCENE: PackedScene = preload("res://ui/chat/emoji_button.tscn")
const _AVAILABLE_EMOJIS: PackedStringArray = ["🙂", "😀", "😲", "😎", "👍", "👎", "❤️", "☹️", "😢"]

@onready var _chat_box: PanelContainer = $ChatBox
@onready var _message_container: VBoxContainer = %MessageContainer
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _scrollbar: ScrollBar = _scroll_container.get_v_scroll_bar()
@onready var _line_edit: LineEdit = %LineEdit
@onready var _chat_send_sound: AudioStreamPlayer = $ChatSendSound
@onready var _chat_receive_sound: AudioStreamPlayer = $ChatReceiveSound
@onready var _emoji_menu_button: Button = %EmojiMenuButton
@onready var _emoji_menu: PanelContainer = %EmojiMenu
@onready var _emoji_grid_container: GridContainer = %EmojiGridContainer


var is_typing_in_chat: bool = false

var _fade_delay: float = 4.0
var _time_since_last_opened: float = 0.0
var _max_scroll_length: float = 0.0
var _initial_position: Vector2 = Vector2.ZERO
var _large_text_size: int = 22
var _use_large_text_size: bool = false


func _ready() -> void:
	if Zone.is_host():
		set_process(false)
		return
	_initial_position = _chat_box.position
	_scrollbar.changed.connect(_on_scrollbar_changed)
	_line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	_line_edit.focus_entered.connect(_on_line_edit_focus_entered)
	_line_edit.focus_exited.connect(_on_line_edit_focus_exited)
	_max_scroll_length = _scrollbar.max_value
	_use_large_text_size = ProjectSettings.get_setting("feature_flags/large_text_size", false)
	if _use_large_text_size:
		_line_edit.add_theme_font_size_override(&"font_size", _large_text_size)
		_line_edit.custom_minimum_size = Vector2(0, 48)
		_emoji_menu_button.custom_minimum_size = Vector2(48, 48)
		_emoji_menu_button.add_theme_font_size_override(&"font_size", _large_text_size)
	for emoji in _AVAILABLE_EMOJIS:
		var emoji_button: Button = _EMOJI_BUTTON_SCENE.instantiate()
		emoji_button.text = "%s " % emoji
		emoji_button.add_theme_font_size_override(&"font_size", _large_text_size)
		emoji_button.custom_minimum_size = Vector2(40, 40)
		_emoji_grid_container.add_child(emoji_button)
		emoji_button.pressed.connect(func(): _on_emoji_pressed(emoji))
	Zone.social_manager.player_connected.connect(_on_player_connected)
	Zone.social_manager.player_disconnected.connect(_on_player_disconnected)
	Zone.client.disconnected.connect(clear_chat)


func _process(delta: float) -> void:
	_time_since_last_opened += delta
	var safe_area_for_gui: Rect2 = GameUI.get_safe_area()
	var new_position: Vector2 = _initial_position + safe_area_for_gui.position
	_chat_box.position = new_position
	if Input.is_action_just_pressed("player_open_chat", true) and not GameUI.is_any_full_screen_or_modal_ui_visible([self]) and get_viewport().gui_get_focus_owner() == null:
		_line_edit.grab_focus()
	if not is_typing_in_chat and _time_since_last_opened > _fade_delay:
		var visibility_loss_speed = delta * 0.5
		_lower_visibility(_chat_box, visibility_loss_speed)
		_lower_visibility(_line_edit, visibility_loss_speed)
		_lower_visibility(_scrollbar, visibility_loss_speed)
		_lower_visibility(_emoji_menu_button, visibility_loss_speed)


func send_message_from_object(obj: Object, message: String, range: float) -> void:
	var pos := Vector3.ZERO
	if obj is Node3D:
		pos = obj.global_position
	if obj is SpaceObject:
		var node_name: String = obj.get_space_object_name()
		var color: Color = Color.WHITE #obj.object_color
		message = "[color=#%s]%s[/color]: %s" % [color.to_html(false), node_name, message]
	if Zone.is_host():
		_send_message_from_object_network.rpc(message, pos, range)
	else:
		# Messages from client-side scripts should only appear client-side,
		# but server-side messages are sent to all players.
		_send_message_from_object_network(message, pos, range)


@rpc("call_remote", "authority", "reliable")
func _send_message_from_object_network(message: String, pos: Vector3, range: float) -> void:
	if PlayerData.has_local_player():
		var player: Player = PlayerData.get_local_player()
		var distance_sq: float = player.position.distance_squared_to(pos)
		if distance_sq > range * range:
			return
	add_message_clientside(message)
	_chat_receive_sound.play()


func add_message_clientside(text: String) -> void:
	var message: RichTextLabel = _CHAT_MESSAGE_SCENE.instantiate()
	if _use_large_text_size:
		var text_size_keys: Array[String] = [&"bold_italics_font_size", &"italics_font_size", &"mono_font_size", &"normal_font_size", &"bold_font_size"]
		for key in text_size_keys:
			message.add_theme_font_size_override(key, _large_text_size)
	message.text = text
	_message_container.add_child(message)


@rpc("call_remote", "any_peer", "reliable")
func send_chat_message_server(text: String) -> void:
	if not Zone.is_host():
		return
	var user_id: String = Zone.server.get_user_id(multiplayer.get_remote_sender_id())
	_send_chat_message_client.rpc(text, user_id)


@rpc("call_local", "any_peer", "reliable")
func _send_chat_message_client(text: String, user_id: String) -> void:
	if not Zone.social_manager.has_player(user_id):
		return
	var player: Player = Zone.social_manager.get_player(user_id)
	var user_name: String = player.get_player_name()
	var user_color: String = player.get_player_team_color().to_html(false)
	var message: String = "[color=#%s]%s[/color]: %s" % [user_color, user_name, text]
	add_message_clientside(message)
	if not Zone.is_host() and user_id != PlayerData.get_local_user_id():
		_chat_receive_sound.play()
	chat_message_sent.emit(text, user_id)


func _on_player_connected(player: Player) -> void:
	_handle_player_event(player, "connected")


func _on_player_disconnected(player: Player) -> void:
	_handle_player_event(player, "disconnected")


func _handle_player_event(player: Player, event_type: String) -> void:
	if not Zone.is_host():
		return
	var promise := Net.user_client.get_user_profile(player.get_user_id())
	var profile = await promise.wait_till_fulfilled()
	if promise.is_error():
		print(promise.get_error_message())
		return
	var player_name: String = profile.get("displayName", "Player")
	var message: String = ""
	if event_type == "connected":
		var role: int = Util.get_role_for_user(Zone.space, player.get_user_id())
		var role_name = Enums.ROLE.find_key(role)
		if role_name == null:
			role_name = "unknown"
		message = "[color=#256bfb]%s has joined as %s![/color]" % [player_name, role_name.to_lower()]
	else:
		message = "[color=#256bfb]%s has %s![/color]" % [player_name, event_type]
	_handle_player_event_client.rpc(message)


@rpc("call_local", "any_peer", "reliable")
func _handle_player_event_client(message: String) -> void:
	add_message_clientside(message)
	if not Zone.is_host():
		_chat_receive_sound.play()


func _on_line_edit_focus_entered() -> void:
	is_typing_in_chat = true
	_reset_chat_transparency()
	GameUI.grab_input_lock(self)


func _on_line_edit_focus_exited() -> void:
	is_typing_in_chat = false
	_reset_chat_transparency()
	_scroll_to_bottom()
	_emoji_menu.hide()
	GameUI.release_input_lock(self)


func _on_line_edit_text_submitted(text: String) -> void:
	if Zone.is_host() or text == "":
		_clear_chat_input()
		return
	var player: Player = PlayerData.get_local_player()
	if not player:
		return
	send_chat_message_server.rpc_id(Zone.SERVER_PEER_ID, text)
	_chat_send_sound.play()
	_clear_chat_input()


func _on_scrollbar_changed() -> void:
	if _max_scroll_length == _scrollbar.max_value or is_typing_in_chat:
		return
	_max_scroll_length = _scrollbar.max_value
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	_scroll_container.scroll_vertical = int(_max_scroll_length)


func _reset_chat_transparency() -> void:
	_time_since_last_opened = 0.0
	_chat_box.self_modulate.a = 1.0
	_line_edit.self_modulate.a = 1.0
	_scrollbar.self_modulate.a = 1.0
	_emoji_menu_button.self_modulate.a = 1.0
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	_chat_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrollbar.mouse_filter = Control.MOUSE_FILTER_STOP
	_emoji_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _clear_chat_input() -> void:
	_line_edit.clear()
	_line_edit.release_focus()


func clear_chat() -> void:
	for message in _message_container.get_children():
		message.queue_free()


func _lower_visibility(control: Control, speed: float) -> void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chat_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_edit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrollbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emoji_menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.self_modulate.a -= speed
	if control.self_modulate.a <= 0.0:
		control.self_modulate.a = 0.0


func _on_emoji_menu_button_mouse_entered() -> void:
	_emoji_menu_button.text = "😀 "


func _on_emoji_menu_button_mouse_exited() -> void:
	_emoji_menu_button.text = "🙂 "


func _on_emoji_menu_button_pressed() -> void:
	_emoji_menu.show()
	_line_edit.grab_focus()
	var open_offset := Vector2(12.0, 12.0)
	var shift_offset := Vector2(16.0, 16.0)
	_emoji_menu.position = get_global_mouse_position() + open_offset
	size = Vector2.ZERO
	var viewport_size: Vector2i = get_viewport_rect().size
	if _emoji_menu.position.x + _emoji_menu.size.x > viewport_size.x:
		_emoji_menu.position.x -= _emoji_menu.size.x + shift_offset.x
	if position.y + size.y > viewport_size.y:
		_emoji_menu.position.y -= _emoji_menu.size.y + shift_offset.y


func _on_emoji_pressed(emoji: String) -> void:
	if Zone.is_host():
		return
	var player: Player = PlayerData.get_local_player()
	if not player:
		return
	_clear_chat_input()
	player.create_emoji.rpc(emoji)

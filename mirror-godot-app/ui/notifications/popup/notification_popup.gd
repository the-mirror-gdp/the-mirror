extends BasePopup


@export var _self_destruct_timeout: float = 3.5

@onready var animation_player := $AnimationPlayer
@onready var self_destruct := $SelfDestruct


func create_popup(title: String, description: String, is_closable: bool = true) -> void:
	super.create_popup(title, description, is_closable)
	self.modulate = Color.TRANSPARENT
	animation_player.play("FadeIn")
	if not is_closable:
		self_destruct.queue_free()
		return
	self_destruct.wait_time = _self_destruct_timeout
	self_destruct.start()
	self_destruct.timeout.connect(func(): _close_popup())


func _close_popup() -> void:
	if animation_player:
		animation_player.play_backwards("FadeIn")
		await animation_player.animation_finished
	super._close_popup()


# Stops the self destruct timer, self destruct is running if the mouse is able to enter
func _on_popup_message_mouse_entered() -> void:
	if self_destruct:
		self_destruct.stop()


# Starts another self destruct timer, assumes the mouse was entered and has exited
func _on_popup_message_mouse_exited() -> void:
	if self_destruct:
		self_destruct.start()

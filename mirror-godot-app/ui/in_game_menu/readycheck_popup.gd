extends Control


var _check_ends_time = 0


func _ready() -> void:
	Zone.ready_check_started.connect(_on_ready_check_started)
	Zone.ready_check_rejected.connect(hide)


func _process(_delta: float) -> void:
	if not visible:
		return
	var now = Time.get_unix_time_from_system()
	if now > _check_ends_time or _check_ends_time == 0:
		hide()
		Notify.error("Preview Canceled", "Ready check expired.")


func _on_ready_check_started(ready_player_ids: Array, seconds_left: float) -> void:
	# this player has already readied up, hide the ready check and escape
	if ready_player_ids.has(Net.user_id):
		if visible:
			hide()
		return
	# if this is not visible and they haven't checked in, show and update time left
	if not visible:
		show()
	var now = Time.get_unix_time_from_system()
	_check_ends_time = now + seconds_left


func _on_play_button_pressed() -> void:
	Zone.client_ready_check()
	hide()


func _on_reject_button_pressed() -> void:
	Zone.client_reject_ready_check()
	hide()

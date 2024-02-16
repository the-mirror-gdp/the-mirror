extends LineEdit

@export var value: String:
	set = _try_updating_value
@export var update_ignore_delay = 0.5

var _last_update_time: float = 0


func _ready() -> void:
	text_changed.connect(_on_text_changed)
	focus_exited.connect(_on_focus_exited)


func _try_updating_value(new_value: String) -> void:
	if value == new_value or has_focus():
		return
	var current_time = Time.get_unix_time_from_system()
	if current_time < _last_update_time + update_ignore_delay:
		return
	value = new_value
	text = value


func _on_focus_exited() -> void:
	text_submitted.emit(text)


func _on_text_changed(_new_text: String) -> void:
	_last_update_time = Time.get_unix_time_from_system()

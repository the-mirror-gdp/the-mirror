extends PanelContainer


@onready var _progress_bar = $ProgressBar

var player_counter: Dictionary:
	set(value):
		_progress_bar.min_value = 0
		_progress_bar.max_value = value.get("max_users")
		_progress_bar.value = value.get("value")

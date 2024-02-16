extends Panel

@onready var _loading_spinner = $LoadingSpinner


func show_loading() -> void:
	_loading_spinner.visible = true

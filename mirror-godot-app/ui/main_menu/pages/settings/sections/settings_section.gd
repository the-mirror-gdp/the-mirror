extends VBoxContainer


@onready var options_holder: Node = $Options


func _ready() -> void:
	for setting in options_holder.get_children():
		setting.setting_changed.connect(_on_setting_changed.bind(setting))


func _on_setting_changed(_in_setting_val, in_setting_node) -> void:
	for setting in options_holder.get_children():
		if setting != in_setting_node:
			setting.refresh_ui()


func prepare_ui() -> void:
	for setting in options_holder.get_children():
		setting.prepare_ui()

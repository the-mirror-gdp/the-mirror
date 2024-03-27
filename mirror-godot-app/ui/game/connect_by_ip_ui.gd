extends Panel

func _ready():
	visible = ProjectSettings.get_setting("feature_flags/join_by_ip", false)


func _on_connect_pressed():
	var line_edit = $MarginContainer/HBoxContainer/LineEdit
	print("Attempting connection: ", line_edit.text)
	Zone.client.connect_to_server_by_string(line_edit.text)

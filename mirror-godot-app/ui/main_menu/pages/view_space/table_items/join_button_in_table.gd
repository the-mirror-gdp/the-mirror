extends PanelContainer


signal button_pressed()

func _on_join_button_pressed():
	button_pressed.emit()

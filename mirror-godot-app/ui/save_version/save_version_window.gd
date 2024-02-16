extends Control


signal space_version_published()

@onready var _loading_spinner: Control = %LoadingSpinner
@onready var _save_button: Button = %SaveButton
@onready var _space_version_name = %SpaceVersionName

var space_id: String = ""


func populate(space: Dictionary) -> void:
	space_id = space.get("_id", "")
	_save_button.disabled = false
	_save_button.visible = true
	_loading_spinner.visible = false
	_space_version_name.clear()


func _on_close_button_pressed():
	hide()


func _on_save_button_pressed():
	if space_id.is_empty():
		Notify.error("Error trying save a space version", "Incorrect space id.")
		return
	var version_name = _space_version_name.text
	_loading_spinner.visible = true
	_save_button.disabled = true
	var promise: Promise = Net.space_client.create_space_version(space_id, version_name)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Error trying save a space version", promise.get_error_message())
	else:
		Notify.success("Saving space version sucesfull", "%s saved." % version_name)
		hide()
	_loading_spinner.visible = false
	_save_button.disabled = false

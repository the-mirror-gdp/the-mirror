extends Control


signal play_server_created(play_server_id: String)

@onready var _create_window = $CreateWindow
@onready var _share_window = $ShareWindow
@onready var _space_name_label = %SpaceNameLabel
@onready var _server_name_edit = %ServerNameEdit
@onready var _create_server_button = %CreateServerButton
@onready var _loading_spinner = %CreateServerButton/LoadingSpinner
@onready var _url_label = %UrlLabel
@onready var _play_server_name_label = %PlayServerNameLabel

var _space_id: String = ""
var _new_zone_id: String = ""

func _ready():
	hide_popups()


func populate(space: Dictionary, space_url: String):
	_space_id = space.get("_id")
	_url_label.text = space_url
	_space_name_label.text = space.get("name", "Unknown")


func hide_popups():
	hide()
	_create_window.visible = true
	_share_window.visible = false
	_create_server_button.disabled =  false
	_loading_spinner.visible = false
	_new_zone_id = ""


func _on_close_button_pressed():
	hide_popups()


func _on_create_server_button_pressed():
	if _space_id.is_empty():
		Notify.error("Error on Creating Play Server", "Invalid space id")
		return
	_create_server_button.disabled = true
	_loading_spinner.visible = true
	var promise: Promise = Net.zone_client.create_play_server_by_space_id(_space_id, _server_name_edit.text)
	var data = await promise.wait_till_fulfilled()
	_create_server_button.disabled = false
	_loading_spinner.visible = false
	if promise.is_error():
		Notify.error("Error on Creating Play Server", promise.get_error_message())
		return
	_new_zone_id = data.get("id", "")
	play_server_created.emit(_new_zone_id)
	_play_server_name_label.text = data.get("name", "Unknown")

	_create_window.visible = false
	_share_window.visible = true


func _on_visibility_changed():
	if is_instance_valid(_create_window):
		_create_window.visible = true
	if  is_instance_valid(_share_window):
		_share_window.visible = false
	if is_instance_valid(_server_name_edit):
		_server_name_edit.text = ""


func _on_share_button_pressed():
	DisplayServer.clipboard_set(_url_label.text)
	Notify.success(tr("Copy"), tr("Space URL copied to clipboard"))


func _on_launch_space_button_pressed():
	if _new_zone_id.is_empty():
		printerr("Zone ID is empty")
		return
	Zone.client.start_join_play_space_by_zone_id(_new_zone_id)
	hide_popups()

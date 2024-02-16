class_name UserTutorial
extends Control


enum Tutorial_Type {
	HOME,
	SPACE,
}

@export var _home_pages: Array[Texture2D] = []
@export var _space_pages: Array[Texture2D] = []

@onready var window: Panel = $Window
@onready var _page_image: TextureRect = %PageImage
@onready var _previous_button: Button = %PreviousButton
@onready var _next_button: Button = %NextButton
@onready var _done_button: Button = %DoneButton

var _tutorial_type := Tutorial_Type.HOME
var _user_data: Dictionary = {}
var _pages: Array[Texture2D] = []
var _current_page: int = 0:
	set(value):
		_current_page = value
		_refresh_page_image()
	get:
		return _current_page


func _ready():
	window.set_visible(false)
	visibility_changed.connect(_refresh_page_image)
	Net.fully_logged_in.connect(_on_fully_logged_in)
	Zone.client.join_server_complete.connect(_on_space_loaded)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"action_deselect") and window.visible:
		window.set_visible(false)


func _on_fully_logged_in() -> void:
	var promise := Net.user_client.get_user_private_profile()
	var user_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		print(promise.get_error_message())
		return
	if user_data == null or user_data.is_empty():
		return
	_user_data = user_data
	var feature_enabled = ProjectSettings.get_setting("feature_flags/the-mirror-tutorials", false)
	var has_already_seen_that_specific_tutorial = _user_data.get("tutorial", {}).get("shownFirstHomeScreenPopupV1", false)
	if feature_enabled and not has_already_seen_that_specific_tutorial:
		show_tutorial_type(Tutorial_Type.HOME)


func _on_space_loaded() -> void:
	var is_feature_enabled = ProjectSettings.get_setting("feature_flags/the-mirror-tutorials", false)
	var has_already_seen_that_specific_tutorial = _user_data.get("tutorial", {}).get("shownFirstInSpacePopupV1", false)
	if is_feature_enabled and not has_already_seen_that_specific_tutorial:
		show_tutorial_type(Tutorial_Type.SPACE)


func show_tutorial_type(type: Tutorial_Type) -> void:
	_tutorial_type = type
	match _tutorial_type:
		Tutorial_Type.HOME:
			_pages = _home_pages
		Tutorial_Type.SPACE:
			_pages = _space_pages
	_current_page = 0
	window.set_visible(true)


func _refresh_page_image() -> void:
	if _pages.is_empty():
		_page_image.texture = null
		return
	_page_image.texture = _pages[_current_page]
	# Hide the previous page button if we're on the first page.
	# Show the done button & hide the next page button if we're on the last page.
	_previous_button.visible = _current_page > 0
	_done_button.visible = _current_page == _pages.size() -1
	_next_button.visible = not _done_button.visible


func _on_previous_button_pressed() -> void:
	if _pages.is_empty():
		return
	if _current_page > 0:
		_current_page -= 1


func _on_next_button_pressed() -> void:
	if _pages.is_empty():
		return
	if _current_page < _pages.size() - 1:
		_current_page += 1


func _on_done_button_pressed() -> void:
	var data: Dictionary = {}
	match _tutorial_type:
		Tutorial_Type.HOME:
			data["shownFirstHomeScreenPopupV1"] = true
		Tutorial_Type.SPACE:
			data["shownFirstInSpacePopupV1"] = true
	Net.user_client.update_user_tutorial(data)
	if _user_data.has("tutorial"):
		_user_data.tutorial.merge(data, true)
	window.set_visible(false)

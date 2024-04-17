extends HoverableButton


signal create_pressed()
signal space_pressed(space: Dictionary)

@onready var _preview_image: UrlTextureRect = %Preview
@onready var _title_label: Label = %TitleLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _is_ready_zone: Control = %IsReadyZone
@onready var _present_users_in_build = %PresentUsersInBuild
@onready var _present_users_in_play = %PresentUsersInPlay
@onready var _decor_border = find_child("DecorBorder", true, true)
@onready var _rating_label = find_child("RatingLabel", true, true)
@onready var _rating_star_icon = find_child("RatingStarIcon", true, true)
@onready var _users_count_label = find_child("UsersCountLabel", true, true)
@onready var _users_count_icon = find_child("UsersCountIcon", true, true)

@onready var _enter_button: HoverableButton = %EnterButton
@onready var _play_button: HoverableButton = %PlayButton
@onready var _create_button: HoverableButton = %CreateButton

@onready var map_role_to_button_text = {
	1000: tr("Owner"),
	700: tr("Manage"),
	400: tr("Contribute"),
	100: tr("Observe"),
}

var _id: String
var _space_or_zone: Dictionary
var _has_id: bool
var _users_in_build: int = 0
var _users_in_play: int = 0


func get_updated_time() -> String:
	return _space_or_zone.get("updatedAt", "")


func get_space_name() -> String:
	return _space_or_zone.get("name", "")


func get_space_id() -> String:
	return _id


func set_ready_status(status: bool) -> void:
	if _is_ready_zone:
		_is_ready_zone.visible = status


func _set_present_users(present_users: Array, control: Control):
	var users = present_users.map(func(user): return user.get("displayName", tr("Unknown")))
	var display_list =  "\n".join(PackedStringArray(users))
	control.visible = users.size() > 0
	control.hover_tooltip_text = display_list


func set_build_present_users(present_users: Array):
	_users_in_build = present_users.size()
	_set_present_users(present_users, _present_users_in_build)


func set_play_present_users(present_users: Array):
	_users_in_play = present_users.size()
	_set_present_users(present_users, _present_users_in_play)


func get_user_count_in_zones():
	return _users_in_build + _users_in_play


## populates the panel with space data
func populate_item_slot(space: Dictionary, show_only_date := false) -> void:
	_id = space.get("_id", "")
	_space_or_zone = space
	var role: int = Util.get_role_for_user(space, Net.user_id)
	var dedicated = space.get("dedicated")
	_has_id = not _id.is_empty()
	var has_published_space: bool = not space.get("activeSpaceVersion", "").is_empty()
	var has_uuid: bool = space.get("uuid") != null
	if _enter_button:
		var permissions_level: String = map_role_to_button_text.get(role, "Build")
		_enter_button.text = permissions_level
		_enter_button.visible = _has_id and role >= Enums.ROLE.OBSERVER
		_enter_button.hover_tooltip_text = "Load the space in Build mode to edit the space. You have " + permissions_level + " permissions here."
	if _play_button:
		_play_button.visible = has_published_space and role >= Enums.ROLE.BLOCK
	if _create_button:
		_create_button.visible = not _has_id and not has_uuid
	if _rating_label and _rating_star_icon:
		_rating_star_icon.visible = space.get("AVG_RATING") is float
		_rating_label.visible = _rating_star_icon.visible
		if _rating_label.visible:
			_rating_label.text = "%.1f" % space.get("AVG_RATING")
	if _users_count_label and _users_count_icon:
		var cnt = space.get("usersCount", 0)
		_users_count_icon.visible = not cnt == null and cnt > 0
		_users_count_label.visible = _users_count_icon.visible
		if _users_count_label.visible:
			_users_count_label.text = "%d" % cnt

	if space.has("images") and not space.images.is_empty():
		if space.images[0] != null:
			_preview_image.set_image_from_url(space.images[0])
	_title_label.text = space.get("name", "")
	_title_label.hover_tooltip_text = _title_label.text
	var description = space.get("description","").strip_edges()
	if description == "" and not show_only_date and space.get("creator", {}) is Dictionary:
		var creator_name = space.get("creator", {}).get("displayName")
		if creator_name:
			description = tr("Created by {0}").format([creator_name])
	if description == "":
		var date = Time.get_datetime_dict_from_datetime_string(space.get('updatedAt'), false)
		var formatted_date = Util.datetime_dict_to_mmm_dd_yyyy(date)
		description = tr("Updated {0}").format([formatted_date])
	_description_label.text = description
	_preview_image.visible = not _create_button.visible
	if _decor_border:
		_decor_border.visible = _create_button.visible

	if (
		(not _enter_button or not _enter_button.visible)
		and (not _play_button or not _play_button.visible)
		and (_create_button or not _create_button.visible)
	):
		_enter_button.get_parent().visible = false


## emits the signal that create button was pressed
func _on_create_button_pressed() -> void:
	create_pressed.emit()


func _on_pressed():
	if not _create_button.visible:
		space_pressed.emit(_space_or_zone)
	else:
		create_pressed.emit()


## joins a space
func _join_space(build_mode = false) -> void:
	if _id.is_empty():
		print("No populated space to enter")
		return
	Zone.client.quit_to_main_menu()
	if build_mode:
		Zone.client.start_join_zone_by_space_id(_id)
	else:
		Zone.client.start_join_play_space_by_space_id(_id)
	GameUI.instance.loading_ui.set_loading_image(_preview_image.texture)


## receiver method for the button was pressed that triggers entering a space
func _on_enter_button_pressed() -> void:
	_join_space(true)


## receiver method for the button was pressed that triggers entering a play space
func _on_play_button_pressed():
	_join_space()

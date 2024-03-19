extends Control


# cache only do not set more than once
var _space = null
@export var _default_space_image: Texture2D = null
@onready var _name_label: Label = %NameLabel
@onready var _created_at_label = %CreatedAtLabel
@onready var _updated_at_label = %UpdatedAtLabel
@onready var _rating_container = %RatingContainer
@onready var _rating_label = %RatingLabel
@onready var _url_label = %UrlLabel
@onready var _creator_label = %CreatorLabel
@onready var _description_label = %DescriptionLabel
@onready var _space_settings_button = %SpaceSettingsButton
@onready var _space_image: UrlTextureRect = %SpaceImage
@onready var _build_button = %SpaceButtons/Build
@onready var _play_button = %SpaceButtons/Play
@onready var _star_rating = %StarRating
@onready var _create_play_server = $CreatePlayServer
@onready var _servers_panel = %ServersPanel
@onready var _publish_space_window = $PublishSpaceWindow
@onready var _back_button = %BackButton
@onready var map_role_to_button_text = {
	1000: tr("Build: Owner"),
	700: tr("Build: Manage"),
	400: tr("Build: Contribute"),
	100: tr("Build: Observe"),
}

var _space_id: String = ""
var _entity_action_rating_id: String = ""

func _construct_space_url(space_id: String) -> String:
	var base_url: String = ProjectSettings.get_setting("mirror/base_url")
	return base_url + "/s/" + space_id


func _on_cancel_pressed() -> void:
	GameUI.main_menu_ui.history_go_back()


func _load_avg_space_rating() -> void:
	# Set the label immediately with the cached value in the Space.
	if _space is Dictionary:
		var space_rating = _space.get("AVG_RATING", 0.0)
		_set_space_rating_label(space_rating)
	# Fetch the latest value and set that a split second later.
	var space_rating_promise: Promise = Net.user_client.get_entity_action_stats(_space_id)
	var rating_data = await space_rating_promise.wait_till_fulfilled()
	if space_rating_promise.is_error():
		_rating_container.hide()
		printerr("Failed to download Space Rating data", space_rating_promise.get_error_message())
		# TODO: this can be triggered when space has no rates, so do not show notification to user
		# Notify.error("Request Error", "Cannot retrive space rating data")
		return
	var avg_rating = rating_data.get("AVG_RATING", 0.0)
	_set_space_rating_label(avg_rating)


func _set_space_rating_label(avg_rating) -> void:
	if avg_rating is float and avg_rating > 0.0:
		var avg_rating_fmt = "%.1f" % avg_rating
		_rating_label.text = avg_rating_fmt
		_rating_container.show()
	else:
		_rating_container.hide()


func _load_user_space_rating() -> void:
	var my_space_rating_promise: Promise = Net.user_client.get_entity_action(_space_id)
	var entitiy_actions = await my_space_rating_promise.wait_till_fulfilled()
	if my_space_rating_promise.is_error():
		printerr("Failed to download User Space Rating data", my_space_rating_promise.get_error_message())
		# TODO: this can be triggered when space has no rates, so do not show notification to user
		# Notify.error("Request Error", "Cannot retrive space rating data")
		return
	for action in entitiy_actions:
		if action.get("actionType") == "RATING":
			_entity_action_rating_id = action.get("_id")
			_star_rating.current_value = action.get("rating", 0)
			return


func _preprocess_description(desciption: String) -> String:
	# We only need to replace opening brackets to prevent tags from being parsed.
	var desc = desciption.replace("[", "[lb]")
	var result := ""
	var lines = desc.split("\n", true)
	for line in lines:
		var parsed_line: Array[String] = []
		var words = line.split(" ", true)
		for word in words:
			if word.begins_with("#"):
				parsed_line.append("[color=#4370FF][b][url]%s[/url][/b][/color]" % word)
			else:
				parsed_line.append(word)
		result += " ".join(parsed_line) + "\n"
	return result.strip_edges()


func populate(space: Dictionary) -> void:
	_back_button.visible = GameUI.should_display_space_listings
	# cache space
	_space = Net.space_client.spaces.get(space.get("_id"), space) # always get newest data
	_entity_action_rating_id = ""
	_star_rating.current_value = 0
	_space_id = _space.get("_id") as String

	if _space.is_empty():
		return

	if _space_id.is_empty():
		push_error("Invalid space id assigned to space")
		return

	_name_label.text = _space.get("name", "")
	var created = Time.get_datetime_dict_from_datetime_string(_space.get('createdAt', ""), false)
	_created_at_label.text = Util.datetime_dict_to_mmm_dd_yyyy(created)
	var updated = Time.get_datetime_dict_from_datetime_string(_space.get('updatedAt', ""), false)
	_updated_at_label.text = Util.datetime_dict_to_mmm_dd_yyyy(updated)
	_url_label.text = _construct_space_url(_space.get("_id", "unknown"))
	var creator_promise: Promise = Net.user_client.get_user_profile(_space.creator)
	creator_promise.connect_func_to_fulfill(func(): 
		if creator_promise.is_error():
			push_error("Failed to get creator")
		var data = creator_promise.get_result()
		var creator_name = data.get("displayName", tr("Unknown"))
		_creator_label.text = tr("Created by {0}").format([creator_name])
	)
	_description_label.text = _preprocess_description(_space.get("description",""))
	if _description_label.text == "":
		_description_label.text = tr("No description was provided for this space.")
	var role: int = Util.get_role_for_user(_space, Net.user_id)
	_space_settings_button.visible = role >= Enums.ROLE.OWNER
	_build_button.visible = role >= Enums.ROLE.OBSERVER
	_build_button.text = map_role_to_button_text.get(role, "Build")
	_play_button.visible = role >= Enums.ROLE.OBSERVER
	var has_published_space = not _space.get("activeSpaceVersion", "").is_empty()
	if not has_published_space and role >= Enums.ROLE.OWNER:
		_play_button.visible = true
		_play_button.text = "Publish"
	elif has_published_space and role >= Enums.ROLE.BLOCK:
		_play_button.visible = true
		_play_button.text = "Play"
	elif not has_published_space:
		_play_button.visible = false
	#
	# Slow operations these should be fixed!
	#
	if _space.has("images") and not _space.images.is_empty():
		if _space.images[0] != null:
			_space_image.set_image_from_url(_space.images[0])
	else:
		_space_image.texture = _default_space_image

	_load_avg_space_rating()
	_load_user_space_rating()
	_servers_panel.populate(_space)
	_create_play_server.populate(_space, _url_label.text)
	_publish_space_window.populate(_space)
	_publish_space_window.hide()


func _on_build_button_pressed():
	var space_id = _get_space_id(_space)
	if space_id == null:
		return
	Zone.client.quit_to_main_menu()
	Zone.client.start_join_zone_by_space_id(space_id)
	GameUI.loading_ui.set_loading_image(_space_image.texture)


# do not call this excessively, we only need to call it when a user publishes
# an unpublished space
func refresh_pane(space_id):
	var promise = Net.space_client.get_space(space_id)
	var space = await promise.wait_till_fulfilled()
	populate(space)


func _on_play_published_space() -> void:
	print("Play published space")
	var space_id = _get_space_id(_space)
	if space_id == null:
		return
	var promise = Net.space_client.get_published_space_versions(space_id)
	var versions = await promise.wait_till_fulfilled()
	if versions.size() == 0:
		_publish_space_window.show()
		return
	Zone.client.quit_to_main_menu()
	Zone.client.start_join_play_space_by_space_id(space_id)
	GameUI.loading_ui.set_loading_image(_space_image.texture)


func _on_copy_url_button_pressed():
	DisplayServer.clipboard_set(_url_label.text)
	Notify.success(tr("Copy"), tr("Space URL copied to clipboard"))


func _get_space_id(space) -> String:
	return str(space.get("_id", ""))


func _on_space_settings_button_pressed():
	GameUI.main_menu_ui.change_subpage("EditSpace", _space)


func _on_star_rating_value_changed(value):
	if _space_id.is_empty():
		push_error("Trying to rate a invalid space")
		return
	var entity_action := {
		"forEntity": _space_id,
		"actionType": "RATING",
		"entityType": "SPACE",
		"rating": value
	}
	if value > 0:
		var promise: Promise = Net.user_client.upsert_entity_action(entity_action)
		var data = await promise.wait_till_fulfilled()
		if promise.is_error():
			printerr("Failed to rate a Space")
			Notify.error("Request Error","Failed to rate a Space")
		else:
			_load_avg_space_rating()
			_entity_action_rating_id = data.get("_id")
	elif not _entity_action_rating_id.is_empty():
		var promise: Promise = Net.user_client.delete_entity_action(_entity_action_rating_id)
		var data = await promise.wait_till_fulfilled()
		if promise.is_error():
			printerr("Failed to remove rate from a Space")
			Notify.error("Request Error","Failed to remove rate from a Space")
		else:
			_load_avg_space_rating()
			_entity_action_rating_id = ""


func _on_servers_panel_create_new_play_server_request():
	_create_play_server.show()


func _on_create_play_server_play_server_created(play_server_id):
	_servers_panel.update_play_servers_data()


func _on_description_label_meta_clicked(meta):
	GameUI.main_menu_ui.change_page(&"Build")
	GameUI.main_menu_ui.change_subpage(&"DiscoverSpaceSelect", meta)


func _on_publish_space_window_space_version_published():
	var space_id = _get_space_id(_space)
	if space_id == null:
		return
	refresh_pane(space_id)

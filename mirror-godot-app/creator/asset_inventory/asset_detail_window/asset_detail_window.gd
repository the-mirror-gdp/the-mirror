extends Control


signal request_edit_script_asset(asset_data: AssetData, allow_opening: bool)

@export var sidebar: Control
@export var object_selection: Control

@onready var _asset_detail = $AssetDetail
@onready var _tags_editor = %TagsEditor
@onready var _preview = %Preview
@onready var _asset_name_line_edit = %AssetNameLineEdit
@onready var _descritpion_text_edit = %DescritpionTextEdit
@onready var _creator_label_value = %CreatorLabelValue
@onready var _owner_label_value = %OwnerLabelValue
@onready var _created_at_label_value = %CreatedAtLabelValue
@onready var _asset_type_label_value = %AssetTypeLabelValue
@onready var _delete_button = %DeleteButton
@onready var _save_button = %SaveButton
@onready var _delete_dialog = $DeleteDialog
@onready var _download_button = %DownloadButton
@onready var _script_button = %ScriptButton
@onready var _is_equipable = %IsEquipable


var asset_id: String = ""
var _asset_data: AssetData
var _is_dirty = false


func set_game_mode(new_mode) -> void:
	if not is_visible_in_tree():
		return
	if new_mode == GameMode.Mode.NORMAL:
		_tags_editor.tag_filter_menu.hide()
		hide()


func _populate_username(user_id: String, label: Label) -> void:
	var promise = Net.user_client.get_user_profile(user_id)
	var user_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Asset Detail", "Error requesting user data.")
		label.text = "Unknown"
		return
	label.text = user_data.get("displayName", "Unknown")


# Working with tags is a real PITA now so we need to reformat data for us
func _get_old_tag_names() -> Dictionary:
	var old_tags = {}
	for tag_category in _asset_data.tags:
		var sub_tags = _asset_data.tags[tag_category]
		for tag in sub_tags:
			var tag_data: Dictionary
			if tag is String:
				old_tags[tag] = tag_category
			elif tag is Dictionary:
				old_tags[tag.get("name")] = tag_category
	return old_tags


func _update_tags() -> bool:
	var asset_id = _asset_data.asset_id
	var old_tags: Dictionary = _get_old_tag_names()
	var add_tags := {}
	var remove_tags := []
	for updated_tag in _tags_editor.get_tags():
		# tag already exists
		if old_tags.has(updated_tag.name):
			old_tags.erase(updated_tag.name) # remove it from this array
		else:
			add_tags.get_or_add(updated_tag.type,[]).append(updated_tag.name)
	# everything that was a leftover in old_tags array should be removed:
	var promises = []
	for tag_name in old_tags:
		var tag_category = old_tags[tag_name]
		var promise = Net.asset_client.delete_asset_tag(asset_id, tag_category, tag_name)
		promises.append(promise)
	# now add tags that were missing:
	for tag_category in add_tags:
		var tag_names = add_tags[tag_category]
		for tag in tag_names:
			var tag_dict = {
				"tagType": tag_category,
				"tagName": tag
			}
			var promise = Net.asset_client.update_asset_tag(asset_id, tag_dict)
			promises.append(promise)
	# now wait for all promises
	var success = true
	for promise in promises:
		await promise.wait_till_fulfilled()
		if promise.is_error():
			printerr(promise.get_error_message())
			Notify.error("Tag Update Error", promise.get_error_message())
			success = false
	return success


func _get_role():
	var asset_role = {"role": _asset_data.role}
	return Util.get_role_for_user(asset_role, Net.user_id)


func _populate(asset_data: AssetData) -> void:
	asset_id = asset_data.asset_id
	_asset_data = asset_data
	_is_dirty = false
	var asset_type: String = _asset_data.type
	_asset_data.preview_generated.connect(_refresh_preview_image)
	_asset_data.preview_downloaded.connect(_refresh_preview_image)
	_asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	_refresh_preview_image()
	_asset_name_line_edit.text = _asset_data.asset_name
	_descritpion_text_edit.text = _asset_data.description
	_populate_username(_asset_data.creator_id, _creator_label_value)
	_populate_username(_asset_data.owner_id, _owner_label_value)
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(_asset_data.created_at_unix_time)
	_created_at_label_value.text = Util.datetime_dict_to_mmm_dd_yyyy(date)
	_asset_type_label_value.text = asset_data.type
	_tags_editor.tag_filter_menu.hide()
	_is_equipable.visible = _asset_data.is_equipable
	_download_button.visible = _get_role() == Enums.ROLE.OWNER
	_script_button.visible = asset_type == Enums.ASSET_TYPE.SCRIPT

	_tags_editor.populate(asset_data.tags)


func _set_editable(can_edit: bool) -> void:
	_asset_name_line_edit.editable = can_edit
	_descritpion_text_edit.editable = can_edit
	_tags_editor.editable = can_edit
	_delete_button.disabled = not can_edit
	_save_button.disabled = not can_edit


func _refresh_preview_image() -> void:
	_preview.texture = _asset_data.preview_texture


func _on_asset_browser_request_show_details_editor(slot: AssetSlot) -> void:
	if not is_instance_valid(slot):
		hide()
		return
	global_position.x = sidebar.global_position.x + sidebar.size.x
	global_position.y = slot.global_position.y
	var viewport_size: Vector2i = get_viewport_rect().size
	_set_editable(slot.can_asset_be_deleted())
	_populate(slot.asset_data)
	show()
	await get_tree().process_frame
	if global_position.y + _asset_detail.size.y > viewport_size.y:
		global_position.y = viewport_size.y - _asset_detail.size.y


func _on_save_button_pressed() -> void:
	if asset_id.is_empty():
		return
	var asset_dict = {
		"name": _asset_name_line_edit.text,
		"description": _descritpion_text_edit.text
	}
	var promise = Net.asset_client.update_asset(asset_id, asset_dict)
	_save_button.disabled = true
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Update Asset Error", promise.get_error_message())
		_save_button.disabled = false
		return
	var tags_update_success = await _update_tags()

	# now we need to refresh asset data..
	await Net.asset_client.queue_download_asset(asset_id)
	if tags_update_success:
		Notify.info("Update Asset Success", "Assset details updated succesfully.")
	_save_button.disabled = false



func _on_cancel_button_pressed() -> void:
	_tags_editor.tag_filter_menu.hide()
	hide()


func _input(input_event: InputEvent) -> void:
	if _tags_editor.tag_filter_menu.visible or not is_visible_in_tree() or _is_dirty or _tags_editor.is_dirty():
		return
	if input_event.is_action_pressed("ui_close"):
		get_viewport().set_input_as_handled()
		hide()
	if input_event is InputEventMouseButton and input_event.pressed and input_event.button_index == MOUSE_BUTTON_LEFT:
		var local = _asset_detail.make_input_local(input_event)
		if not Rect2(Vector2.ZERO, _asset_detail.get_rect().size).has_point(local.position):
			hide()


func _on_asset_received(asset_dict: Dictionary) -> void:
	if _asset_data == null or asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] == _asset_data.asset_id:
		var asset_data = AssetData.new()
		asset_data.populate(asset_dict)
		_populate(asset_data)


func _ready() -> void:
	if Zone.is_host():
		return
	await LoginUI.wait_till_login(get_tree())
	Net.asset_client.asset_received.connect(_on_asset_received)

	var promise = Net.asset_client.get_public_library_tags()
	var tags = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Failed to get tags", promise.get_error_message())
		tags = []
	var mat_tags = tags.filter(func(tag): return tag.get("__t","") == "ThemeTag")
	mat_tags.sort_custom(func(a, b): return a.get("name").naturalnocasecmp_to(b.get("name")) < 0)
	_tags_editor.tag_filter_menu.delete_filter_menu_items()
	for tag in mat_tags:
		_tags_editor.tag_filter_menu.add_filter_menu_item( tag.get("name"), tag)


func _on_download_button_pressed() -> void:
	if _asset_data.file_url.is_empty():
		Notify.error("Download Error", "Cannot download this type of Asset")
		return
	var download_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var asset_name = _asset_data.asset_name
	var ext = _asset_data.file_url.get_extension()
	var file_name = "%s_%s" % [asset_name, _asset_data.asset_id]
	file_name = "%s.%s" % [file_name.validate_filename(), ext]
	var path = download_dir.path_join(file_name)
	var promise: Promise = Net.file_client.save_file(_asset_data.file_url, path, Enums.DownloadPriority.SPACE_OBJECT_HIGH)
	Notify.info("Download", "Download for file: %s has started" % file_name)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Download Error", "Download for file: %s failed" % file_name)
	else:
		Notify.info("Download Success", "File: %s saved in users Downloads directory" % file_name)


func _on_share_button_pressed() -> void:
	if not is_instance_valid(_asset_data):
		return
	var asset_id: String = _asset_data.asset_id
	var base_url: String = ProjectSettings.get_setting("mirror/base_url")
	DisplayServer.clipboard_set(base_url + "/a/" + asset_id)
	Notify.info("Asset URL Copied", base_url + "/a/ " + asset_id)


func _on_copy_button_pressed() -> void:
	if not is_instance_valid(_asset_data):
		return
	var asset_id: String = _asset_data.asset_id
	DisplayServer.clipboard_set(asset_id)
	Notify.info("Asset ID Copied", asset_id)


func _on_script_button_pressed() -> void:
	if not is_instance_valid(_asset_data):
		return
	request_edit_script_asset.emit(_asset_data)
	hide()


func request_info_popup(asset_data: AssetData) -> void:
	if not is_instance_valid(asset_data):
		hide()
		return
	global_position.x = object_selection.global_position.x - _asset_detail.size.x
	global_position.y = get_viewport().get_mouse_position().y
	var viewport_size: Vector2i = get_viewport_rect().size
	_populate(asset_data)
	_set_editable(false)
	show()
	await get_tree().process_frame
	if global_position.y + _asset_detail.size.y > viewport_size.y:
		global_position.y = viewport_size.y - _asset_detail.size.y


func _on_delete_button_pressed():
	var pos: Vector2i = Vector2i(global_position + _asset_detail.size/2.0)
	_delete_dialog.prompt_for_deletion("Asset", pos)


func _on_delete_dialog_confirmed():
	var promise =  Net.asset_client.delete_asset(asset_id)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Asset Delete Error", promise.get_error_message())
	else:
		Notify.info("Asset Deleted", "Asset deleted succesfully.")
		GameUI.instance.creator_ui.asset_browser.on_asset_deleted(true)
		hide()


func _on_asset_name_line_edit_text_changed(new_text):
	_is_dirty = true


func _on_descritpion_text_edit_text_changed():
	_is_dirty = true

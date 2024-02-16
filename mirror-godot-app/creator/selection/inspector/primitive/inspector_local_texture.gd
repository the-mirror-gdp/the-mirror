@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: String)

@export var reset_value: String = ""
@export var current_value: String = "":
	set(value):
		# Allows to reset an image, even though it's same value
		if current_value == value and not value.is_empty():
			return
		current_value = value
		_set_texture(value)
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if drop_area:
			drop_area.disabled = not value
@export var use_full_texture_as_preview: bool = true

var asset_data: AssetData = AssetData.new()

@onready var drop_area: Button = $HBoxContainer/DropArea
@onready var _texture_name = $HBoxContainer/TextureName
@onready var _file_dialog = $FileDialog
@onready var _loading_spinner = $HBoxContainer/DropArea/Preview/LoadingSpinner


func _ready() -> void:
	super()
	drop_area.texture_dropped.connect(_on_texture_dropped)
	Net.asset_client.asset_received.connect(_on_asset_received)
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	asset_data.files_loaded.connect(_asset_files_loaded)
	asset_data.preview_downloaded.connect(_update_preview)
	asset_data.preview_generated.connect(_update_preview)
	_loading_spinner.visible = false


func _set_texture(texture_id: String) -> void:
	if Zone.is_host():
		return
	if texture_id.is_empty():
		_texture_name.text = ""
		drop_area.set_preview(null)
		return
	if FileAccess.file_exists(texture_id):
		var img = Util.load_image(texture_id)
		drop_area.set_preview(img)
	else:
		var asset_json: Dictionary = Net.asset_client.get_asset_json(texture_id)
		if not asset_json.get("assetType", "") in [Enums.ASSET_TYPE.IMAGE, Enums.ASSET_TYPE.TEXTURE]:
			return
		if not asset_json.is_empty():
			_set_texture_data(asset_json)
	if reset_value != "":
		_update_reset_visibility(texture_id != reset_value)
	value_changed.emit(texture_id)


func _set_texture_data(asset_dict: Dictionary) -> void:
	asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	if not use_full_texture_as_preview:
		asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
		drop_area.set_preview(asset_data.preview_texture)
	elif asset_data.get_asset_file_promise().has_result():
		drop_area.set_preview(asset_data.get_asset_file_promise().get_result())

	_texture_name.text = asset_data.asset_name


func _on_asset_received(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] == current_value:
		_set_texture_data(asset_dict)


func _on_asset_deleted(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] == current_value:
		_clear()


func _asset_files_loaded() -> void:
	if not use_full_texture_as_preview:
		asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	elif asset_data.get_asset_file_promise().has_result():
		drop_area.set_preview(asset_data.get_asset_file_promise().get_result())


func _on_texture_dropped(new_value: String) -> void:
	if not enabled:
		return
	current_value = new_value


func _on_reset_button_pressed() -> void:
	_clear()
	value_changed.emit(current_value)


func _on_drop_area_pressed() -> void:
	_file_dialog.popup_centered_ratio()


func _clear() -> void:
	current_value = reset_value
	asset_data = null
	drop_area.set_preview(null)
	_update_reset_visibility(false)


func _on_file_dialog_file_selected(path):
	current_value = path
	_upload_as_texture(path, label_text)


func _upload_as_texture(path: String, param: String) -> void:
	_loading_spinner.show()
	var promise: Promise = await GameUI.creator_ui.asset_browser.create_asset_from_url(
			path,
			Enums.ASSET_TYPE.TEXTURE,
			{"textureImagePropertyAppliesTo": param}
	)
	await promise.wait_till_fulfilled()
	if not promise.is_error():
		current_value = promise.get_result().get("_id")
	_loading_spinner.hide()


func _update_preview() -> void:
	if not use_full_texture_as_preview:
		drop_area.set_preview(asset_data.preview_texture)

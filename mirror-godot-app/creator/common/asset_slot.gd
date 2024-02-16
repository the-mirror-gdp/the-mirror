class_name AssetSlot
extends BaseAssetSlot


const _MAX_UPLOAD_SECONDS: int = 300

@export var is_preview_slot: bool = false

var asset_id: String = ""
var allow_empty_file_url = false
var asset_data: AssetData


@onready var _is_equipable = $Panel/IsEquipable


func _ready() -> void:
	_show_loading()
	_refresh_preview_image()


func can_asset_be_deleted() -> bool:
	if  asset_data.role.is_empty():
		return false
	var asset_role = {"role": asset_data.role}
	var current_user_role = Util.get_role_for_user(asset_role, Net.user_id)
	return asset_data and current_user_role >= Enums.ROLE.MANAGER and asset_id is String


func delete_asset() -> void:
	assert(can_asset_be_deleted())
	Net.asset_client.delete_asset(asset_id)
	asset_deleted.emit()


func edit_asset() -> void:
	request_edit_asset.emit(self)


func edit_script_asset() -> void:
	request_edit_script_asset.emit(self)


func get_asset_name() -> String:
	return asset_data.asset_name if asset_data else ""


func _on_asset_updated(asset_dict: Dictionary) -> void:
	if asset_dict.get("_id", "") == asset_id:
		populate_item_slot(asset_dict)


## Checks the in memory asset data for the preview image and populates the slot.
func _refresh_preview_image() -> void:
	_set_preview_texture_offsets(24)
	if not asset_data:
		return
	if asset_data.preview_texture and preview_texture:
		_show_ready(asset_data.preview_texture)
	# if the file is currently queued for download, show loading
	elif Net.file_client.file_is_queued_or_downloading(asset_data.file_url):
		_show_loading()
	# allow some time for the file to be uploaded, show loading
	elif Time.get_unix_time_from_system() < asset_data.created_at_unix_time + _MAX_UPLOAD_SECONDS:
		_show_loading()
	# allow to show loading screen for asset that doesn't have fle_url
	elif allow_empty_file_url and Net.file_client.file_is_queued_or_downloading(asset_data.thumbnail_url):
		_show_loading()
	# otherwise show invalid.
	elif asset_data.file_url.is_empty():
		_show_invalid()


func _show_ready(ready_texture: Texture) -> void:
	super(ready_texture)
	_update_is_equipable_icon()


func _update_download_icon() -> void:
	if asset_data.type in [Enums.ASSET_TYPE.MAP, Enums.ASSET_TYPE.MATERIAL]:
		_needs_download.visible = false
		return
	_needs_download.visible = not Net.file_client.is_file_downloaded(asset_data.file_url)


func _update_is_equipable_icon() -> void:
	if asset_data:
		_is_equipable.visible = asset_data.is_equipable


func _slot_primary_action() -> void:
	_try_download_asset()


func _try_download_asset() -> void:
	if asset_data.file_url.is_empty() or not _needs_download.visible:
		return
	var has_asset = Net.file_client.is_file_downloaded(asset_data.file_url)
	_needs_download.visible = not has_asset
	if has_asset:
		return
	var promise = asset_data.get_asset_file_promise()
	asset_data.try_download_file(Enums.DownloadPriority.UI_MODELS)
	loading_spinner.show()
	await promise.wait_till_fulfilled()
	loading_spinner.hide()
	_update_download_icon()


func populate_item_slot(asset_dict: Dictionary) -> void:
	asset_id = asset_dict["_id"]
	if asset_data == null:
		asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	if asset_data.type == Enums.ASSET_TYPE.MAP:
		asset_data = AssetDataMap.new()
		asset_data.populate(asset_dict)
		_asset_files_loaded()
	else:
		Util.safe_signal_connect(asset_data.files_loaded, _asset_files_loaded)

	Util.safe_signal_connect(asset_data.preview_generated, _refresh_preview_image)
	Util.safe_signal_connect(asset_data.preview_downloaded, _refresh_preview_image)
	Util.safe_signal_connect(asset_data.files_loaded, _asset_files_loaded)
	asset_data.populate(asset_dict)
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	Util.safe_signal_connect(Net.asset_client.asset_updated, _on_asset_updated)
	Util.safe_signal_connect(Net.asset_client.asset_received, _on_asset_updated)
	_refresh_preview_image()
	_update_download_icon()


func _asset_files_loaded() -> void:
	if not asset_data:
		return
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	_refresh_preview_image()
	_update_is_equipable_icon()


func _get_drag_data(_position) -> Variant:
	if not asset_data:
		return null
	# TODO: Allow for materials dragging when subwindows dragging is fixed:
	# https://github.com/godotengine/godot/issues/62384
	if asset_data.type == Enums.ASSET_TYPE.MATERIAL:
		return null
	elif asset_data.type == Enums.ASSET_TYPE.MESH and asset_data.file_url.is_empty():
		return null
	var drag_preview := TextureRect.new()
	drag_preview.texture = preview_texture.texture
	drag_preview.set_expand_mode(TextureRect.EXPAND_IGNORE_SIZE)
	drag_preview.size = Vector2(64, 64)
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(drag_preview)
	var drag_data: Dictionary = {
		"drag_type": "dragged_asset",
		"string_to_drop": asset_id,
		"asset_id": asset_id,
		"asset_type": asset_data.type,
		"asset_data": asset_data,
		"preview_texture": preview_texture.texture,
		"drag_preview": drag_preview,
	}
	slot_activated.emit(self, true)
	return drag_data


func clear() -> void:
	asset_id = ""
	asset_data = null
	super()


func _on_asset_slot_mouse_entered() -> void:
	super()
	if not asset_data:
		return
	var hover_uri = asset_data.thirdparty_source_home_page_url
	hover_uri = hover_uri.trim_prefix("https://").trim_prefix("http://")
	GameUI.set_hover_tooltip_text(asset_data.asset_name, hover_uri)

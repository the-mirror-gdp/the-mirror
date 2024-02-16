class_name HotbarSlot
extends Panel


signal slot_pressed(slot)
signal slot_updated(slot)

@export var hover_color: Color = Color(1, 1, 1, 1)
@export var selected_color: Color = Color(1, 1, 1, 1)
@export var deselected_color: Color = Color(1, 1, 1, 0)

@onready var preview = $Preview
@onready var _is_equipable = $IsEquipable
@onready var text = $Text
@onready var outline = $Outline

var asset_data: AssetData = null
var asset_dict: Dictionary = {}
var asset_id: String = ""
var asset_type: String = ""
var selected: bool = false


func _ready() -> void:
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func select() -> void:
	outline.self_modulate = selected_color
	selected = true


func deselect() -> void:
	outline.self_modulate = deselected_color
	selected = false


func set_slot(id: String, image: Texture2D = null) -> void:
	asset_id = id
	asset_dict = Net.asset_client.get_asset_json(asset_id)
	if asset_dict.is_empty():
		var asset_promise = Net.asset_client.queue_download_asset(asset_id, Enums.DownloadPriority.SPACE_OBJECT_HIGH)
		var temp_asset_dict = await asset_promise.wait_till_fulfilled()
		if asset_promise.is_error():
			printerr("Failed to get asset: %s" % asset_promise.get_error_message())
			return
		asset_dict = temp_asset_dict
	asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	asset_type = asset_data.type
	if image:
		preview.texture = image
	else:
		asset_data.preview_generated.connect(_refresh_preview_image)
		asset_data.preview_downloaded.connect(_refresh_preview_image)
		asset_data.files_loaded.connect(_asset_files_loaded)
		asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
		asset_data.try_download_file(Enums.DownloadPriority.SPACE_OBJECT_HIGH)
		_refresh_preview_image()
	_update_is_equipable_icon()
	slot_updated.emit(self)


func clear_slot_no_emit() -> void:
	asset_data = null
	asset_id = ""
	asset_type = ""
	preview.texture = null
	_is_equipable.hide()


func clear_slot() -> void:
	clear_slot_no_emit()
	slot_updated.emit(self)


func _update_is_equipable_icon() -> void:
	if asset_data:
		_is_equipable.visible = asset_data.is_equipable


func _asset_files_loaded() -> void:
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	_update_is_equipable_icon()


func _refresh_preview_image() -> void:
	preview.texture = asset_data.preview_texture


func _on_asset_deleted(asset: Dictionary) -> void:
	if asset.get("_id", "") == asset_id:
		clear_slot()


func _can_drop_data(_position, data) -> bool:
	return data is Dictionary and not data.get("asset_id", "").is_empty()


func _drop_data(_position, data) -> void:
	set_slot(data.asset_id, data["preview_texture"])
	slot_pressed.emit(self)


func _get_drag_data(_position) -> Variant:
	if asset_id.is_empty() or Zone.is_in_play_mode():
		return null
	var asset_url = Net.asset_client.get_asset_url(asset_id)
	var is_model_url_known = not asset_url.is_empty()
	var is_model_downloaded = is_model_url_known and Net.file_client.is_file_downloaded(asset_url)
	if not is_model_downloaded:
		return null
	var drag_preview = TextureRect.new()
	drag_preview.texture = preview.texture
	drag_preview.ignore_texture_size = true
	drag_preview.size = Vector2(64, 64)
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(drag_preview)
	var drag_data: Dictionary = {
		"asset_id": asset_id,
		"asset_type": asset_type,
		"preview_texture": preview.texture,
		"drag_preview": drag_preview,
	}
	clear_slot()
	return drag_data


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		slot_pressed.emit(self)


func _on_mouse_entered() -> void:
	outline.self_modulate = hover_color


func _on_mouse_exited() -> void:
	outline.self_modulate = selected_color if selected else deselected_color

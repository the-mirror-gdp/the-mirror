@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: String)

@export var reset_value: String = ""
@export var current_value: String = "":
	set(value):
		current_value = value
		_set_texture(value)
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if drop_area:
			drop_area.disabled = not value

var asset_data: AssetData = AssetData.new()

@onready var drop_area: Button = $HBoxContainer/DropArea
@onready var _texture_name = $HBoxContainer/TextureName


func _ready() -> void:
	super()
	drop_area.texture_dropped.connect(_on_texture_dropped)
	Net.asset_client.asset_received.connect(_on_asset_received)
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	asset_data.files_loaded.connect(_asset_files_loaded)


func _set_texture(texture_id: String) -> void:
	if Zone.is_host():
		return
	if texture_id.is_empty():
		_texture_name.text = ""
		drop_area.set_preview(null)
		return
	var asset_json: Dictionary = Net.asset_client.get_asset_json(texture_id)
	if asset_json.get("assetType", "") != Enums.ASSET_TYPE.IMAGE:
		return
	if not asset_json.is_empty():
		_set_texture_data(asset_json)
	if reset_value != "":
		_update_reset_visibility(texture_id != reset_value)
	value_changed.emit(texture_id)


func _set_texture_data(asset_dict: Dictionary) -> void:
	asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	drop_area.set_preview(asset_data.preview_texture)
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
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)


func _on_texture_dropped(new_value: String) -> void:
	if not enabled:
		return
	current_value = new_value


func _on_reset_button_pressed() -> void:
	_clear()
	value_changed.emit(current_value)


func _on_drop_area_pressed() -> void:
	## TODO: Show a window with textures similar to materials.
	## For now We will show an info message
	Notify.info("Texture", "Please drag-and-drop texture from asset browser.")


func _clear() -> void:
	current_value = reset_value
	asset_data = null
	drop_area.set_preview(null)
	_update_reset_visibility(false)

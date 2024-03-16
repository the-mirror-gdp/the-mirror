@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: String)
signal asset_clicked(asset_data)

@export var reset_value: String = ""
@export var current_value: String = "":
	set(value):
		current_value = value
		_set_asset(value)

var asset_data: AssetData = AssetData.new()

@onready var _preview: TextureRect = %Preview
@onready var _asset_name = $HBoxContainer/AssetName


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return # Can't connect Net signals from a @tool script.
	Net.asset_client.asset_received.connect(_on_asset_received)
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	asset_data.preview_generated.connect(_refresh_preview_image)
	asset_data.preview_downloaded.connect(_refresh_preview_image)


func _set_asset(asset_id: String) -> void:
	if Zone.is_host():
		return
	if asset_id.is_empty():
		_preview.texture = null
		return
	var asset_json: Dictionary = Net.asset_client.get_asset_json(asset_id)
	if not asset_json.is_empty():
		_set_texture_data(asset_json)
	value_changed.emit(asset_id)


func _refresh_preview_image():
	_preview.texture = asset_data.preview_texture


func _set_texture_data(asset_dict: Dictionary) -> void:
	asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	_refresh_preview_image()
	_asset_name.text = asset_data.asset_name


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


func _clear() -> void:
	current_value = reset_value
	asset_data = null
	_preview.texture = null
	_update_reset_visibility(false)


func _on_asset_button_pressed():
	asset_clicked.emit(asset_data)

@tool
extends "inspector_property_base.gd"


signal value_changed(new_value: Array)

@export var reset_value: Array = ["", ""]
@export var current_value: Array = ["", ""]:
	set(value):
		current_value = value
		_set_material(value[0], value[1])
		_update_reset_visibility(value != reset_value)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if _button:
			_button.disabled = not value

var asset_data: AssetData = AssetData.new()
@onready var _button = $HBoxContainer/Button
@onready var _preview = $HBoxContainer/Button/Preview
@onready var _material_name = $HBoxContainer/MaterialName


func _ready() -> void:
	super()
	Net.asset_client.asset_received.connect(_on_asset_received)
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	asset_data.files_loaded.connect(_asset_files_loaded)


func _set_asset_material(material_id: String) -> void:
	var asset_json: Dictionary = Net.asset_client.get_asset_json(material_id)
	if not asset_json.is_empty():
		_set_material_data(asset_json)


func _set_material(type: String, material_id: String) -> void:
	if Zone.is_host():
		return
	if material_id.is_empty():
		_preview.texture = null
		_material_name.text = ""
		value_changed.emit(["", ""])
		return
	# First check if its in material_instance cache
	if type == Enums.MATERIAL_TYPE.INSTANCE and Zone.material_manager.has_material_instance(material_id):
		var mat_promise: Promise = Zone.material_manager.get_material_instance(material_id)
		var mat = mat_promise.get_result() # we can do that, we know it is loaded
		_preview.texture = null
		_material_name.text = mat.instance_name
	else: # material is not known, try loading asset data anyway
		_set_asset_material(material_id)
	if reset_value[1] != "":
		_update_reset_visibility(material_id != reset_value[1])
	value_changed.emit([type, material_id])


func _set_material_data(asset_dict: Dictionary) -> void:
	asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)
	_preview.texture = asset_data.preview_texture
	_material_name.text = asset_data.asset_name


func _on_asset_received(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id") or current_value[0] != Enums.MATERIAL_TYPE.ASSET:
		return
	if asset_dict["_id"] == current_value[1]:
		_set_material_data(asset_dict)


func _on_asset_deleted(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] == current_value[1]:
		_clear()


func _asset_files_loaded() -> void:
	asset_data.try_get_preview_texture(Enums.DownloadPriority.UI_THUMBNAILS)


func _on_reset_button_pressed() -> void:
	_clear()
	value_changed.emit(current_value)


func _on_material_selected():
	var selected_slot = GameUI.creator_ui.material_window.material_browser.get_selected_slot()
	if selected_slot:
		var is_instance = selected_slot is MaterialInstanceSlot
		var material_type = Enums.MATERIAL_TYPE.INSTANCE if is_instance else Enums.MATERIAL_TYPE.ASSET
		var selected_asset: AssetData = selected_slot.asset_data
		current_value = [material_type, selected_asset.asset_id]


func _on_button_pressed():
	GameUI.creator_ui.material_window.popup_centered()
	GameUI.creator_ui.material_window.material_browser.selected_material_slot_changed.connect(_on_material_selected)


func _clear() -> void:
	current_value = reset_value
	asset_data = null
	_preview.texture = null
	_update_reset_visibility(false)

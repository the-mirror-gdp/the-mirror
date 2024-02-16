class_name CategoryPreview
extends Control


signal view_all_pressed(category_name: String, search_text: String, field: String, asset_type: String, tag: String)

const _ASSET_SLOT_SCENE = preload("res://creator/common/asset_slot.tscn")

@export var _category_tag: String = ""
@export var _category_tagsV2: Array = []
@export var _category_name: String = ""
@export var _category_asset_type: String = ""
@export var _category_search_text: String = ""
@export var _category_field: String = ""

var _asset_browser: AssetBrowser
var _asset_slots: Array = []

@onready var _category_name_label: Label = $MarginContainer/VBoxContainer/ViewAllButton/CategoryNameLabel
@onready var _asset_slot_container: GridContainer = $MarginContainer/VBoxContainer/Slots


func setup(asset_browser: AssetBrowser) -> void:
	_asset_browser = asset_browser
	set_asset_slot_count(8)


func set_asset_slot_count(asset_slot_count: int) -> void:
	for i in range(asset_slot_count):
		if i < _asset_slots.size():
			continue
		var asset_slot = _ASSET_SLOT_SCENE.instantiate()
		asset_slot.asset_deleted.connect(_on_asset_deleted)
		asset_slot.request_edit_asset.connect(_asset_browser.edit_slot_asset)
		asset_slot.request_edit_script_asset.connect(_asset_browser.edit_slot_script_asset)
		asset_slot.slot_activated.connect(_asset_browser.asset_slot_activated)
		asset_slot.slot_special_action.connect(_asset_browser.use_slot_asset)
		_asset_slot_container.add_child(asset_slot)
		_asset_slots.append(asset_slot)


func clear() -> void:
	for slot in _asset_slots:
		slot.visible = true
		slot.clear()


func populate(page: Dictionary) -> void:
	var assets_arr: Array = page.get("data", [])
	for i in range(_asset_slots.size()):
		var slot = _asset_slots[i]
		if assets_arr.size() <= i:
			slot.visible = false
			continue
		if not slot is AssetSlot:
			continue
		slot.populate_item_slot(assets_arr[i])


func get_search_text() -> String:
	return _category_search_text


func get_asset_type() -> String:
	return _category_asset_type


func get_field() -> String:
	return _category_field


func get_tag() -> String:
	return _category_tag


func get_search_key() -> String:
	var tagsv2_text = ",".join(_category_tagsV2)
	return "%s_%s_%s_%s_%s" % [_category_search_text, _category_field, _category_asset_type, _category_tag, tagsv2_text]


func _ready() -> void:
	_category_name_label.text = _category_name


func _on_asset_deleted(_asset_slot: BaseAssetSlot) -> void:
	_asset_browser.on_asset_deleted()


func _on_view_all_button_pressed() -> void:
	view_all_pressed.emit(_category_name, _category_search_text, _category_field, _category_asset_type, _category_tag)

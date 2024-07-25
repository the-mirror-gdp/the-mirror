extends InspectorCategoryBase


signal name_updated()

var target_node: SpaceObject

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _name_property = _property_list.get_node(^"Name")
@onready var _locked_property = _property_list.get_node(^"Locked")
@onready var _damageable_property = _property_list.get_node(^"Damageable")
@onready var _asset_property = _property_list.get_node(^"Asset")
@onready var _description = _property_list.get_node(^"Description")
@onready var _creator = _property_list.get_node(^"Creator")

var _creator_id_cache: String

func _ready() -> void:
	refresh()
	super()


func refresh() -> void:
	update_active_fields_by_permissions()
	_name_property.current_value = target_node.get_space_object_name()
	_locked_property.current_value = target_node.locked
	_damageable_property.current_value = target_node.damage_handler_enabled
	_asset_property.current_value = target_node.asset_id
	_description.current_value = target_node.description
	_creator_id_cache = ""
	var creator_data = await target_node.get_creator()
	_creator.button_text = creator_data["name"]
	_creator_id_cache = creator_data["user_id"]


func _on_damageable_value_changed(new_value: bool) -> void:
	var old_value = target_node.damage_handler_enabled
	if old_value != new_value:
		target_node.damage_handler_enabled = new_value
		target_node.queue_update_network_object()


func _on_name_value_changed(new_value: String) -> void:
	var old_name = target_node.get_space_object_name()
	if old_name == new_value:
		return
	target_node.space_object_data["name"] = new_value
	target_node.record_property_changed(&"name", old_name, new_value)
	_inspected_object_updated(target_node)
	name_updated.emit()


func _on_locked_value_changed(new_value: bool) -> void:
	var old_locked = target_node.locked
	if old_locked == new_value:
		return
	target_node.locked = new_value
	target_node.record_property_changed(&"locked", old_locked, new_value)
	_inspected_object_updated(target_node)


func _on_asset_asset_clicked(asset_data):
	GameUI.instance.creator_ui.asset_detail_window.request_info_popup(asset_data)


func _on_description_value_changed(new_value):
	var old_desc = target_node.description
	if old_desc == new_value:
		return
	target_node.description = new_value
	#target_node.space_object_data["description"] = new_value
	target_node.record_property_changed(&"description", old_desc, new_value)
	_inspected_object_updated(target_node)
	name_updated.emit()


func _on_creator_inspector_button_pressed():
	if _creator_id_cache.is_empty():
		Notify.warning("User ID could not be copied", "Please try again in a few seconds")
	else:
		DisplayServer.clipboard_set(_creator_id_cache)
		Notify.info("User ID Copied", _creator_id_cache)

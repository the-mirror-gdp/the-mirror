extends BaseBrowserSection


signal asset_deleted()
signal request_edit_script_instance(script_instance: ScriptInstance)

const _MAX_RECENT_ITEMS: int = 40
const _RECENTS_SAVE_PATH := "user://recent_assets.cfg"
const _ASSET_SLOT_SCENE := preload("res://creator/common/asset_slot.tscn")
const _SCRIPT_ENTITY_SLOT_SCENE := preload("res://creator/asset_inventory/browser/recent/space_script_entity_slot.tscn")

var _recently_used_assets: Array[Dictionary] = []
var _id_to_slot_map: Dictionary = {}

@onready var _slots_flow_container = %SlotsFlowContainer


func _ready() -> void:
	super()
	await GameUI.ui_ready()
	await GameUI.instance.ready
	GameUI.instance.login_ui.login_succeeded.connect(Net.asset_client.get_recent_assets)
	Net.asset_client.asset_received.connect(_on_net_asset_received)
	Net.asset_client.recent_assets_received.connect(_on_net_recent_assets_received)
	Zone.client.disconnected.connect(_on_zone_disconnected)
	var config_file := ConfigFile.new()
	config_file.load(_RECENTS_SAVE_PATH)
	_recently_used_assets = config_file.get_value("recents", "recents", _recently_used_assets)


func show_content() -> void:
	super()
	_regenerate_recents_ui(true)


func reset() -> void:
	_regenerate_recents_ui(false)


func track_recently_used_asset(asset_data: AssetData) -> void:
	var asset_id: String = asset_data.asset_id
	var edited_asset: Dictionary
	for recent_asset in _recently_used_assets:
		if recent_asset["id"] == asset_id:
			recent_asset["asset_data"] = asset_data
			recent_asset["name"] = asset_data.asset_name
			recent_asset["time_utc"] = Time.get_datetime_string_from_system(true)
			edited_asset = recent_asset
			break
	if edited_asset.is_empty():
		# No existing recent edited asset was found, so add a new one.
		edited_asset = {
			"asset_data": asset_data,
			"id": asset_id,
			"name": asset_data.asset_name,
			"time_utc": Time.get_datetime_string_from_system(true),
			"type": "asset",
		}
		# When too many items are in the list, erase the first item (the least recently used).
		if _recently_used_assets.size() >= _MAX_RECENT_ITEMS:
			_erase_least_recently_used()
	else:
		# We found a recent edited asset, but we still want to move it to the back.
		_recently_used_assets.erase(edited_asset)
	# Add the most recent script to the back.
	_recently_used_assets.push_back(edited_asset)
	if _section_holder.visible:
		_regenerate_recents_ui(false)
	_save_recents()


func track_recently_used_space_script(script_instance: ScriptInstance) -> void:
	var script_id: String = script_instance.script_id
	var edited_script: Dictionary
	for recent_asset in _recently_used_assets:
		if recent_asset["id"] == script_id:
			recent_asset["name"] = script_instance.script_name
			recent_asset["script_instance"] = script_instance
			recent_asset["target_node"] = script_instance.target_node
			recent_asset["time_utc"] = Time.get_datetime_string_from_system(true)
			edited_script = recent_asset
			if _id_to_slot_map.has(script_id) and is_instance_valid(_id_to_slot_map[script_id]):
				_id_to_slot_map[script_id].populate_recent_script_entity(recent_asset)
			break
	if edited_script.is_empty():
		# No existing recent edited script was found, so add a new one.
		assert(not script_instance.is_script_asset, "This code path shouln't be used for script assets, only space script entities. Use the asset path instead.")
		edited_script = {
			"id": script_id,
			"name": script_instance.script_name,
			"script_instance": script_instance,
			"script_type": _get_script_type_name(script_instance),
			"target_node": script_instance.target_node,
			"time_utc": Time.get_datetime_string_from_system(true),
			"type": "space_script_entity",
		}
		# When too many items are in the list, erase the first item (the least recently used).
		if _recently_used_assets.size() >= _MAX_RECENT_ITEMS:
			_erase_least_recently_used()
	else:
		# We found a recent edited script, but we still want to move it to the back.
		_recently_used_assets.erase(edited_script)
	# Add the most recent script to the back.
	_recently_used_assets.push_back(edited_script)
	if _section_holder.visible:
		_regenerate_recents_ui(false)
	_save_recents()


func _regenerate_recents_ui(move_existing: bool) -> void:
	var recent_size: int = _recently_used_assets.size()
	var end_offset: int = recent_size - 1
	for i in range(recent_size):
		var recent_asset: Dictionary = _recently_used_assets[end_offset - i]
		var recent_asset_slot: BaseAssetSlot
		var asset_id: String = recent_asset["id"]
		if _id_to_slot_map.has(asset_id):
			recent_asset_slot = _id_to_slot_map[asset_id]
			# Refresh existing asset slots.
			if recent_asset_slot is AssetSlot:
				var asset_json: Dictionary = Net.asset_client.get_asset_json(asset_id)
				if not asset_json.is_empty():
					recent_asset_slot.populate_item_slot(asset_json)
		else:
			recent_asset_slot = _generate_new_slot(recent_asset)
		if move_existing:
			_slots_flow_container.move_child(recent_asset_slot, i)


func _generate_new_slot(recent_asset: Dictionary) -> BaseAssetSlot:
	var type: String = recent_asset["type"]
	var slot: BaseAssetSlot
	if type == "asset":
		slot = _ASSET_SLOT_SCENE.instantiate()
		_slots_flow_container.add_child(slot)
		var asset_id: String = recent_asset["id"]
		var asset_json: Dictionary = Net.asset_client.get_asset_json(asset_id)
		if asset_json.is_empty():
			slot.populate_item_slot({
				"_id": asset_id,
				"name": recent_asset["name"],
			})
		else:
			slot.populate_item_slot(asset_json)
	elif type == "space_script_entity":
		slot = _SCRIPT_ENTITY_SLOT_SCENE.instantiate()
		_slots_flow_container.add_child(slot)
		slot.populate_recent_script_entity(recent_asset)
		slot.request_edit_script_instance.connect(_on_request_edit_script_instance)
	slot.asset_deleted.connect(_on_asset_deleted)
	slot.request_edit_asset.connect(_asset_browser.edit_slot_asset)
	slot.request_edit_script_asset.connect(_asset_browser.edit_slot_script_asset)
	slot.slot_activated.connect(_asset_browser.asset_slot_activated)
	slot.slot_special_action.connect(_asset_browser.use_slot_asset)
	_id_to_slot_map[recent_asset["id"]] = slot
	if slot.get_parent() != _slots_flow_container:
		_slots_flow_container.add_child(slot)
	return slot


func _erase_least_recently_used() -> void:
	var least_recently_used: Dictionary = _recently_used_assets[0]
	var least_recently_used_id: String = least_recently_used["id"]
	if _id_to_slot_map.has(least_recently_used_id):
		var slot = _id_to_slot_map[least_recently_used_id]
		_slots_flow_container.remove_child(slot)
		slot.clear()
		slot.queue_free()
		_id_to_slot_map.erase(least_recently_used_id)
	_recently_used_assets.remove_at(0)


func _save_recents() -> void:
	var config_file := ConfigFile.new()
	var recents_without_objects: Array[Dictionary] = []
	for recent in _recently_used_assets:
		recent = recent.duplicate(false)
		recent.erase("asset_data")
		recent.erase("script_instance")
		recent.erase("target_node")
		recents_without_objects.append(recent)
	config_file.set_value("recents", "recents", recents_without_objects)
	config_file.save(_RECENTS_SAVE_PATH)


func _get_script_type_name(script_instance: ScriptInstance) -> String:
	if script_instance is GDScriptInstance:
		return "GDScript"
	if script_instance is VisualScriptInstance:
		return "MirrorVisualScript"
	assert(false)
	return "Error" # Unreachable.


func _on_asset_deleted(asset_slot: BaseAssetSlot) -> void:
	assert(asset_slot is AssetSlot, "This should only happen for actual asset slots.")
	_asset_browser.on_asset_deleted(false)
	var asset_id: String = asset_slot.asset_id
	for recent_asset in _recently_used_assets:
		if recent_asset["id"] == asset_id:
			_recently_used_assets.erase(recent_asset)
			break
	asset_deleted.emit(self)


func _on_net_asset_received(asset_data: Dictionary) -> void:
	if asset_data.has("_id"):
		var asset_id: String = asset_data["_id"]
		if _id_to_slot_map.has(asset_id):
			var slot: AssetSlot = _id_to_slot_map[asset_id]
			slot.populate_item_slot(asset_data)


func _on_net_recent_assets_received(recent_assets_data: Array) -> void:
	for recent_asset_data in recent_assets_data:
		_insert_net_recent_asset(recent_asset_data)
	for recent_asset in _recently_used_assets:
		var recent_id: String = recent_asset["id"]
		if recent_asset["type"] == "asset":
			Net.asset_client.queue_download_asset(recent_id)
		elif recent_asset["type"] == "space_script_entity":
			recent_asset["script_entity"] = Net.script_client.get_script_entity(recent_id)
		else:
			breakpoint
	if _section_holder.visible:
		_regenerate_recents_ui(false)
	_save_recents()


func _insert_net_recent_asset(recent_asset_data: Dictionary) -> void:
	var asset_id: String = recent_asset_data["_id"]
	var asset_name: String = recent_asset_data["name"]
	for recent_asset in _recently_used_assets:
		if recent_asset["id"] == asset_id:
			recent_asset["name"] = asset_name
			return
	# If we have not returned yet, we are inserting a new item.
	var recent_asset: Dictionary = {
		"id": asset_id,
		"name": asset_name,
		"time_utc": Time.get_datetime_string_from_system(true),
		"type": "asset",
	}
	_recently_used_assets.push_back(recent_asset)
	# When too many items are in the list, erase the first item (the least recently used).
	if _recently_used_assets.size() > _MAX_RECENT_ITEMS:
		_erase_least_recently_used()


func _on_request_edit_script_instance(script_instance: ScriptInstance) -> void:
	request_edit_script_instance.emit(script_instance)


func _on_zone_disconnected() -> void:
	for recent in _recently_used_assets:
		recent.erase("script_instance")
		recent.erase("target_node")

extends VBoxContainer

const _INSTANCEABLE_ASSET_TYPES = [
	Enums.ASSET_TYPE.MESH,
	Enums.ASSET_TYPE.MAP,
	Enums.ASSET_TYPE.AUDIO
]

var _context_menu: PanelContainer = null
var _asset_slot: AssetSlot = null
var _creator_ui: CreatorUI

@onready var _create_instance_button: Button = $CreateInstance
@onready var _edit_script_button: Button = $EditScript
@onready var _delete_asset_button: Button = $DeleteAsset
@onready var _delete_dialog = $DeleteDialog


func setup(context_menu: PanelContainer, creator_ui: CreatorUI) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(hide)
	_creator_ui = creator_ui


func open(asset_slot: AssetSlot) -> void:
	_asset_slot = asset_slot
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	var can_create: bool = space_role >= Enums.ROLE.CONTRIBUTOR
	_create_instance_button.visible = _asset_slot.asset_data.type in _INSTANCEABLE_ASSET_TYPES and can_create
	_edit_script_button.visible = _asset_slot.asset_data.type == Enums.ASSET_TYPE.SCRIPT
	_delete_asset_button.visible = asset_slot.can_asset_be_deleted()
	show()


func _on_edit_asset_pressed() -> void:
	_context_menu.close()
	if is_instance_valid(_asset_slot):
		_asset_slot.edit_asset()


func _on_edit_script_pressed() -> void:
	_context_menu.close()
	if is_instance_valid(_asset_slot):
		_asset_slot.edit_script_asset()


func _on_copy_asset_id_pressed() -> void:
	_context_menu.close()
	if not is_instance_valid(_asset_slot):
		return
	var asset_id: String = _asset_slot.asset_data.asset_id
	DisplayServer.clipboard_set(asset_id)
	Notify.info("Asset ID Copied", asset_id)


func _on_copy_asset_url_pressed() -> void:
	_context_menu.close()
	if not is_instance_valid(_asset_slot):
		return
	var asset_id: String = _asset_slot.asset_data.asset_id
	var base_url: String = ProjectSettings.get_setting("mirror/base_url")
	DisplayServer.clipboard_set(base_url + "/a/" + asset_id)
	Notify.info("Asset URL Copied", base_url + "/a/ " + asset_id)


func _on_delete_asset_pressed() -> void:
	_context_menu.close()
	if is_instance_valid(_asset_slot):
		var pos: Vector2i = Vector2i(450, _asset_slot.global_position.y)
		_delete_dialog.prompt_for_deletion("Asset", pos)


func _on_delete_dialog_confirmed() -> void:
	if is_instance_valid(_asset_slot):
		_asset_slot.delete_asset()


func _on_create_instance_pressed():
	_context_menu.close()
	if not is_instance_valid(_asset_slot):
		return
	var asset_id = _asset_slot.asset_data.asset_id
	if asset_id.is_empty():
		return
	if _asset_slot.asset_data.type == Enums.ASSET_TYPE.MAP:
		if _asset_slot.asset_data is AssetDataMap:
			Zone.Scene.update_heightmap(_asset_slot.asset_data)
		else:
			printerr("Internal error: AssetData object is not an AssetDataMap")
		return
	var properties: Dictionary = {
		"asset": asset_id,
		"position": Serialization.vector3_to_array(Vector3.ZERO),
		"rotation": Serialization.vector3_to_array(Vector3.ZERO),
		"scale": Serialization.vector3_to_array(Vector3.ONE),
	}
	var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
	Zone.client_send_create_space_object(properties, receipt)
	Analytics.track_event_client(AnalyticsEvent.TYPE.OBJECT_PLACED)

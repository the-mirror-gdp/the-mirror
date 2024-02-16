class_name RecentScriptEntitySlot
extends BaseAssetSlot


signal request_edit_script_instance(script_instance: ScriptInstance)

const _GDSCRIPT_ICON = preload("res://script/gd/editor/icons/text_script.svg")
const _VISUAL_SCRIPT_ICON = preload("res://script/visual/editor/icons/visual_script.svg")

var recent_script: Dictionary
var recent_script_instance: ScriptInstance
var script_entity_id: String = ""
var script_entity: Dictionary


func populate_recent_script_entity(in_recent_script: Dictionary) -> void:
	recent_script = in_recent_script
	if recent_script.has("script_instance"):
		if is_instance_valid(recent_script["script_instance"]):
			recent_script_instance = recent_script["script_instance"]
		else:
			recent_script.erase("script_instance")
	script_entity_id = recent_script["id"]
	script_entity = Net.script_client.get_script_entity(script_entity_id)
	if recent_script["script_type"] == "GDScript":
		_show_ready(_GDSCRIPT_ICON)
	else:
		_show_ready(_VISUAL_SCRIPT_ICON)
	_needs_download.hide()


func get_asset_name() -> String:
	if script_entity.has("name"):
		return script_entity["name"]
	return recent_script["name"]


func edit_script_entity() -> void:
	if is_instance_valid(recent_script_instance):
		request_edit_script_instance.emit(recent_script_instance)
		return
	if script_entity.is_empty():
		script_entity = Net.script_client.get_script_entity(script_entity_id)
		if script_entity.is_empty():
			Notify.error("Can't Edit Script", "Unable to load this space script.")
			return
	if recent_script["script_type"] == "GDScript":
		recent_script_instance = GDScriptInstance.new()
	else:
		recent_script_instance = VisualScriptInstance.new()
	recent_script_instance.script_id = script_entity_id
	recent_script_instance.setup_script_data(script_entity)
	request_edit_script_instance.emit(recent_script_instance)


func _slot_primary_action() -> void:
	edit_script_entity()


func _on_asset_slot_mouse_entered() -> void:
	super()
	GameUI.set_hover_tooltip_text(recent_script["name"], "Space Script")

extends InspectorCategoryBase


@onready var _asset_name = $Properties/MarginContainer/PropertyList/AssetName
@onready var _property_list = $Properties/MarginContainer/PropertyList

var target_node: SpaceObject:
	set(value):
		if is_instance_valid(target_node):
			Util.safe_signal_disconnect(target_node.node_property_changed, _on_property_changed)
		target_node = value
		Util.safe_signal_connect(target_node.node_property_changed, _on_property_changed)


func _on_property_changed(object_node: SpaceObject, property_name: StringName, old_value: Variant, new_value: Variant) -> void:
	if object_node != target_node:
		return
	if property_name == &"asset_id":
		var asset_json: Dictionary = Net.asset_client.get_asset_json(new_value)
		if asset_json.is_empty():
			Notify.warning("Unexpected State", "Unexpected state encountered. No new asset data for loaded object")
			return
		_asset_name.current_value = asset_json.get("name")


func _ready() -> void:
	if is_instance_valid(target_node):
		_asset_name.current_value = target_node.asset_data.asset_name
	super()


func _force_map_mode():
	var map_event = InputEventAction.new()
	map_event.action = &"map_mode_toggle"
	map_event.pressed = true
	Input.parse_input_event(map_event)

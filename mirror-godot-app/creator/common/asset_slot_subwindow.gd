class_name AssetSlotSubwindow
extends AssetSlot


func _on_asset_slot_mouse_entered() -> void:
	if not asset_data:
		return
	var hover_uri = asset_data.thirdparty_source_home_page_url
	hover_uri = hover_uri.trim_prefix("https://").trim_prefix("http://")
	if hover_uri.is_empty():
		tooltip_text = asset_data.asset_name
	else:
		tooltip_text = "%s (%s)" % [asset_data.asset_name, hover_uri]

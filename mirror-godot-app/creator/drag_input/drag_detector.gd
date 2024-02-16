extends Control


signal select_asset_id(asset_id: String)

@onready var selector = $DragSelector

var hovering_game_view: bool = false


func _on_drag_asset_placement_mouse_entered() -> void:
	hovering_game_view = true
	if not get_viewport().gui_is_dragging():
		return
	var drag_data = get_viewport().gui_get_drag_data()
	if drag_data.has("asset_id") and drag_data.has("asset_type") and drag_data["asset_type"] != "":
		select_asset_id.emit(drag_data["asset_id"])
		var drag_preview: Control = drag_data.get("drag_preview")
		if is_instance_valid(drag_preview) and drag_data["asset_type"] != "IMAGE":
			drag_preview.hide()


func _on_drag_asset_placement_mouse_exited() -> void:
	hovering_game_view = false
	if not get_viewport().gui_is_dragging():
		return
	select_asset_id.emit("")
	var drag_data = get_viewport().gui_get_drag_data()
	var drag_preview: Control = drag_data.get("drag_preview")
	if is_instance_valid(drag_preview):
		drag_preview.show()

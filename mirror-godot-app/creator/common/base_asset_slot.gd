class_name BaseAssetSlot
extends Control


signal asset_deleted(asset_slot: BaseAssetSlot)
signal request_edit_asset(asset_slot: BaseAssetSlot)
signal request_edit_script_asset(asset_slot: BaseAssetSlot)
signal slot_activated(asset_slot: BaseAssetSlot, select_asset_id: bool)
signal slot_special_action(asset_slot: BaseAssetSlot)

var _is_selected: bool = false

@onready var preview_texture: TextureRect = $Panel/Preview
@onready var loading_spinner: TextureRect = $Panel/LoadingSpinner
@onready var _invalid_icon: TextureRect = $Panel/InvalidIcon
@onready var _hover_state: Panel = $Panel/HoverState
@onready var _active_state: Panel = $Panel/ActiveState
@onready var _needs_download: TextureRect = $Panel/NeedsDownload


func clear() -> void:
	preview_texture.set_texture(null)
	_show_loading()


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	if not is_selected:
		_active_state.hide()
		return
	if _hover_state.visible:
		_hover_state.hide()
	if _active_state.visible:
		_active_state.hide()
	else:
		_active_state.show()
		_slot_primary_action()


func get_asset_name() -> String:
	assert(false, "This method must be overridden in derived classes.")
	return ""


func _show_ready(ready_texture: Texture) -> void:
	preview_texture.texture = ready_texture
	_set_preview_texture_offsets(4)
	if _invalid_icon:
		_invalid_icon.hide()
	if loading_spinner:
		loading_spinner.hide()


func _show_loading() -> void:
	if _invalid_icon:
		_invalid_icon.hide()
	if loading_spinner:
		loading_spinner.show()


func _show_invalid() -> void:
	if _invalid_icon:
		_invalid_icon.show()
	if loading_spinner:
		loading_spinner.hide()


func _set_preview_texture_offsets(offset: int) -> void:
	if not preview_texture:
		return
	preview_texture.offset_left = offset
	preview_texture.offset_top = offset
	preview_texture.offset_right = -offset
	preview_texture.offset_bottom = -offset


func _slot_primary_action() -> void:
	assert(false, "This method must be overridden in derived classes.")


func _on_asset_slot_gui_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton and input_event.double_click:
		slot_special_action.emit(self)
	elif input_event.is_action_pressed(&"primary_action"):
		_slot_primary_action()
	elif input_event.is_action_released(&"primary_action"):
		slot_activated.emit(self, false)
	elif input_event.is_action_released(&"secondary_action"):
		GameUI.creator_ui.open_context_menu(self)


func _on_asset_slot_mouse_entered() -> void:
	if not _is_selected:
		_hover_state.show()


func _on_asset_slot_mouse_exited() -> void:
	if not _is_selected:
		_hover_state.hide()
	GameUI.hide_hover_tooltip_text()

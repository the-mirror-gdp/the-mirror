extends Control


signal hotbar_asset_selected(asset_id: String)

@onready var slots_parent = $PanelContainer/HBoxContainer/MarginContainer/Slots

var _creator_ui: CreatorUI = null
var _current_game_mode: ZoneClass.ZONE_MODE = ZoneClass.ZONE_MODE.EDIT
var _slots: Array = []
var _currently_selected_slot: HotbarSlot = null
var _last_build_mode_tool_slot: HotbarSlot = null
var _persistent_hotbar: bool = false


func setup(creator_ui: CreatorUI) -> void:
	_creator_ui = creator_ui


func _ready() -> void:
	for slot in slots_parent.get_children():
		var index = slot.get_index()
		_slots.append(slot)
		slot.get_node(^"Text").text = str(index + 1)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.slot_updated.connect(_on_slot_updated)
	if _slots.size() > 1:
		select_slot(_slots[0])
	else:
		push_error("We have no slots on ready for hotbar.gd")
	Zone.script_network_sync.variables_ready.connect(_space_vars_loaded)
	Zone.script_network_sync.global_variable_changed.connect(_space_var_updated)
	Zone.mode_changed.connect(_on_mode_changed)


func _input(input_event: InputEvent) -> void:
	if not visible or (Zone.is_in_edit_mode() and _creator_ui.is_mouse_needed_for_ui()):
		return
	# This is a bit messy, but works for now.
	if input_event is InputEventKey and input_event.pressed:
		var not_allowed_keys: Array = ["tool_1", "tool_2", "tool_3", "tool_4"]
		for key in not_allowed_keys:
			if Input.is_action_pressed(key):
				return
		match input_event.keycode:
			KEY_1:
				select_slot(_slots[0])
			KEY_2:
				select_slot(_slots[1])
			KEY_3:
				select_slot(_slots[2])
			KEY_4:
				select_slot(_slots[3])
			KEY_5:
				select_slot(_slots[4])
			KEY_6:
				select_slot(_slots[5])
			KEY_7:
				select_slot(_slots[6])
			KEY_8:
				select_slot(_slots[7])
			KEY_9:
				select_slot(_slots[8])


func add_equipable(asset_id: String) -> void:
	var chosen_slot: HotbarSlot = null
	for slot in _slots:
		if slot.asset_id.is_empty():
			chosen_slot = slot
			break
	if not chosen_slot:
		chosen_slot = _currently_selected_slot if _currently_selected_slot else _slots[0]
	chosen_slot.set_slot(asset_id)


func clear_equipables() -> void:
	for slot in _slots:
		slot.clear_slot_no_emit()
	_refresh_selected_slot()


func clear_equipables_no_emit() -> void:
	for slot in _slots:
		slot.clear_slot_no_emit()


func set_equipables(items: Dictionary = {}) -> void:
	if Zone.is_host() or not PlayerData.has_local_player():
		return
	clear_equipables_no_emit()
	for slot in _slots:
		var index = slot.get_index()
		if items.has(index):
			slot.set_slot(items[index])


func save_equipables() -> void:
	if Zone.is_host() or not PlayerData.has_local_player():
		return
	var items: Dictionary = {}
	for slot in _slots:
		if not slot.asset_id.is_empty():
			items[slot.get_index()] = slot.asset_id
	var local_player: Player = PlayerData.get_local_player()
	var data_store_value: String = "saved_build_items"
	if _current_game_mode == ZoneClass.ZONE_MODE.PLAY:
		data_store_value = "saved_play_items"
	local_player.save_equipables.rpc_id(Zone.SERVER_PEER_ID, data_store_value, items)


func load_equipables() -> void:
	if Zone.is_host() or not PlayerData.has_local_player():
		return
	var local_player: Player = PlayerData.get_local_player()
	match _current_game_mode:
		ZoneClass.ZONE_MODE.EDIT:
			set_equipables(local_player.data_store.get_value("saved_build_items", {}))
			select_slot(_last_build_mode_tool_slot)
		ZoneClass.ZONE_MODE.PLAY:
			if _persistent_hotbar:
				set_equipables(local_player.data_store.get_value("saved_play_items", {}))
			else:
				clear_equipables_no_emit()
			_last_build_mode_tool_slot = _currently_selected_slot
			select_slot(_slots[0])


func select_slot(selected_slot: Panel) -> void:
	if not selected_slot:
		return
	for slot in _slots:
		slot.deselect()
	selected_slot.select()
	_currently_selected_slot = selected_slot
	hotbar_asset_selected.emit(_currently_selected_slot.asset_id)


func _refresh_selected_slot() -> void:
	if _currently_selected_slot == null:
		hotbar_asset_selected.emit("")
	else:
		hotbar_asset_selected.emit(_currently_selected_slot.asset_id)


func _on_mode_changed(new_zone_mode: ZoneClass.ZONE_MODE) -> void:
	_current_game_mode = new_zone_mode
	load_equipables()


func _on_slot_pressed(slot: HotbarSlot) -> void:
	select_slot(slot)


func _on_slot_updated(slot: HotbarSlot) -> void:
	if slot == _currently_selected_slot:
		hotbar_asset_selected.emit(slot.asset_id)
	save_equipables()


func _set_persistent_hotbar() -> void:
	var persistent = Zone.script_network_sync.get_global_variable("persistent_hotbar")
	if persistent is bool:
		_persistent_hotbar = persistent
		return
	# Default to false.
	Zone.script_network_sync.set_global_variable("persistent_hotbar", false)


func _space_var_updated(variable_name: String, _variable_value: Variant) -> void:
	if variable_name == "persistent_hotbar":
		_set_persistent_hotbar()


func _space_vars_loaded() -> void:
	_set_persistent_hotbar()

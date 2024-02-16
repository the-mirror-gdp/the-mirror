extends Node


func _ready() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_GLOBAL_MENU):
		queue_free()
		return
	_setup_space_menu()
	_setup_asset_menu()
	_setup_edit_menu()
	_setup_tools_menu()
	on_exit_space()


func on_enter_space() -> void:
	DisplayServer.global_menu_clear("_main")
	# This code assumes the user always has edit permissions.
	DisplayServer.global_menu_add_submenu_item("_main", "Asset", "_main/Asset")
	DisplayServer.global_menu_add_submenu_item("_main", "Space", "_main/Space")
	DisplayServer.global_menu_add_submenu_item("_main", "Edit", "_main/Edit")
	DisplayServer.global_menu_add_submenu_item("_main", "Tools", "_main/Tools")
	DisplayServer.global_menu_set_item_disabled("_main/Asset", 0, false)


func on_exit_space() -> void:
	DisplayServer.global_menu_clear("_main")
	DisplayServer.global_menu_add_submenu_item("_main", "Asset", "_main/Asset")
	DisplayServer.global_menu_set_item_disabled("_main/Asset", 0, true)


func _setup_space_menu() -> void:
	DisplayServer.global_menu_add_item("_main/Space", "Disconnect", _disconnect, _disconnect)
	DisplayServer.global_menu_add_item("_main/Space", "Preview Mode", _action, _action, &"preview_mode_toggle")


func _disconnect(_tag) -> void:
	Zone.client.quit_to_main_menu()


func _setup_asset_menu() -> void:
	DisplayServer.global_menu_add_item("_main/Asset", "Asset Inventory", _action, _action, &"asset_inventory", KEY_Q)
	DisplayServer.global_menu_add_item("_main/Asset", "Upload New Asset", _action, _action, &"asset_upload", KEY_U)
	DisplayServer.global_menu_add_submenu_item("_main/Asset", "Open Folder", "_main/Asset/Files")
	DisplayServer.global_menu_add_item("_main/Asset/Files", "My Primitive Models", _open_folder_at_path, _open_folder_at_path, Util.get_primitive_models_directory_path())
	DisplayServer.global_menu_add_item("_main/Asset/Files", "All Downloaded GLBs", _open_folder_at_path, _open_folder_at_path, Util.get_files_directory_path())


func _open_folder_at_path(path_tag) -> void:
	Util.open_folder_at_path(path_tag)


func _setup_edit_menu() -> void:
	DisplayServer.global_menu_add_item("_main/Edit", "Undo", _action, _action, &"ui_undo", KEY_MASK_META + KEY_Z, 0)
	DisplayServer.global_menu_set_item_disabled("_main/Edit", 0, true)
	DisplayServer.global_menu_add_item("_main/Edit", "Redo", _action, _action, &"ui_redo", KEY_MASK_META + KEY_Y, 1)
	DisplayServer.global_menu_set_item_disabled("_main/Edit", 1, true)
	DisplayServer.global_menu_add_separator("_main/Edit")
	DisplayServer.global_menu_add_item("_main/Edit", "Duplicate", _action, _action, &"action_duplicate", KEY_MASK_META + KEY_D)
	DisplayServer.global_menu_add_item("_main/Edit", "Copy", _action, _action, &"action_copy", KEY_MASK_META + KEY_C)
	DisplayServer.global_menu_add_item("_main/Edit", "Paste", _action, _action, &"action_paste", KEY_MASK_META + KEY_V)
	DisplayServer.global_menu_add_item("_main/Edit", "Deselect", _action, _action, &"action_deselect", KEY_ESCAPE)
	DisplayServer.global_menu_add_item("_main/Edit", "Delete", _action, _action, &"action_delete", KEY_DELETE)


func _setup_tools_menu() -> void:
	DisplayServer.global_menu_add_item("_main/Tools", "Primitive Builder", _action, _action, &"primitive_model_builder_toggle", KEY_P)
	#DisplayServer.global_menu_add_item("_main/Tools", "Terrain Editor", _action, _action, &"terrain_mode_toggle", KEY_T)
	DisplayServer.global_menu_add_item("_main/Tools", "Map Editor", _action, _action, &"map_mode_toggle")
	DisplayServer.global_menu_add_item("_main/Tools", "Teams Menu", _action, _action, &"team_menu_toggle", KEY_M)
	DisplayServer.global_menu_add_separator("_main/Tools")
	DisplayServer.global_menu_add_item("_main/Tools", "Build Mode", _action, _action, &"build_mode_toggle", KEY_B)
	DisplayServer.global_menu_add_item("_main/Tools", "Inspect Mode", _action, _action, &"inspect_mode_toggle", KEY_I)
	DisplayServer.global_menu_add_item("_main/Tools", "Camera FPS/TPS", _action, _action, &"player_change_camera", KEY_C)
	DisplayServer.global_menu_add_separator("_main/Tools")
	DisplayServer.global_menu_add_item("_main/Tools", "Tool 1", _action, _action, &"tool_1", KEY_MASK_META + KEY_1)
	DisplayServer.global_menu_add_item("_main/Tools", "Tool 2", _action, _action, &"tool_2", KEY_MASK_META + KEY_2)
	DisplayServer.global_menu_add_item("_main/Tools", "Tool 3", _action, _action, &"tool_3", KEY_MASK_META + KEY_3)
	DisplayServer.global_menu_add_item("_main/Tools", "Tool 4", _action, _action, &"tool_4", KEY_MASK_META + KEY_4)
	DisplayServer.global_menu_add_item("_main/Tools", "Tool 5", _action, _action, &"tool_5", KEY_MASK_META + KEY_5)


func _action(tag: StringName) -> void:
	var a = InputEventAction.new()
	a.action = tag
	a.pressed = true
	Input.parse_input_event(a)

extends VBoxContainer


signal teleport_local_player_near_point(teleport_position: Vector3)

@onready var _rename_button: Button = $Rename
@onready var _lock_button: Button = $Lock
@onready var _unlock_button: Button = $Unlock
@onready var _enable_physics_button: Button = $EnablePhysics
@onready var _disable_physics_button: Button = $DisablePhysics
@onready var _properties: Button = $Properties
@onready var _script: Button = $Script
@onready var _delete: Button = $Delete
@onready var _copy_material = $CopyMaterial
@onready var _paste_material = $PasteMaterial

var _context_menu: PanelContainer = null
var _creator_ui: CreatorUI
var _rename_popup: PanelContainer = null
var _space_object: SpaceObject = null
var _teleport_position: Vector3 = Vector3.ZERO

var _copied_material: MirrorMaterial = null
var _last_clicked_surface: MaterialSelector.SpaceObjectSelectedMaterial = null


func setup(context_menu: PanelContainer, creator_ui: CreatorUI, rename_popup: PanelContainer) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(_clear)
	_creator_ui = creator_ui
	_rename_popup = rename_popup


func open(object: SpaceObject, hit_position: Vector3) -> void:
	set_visible(true)
	_space_object = object
	_teleport_position = hit_position
	var can_edit = Util.can_edit_object_in_space(_space_object)
	_rename_button.visible = can_edit
	_lock_button.visible = not _space_object.locked and can_edit
	_unlock_button.visible = _space_object.locked and can_edit
	_delete.visible = can_edit
	var is_multiple: bool = _is_object_selected(_space_object) and _creator_ui.scene_hierarchy.get_selected_nodes().size() > 1
	var is_audio: bool = _space_object.asset_data.type == Enums.ASSET_TYPE.AUDIO
	_enable_physics_button.set_visible(_space_object.physics_body_type == "Static" and not is_audio and can_edit)
	_disable_physics_button.set_visible(_space_object.physics_body_type == "Dynamic" and not is_audio and can_edit)
	_properties.set_visible(not is_multiple)
	_script.set_visible(not is_multiple and can_edit)
	# we have to do that on open, to be sure to get proper data related to object under the cursor in time of click
	_record_material(object)


func _record_material(object: SpaceObject):
	_last_clicked_surface = null
	_copy_material.set_visible(false)
	_paste_material.set_visible(false)
	var surface_selected = await GameplayTools.material_selector.get_raycasted_surface_data()
	if (surface_selected == null or surface_selected.space_object != object):
		return
	_last_clicked_surface = surface_selected
	var mat =  surface_selected.mesh.get_surface_override_material(surface_selected.surface_id)
	_paste_material.set_visible(is_instance_valid(_copied_material))
	if not mat is MirrorMaterial:
		return
	_copy_material.set_visible(true)


func _clear() -> void:
	set_visible(false)
	_space_object = null


func _on_focus_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	if not _is_object_selected(_space_object):
		_creator_ui.select_object(_space_object)
	if _creator_ui.is_game_mode(GameMode.Mode.BUILD):
		_creator_ui.focus_build_mode_camera()
	_context_menu.close()


func _set_physics_body_type(value: String) -> void:
	if not is_instance_valid(_space_object):
		return
	if _is_object_selected(_space_object):
		for object in _creator_ui.scene_hierarchy.get_selected_nodes():
			if object is SpaceObject and object.asset_data.type == Enums.ASSET_TYPE.MESH:
				object.physics_body_type = value
	else:
		_space_object.physics_body_type = value
	_context_menu.close()


func _set_locked(value: bool) -> void:
	if not is_instance_valid(_space_object):
		return
	if _is_object_selected(_space_object):
		for object in _creator_ui.scene_hierarchy.get_selected_nodes():
			if object is SpaceObject:
				object.locked = value
	else:
		_space_object.locked = value
	_context_menu.close()


func _on_lock_pressed() -> void:
	_set_locked(true)


func _on_unlock_pressed() -> void:
	_set_locked(false)


func _on_enable_physics_pressed() -> void:
	_set_physics_body_type("Dynamic")


func _on_disable_physics_pressed() -> void:
	_set_physics_body_type("Static")


func _on_properties_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	_creator_ui.select_object(_space_object)
	_creator_ui.object_selection.set_inspector_tab(0)
	_context_menu.close()


func _on_script_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	_creator_ui.select_object(_space_object)
	_creator_ui.object_selection.set_inspector_tab(1)
	_context_menu.close()


func _on_delete_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	if _is_object_selected(_space_object):
		_creator_ui.object_selection.delete_objects()
	else:
		Zone.send_data_to_server([Packet.TYPE.DELETE_SPACE_OBJECT, _space_object.space_object_data])
	_context_menu.close()


func _on_copy_id_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	DisplayServer.clipboard_set(_space_object.name)
	Notify.info("SpaceObject ID Copied", _space_object.name)
	_context_menu.close()


func _is_object_selected(object: Node) -> bool:
	return _creator_ui.selection_helper.is_object_selected(object.get_instance_id())


func _on_rename_pressed() -> void:
	if not is_instance_valid(_space_object):
		return
	if _is_object_selected(_space_object):
		_rename_popup.open(_creator_ui.scene_hierarchy.get_selected_nodes())
	else:
		_rename_popup.open([_space_object])
	_context_menu.close()


func _on_teleport_pressed() -> void:
	teleport_local_player_near_point.emit(_teleport_position)
	_context_menu.close()


func _on_copy_material_pressed():
	if not is_instance_valid(_last_clicked_surface):
		_copied_material = null
		return
	var mat = _last_clicked_surface.mesh.get_surface_override_material(_last_clicked_surface.surface_id)
	if not mat is MirrorMaterial:
		_copied_material = null
		return
	_copied_material = mat
	Notify.info("Material Copied", mat.resource_name)
	_context_menu.close()


func _on_paste_material_pressed():
	if not is_instance_valid(_copied_material) or not _copied_material is MirrorMaterial:
		return
	if not is_instance_valid(_space_object) or not is_instance_valid(_last_clicked_surface):
		return
	_space_object.set_surface_material(_last_clicked_surface.mesh, _last_clicked_surface.surface_id, _copied_material.id, _copied_material.is_asset_based)
	Notify.info("Material Pasted", _copied_material.resource_name)
	_context_menu.close()

extends "raycast_camera.gd"


var _camera_manager: CameraManager
var _gizmo: Gizmo


func setup(camera_manager: CameraManager, gizmo: Gizmo) -> void:
	clear_current(false)
	# Depend on the player and camera manager to get asset information.
	_camera_manager = camera_manager
	# Depend on the gizmo to get snap information.
	_gizmo = gizmo


## Process method calls every frame.
## Updates the mouse raycast and placement indicator.
## Virtual
func update(_delta: float) -> void:
	if not current:
		return
	update_mouse_raycast()
	if Input.is_action_just_released(&"primary_action") and _camera_manager.is_selected_asset_placeable:
		_place_previewed_asset()


## Handles input for object placement and object inspection.
func handle_asset_placement_input(input_event: InputEvent) -> void:
	if not has_input_to_raycast_from_camera(input_event):
		return
	# If the Gizmo raycast succeeds, stop, we're done.
	if interact_raycast_layer(input_event, ["GIZMO"]):
		return
	if (
		not GameUI.instance.creator_ui.is_edit_mode(Enums.EDIT_MODE.Asset)
		and not GameUI.instance.creator_ui.is_edit_mode(Enums.EDIT_MODE.Map)
	):
		return
	select_object()


## Selects an object in the world space.
## An object is detected via a raycast collision.
## 'Selects' the object that is collided if possible.
func select_object() -> void:
	var object = raycast_dict.get("collider", null)
	var multi_select_pressed = Input.is_action_pressed(&"object_multi_select")
	if not is_instance_valid(object):
		if not multi_select_pressed:
			GameUI.instance.creator_ui.clear_selection()
		return
	if object is ModelPrimitive:
		GameUI.instance.creator_ui.raycast_hit_object(object)
		return
	var space_object = Util.get_space_object(object)
	if space_object:
		if space_object.asset_type == Enums.ASSET_TYPE.MAP or space_object.locked:
			if not multi_select_pressed:
				GameUI.instance.creator_ui.clear_selection()
			return
		GameUI.instance.creator_ui.raycast_hit_object(space_object)


## Places the currently selected asset in the world.
func _place_previewed_asset() -> void:
	var asset_id = _camera_manager.get_placement_preview_asset_id()
	if asset_id.is_empty():
		return
	var placement_transform = get_placement_transform_or_null()
	if placement_transform == null:
		return
	var properties: Dictionary = {
		"asset": asset_id,
		"position": Serialization.vector3_to_array(placement_transform.origin),
		"rotation": Serialization.vector3_to_array(placement_transform.basis.get_euler()),
		"scale": Serialization.vector3_to_array(placement_transform.basis.get_scale()),
	}
	var receipt: Dictionary = Zone.receipt_create(PlayerData.get_local_user_id(), true)
	Zone.client_send_create_space_object(properties, receipt)
	if not Input.is_action_pressed(&"object_multi_select"):
		_camera_manager.set_placement_preview_asset_id("")
	Analytics.track_event_client(AnalyticsEvent.TYPE.OBJECT_PLACED)


func get_placement_transform_or_null(): # -> Transform3D?
	var placement_transform := Transform3D.IDENTITY
	if not raycast_dict.has("position"):
		return null
	placement_transform.origin = raycast_dict.position
	# Calculate the rotation Basis of the placement transform.
	var target = raycast_dict.normal
	var back = placement_transform.origin.direction_to(global_position)
	if abs(target.dot(back)) > 0.99:
		# Edge case handling: Don't allow these vectors to be colinear.
		back = global_transform.basis.y
	if GameUI.instance.creator_ui.is_gizmo_type(Enums.GIZMO_TYPE.GRAB):
		placement_transform.basis = _basis_looking_at_y(target, back)
	# Calculate the position. If Gizmo snap is enabled, snap to the snap step.
	placement_transform = placement_transform.translated_local(_camera_manager.placement_offset)
	if _gizmo.is_snap_enabled():
		var snap: Vector3 = _gizmo.get_snap_step(Enums.GIZMO_TYPE.MOVE) * Vector3.ONE
		placement_transform.origin = placement_transform.origin.snapped(snap)
	return placement_transform


## Like Godot's Basis.looking_at except the target points the Y vector,
## and the secondary direction is back instead of up. NOTE: This excludes
## the safety checks found in the engine, be sure to only use valid input!
func _basis_looking_at_y(target: Vector3, back: Vector3) -> Basis:
	var v_y: Vector3 = target.normalized()
	var v_x: Vector3 = v_y.cross(back).normalized()
	var v_z: Vector3 = v_x.cross(v_y)
	return Basis(v_x, v_y, v_z)

extends Node
class_name GameUI

## Why does this class exist? Well you may have guessed that we have VR support.
## We need UI in the VR instance of the game.
## In VR we require the Node Layout to be:
## - SubViewport -> GameUI.instance
## In non VR mode we require the Node Layout to be:
## - GameUI.instance
## To clarify in short, this code sucks because it fixes an arch issue and bypasses it.

## We don't always want every bit of UI in a Sub Viewport or all the VR nodes applied to the game when VR isn't needing to be active.
## So this file will dynamically allow you to configure under ANY node type so this allows VR/AR implementation to be clean
## While also allowing us to completely turn it off in the menu should we desire this.

static var _readonly_singleton_instance = preload("res://ui/game/game_ui.tscn")
static var _readonly_vr_menu = preload("res://player/vr/vr_controller_menu.tscn")
static var _internal_instance = null # this is the actual data
static var _root_node = null
static var _vr_decided = false
static var _sub_viewport: SubViewport = null
static var _vr_controller_menu: VRControllerMenu = null
static var instance:
	get:
		assert(_internal_instance != null)
		assert(_internal_instance.get_parent() != null)
		return _internal_instance
	set(v):
		push_error("You can't re-assign the Game UI singleton.")


static func get_sub_viewport() -> SubViewport:
	await ui_ready()
	return _sub_viewport


static func ui_ready() -> void:
	while not is_instance_valid(_internal_instance) or _internal_instance.get_parent() == null or _root_node == null:
		await _root_node.get_tree().create_timer(0.1).timeout
	await _internal_instance.wait_till_ready()
	if not _vr_decided:
		await VRManager.vr_decision_made


static var _last_state: bool = false
static var lockout = false
static func set_vr_mouse_state(state: bool) -> void:
	if lockout:
		return
	lockout = true
	if _sub_viewport == null or state == _last_state:
		return # this is non VR mode and is okay to ignore this setting then
	print("VR GameUI status changed: ", state)
	_last_state = state
	_vr_controller_menu.set_vr_mouse_input_state(state)
	await _root_node.get_tree().create_timer(45.0).timeout
	_last_state = false
	_vr_controller_menu.set_vr_mouse_input_state(false)
	print("Removing menu")
	# remove VRControllerMenu node (not required)
	_root_node.remove_child(_vr_controller_menu)
	_vr_controller_menu.queue_free()

	print("Removing subviewport")
	# remove subviewport
	_sub_viewport.remove_child(_internal_instance)
	_root_node.add_child(_internal_instance)
	_sub_viewport.get_parent().remove_child(_sub_viewport)
	_sub_viewport.queue_free()


## Called when booting the app when we know if the app is VR or non-VR
static func setup_game_ui(root_node: Node, is_vr: bool):
	assert(root_node)
	_root_node = root_node
	if _internal_instance == null:
		# read the node, and add it to the root of the game
		_internal_instance = _readonly_singleton_instance.instantiate()
		## Again if you didn't read the comments further up, we need a SubViewport
		## We don't need it in non VR Mode.
		## If you need a 3D viewport use Zone.get_viewport() as I updated all code to do this
		## Read here on why we're doing this: https://docs.godotengine.org/en/latest/tutorials/xr/openxr_composition_layers.html#setting-up-the-subviewport
		if is_vr:
			## Add the player controller for the menu
			var vr_player_for_menu: VRControllerMenu = _readonly_vr_menu.instantiate()
			root_node.add_child(vr_player_for_menu)
			## Add the subviewport for the VR Headset's UI
			_sub_viewport = SubViewport.new()
			_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			#_sub_viewport.disable_3d = true
			_sub_viewport.transparent_bg = false
			#_sub_viewport.msaa_2d = Viewport.MSAA_4X
			#_sub_viewport.msaa_3d = Viewport.MSAA_4X
			_sub_viewport.size = Vector2i(1920, 1050)
			# _sub_viewport.use_xr = true
			var viewport: Viewport = Zone.get_viewport()
			viewport.use_xr = true
			viewport.vrs_mode = Viewport.VRS_XR

			#viewport.fsr_sharpness = 0.25
			#viewport.scaling_3d_scale = 0.80
			viewport.vrs_update_mode = Viewport.VRS_UPDATE_ALWAYS
			viewport.msaa_2d = Viewport.MSAA_2X
			viewport.msaa_3d = Viewport.MSAA_2X
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			_sub_viewport.set_name("VRSubViewport")
			_sub_viewport.add_child(_internal_instance)
			root_node.add_child(_sub_viewport)
			_vr_controller_menu = vr_player_for_menu
		else:
			root_node.add_child(_internal_instance)
	VRManager.vr_decision_made.emit()
	_vr_decided = true

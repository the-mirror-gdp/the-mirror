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

static var readonly_singleton_instance = preload("res://ui/game/game_ui.tscn")
static var _internal_instance = null # this is the actual data
static var _root_node = null
static var _vr_decided = false
static var _sub_viewport: SubViewport = null
static var instance:
	get:
		await ui_ready()
		assert(_internal_instance != null)
		assert(_internal_instance.get_parent() != null)
		return _internal_instance
	set(v):
		push_error("You can't re-assign the Game UI singleton.")


static func get_sub_viewport() -> SubViewport:
	await ui_ready()
	return _sub_viewport


static func ui_ready() -> void:
	if _internal_instance != null and _internal_instance.get_parent() != null:
		return
	while _internal_instance.get_parent() == null or _root_node == null:
		await _root_node.get_tree().create_timer(0.1).timeout
	await _internal_instance.wait_till_ready()
	if not _vr_decided:
		await VRManager.vr_decision_made


## Called when booting the app when we know if the app is VR or non-VR
static func setup_game_ui(root_node: Node, is_vr: bool):
	_root_node = root_node
	if _internal_instance == null:
		# read the node, and add it to the root of the game
		_internal_instance = readonly_singleton_instance.instantiate()
		## Again if you didn't read the comments further up, we need a SubViewport
		## We don't need it in non VR Mode.
		## If you need a 3D viewport use Zone.get_viewport() as I updated all code to do this
		## Read here on why we're doing this: https://docs.godotengine.org/en/latest/tutorials/xr/openxr_composition_layers.html#setting-up-the-subviewport
		if is_vr:
			_sub_viewport = SubViewport.new()
			_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			_sub_viewport.disable_3d = true
			_sub_viewport.transparent_bg = true
			_sub_viewport.set_name("VRSubViewport")
			_sub_viewport.add_child.call_deferred(_internal_instance)
			root_node.add_child.call_deferred(_sub_viewport)
		else:
			root_node.add_child.call_deferred(_internal_instance)
	while _internal_instance.get_parent() == null:
		await root_node.get_tree().create_timer(0.1).timeout
	VRManager.vr_decision_made.emit()
	_vr_decided = true

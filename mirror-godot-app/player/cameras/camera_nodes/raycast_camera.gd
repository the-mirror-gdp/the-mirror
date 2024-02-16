extends Camera3D


const GIZMO_COLLISION_LAYER_INDEX: int = 10

var raycast_dict: Dictionary = {}


var _raycastable_layers: Array = [
	&"STATIC",
	&"KINEMATIC",
	&"CHARACTER",
	&"DYNAMIC",
	&"TRIGGER",
	&"GIZMO",
]

func _process(_delta: float) -> void:
	if not current:
		return
	update_mouse_raycast()


func handle_asset_placement_input(input_event: InputEvent) -> void:
	if has_input_to_raycast_from_camera(input_event):
		var __ = interact_raycast_layer(input_event, ["GIZMO"])


## Input method for the raycast camera. Returns true if this isn't the
## camera, the input is not applicable, or the method handles the input.
## Returns false if the input still needs to be handled.
func has_input_to_raycast_from_camera(input_event: InputEvent) -> bool:
	if not current:
		return false # If this isn't the current camera, stop.
	if not input_event.is_action_pressed(&"primary_action"):
		return false # If this isn't the primary action (left mouse click), stop.
	if Input.is_action_pressed(&"secondary_action"):
		return false # If the secondary action is held, skip raycast interaction.
	return true


## Performs a raycast on a layer and calls `click_raycast_event` on the
## collider it hits. Returns true if it hit something, false otherwise.
func interact_raycast_layer(input_event: InputEvent, collide_with_object_layers: Array = []) -> bool:
	var ray_collision_dict = get_mouse_raycast(collide_with_object_layers)
	if ray_collision_dict.has("collider"):
		var collider = ray_collision_dict.collider
		if collider.has_method(&"click_raycast_event"):
			collider.click_raycast_event(input_event)
		return true
	return false


## Updates the mouse raycast and sets the raycast info dictionary for use.
## Called every frame from process method.
func update_mouse_raycast():
	var ignored_bodies: Array = []
	if not Zone.is_host() and PlayerData.has_local_player():
		ignored_bodies.append(PlayerData.get_local_player())
	raycast_dict = get_mouse_raycast(_raycastable_layers, ignored_bodies)


## Get a raycast collision dictionary from the current mouse position
## By default, it collides with Collision Layer 1
##
## Used in update_mouse_raycast() to update the placement_indicator position
func get_mouse_raycast(collide_with_object_layers: Array = [], ignored_bodies: Array = []) -> Dictionary:
	return Util.get_mouse_raycast(self, get_viewport(), collide_with_object_layers, ignored_bodies)


func get_camera_raycast_dict_but_ignore(ignored_bodies) -> Dictionary:
	return get_mouse_raycast(_raycastable_layers, ignored_bodies)

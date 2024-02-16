extends Node3D


@export var camera_manager: Node = null


var _voxel_viewer: VoxelViewer


func _ready() -> void:
	assert(is_instance_valid(camera_manager) and camera_manager is CameraManager)
	assert(multiplayer.get_unique_id() != 0)
	set_physics_process(false)
	var is_player_local = is_multiplayer_authority() and Zone.is_client()
	if is_player_local:
		# can be created only on a client which is controlling related player
		_create_viewer(multiplayer.get_unique_id())

		# server one needs to be created after the client one to be sure client one is there to
		# receive information from the server
		_create_viewer.rpc_id(Zone.SERVER_PEER_ID, multiplayer.get_unique_id())
		GameplaySettings.view_distance_changed.connect( update_view_distance_and_rpc )


@rpc("call_remote", "any_peer", "reliable")
func _create_viewer(in_peer: int):
	var is_server = Zone.is_host()
	var is_client = not is_server
	var view_distance = 96 if is_server else 300
	var is_using_server_camera = ProjectSettings.get_setting("mirror/use_server_camera", false)
	var master_viewer = multiplayer.get_unique_id() == in_peer or is_server
	if not master_viewer:
		return

	_voxel_viewer = VoxelViewer.new()
	_voxel_viewer.name = &"VoxelViewer"
	_voxel_viewer.requires_data_block_notifications = is_server
	_voxel_viewer.requires_collisions = true
	_voxel_viewer.requires_visuals = true if is_client else is_using_server_camera
	_voxel_viewer.view_distance = view_distance
	_voxel_viewer.set_network_peer_id(in_peer)
	add_child(_voxel_viewer)
	set_physics_process(true)

@rpc("call_remote", "any_peer", "reliable")
func update_view_distance(new_value):
	_voxel_viewer.view_distance = new_value


# popping_out_view_distance means that is the maximum distance we could seed
# popping_in_view_distance means the minimum distance we should start seeing terrain
# That difference allow to keep seeing terrain farther, but without the server overheating
func update_view_distance_and_rpc(popping_out_view_distance):
	# Normal call
	update_view_distance(popping_out_view_distance)
	# RPC call
	var popping_in_view_distance = min(
		96,
		popping_out_view_distance
	)
	update_view_distance.rpc_id(Zone.SERVER_PEER_ID, popping_in_view_distance)


func _physics_process(_delta: float) -> void:
	_voxel_viewer.global_position = camera_manager.get_head_global_transform().origin


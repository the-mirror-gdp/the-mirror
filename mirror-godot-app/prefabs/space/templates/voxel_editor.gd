class_name VoxelEditor
extends VoxelTerrain


const _VOXELS_DB_FILE_PATH = "voxels.db"
const _VOXEL_CLOUD_SAVE_COOLDOWN_SECONDS = 15.0
const _MINIMUM_BLOCKS_RECEIVED_THRESHOLD: int = 2400

@export var ghost_preview_prefab: PackedScene

@onready var voxel_tool: VoxelToolTerrain = self.get_voxel_tool() as VoxelToolTerrain

var _ghost_preview: Node3D

var _serializer: VoxelBlockSerializer = VoxelBlockSerializer.new()
var _voxel_buffer: VoxelBuffer = VoxelBuffer.new()
var _next_cloud_save_time: float
var _stream_is_setup: bool
var _blocks_received: int = 0
var _is_mouse_held = false
var _last_mouse_velocity: Vector2
#var _material_paint_brushes: Array
var _material_index = 0
var _is_editing = false


func _ready() -> void:
	_create_ghost_preview()
	GameUI.creator_ui.edit_mode_changed.connect(self._on_creator_ui_edit_mode_changed)


func _process(_delta: float) -> void:
	_process_terrain_cloud_save()
	_ghost_preview.set_enabled(_is_editing)

	if _is_mouse_held:
		_handle_terrain_edit()


func _unhandled_input(input_event) -> void:
	if input_event is InputEventMouseMotion:
		_update_ghost_preview()
	if Input.is_action_pressed(&"secondary_action"):
		return
	if _is_editing and input_event.is_action(&"primary_action"):
		_is_mouse_held = input_event.pressed


## runtime update check for saving the terrain to the cloud infrequently.
func _process_terrain_cloud_save() -> void:
	if _next_cloud_save_time <= 0:
		return

	var now = Time.get_unix_time_from_system()
	if _next_cloud_save_time <= now:
		_save_cloud_voxel_db()


func server_stream_is_ready() -> bool:
	return _stream_is_setup


func initial_load_complete() -> bool:
	return _blocks_received > _MINIMUM_BLOCKS_RECEIVED_THRESHOLD


func count_block_received() -> void:
	if not initial_load_complete():
		_blocks_received += 1


## sets up the stream to load the voxel data from disk.
## connects to the terrain download signal.
func setup_stream() -> void:
	var db_stream: VoxelStreamSQLite = VoxelStreamSQLite.new()
	db_stream.database_path = _VOXELS_DB_FILE_PATH
	self.stream = db_stream

	Util.safe_signal_connect(Net.zone_client.space_voxels_received, _zone_client_space_voxels_received)


## Receives and loads the downloaded terrain UI and resets the stream.
func _zone_client_space_voxels_received(file_data: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(_VOXELS_DB_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_buffer(file_data)
	file.flush()

	setup_stream()
	_stream_is_setup = true


func _get_operation_params() -> Dictionary:
	var params = {}
	var raycast_dict = _get_mouse_raycast()
	if not raycast_dict.has("position"):
		return params

	var terrain_tool = GameUI.creator_ui.terrain_tool
	params.mode = terrain_tool.brush_mode
	params.radius = terrain_tool.brush_size
	params.sdf_strength = terrain_tool.brush_strength
	params.position = raycast_dict.position
	params.texture_index = _material_index
	return params


func _handle_terrain_edit() -> void:
	assert(Zone.is_client())
	var op_params: Dictionary = _get_operation_params()
	if op_params.is_empty():
		return

	if _last_mouse_velocity == Input.get_last_mouse_velocity():
		op_params.position = _ghost_preview.position

	if not _can_apply_voxel(op_params.radius, op_params.position):
		return
	_server_receive_voxel_operation.rpc_id(Zone.SERVER_PEER_ID, op_params.mode, op_params.radius, op_params.position,
		op_params.sdf_strength, op_params.texture_index)


@rpc("call_remote", "any_peer", "reliable")
func _server_receive_voxel_operation(mode, radius, pos, strength, texture_index) -> void:
	assert(Zone.is_host())
	var now = Time.get_unix_time_from_system()
	_apply_voxel(mode, radius, pos, strength, texture_index)
	save_modified_blocks()
	_next_cloud_save_time = now + _VOXEL_CLOUD_SAVE_COOLDOWN_SECONDS


func _on_data_block_entered(info: VoxelDataBlockEnterInfo):
	assert(Zone.is_host())
	var block_position = info.get_position()
	var peer_id = info.get_network_peer_id()
	var data = _serialize_voxel_data(info.get_voxels())
	_client_receive_voxel_data.rpc_id(peer_id, block_position, data)


@rpc("call_remote", "authority", "reliable")
func _client_receive_voxel_data(in_position, data):
	assert(Zone.is_client())
	count_block_received()
	try_set_block_data(in_position, _deserialize_voxel_block_data(data))


func _on_area_edited(origin, size):
	assert(Zone.is_host())
	var peers_in_area = get_viewer_network_peer_ids_in_area(origin, size)
	if peers_in_area.size() > 0:
		_voxel_buffer.create(size.x, size.y, size.z)
		voxel_tool.copy(origin, _voxel_buffer,  (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES) | (1 << VoxelBuffer.CHANNEL_WEIGHTS))
		var serialized_voxel_buffer = _serialize_voxel_data(_voxel_buffer)
		for peer_id in peers_in_area:
			_client_voxel_buffer_received.rpc_id(peer_id, origin, serialized_voxel_buffer)


@rpc("call_remote", "authority", "reliable")
func _client_voxel_buffer_received(pos, data):
	assert(Zone.is_client())
	var block_data = _deserialize_voxel_block_data(data as PackedByteArray)
	voxel_tool.paste(pos, block_data, (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES) | (1 << VoxelBuffer.CHANNEL_WEIGHTS))


func _deserialize_voxel_block_data(data: PackedByteArray):
	var _block_serializer: VoxelBlockSerializer = VoxelBlockSerializer.new()
	var stream_peer_buffer = StreamPeerBuffer.new()
	var voxel_buffer = VoxelBuffer.new()
	stream_peer_buffer.data_array = data
	_block_serializer.deserialize(stream_peer_buffer, voxel_buffer, data.size(), true)
	return voxel_buffer


func _serialize_voxel_data(voxel_buffer_data: VoxelBuffer) -> PackedByteArray:
	var stream_peer_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	var _size = _serializer.serialize(stream_peer_buffer, voxel_buffer_data, true)
	return stream_peer_buffer.data_array


@rpc("call_remote", "any_peer", "reliable")
func server_clear_voxel_modifications() -> void:
	assert(Zone.is_host())
	var space_id: String = Zone.space["_id"]
	Net.zone_client.clear_space_voxels(space_id)
	_zone_client_space_voxels_received(PackedByteArray())


## Server saves the voxel terrain database to the cloud.
func _save_cloud_voxel_db() -> void:
	_next_cloud_save_time = 0
	_save_voxel_data_to_disk()
	_send_disk_voxel_data_to_cloud()


func _save_voxel_data_to_disk() -> void:
	save_modified_blocks()
	stream.flush_cache()


func _send_disk_voxel_data_to_cloud() -> void:
	var voxels_bytes: PackedByteArray = TMFileUtil.load_file_bytes(_VOXELS_DB_FILE_PATH)
	var space_id = Zone.space["_id"]
	Net.zone_client.update_space_voxels(space_id, voxels_bytes)


func _can_apply_voxel(radius: float, pos: Vector3) -> bool:
	var area_box: AABB = AABB(pos, Vector3.ONE * radius)
	if _ghost_preview.check_object_collision():
		return false
	return voxel_tool.is_area_editable(area_box)


func _apply_voxel(mode: int, radius: float, pos: Vector3, strength = 1.0, texture_index = 0) -> void:
	voxel_tool.sdf_strength = strength
	voxel_tool.texture_opacity = strength
	voxel_tool.texture_index = texture_index
	if mode == 2:
		voxel_tool.do_flatten_sphere(pos + Vector3.UP * 0.1, radius + 0.1, radius, Vector3.DOWN)
	else:
		voxel_tool.mode = mode
		voxel_tool.do_sphere(pos, radius)


func _update_ghost_preview() -> void:
	if not _is_editing:
		return

	var op_params: Dictionary = _get_operation_params()
	if op_params.is_empty():
		_ghost_preview.set_enabled(false)
		return

	_ghost_preview.position = op_params.position


func _create_ghost_preview() -> void:
	_ghost_preview = ghost_preview_prefab.instantiate()
	self.add_child(_ghost_preview)



## Gets the mouse raycast info dictionary.
func _get_mouse_raycast() -> Dictionary:
	var viewport = PlayerData.get_local_player().camera_get_viewport()
	var camera = viewport.get_camera_3d()
	if not is_instance_valid(camera):
		return {}
	var result = Util.get_mouse_raycast(camera, viewport)

	return result


func set_material_params(index, _material_data):
	_material_index = index


func _on_creator_ui_edit_mode_changed(new_mode) -> void:
	_is_editing = new_mode == Enums.EDIT_MODE.Terrain

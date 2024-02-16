extends Node3D


const _AUDIO_SPRITE_SCENE: PackedScene = preload("res://gameplay/space_object/audio/audio_sprite.tscn")
const _PLACEHOLDER_SCENE: PackedScene = preload("res://gameplay/space_object/placeholder/placeholder.tscn")

const _PREVIEWABLE_ASSET_TYPES: PackedStringArray = [
	Enums.ASSET_TYPE.MESH,
	Enums.ASSET_TYPE.AUDIO,
]

var _camera_manager: CameraManager
var _current_model: Node
var _placement_preview_asset_id: String = ""


func setup(camera_manager: CameraManager) -> void:
	_camera_manager = camera_manager


func _process(_delta: float) -> void:
	if _current_model == null:
		visible = false
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return
	var t = camera.get_placement_transform_or_null()
	if t == null:
		visible = false
	else:
		visible = true
		transform = t


func set_placement_preview_asset_id(asset_id: String) -> void:
	_placement_preview_asset_id = asset_id
	_camera_manager.is_selected_asset_placeable = false
	var instanced_asset: Object = await _instantiate_preview_asset(asset_id)
	_camera_manager.placement_offset = _calculate_placement_offset(instanced_asset)
	_set_preview_model(instanced_asset)
	if instanced_asset == null:
		return
	_camera_manager.is_selected_asset_placeable = true
	Cursors.set_cursor(Cursors.GRAB)


func _instantiate_preview_asset(asset_id: String) -> Object:
	if asset_id.is_empty():
		return null
	var asset_dict: Dictionary = Net.asset_client.get_asset_json(asset_id)
	var asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	if not asset_data.type in _PREVIEWABLE_ASSET_TYPES:
		return null
	var file_promise = asset_data.get_asset_file_promise()
	if not file_promise.has_result():
		if asset_data.type == Enums.ASSET_TYPE.MESH:
			_camera_manager.placement_offset = Vector3.UP
			_camera_manager.is_selected_asset_placeable = true
			Cursors.set_cursor(Cursors.GRAB)
			_set_preview_model(_PLACEHOLDER_SCENE.instantiate())
		# If its already requested, it will return old Promise
		asset_data.try_download_file(Enums.DownloadPriority.UI_MODELS)
		await file_promise.wait_till_fulfilled()
		if _placement_preview_asset_id != asset_id:
			# The selected asset could be changed after await
			return null
	var file_result = file_promise.get_result()
	assert(file_result is Object)
	if file_result.has_meta(&"MIRROR_equipable"):
		return null
	return file_result


func _calculate_placement_offset(instanced_asset: Object) -> Vector3:
	if instanced_asset == null:
		return Vector3.ZERO
	if instanced_asset is Node3D:
		return -TMNodeUtil.get_local_bottom_point(instanced_asset)
	return Vector3.UP


func _set_preview_model(for_file: Object) -> void:
	if _current_model:
		remove_child(_current_model)
		_current_model.queue_free()
		_current_model = null
	if for_file == null:
		return
	if for_file is Node:
		_current_model = for_file.duplicate()
		# Disable all motion imported from GLTF on the placement preview.
		for jbody in Util.recursive_find_nodes_of_type(_current_model, JBody3D):
			jbody.set_layer_name(&"")
			if jbody.is_dynamic() or jbody.is_kinematic():
				jbody.body_mode = JBody3D.BodyMode.STATIC
	elif for_file is AudioStream:
		_current_model = _AUDIO_SPRITE_SCENE.instantiate()
	else:
		printerr("Unable to set placement preview model for file %s." % str(for_file))
		return
	add_child(_current_model)

class_name ExtraNodeVisualEditor
extends Node3D


var _target_space_object: SpaceObject
var _target_model_parent: Node3D
var _target_extra_node_dict: Dictionary
var _parent_transform: Transform3D
var _last_transform: Transform3D
var _frames_to_update_space_object: int = 0


func _process(delta: float) -> void:
	if not is_instance_valid(_target_space_object):
		queue_free()
		return
	if _target_space_object.extra_node_dicts.has(_target_extra_node_dict):
		process_update_queue()
		return
	# The SpaceObject's extra node list no longer includes the dict we
	# were editing. Let's try to recover by finding one with the same name.
	for dict in _target_space_object.extra_node_dicts:
		if dict["name"] == _target_extra_node_dict["name"]:
			setup_visual_editor(_target_space_object, dict)
			return
	# If we got here, what we were editing has disappeared. Time to self-destruct.
	queue_free()


func setup_visual_editor(target_space_object: SpaceObject, extra_node_dict: Dictionary) -> void:
	_target_space_object = target_space_object
	_target_extra_node_dict = extra_node_dict
	_target_model_parent = _target_space_object.get_model_node_by_name(extra_node_dict["parent"])
	_parent_transform = TMNodeUtil.get_relative_transform(_target_space_object, _target_model_parent)
	_last_transform = _parent_transform * _gltf_to_transform(extra_node_dict)
	transform = _last_transform


func process_update_queue() -> void:
	var changed: bool = process_editor_updates()
	if changed:
		# When an extra node changes, updating can be expensive and intrusive.
		# It does things like re-create the nodes, kick players off seats, and
		# re-create the script events. So let's try to be on the chill side,
		# only updating after some inactivity (50 frames should do it).
		_frames_to_update_space_object = 50
	_frames_to_update_space_object -= 1
	if _frames_to_update_space_object == 0:
		write_data_and_update_space_object()


func process_editor_updates() -> bool:
	var changed: bool = false
	if not _last_transform.is_equal_approx(transform):
		_last_transform = transform
		changed = true
	return changed


func write_data_and_update_space_object() -> void:
	_write_values_to_target()
	_target_space_object.update_extra_nodes()


func _write_values_to_target() -> void:
	var relative: Transform3D = _parent_transform.affine_inverse() * _last_transform
	_transform_to_gltf(relative, _target_extra_node_dict)


func _gltf_to_transform(gltf_dict: Dictionary) -> Transform3D:
	var ret := Transform3D.IDENTITY
	if gltf_dict.has("translation"):
		ret.origin = Serialization.array_to_vector3(gltf_dict["translation"])
	if gltf_dict.has("rotation"):
		var quat: Array = gltf_dict["rotation"]
		ret.basis = Basis(Quaternion(quat[0], quat[1], quat[2], quat[3]))
	if gltf_dict.has("scale"):
		ret.basis = ret.basis * Basis.from_scale(Serialization.array_to_vector3(gltf_dict["scale"]))
	return ret


func _transform_to_gltf(transf: Transform3D, gltf_dict: Dictionary):
	if not transf.origin.is_zero_approx():
		gltf_dict["translation"] = Serialization.vector3_to_array(transf.origin)
	var quat: Quaternion = transf.basis.get_rotation_quaternion()
	if not quat.is_equal_approx(Quaternion.IDENTITY):
		gltf_dict["rotation"] = [quat.x, quat.y, quat.z, quat.w]
	var scl: Vector3 = transf.basis.get_scale()
	if not scl.is_equal_approx(Vector3.ONE):
		gltf_dict["scale"] = Serialization.vector3_to_array(scl)

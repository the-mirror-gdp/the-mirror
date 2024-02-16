class_name MaterialManager
extends Node


signal material_instance_created(material_id)
signal material_instance_removed(material_id)

var _space_material_instances: Dictionary = {}
var _space_material_assets: Dictionary = {}


func _ready() -> void:
	_ready_deffered.call_deferred() # make sure that Net dependency is loaded


func _ready_deffered() -> void:
	Net.material_client.material_instance_get.connect(_on_material_instance_update_received)
	Zone.client.disconnected.connect(_on_zone_disconnected)


func has_material_instance(material_id: String) -> bool:
	return (_space_material_instances.has(material_id)
		and _space_material_instances[material_id].has_result())


func get_material_asset(material_id: String) -> Promise:
	if not _space_material_assets.has(material_id) or _space_material_assets[material_id].is_error():
		var promise = Promise.new()
		_space_material_assets[material_id] = promise
		var asset_dict = Net.asset_client.get_asset_json(material_id)
		var material = MirrorMaterial.new()
		material.is_asset_based = true
		material.resource_name = material_id
		material.id = material_id
		if not asset_dict.is_empty():
			material.setup(asset_dict)
			promise.set_result(material)
			return promise
		var net_promise = Net.asset_client.queue_download_asset(material_id)
		net_promise.connect_func_to_fulfill(func():
			if net_promise.is_error():
				promise.set_error("Error downloading asset material: %s" % net_promise.get_error_message())
				return
			material.setup(net_promise.get_result())
			promise.set_result(material)
		)
	return _space_material_assets.get(material_id)


func get_material_instance(material_id: String) -> Promise:
	if not _space_material_instances.has(material_id) or _space_material_instances[material_id].is_error():
		var promise = Promise.new()
		_space_material_instances[material_id] = promise
		var space_id = Zone.space.get("_id", null)
		if space_id == null:
			promise.set_error("Errror retriving space id")
			return
		var net_promise = Net.material_client.get_material_instance(space_id, material_id, true)
		net_promise.connect_func_to_fulfill(func():
			if net_promise.is_error():
				promise.set_error(net_promise.get_error_message())
				return
			var material = MirrorMaterial.new()
			material.id = net_promise.get_result().get("_id")
			material.instance_name = net_promise.get_result().get("name")
			material.is_asset_based = false
			material.setup(net_promise.get_result())
			material.resource_name = material_id
			material.id = material_id
			promise.set_result(material)
		)
	return _space_material_instances.get(material_id)


func create_material_instance(material: MirrorMaterial) -> Promise:
	material.resource_name = UUID.generate_guid()
	var material_data = material.serialize()
	material_data["name"] = material.resource_name # needed for recognizing correct request
	var space_id = Zone.space.get("_id", null)
	if space_id == null:
		print("Errror retriving space id")
		return null
	var promise: Promise = Net.material_client.create_material_instance(space_id, material_data)
	promise.connect_func_to_fulfill(func():
		if promise.is_error():
			print("Errror during creating an instance of material: ", promise.get_error_message())
			return
		var data = promise.get_result()
		material.id = data["_id"]
		material.is_asset_based = false
		material.instance_name = data.get("name", "")
		_add_material_instance(data["_id"], material)
	)
	return promise


func create_instance_from_base_material(material: BaseMaterial3D, override: Dictionary = {}, space_object: SpaceObject = null, mesh: MeshInstance3D = null, surface_id = 0) -> String:
	if not is_instance_valid(material):
		return ""
	var target_material = MirrorMaterial.new()
	target_material.allow_local = true
	target_material.is_asset_based = false
	var promise_move = target_material.move_from_base_material(material, override.keys())
	for param in override:
		var value = override[param]
		target_material.set_shader_param(param, value)
	if is_instance_valid(space_object):
		space_object.set_preview_surface_material(mesh, surface_id, target_material)
	await promise_move.wait_till_fulfilled()
	var promise = create_material_instance(target_material)
	var data = await promise.wait_till_fulfilled()
	# wait one frame to be sure that all callbacks on instance material created are executed
	await get_tree().process_frame
	if is_instance_valid(space_object):
		await space_object.set_surface_material(mesh, surface_id, data["_id"], false)
	return data["_id"]


func update_material_instance(materal: MirrorMaterial) -> void:
	var dict = materal.serialize()
	if not dict.has("_id"):
		printerr("Material instance does not have an ID, updated canceled!!!")
		return
	var space_id = Zone.space.get("_id", null)
	if space_id == null:
		print("Errror retriving space id")
		return
	Net.material_client.update_material_instance(space_id, dict)


func _add_material_instance(material_id: String, material: MirrorMaterial) -> void:
	var promise = _space_material_instances.get(material_id, null)
	if promise == null:
		promise = Promise.new()
		_space_material_instances[material_id] = promise
	promise.set_result(material)
	material_instance_created.emit(material_id)


func remove_material_instance(material_id: String) -> void:
	if _space_material_instances.erase(material_id):
		material_instance_removed.emit(material_id)


func get_loaded_material_instances() -> Array:
	var arr: Array[Material] = []
	for idx in _space_material_instances:
		var promise = _space_material_instances[idx]
		if promise.has_result():
			arr.append(promise.get_result())
	return arr


func get_loaded_material_assets() -> Array:
	var arr: Array[Material] = []
	for idx in _space_material_assets:
		var promise = _space_material_assets[idx]
		if promise.has_result():
			arr.append(promise.get_result())
	return arr


func lazy_set_material(mesh: MeshInstance3D, surface_id: int, material_id: String, material_type: String) -> void:
	if not is_instance_valid(mesh):
		return
	if material_id == null or material_id.is_empty():
		mesh.set_surface_override_material(surface_id, null)
		return
	var promise: Promise
	if material_type == Enums.MATERIAL_TYPE.INSTANCE:
		promise = get_material_instance(material_id)
	else:
		promise = get_material_asset(material_id)
	var material: Material
	if promise.has_result():
		material = promise.get_result()
	else:
		material = await promise.wait_till_fulfilled()
	if promise.is_error():
		printerr("Error loading material: %s msg: %s" % [material_id, promise.get_error_message()])
		return
	# need to check second time after await
	if not is_instance_valid(mesh):
		return
	mesh.set_surface_override_material(surface_id, material)


func _on_material_instance_update_received(material_data: Dictionary) -> void:
	var material_id = material_data["_id"]
	var promise = _space_material_instances.get(material_id, null)
	if promise == null:
		promise = Promise.new()
		_space_material_instances[material_id] = promise
	if not promise.has_result():
		promise.set_result(MirrorMaterial.new())
	var material = promise.get_result()
	material.id = material_id
	material.is_asset_based = false
	material.setup(material_data)
	material.resource_name = material_id
	material.instance_name = material_data.get("name", "")


func replace_material_references(from_type: String, from_id: String, to_type: String, to_id: String) -> void:
	var instances = Zone.instance_manager.get_all_instances()
	for instance in instances:
		if not instance is SpaceObject:
			continue
		for mat in instance.surface_material_id:
			if (
					instance.surface_material_id[mat][0] == from_type
					and instance.surface_material_id[mat][1] == from_id
			):
				instance.surface_material_id[mat] = [to_type, to_id]
				instance.queue_update_network_object()


func _on_zone_disconnected() -> void:
	_space_material_instances.clear()
	_space_material_assets.clear()

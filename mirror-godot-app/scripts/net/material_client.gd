## Since only the Godot server can control material instanaces via ZoneSocket,
## this class is used to allow Godot clients to operate on material_instances.
## This is ultimately a good thing because it allows us to ensure material instance
## network updates are propagated to all clients through the Godot server.
class_name MaterialClient
extends Node


signal material_instance_create(material: Dictionary)
signal material_instance_get(material: Dictionary)

var _material_instance_creation_queue: Dictionary = {}
var _client_awaiting_material_instance_create: Dictionary = {}
var _material_instance_id_to_entity_cache: Dictionary = {}


func _ready() -> void:
	Net.zone_socket.material_instance_created.connect(_on_net_create_material_instance)
	Net.zone_socket.material_instance_received.connect(_on_net_get_or_update_material_instance)
	Net.zone_socket.material_instance_updated.connect(_on_net_get_or_update_material_instance)


func create_material_instance(space_id: String, new_material_instance_data: Dictionary) -> Promise:
	var temp_id = new_material_instance_data["name"]
	_material_instance_creation_queue[temp_id] = Promise.new()
	_request_create_material_instance_godot_server.rpc_id(Zone.SERVER_PEER_ID, space_id, new_material_instance_data)
	return _material_instance_creation_queue[temp_id]


func get_material_instance(space_id: String, material_instance_id: String, force: bool = false) -> Promise:
	if not force:
		if _material_instance_id_to_entity_cache.has(material_instance_id):
			return _material_instance_id_to_entity_cache[material_instance_id]
	_material_instance_id_to_entity_cache[material_instance_id] = Promise.new()
	_request_get_material_instance_godot_server.rpc_id(Zone.SERVER_PEER_ID, space_id, material_instance_id)
	return _material_instance_id_to_entity_cache[material_instance_id]


func update_material_instance(space_id: String, updated_material_instance: Dictionary) -> void:
	_request_update_material_instance_godot_server.rpc_id(Zone.SERVER_PEER_ID, space_id, updated_material_instance)


func cache_created_material_instance(material_instance: Dictionary) -> void:
	var material_instance_id: String = material_instance["_id"]
	_material_instance_id_to_entity_cache[material_instance_id] = material_instance


func get_material_instance_id_to_name_dict() -> Dictionary:
	var ret: Dictionary = {}
	for material_instance_id in _material_instance_id_to_entity_cache:
		var promise: Promise = _material_instance_id_to_entity_cache[material_instance_id]
		if not promise.has_result():
			continue
		var material_instance = promise.get_result()
		ret[material_instance_id] = material_instance.get("name", "<Error: Unnamed Material Instance>")
	return ret


@rpc("call_remote", "any_peer", "reliable")
func _request_create_material_instance_godot_server(space_id: String, new_material_instance_data: Dictionary) -> void:
	var peer_id: int = get_tree().get_multiplayer().get_remote_sender_id()
	_client_awaiting_material_instance_create[new_material_instance_data["name"]] = peer_id
	Net.zone_socket.create_material_instance(space_id, new_material_instance_data)


func _on_net_create_material_instance(material_instance: Dictionary) -> void:
	var material_instance_name: String = material_instance["name"]
	if not material_instance_name in _client_awaiting_material_instance_create:
		return
	if not material_instance.has("spaceId"):
		print("Error: No spaceId in material Instance data!")
		return
	var peer_id: int = _client_awaiting_material_instance_create[material_instance_name]
	# Before the material_instance has been created, it does not have an ID, so the
	# client that creates it keeps track of it by name. Pass this name back to
	# the client as "create_name" so that it can identify the incoming material.
	material_instance["create_name"] = material_instance_name
	material_instance["name"] = _generate_friendly_unique_material_instance_name()
	_inform_client_material_instance_created.rpc_id(peer_id, material_instance)
	_client_awaiting_material_instance_create.erase(material_instance_name)
	material_instance.erase("create_name")
	_request_update_material_instance_godot_server(material_instance["spaceId"], material_instance)


func _generate_friendly_unique_material_instance_name(material_instance_name_base: String = "New Material Instance") -> String:
	var number_suffix: int = 2
	var material_instance_name: String = material_instance_name_base
	while _any_material_instance_has_name(material_instance_name):
		material_instance_name = material_instance_name_base + " " + str(number_suffix)
		number_suffix += 1
	return material_instance_name


func _any_material_instance_has_name(material_instance_name: String) -> bool:
	for material_instance_id in _material_instance_id_to_entity_cache:
		var promise: Promise = _material_instance_id_to_entity_cache[material_instance_id]
		if not promise.has_result():
			continue
		var material_instance_dict = promise.get_result()
		if material_instance_dict["name"] == material_instance_name:
			return true
	return false


@rpc("call_remote", "authority", "reliable")
func _inform_client_material_instance_created(material_instance: Dictionary) -> void:
	var create_name = material_instance["create_name"]
	if _material_instance_creation_queue.has(create_name):
		_material_instance_creation_queue[create_name].set_result(material_instance)
		_material_instance_creation_queue.erase(create_name)
	material_instance_create.emit(material_instance)


## Get and update methods.
@rpc("call_local", "any_peer", "reliable")
func _request_get_material_instance_godot_server(space_id: String, material_instance_id: String) -> void:
	Net.zone_socket.get_material_instance(space_id, material_instance_id)


@rpc("call_remote", "any_peer", "reliable")
func _request_update_material_instance_godot_server(space_id: String, updated_material_instance: Dictionary) -> void:
	var material_instance_id: String = updated_material_instance["_id"]
	Net.zone_socket.update_material_instance(space_id, material_instance_id, updated_material_instance)


func _on_net_get_or_update_material_instance(material_instance: Dictionary) -> void:
	_inform_material_instance_get_or_update.rpc(material_instance)


@rpc("call_local", "authority", "reliable")
func _inform_material_instance_get_or_update(material_instance: Dictionary) -> void:
	var material_instance_id: String = material_instance["_id"]
	if not _material_instance_id_to_entity_cache.has(material_instance_id):
		_material_instance_id_to_entity_cache[material_instance_id] = Promise.new()
	_material_instance_id_to_entity_cache[material_instance_id].set_result(material_instance)
	material_instance_get.emit(material_instance)

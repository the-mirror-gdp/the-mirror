## The `SpaceObject` is the base class for all the physical objects, and offers physics sync by default.
##
## # How the Physics is synchronized
## To have a consistent physics sync, it's necessary to have the same `BodyID`s on
## both the clients and the server.
## This script creates the body on the server, so to generate an ID which
## is set as `desired_body_id`.
## At that point, the server sends that ID to the clients.
## Once the clients receive the ID, the body is created with that ID.
## This setup is quite good because allows:
## - To spawn any SpaceObject and any time, without worrying about sync, as the sync is handled internally.
## - Since the BodyIDs can be easily updated on the clients, it's not needed that the BodyIDs are consistents across all the servers.
## - This mechanism allows to have bodies that are not SpaceObjects, that simplify everything.
##
## ## State streaming
## The state streaming is used for the bodies that are far, but close enough to still been seen.
## In this case, instead to simulate the physics, the transform & the rotation is streamed and lerped across the frames.
## The `SpaceObject` streaming quality is dyanamic and is decided by the `TMSceneSync`.
##
## ## When the Body is too far and barely visible.
## The SpaceObject is entirely deactivated.
class_name SpaceObject
extends TMSpaceObjectBase


# These signals are emitted when the object is updated and needs
# to inform the hierarchy and inspector about the changes.
signal node_structure_changed()
signal node_property_changed(object_node: SpaceObject, property_name: StringName, old_value: Variant, new_value: Variant)
signal locked_state_changed()
signal scripts_changed()
signal setup_done()

const AUDIO_PLAYER_SCENE: PackedScene = preload("audio/audio_player.tscn")
const PLACEHOLDER_SCENE: PackedScene = preload("placeholder/placeholder.tscn")
const ADDITIONAL_PROPERTY_AABB = "aabb"
const COLLISION_LAYER_RAYCAST = 1 << 10
const USE_SYNC_MOVEMENT: bool = false
const _DAMAGE_HANDLER_SCENE = preload("res://scripts/entities/damage_handler.tscn")

const _REST_PROPERTY_NAME_DICT = {
	"_id": "name",
	"asset": "asset_id",
	"description": "description",
	"locked": "_locked",
	"collisionEnabled": "collision_enabled",
	"shapeType": "_physics_shape_type",
	"bodyType": "_physics_body_type",
	"massKg": "mass",
	"gravityScale": "gravity_scale",
	"preloadBeforeSpaceStarts": "is_preloaded",
	"surfaceMaterialId": "surface_material_id",
	"castShadows": "cast_shadows",
	"visibleFrom": "visible_from",
	"visibleTo": "visible_to",
	"visibleFromMargin": "visible_from_margin",
	"visibleToMargin": "visible_to_margin",
}

const PLAYER_DISTANCE_TO_PRIORITY_MAP = {
	# ex: at distance below 10 the priority is SPACE_OBJECT_HIGH
	pow(10, 2) : Enums.DownloadPriority.SPACE_OBJECT_HIGH,
	pow(25, 2) : Enums.DownloadPriority.SPACE_OBJECT_MEDIUM,
	pow(40, 2) : Enums.DownloadPriority.SPACE_OBJECT_LOW,
}

@export var outline_resource: Resource
var damage_handler: DamageHandler

# Keep track of "_is_ready" separately because we call "populate" in our
# instance manager to make it ready, which then calls "_ready_safe".
# Otherwise the instance manager may encounter a race condition with the
# "populate" call, potentially resulting in incorrect setup and instance
# breakage. Later we will fix this better by refactoring SpaceObject.
var _is_ready = false
var _script_instance_dicts_cache: Array = []
var _script_instances: Array[ScriptInstance]
var _shape_type: String = "Auto"
var _audio_player: AudioStreamPlayer3D
var _placeholder: Node3D
var _heightmap: Heightmap = null
var _awaiting_file_setup: bool = false
var _queue_update_network_object_frames: int = 0
var _additional_properties: Dictionary
var _creator_name: String
var _is_setup: bool = false:
	set(value):
		_is_setup = value
		if value:
			setup_done.emit()
var spawn_points: Dictionary = {} # path_key : spawn point data
var asset_id: String
var description: String
var asset_data: AssetData = AssetData.new()
var asset_type: String # Enums.ASSET_TYPE
var is_preloaded: bool = false
var current_asset: Dictionary = {}
var space_object_data: Dictionary = {}
var extra_node_dicts: Array = []
var cast_shadows: bool = true:
	set(value):
		cast_shadows = value
		scaled_model.refresh_model_visibility()
var visible_from: float = 0.0:
	set(value):
		visible_from = value
		scaled_model.refresh_model_visibility()
var visible_to: float = 0.0:
	set(value):
		visible_to = value
		scaled_model.refresh_model_visibility()
var visible_from_margin: float = 0.0:
	set(value):
		visible_from_margin = value
		scaled_model.refresh_model_visibility()
var visible_to_margin: float = 0.0:
	set(value):
		visible_to_margin = value
		scaled_model.refresh_model_visibility()

var last_trickle_update = 0

## true when running a space object in the unit tests
var _test_harness = false
# Locked will prevent selecting an object using left-click from a raycast (for maps/etc).
var _locked: bool = false
var locked: bool:
	get:
		return _locked
	set(value):
		if _locked != value:
			_locked = value
			queue_update_network_object()
			locked_state_changed.emit()

# Physics properties.
var collision_enabled: bool = true:
	set(value):
		collision_enabled = value
		_refresh_collision_layers()
var freeze_override: bool = false:
	set(value):
		pass

var _physics_shape_type: String = "Auto"
var physics_shape_type: String:
	get:
		return _physics_shape_type
	set(new_physics_shape_type):
		if _physics_shape_type != new_physics_shape_type:
			_physics_shape_type = new_physics_shape_type
			if _physics_body_type != "Static" and scaled_model.does_desired_shape_type_require_static():
				# The user requested a shape type that requires Static, but the
				# current body type is not Static. So we set the type to Static.
				_physics_body_type = "Static"
				_refresh_collision_layers()
			scaled_model.setup_physics_colliders()
			queue_update_network_object()

var _physics_body_type: String = "Static"
var physics_body_type: String:
	get:
		# We must always provide trigger bodies this prevents bodies pushing
		# the bodies out, this means everything except triggers must be static
		# during the loading process of the game
		# see the instance manager for more information.
		if Zone.instance_manager.ready_to_simulate or _physics_body_type == "Trigger":
			return _physics_body_type
		else:
			return "Static"
	set(new_physics_body_type):
		if _physics_body_type != new_physics_body_type:
			_physics_body_type = new_physics_body_type
			if _physics_body_type != "Static" and scaled_model.does_desired_shape_type_require_static():
				# The user requested a non-Static object, but the current shape
				# settings require Static. So we reset the shape setting to Auto.
				_physics_shape_type = "Auto"
				scaled_model.setup_physics_colliders()
			_refresh_collision_layers()
			queue_update_network_object()

# Material properties.
var material_id: String:
	set(value):
		material_id = value
		_refresh_object_material()
# Material properties.
var surface_material_id: Dictionary
var object_texture_id: String:
	set(value):
		object_texture_id = value
		_refresh_object_texture()
var object_local_texture: Texture = null:
	set(value):
		object_local_texture = value
		scaled_model.refresh_model_materials()

# Bindings for script.
var space_object_name: String:
	get:
		return get_space_object_name()
	set(value):
		set_space_object_name(value)
var model_offset: Vector3:
	get:
		return get_model_offset()
	set(value):
		set_model_offset(value)
var model_scale: Vector3:
	get:
		return get_model_scale()
	set(value):
		set_model_scale(value)
var animation_player: AnimationPlayer

# Internal.
var audio_player: AudioStreamPlayer3D
var damage_handler_enabled = false:
	set(value):
		damage_handler_enabled = value
		var has_damage_handler = damage_handler != null
		if damage_handler_enabled and not has_damage_handler:
			_add_damage_handler()
		elif not damage_handler_enabled and has_damage_handler:
			_remove_damage_handler()

@onready var _ws_debug_prints = ProjectSettings.get_setting("debug_flags/show_web_socket_debug", false)
@onready var data_store: DataStoreNode = $_DataStoreNodePath
@onready var interpolated_node: Node3D = $_InterpolatedNode
@onready var scaled_model: Node3D = $_InterpolatedNode/_ScaledModel
@onready var selection_label: Label3D = $_SelectionLabel


func _setup_synchronizer(node_id):
	TMSceneSync.register_variable(self, "jolt_sync_data")
	TMSceneSync.register_variable(self, "selected_by_peers")
	TMSceneSync.track_variable_changes([self], ["selected_by_peers"], _on_selected_peers_changed, TMSceneSync.ALWAYS)
	TMSceneSync.setup_trickled_sync(self, deferred_sync_state_collect, deferred_sync_state_apply)
	TMSceneSync.register_process(self, TMSceneSync.PROCESS_PHASE_PRE, _process_npc)
	TMSceneSync.register_process(self, TMSceneSync.PROCESS_PHASE_LATE, update_space_object_transform)
	start_updating.connect(_on_net_sync_start_updating)
	stop_updating.connect(_on_net_sync_stop_updating)
	register_interaction(&"_interaction_set_transform")


func update_space_object_transform(sync_delta: float):
	interpolated_node.update_space_object_transform(sync_delta, global_transform)


func load_server_asset(asset_id: String) -> void:
	Util.safe_signal_connect(Net.zone_socket.asset_received, on_asset_received)
	var promise = Net.zone_socket.queue_download_asset(asset_id)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		var file_promise = asset_data.get_asset_file_promise()
		# We need to set asset data file promise to error
		# As we will never request asset_file URI. (It does not exists, we do not have asset_data)
		file_promise.set_error("AssetData for SpaceObject: \"%s\" was not found, showing red error text in its place." % space_object_name)
		_set_as_errored("Invalid asset data for space object %s" % promise.get_error_message())
		return
	else:
		current_asset = promise.get_result()
		assert(asset_id == current_asset._id)
		print_verbose("Loaded asset successfully: ", asset_id)


func load_client_asset(asset_id: String) -> void:
	Util.safe_signal_connect(Net.asset_client.asset_received, on_asset_received)
	var promise = Net.asset_client.queue_download_asset(asset_id, _calculate_download_priority())
	await promise.wait_till_fulfilled()
	if promise.is_error():
		var file_promise = asset_data.get_asset_file_promise()
		# We need to set asset data file promise to error
		# As we will never request asset_file URI. (It does not exists, we do not have asset_data)
		file_promise.set_error("AssetData for SpaceObject: \"%s\" was not found, showing red error text in its place." % space_object_name)
		_set_as_errored("Invalid asset data for space object")
		if is_preloaded:
			Notify.error("Space Object", "Preloaded space_object %s was not loaded correctly" % space_object_name)
			# For the assets that are preloaded
			# We want not to block the loading if it was deleted
			_fade_out_placeholder()
			_is_setup = true
		return
	current_asset = promise.get_result()


## load the asset and apply it to the space object
func _load_asset() -> void:
	asset_id = space_object_data["asset"]
	var is_new_asset_id = not current_asset.is_empty() and current_asset["_id"] != asset_id
	if asset_id.is_empty():
		_set_as_errored("critical: invalid asset for space object")
		return
	if space_object_data.has("asset_data"):
		# Used in play zones
		current_asset = space_object_data["asset_data"]
	else:
		current_asset = Net.asset_client.get_asset_json(asset_id)
		if current_asset.is_empty():
			if Zone.is_host():
				await load_server_asset(asset_id)
			else:
				await load_client_asset(asset_id)
		else:
			if is_new_asset_id:
				_setup_object()
	# we populate the asset data if it has no type we can return early.
	if not _populate_asset_data():
		_set_as_errored("[%s] invalid asset data _load_asset asset_id: %s" % [Zone.get_instance_type(), asset_id])


# we block the ready_safe function from being called twice.
var _block_ready_safe = false
func _ready_safe() -> void:
	_block_ready_safe = true
	_placeholder = PLACEHOLDER_SCENE.instantiate()
	add_child(_placeholder)
	if not _test_harness:
		TMSceneSync.register_node(self)
	scaled_model.setup_initial(self)
	Net.asset_client.asset_deleted.connect(_on_asset_deleted)
	scaled_model.node_structure_changed.connect(on_node_structure_changed)
	# we must ensure the preloaded flag is set
	is_preloaded = space_object_data.get("preloadBeforeSpaceStarts", false)
	populate_all_properties()
	# load the asset data and file into the space object
	# this is a blocking call
	await _load_asset()
	# Don't use file_loaded here, as we are waiting for file promise
	# in _setup_object() Otherwise it will try to setup SpaceObjet twice!
	# asset_data.files_loaded.connect(asset_files_loaded)
	_setup_object()

	if Zone.is_host():
		return
	selection_label.hide()


func deferred_sync_state_collect(db: DataBuffer, update_rate: float):
	if update_rate >= 0.5 or is_static() or is_sensor():
		db.add_bool(true)
		db.add_vector3(get_global_transform().origin, DataBuffer.COMPRESSION_LEVEL_1)
	else:
		db.add_bool(false)
		db.add_vector3(get_global_transform().origin, DataBuffer.COMPRESSION_LEVEL_2)
	# TODO optimize this to use better rotation compression algorithm.
	db.add_vector3(get_global_transform().basis.get_euler(), DataBuffer.COMPRESSION_LEVEL_2)

	for sbp in selected_by_peers:
		db.add_bool(true)
		db.add_int(sbp, DataBuffer.COMPRESSION_LEVEL_1)
	db.add_bool(false)


func deferred_sync_state_apply(dt: float, alpha: float, db_from: DataBuffer, db_to: DataBuffer):
	notify_received_net_sync_update()

	if is_dynamic() or is_kinematic():
		body_mode = JBody3D.KINEMATIC

	var origin_uncompressed_from = db_from.read_bool()
	var origin_from_compression := DataBuffer.COMPRESSION_LEVEL_1 if origin_uncompressed_from else DataBuffer.COMPRESSION_LEVEL_2
	var origin_from := db_from.read_vector3(origin_from_compression)
	var basis_from := Basis.from_euler(db_from.read_vector3(DataBuffer.COMPRESSION_LEVEL_2))
	while db_from.read_bool():
		db_from.read_int(DataBuffer.COMPRESSION_LEVEL_1)

	var origin_uncompressed_to = db_to.read_bool()
	var origin_to_compression := DataBuffer.COMPRESSION_LEVEL_1 if origin_uncompressed_to else DataBuffer.COMPRESSION_LEVEL_2
	var origin_to := db_to.read_vector3(origin_to_compression)
	var basis_to := Basis.from_euler(db_to.read_vector3(DataBuffer.COMPRESSION_LEVEL_2))

	var new_selected_by_peers := []
	while db_to.read_bool():
		var peer = db_to.read_int(DataBuffer.COMPRESSION_LEVEL_1)
		new_selected_by_peers.push_back(peer)
	selected_by_peers = new_selected_by_peers
	_on_selected_peers_changed(null)

	if is_selected():
		# Make sure not to overshoot when the body is moving because it was dragged.
		alpha = min(alpha, 1.0)

	var origin: Vector3 = lerp(origin_from, origin_to, alpha)
	var basis: Basis = lerp(basis_from, basis_to, alpha)

	set_global_transform(Transform3D(basis, origin))
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	body_mode = JBody3D.STATIC
	interpolated_node.update_space_object_transform(0.0, global_transform)


func _process(delta: float) -> void:
	_process_queue_update_network_object()
	interpolated_node._process_interpolate(delta)


## Detects and executes if the network object needs updating the next frame.
func _process_queue_update_network_object() -> void:
	if _queue_update_network_object_frames > 0:
		_queue_update_network_object_frames -= 1
		if _queue_update_network_object_frames == 0:
			_update_network_object()


## Queues an update the network object that will happen in the near future.
func queue_update_network_object() -> void:
	_queue_update_network_object_frames = 10


## Call this method whenever something changes the SpaceObject's node structure.
func on_node_structure_changed():
	node_structure_changed.emit()


func cleanup_and_delete_space_object() -> void:
	_delete_all_script_instances()
	queue_free()


func is_ready() -> bool:
	return not is_instance_valid(_placeholder) and _is_setup


func get_space_object_asset_id() -> String:
	return asset_id


func get_space_object_name() -> String:
	return space_object_data.get("name", self.name)


func set_space_object_name(new_name: String) -> void:
	space_object_data["name"] = new_name
	queue_update_network_object()


## Call this when changing a property. Calling emits the node_property_changed signal.
func record_property_changed(property_name: StringName, old_value: Variant, new_value: Variant) -> void:
	node_property_changed.emit(self, property_name, old_value, new_value)


func is_untracked() -> bool:
	return space_object_data == null or not space_object_data.has("_id")


func get_last_rest_api_value(property: String) -> Variant:
	if not property in self.get_property_list():
		return null
	var rest_key = _REST_PROPERTY_NAME_DICT.find_key(property)
	if rest_key == null:
		return null
	var value = space_object_data.get(rest_key)
	return _convert_to_property(property, value)


func _configure_spawn_points():
	if not _is_setup:
		await setup_done
	#print("configuring spawn points: ", spawn_points)
	#print("spawn points: ", space_object_data.get("spawnPoints"))
	#print("is server: ", "yes" if Zone.is_host() else "no")
	for target_node in spawn_points.keys():
		var spawn_point = spawn_points[target_node]
		if spawn_point.has("team"):
			var spawn_point_node = get_node(NodePath(target_node))
			if not spawn_point_node:
				#print("invalid path or bug with node: ", target_node)
				continue
			spawn_point_node.set_meta("OMI_spawn_point", spawn_point.duplicate())
			#print("updated team: ", spawn_point_node.get_meta("OMI_spawn_point"))


## Applies all data from the space_object_data dictionary onto this SpaceObject.
func apply_from_dictionary(delta_dict: Dictionary, is_in_ready_safe: bool = false) -> void:
	if is_untracked():
		queue_free()
		return
	_apply_transform_from_dictionary()
	if audio_player:
		audio_player.populate(space_object_data)

	if delta_dict.has("damage_handler_enabled"):
		damage_handler_enabled = delta_dict.get("damage_handler_enabled")

	if delta_dict.has("asset_data") or (delta_dict.has("asset") and not is_in_ready_safe):
		## load the asset data and file into the space object
		## this is a blocking call
		await _load_asset()

	if delta_dict.has("spawnPoints"):
		spawn_points = delta_dict.get("spawnPoints")
		_configure_spawn_points()

	# If it has a representation, we ask it to setup again to refresh.
	# If not, it will get physics colliders once the model has loaded.
	if scaled_model.has_representation():
		scaled_model.reset_with_space_object_data()
		var extra_nodes_changed: bool = _setup_extra_nodes(delta_dict)
		# Scripts must be set up after the nodes have been set up.
		# If extra nodes change, we must set up scripts again.
		if extra_nodes_changed or delta_dict.has("scriptEvents"):
			_setup_script_instances(delta_dict, extra_nodes_changed)


func _convert_to_property(property: String, value: Variant):
	if property == "object_color" and (not value is Array or value.size() < 3):
		printerr("Object color for " + str(get_space_object_name()) + " received from network is invalid, this should not happen.")
		value = [1.0, 1.0, 1.0]
	return Serialization.type_convert_from_json(value, typeof(self.get(property)))


func _set_and_convert_to_property(property: String, value: Variant):
	var property_converted = _convert_to_property(property, value)
	if (property in self) and self[property] != property_converted:
		self[property] = property_converted


## populates the properties on an asset
## called by populate_asset_data
func populate_all_properties() -> void:
	for prop in _REST_PROPERTY_NAME_DICT.keys():
		var property = _REST_PROPERTY_NAME_DICT[prop]
		# Populate with the asset's properties.
		if self.current_asset.has(prop):
			_set_and_convert_to_property(property, self.current_asset[prop])
		# Override with the space object's instance properties if they exist.
		if space_object_data.get(prop) != null:
			_set_and_convert_to_property(property, space_object_data[prop])
	if get_layer_name() != "":
		_refresh_collision_layers()


func set_active(is_active: bool) -> void:
	_refresh_collision_layers()
	freeze_override = not is_active


func play_enabled() -> void:
	set_active(true)


func is_selected() -> bool:
	if selected_by_peers.size() > 0:
		return true
	else:
		return false


func force_refresh_collision_layers():
	_refresh_collision_layers()


func _refresh_collision_layers():
	if collision_enabled and _physics_shape_type != "Multi Bodies":
		match physics_body_type:
			"Static":
				set_layer_name(&"STATIC")
				body_mode = JBody3D.STATIC
			"Kinematic":
				set_layer_name(&"CHARACTER")
				body_mode = JBody3D.KINEMATIC
			"Dynamic":
				set_layer_name(&"DYNAMIC")
				body_mode = JBody3D.DYNAMIC
			"Trigger":
				set_layer_name(&"TRIGGER")
				body_mode = JBody3D.SENSOR
			_:
				assert(false, "Unknown body type " + physics_body_type + ".")
	else:
		# No collision.
		set_layer_name(&"NO_COLLIDE")
		body_mode = JBody3D.STATIC

	if is_selected() and body_mode == JBody3D.DYNAMIC:
		body_mode = JBody3D.STATIC
		linear_velocity = Vector3()
		angular_velocity = Vector3()


func get_space_object_global_transform() -> Transform3D:
	var t = global_transform
	t.basis *= scaled_model.basis
	return t


func get_model_scale() -> Vector3:
	return scaled_model.basis.get_scale()


func set_model_scale(new_scale: Vector3):
	scaled_model.transform.basis = Basis.from_scale(new_scale)
	queue_update_network_object()


func get_model_offset() -> Vector3:
	return scaled_model.position


func set_model_offset(new_offset: Vector3):
	scaled_model.position = new_offset
	queue_update_network_object()


func center_model_offset() -> void:
	var aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(self)
	set_model_offset(scaled_model.position - aabb.get_center())


func get_model_node_by_name(node_name: StringName) -> Node:
	return scaled_model.get_model_node_by_name(node_name)


func get_model_node_by_type(node_type: String) -> Node:
	return scaled_model.get_model_node_by_type(node_type)


func add_extra_node(extra_node_json: Dictionary) -> void:
	extra_node_dicts.append(extra_node_json)
	scaled_model.setup_extra_nodes()
	queue_update_network_object()
	node_structure_changed.emit()


func remove_extra_node(extra_node_json: Dictionary) -> void:
	# A bunch of extra logic is needed when deleting extra nodes. We need to
	# ensure there are no stay nodes referencing this node.
	extra_node_dicts.erase(extra_node_json)
	for other_extra_node in extra_node_dicts.duplicate(false):
		var other_name: String = other_extra_node["name"]
		if other_name == extra_node_json["parent"]:
			remove_extra_node(other_extra_node)
	scaled_model.setup_extra_nodes()
	queue_update_network_object()
	node_structure_changed.emit()


func update_extra_nodes() -> void:
	scaled_model.setup_extra_nodes()
	queue_update_network_object()
	node_structure_changed.emit()


func add_key_to_zone_data(key, value) -> void:
	## This function adds the key / value pair into the buffer that is later sent to the clients.
	## NOTE: This looks like an hack and indeed it is: it's a crafty hack to avoid refactoring the spawning mechanism.
	if TMSceneSync.is_server() or not TMSceneSync.is_networked():
		for sod in Zone.space_objects:
			if sod._id == space_object_data._id:
				sod[key] = value
				return


func populate(delta_dict: Dictionary):
	if (TMSceneSync.is_server() or not TMSceneSync.is_networked()) and not has_desired_body_id():
		# Generate the desired_body_id on the server.
		desired_body_id = TMSceneSync.fetch_free_sync_body_id()

	space_object_data.merge(delta_dict, true)

	var ready_safe_executed_temp = false
	# this prevents _ready_safe from ever being called twice
	# _ready should be used for checking if it
	if not _block_ready_safe:
		_ready_safe()
		ready_safe_executed_temp = true

	# populate is called before ready
	if not data_store._configured:
		# configure data store as a node store
		# this automatically registers with space variables for use in the scripting :)
		data_store.configure(self, null, null)

	if TMSceneSync.is_server() or not TMSceneSync.is_networked():
		# The `desired_body_id` was generated above
		assert(has_desired_body_id())
		# Store the `desired_body_id` inside the buffer that is received by the client
		# so the client have the needed body_id right away without any need to
		# write any complex networking logic.
		add_key_to_zone_data("desired_body_id", desired_body_id)
		if not delta_dict.is_read_only():
			delta_dict["desired_body_id"] = desired_body_id
	elif TMSceneSync.is_client():
		# At this point we can always expect to find the `desired_body_id`.
		if space_object_data.has("desired_body_id"):
			desired_body_id = space_object_data["desired_body_id"]
			assert(has_desired_body_id())
		else:
			printerr("[FATAL] The client didn't receive the `desired_body_id` generated on the server. This is never supposed to happen.")

	if has_desired_body_id() and desired_body_id != get_body_id():
		create_body()

	apply_from_dictionary(delta_dict, ready_safe_executed_temp)


func on_asset_received(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return
	if asset_dict["_id"] != asset_id:
		return
	current_asset = asset_dict
	if not _populate_asset_data():
		_set_as_errored("on_asset_received failed to find type for an asset")

	_setup_object()


func _on_asset_deleted(asset_dict: Dictionary) -> void:
	if asset_dict == null or not asset_dict.has("_id"):
		return


var _errored = false

## This is errored when the asset promise fails to load
## or when the GLTF file fails to be loaded by the GLTF loader
## this can happen and block vital loading processes
## this also could detect failures like 404's when an asset is downloaded
## from our web sockets
func is_error() -> bool:
	return _errored


## This sets the space object to be an error object in world
## This allows us to correctly skip assets which are broken on loading the server or client
## use this with is_error to detect errors on a space object
func _set_as_errored(error_message: String) -> void:
	_errored = true
	printerr(error_message)
	if is_instance_valid(_placeholder):
		_placeholder.swap_grid_for_error()
	else:
		printerr("Invalid error model placeholder, critical error.")


func _setup_object() -> void:
	if _awaiting_file_setup:
		return
	var asset_file_result = null
	var asset_file_promise: Promise = asset_data.get_asset_file_promise()
	_awaiting_file_setup = true
	await asset_file_promise.wait_till_fulfilled()
	_awaiting_file_setup = false
	if asset_file_promise.is_error():
		_set_as_errored("SpaceObject: " + asset_file_promise.get_error_message())
		_is_setup = true
		return
	asset_file_result = asset_file_promise.get_result()
	if asset_file_result is Heightmap:
		await _setup_map_object(asset_file_result)
	elif asset_file_result is Node:
		_setup_node_object(asset_file_result)
	elif asset_file_result is AudioStream:
		_setup_audio_player(asset_file_result)
	else:
		_set_as_errored("Unsupported Space Object Type %s" % str(asset_file_result))
		_is_setup = true
		return
	_setup_extra_nodes()
	# Scripts must be set up after the nodes have been set up.
	_setup_script_instances()
	_is_setup = true


func get_heightmap_or_null():
	if asset_type != Enums.ASSET_TYPE.MAP:
		return null
	return _heightmap


func _fade_out_placeholder() -> void:
	if is_instance_valid(_placeholder):
		_placeholder.fade_out()
		_placeholder = null


func _setup_map_object(map: Heightmap) -> void:
	_fade_out_placeholder()
	#remove all previous Heightmap children
	if _heightmap == null:
			_heightmap = map
			add_child(_heightmap)
	_heightmap.populate(self, space_object_data)
	if not _heightmap.is_loaded():
		await _heightmap.map_loaded


func _setup_node_object(asset_file_result: Node) -> void:
	var was_already_represented = scaled_model.has_representation()
	scaled_model.setup_model(asset_file_result)

	if Zone.is_host():
		var aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(self)
		set_additional_property(ADDITIONAL_PROPERTY_AABB, aabb)

	if not was_already_represented and _placeholder:
		_placeholder.setup(TMNodeUtil.get_local_aabb_of_descendants(self))
		_fade_out_placeholder()


func _setup_audio_player(asset_file_result: AudioStream) -> void:
	_fade_out_placeholder()
	if not audio_player:
		audio_player = AUDIO_PLAYER_SCENE.instantiate()
		add_child(audio_player)
	collision_enabled = false
	var collision_shape := JSphereShape3D.new()
	collision_shape.radius = 1.0
	set_shape_and_create_body(collision_shape)
	audio_player.populate(space_object_data)
	audio_player.setup_audio(asset_file_result)


func _setup_extra_nodes(delta_dict: Dictionary = space_object_data) -> bool:
	if not delta_dict.has("extraNodes"):
		return false
	var delta_arr: Array = delta_dict["extraNodes"]
	if delta_arr.is_empty():
		return false
	var delta_arr_dict: Dictionary = delta_arr[0]
	var delta_extra_nodes: Array = []
	for key in delta_arr_dict:
		delta_extra_nodes.append(delta_arr_dict[key])
	# Equal arrays may sometimes not be considered equal by Godot,
	# so we convert them to strings and compare those.
	if str(extra_node_dicts) == str(delta_extra_nodes):
		return false
	extra_node_dicts = delta_extra_nodes
	scaled_model.setup_extra_nodes()
	return true


func _setup_script_instances(delta_dict: Dictionary = space_object_data, force: bool = false) -> void:
	# Check if the new script events we are asking to set up are different.
	if delta_dict.has("scriptEvents"):
		var new_events: Array = delta_dict["scriptEvents"]
		# Equal arrays may sometimes not be considered equal by Godot,
		# so we convert them to strings and compare those.
		if not force and str(_script_instance_dicts_cache) == str(new_events):
			return
		_script_instance_dicts_cache = new_events
	# By this point we know that the data is different so we need to delete
	# all existing script events and add new ones if there are any.
	_delete_all_script_instances()
	if _script_instance_dicts_cache.is_empty():
		scripts_changed.emit()
		return
	# Add new script events. Do not use `add_script()` because it emits a signal.
	for script_inst_dict in _script_instance_dicts_cache:
		_setup_script_instance(script_inst_dict)
	scripts_changed.emit()


func _setup_script_instance(script_inst_dict: Dictionary) -> void:
	var script_instance: ScriptInstance = ScriptInstance.create(script_inst_dict)
	await script_instance.setup(self, script_inst_dict)
	# Must connect this signal only after the script event has been setup.
	script_instance.script_contents_changed.connect(queue_update_network_object)
	_script_instances.append(script_instance)


func add_script_instance(script_instance: ScriptInstance) -> void:
	script_instance.script_contents_changed.connect(queue_update_network_object)
	_script_instances.append(script_instance)
	scripts_changed.emit()
	queue_update_network_object()


func delete_script_instance(script_instance: ScriptInstance) -> void:
	_script_instances.erase(script_instance)
	script_instance.cleanup_script_instance()
	script_instance.free()
	scripts_changed.emit()
	queue_update_network_object()


func script_instances_modified() -> void:
	scripts_changed.emit()
	queue_update_network_object()


func _delete_all_script_instances() -> void:
	# Delete existing ScriptInstances (if any). Do not use
	# `delete_script()` because it emits a signal.
	for script_instance in _script_instances:
		script_instance.cleanup_script_instance()
		script_instance.free()
	_script_instances.clear()


func has_script_instances() -> bool:
	if _is_setup:
		return not _script_instances.is_empty()
	return space_object_data.has("scriptEvents") and not space_object_data.get("scriptEvents").is_empty()


func get_script_instances() -> Array[ScriptInstance]:
	return _script_instances


func _populate_asset_data() -> bool:
	if current_asset:
		asset_data.populate(current_asset)
		asset_type = asset_data.type
		if asset_type == Enums.ASSET_TYPE.MAP:
			var map_asset_data = AssetDataMap.new()
			map_asset_data.populate(current_asset)
			map_asset_data.try_creating_map(_heightmap)
			var file_promise = asset_data.get_asset_file_promise()
			file_promise.set_result(map_asset_data.map)
		else:
			asset_data.try_download_file(_calculate_download_priority())

	if asset_data.type.is_empty():
		return false
	populate_all_properties()
	return true


func _calculate_download_priority():
	if Zone.is_host() or Zone.is_headless():
		return Enums.DownloadPriority.SPACE_OBJECT_LOWEST
	var local_player = PlayerData.get_local_player()
	if local_player == null:
		return Enums.DownloadPriority.SPACE_OBJECT_LOWEST
	var dst2player = global_position.distance_squared_to(local_player.global_position)
	var priority = Enums.DownloadPriority.SPACE_OBJECT_LOWEST
	for distance in PLAYER_DISTANCE_TO_PRIORITY_MAP:
		var dst_threshold_achieved = dst2player < distance
		if dst_threshold_achieved:
			priority = PLAYER_DISTANCE_TO_PRIORITY_MAP[distance]
			break
	return priority


func serialize_extra_nodes() -> Array:
	var ret: Dictionary = {}
	for i in range(extra_node_dicts.size()):
		ret[i] = extra_node_dicts[i]
	return [ret]


func serialize_script_instances() -> Array:
	# Note: Do NOT `.clear()` the existing data because we want this to be a different
	# array. The result of this serialization needs to be compared to what's already
	# in the SpaceObject data to decide what to send over the network.
	var serialized_script_instances: Array = []
	for script_instance in _script_instances:
		assert(is_instance_valid(script_instance))
		serialized_script_instances.append(script_instance.serialize_script_instance_to_json())
	return serialized_script_instances


## Serializes the data of the space object instance to the data dictionary.
## Returns a dictionary of the differences
func serialize_to_dictionary() -> Dictionary:
	var delta_dict: Dictionary = {}

	# we must always include the ID of the document to ensure it works!
	delta_dict["_id"] = space_object_data["_id"]
	delta_dict["name"] = space_object_data["name"]
	delta_dict["asset"] = space_object_data["asset"]

	_serialize_transform_to_dictionary(delta_dict)

	if audio_player:
		audio_player.serialize_to_dictionary(space_object_data, delta_dict)

	# spawn point diff should be part of the space object if present
	Util.apply_delta_to_dict(space_object_data, delta_dict, "spawnPoints", spawn_points)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "damage_handler_enabled", damage_handler_enabled)
	# Map godot properties to the correct database columns for saving them
	for prop in _REST_PROPERTY_NAME_DICT.keys():
		var godot_column = _REST_PROPERTY_NAME_DICT[prop]
		var godot_value = self[godot_column]
		Util.apply_delta_to_dict(space_object_data, delta_dict, prop, Serialization.type_convert_to_json(godot_value))
		# Do not override space object space_object_data if equal to the asset values. TODO: why?
		if current_asset.get(prop) == space_object_data[prop]:
			space_object_data[prop] = null
	Util.apply_delta_to_dict(space_object_data, delta_dict, "extraNodes", serialize_extra_nodes())
	# Serialize script properties.
	_script_instance_dicts_cache = serialize_script_instances()
	Util.apply_delta_to_dict(space_object_data, delta_dict, "scriptEvents", _script_instance_dicts_cache)
	return delta_dict


func _update_network_object() -> void:
	var serialized: Dictionary = serialize_to_dictionary()
	var data: Array = [Packet.TYPE.UPDATE_SPACE_OBJECT, serialized]
	if _ws_debug_prints:
		print("Update network object packet: ", data)
	if Zone.is_host():
		Zone.send_data_to_all_peer(data)
		Net.zone_socket.update_space_object(serialized)
	else:
		Zone.send_data_to_server(data)


func grab() -> void:
	set_layer_name(&"")
	if is_instance_valid(_placeholder):
		_placeholder.grab()


func release() -> void:
	_refresh_collision_layers()
	if is_instance_valid(_placeholder):
		_placeholder.release()


func _apply_transform_from_dictionary() -> void:
	if space_object_data.has("rotation") and space_object_data.has("position"):
		transform = Transform3D(
			Basis.from_euler(Serialization.array_to_vector3(space_object_data["rotation"])),
			Serialization.array_to_vector3(space_object_data["position"])
		)
	if space_object_data.has("scale") and space_object_data.has("offset"):
		scaled_model.transform = Transform3D(
			Basis.from_scale(Serialization.array_to_vector3(space_object_data["scale"])),
			Serialization.array_to_vector3(space_object_data["offset"])
		)


func _serialize_transform_to_dictionary(delta_dict: Dictionary = Dictionary()) -> void:
	var scaled_model_transform: Transform3D = scaled_model.transform
	Util.apply_delta_to_dict(space_object_data, delta_dict, "position", Serialization.vector3_to_array(transform.origin))
	Util.apply_delta_to_dict(space_object_data, delta_dict, "rotation", Serialization.vector3_to_array(rotation))
	Util.apply_delta_to_dict(space_object_data, delta_dict, "scale", Serialization.vector3_to_array(scaled_model_transform.basis.get_scale()))
	Util.apply_delta_to_dict(space_object_data, delta_dict, "offset", Serialization.vector3_to_array(scaled_model_transform.origin))


@rpc("call_remote", "any_peer", "reliable")
func server_add_impulse_at_position(impulse: Vector3, hit_position: Vector3) -> void:
	assert(is_dynamic(), "This method should only be called on dynamic bodies.")
	add_impulse_at_position(impulse, hit_position)


# Health
func damage(amount: float, source: String) -> void:
	if damage_handler and is_instance_valid(damage_handler):
		damage_handler.damage(amount, source)


func heal(amount: float, source: String) -> void:
	if damage_handler and is_instance_valid(damage_handler):
		damage_handler.heal(amount, source)


func revive():
	if damage_handler and is_instance_valid(damage_handler) and Zone.is_host():
		damage_handler.server_revive_after_delay() # delay is statically 5 seconds


func get_health() -> float:
	if damage_handler and is_instance_valid(damage_handler):
		return damage_handler.get_health()
	return 0.0


func is_dead() -> bool:
	if damage_handler and is_instance_valid(damage_handler):
		return damage_handler.get_health() <= 0
	return true


# When the checkbox for "damageable" is set the object calls this
# And vice versa for the _remove_damage_handler.
func _add_damage_handler():
	if damage_handler != null:
		return
	damage_handler = _DAMAGE_HANDLER_SCENE.instantiate()
	add_child(damage_handler)
	const default_health = 100
	var initial_health = data_store.get_value("health", default_health)
	data_store.set_value("health", default_health) # ensure it's always at the default
	#print("added health to datastore ", data_store.get_datastore())
	damage_handler.setup_damage_handler(self, data_store.get_value("health", default_health))
	damage_handler.health_changed.connect(
		func(target_object: Node, new_health: float, old_health: float, event_origin: String):
			data_store.set_value("health", new_health))


func _remove_damage_handler():
	if damage_handler == null:
		return
	remove_child(damage_handler)
	damage_handler.queue_free()
	damage_handler = null
	if data_store.get_value("health", null) != null:
		data_store.erase_value("health") # health this way is always reset on load :)


# # # #
# Additional properties
func get_additional_properties_names():
	return _additional_properties.keys()


func get_additional_property(in_key, default_val = null):
	if _additional_properties.has(in_key):
		return _additional_properties[in_key]
	return default_val


func set_additional_property(in_key: String, in_value):
	_additional_properties[in_key] = in_value

	if in_key == ADDITIONAL_PROPERTY_AABB:
		if scaled_model.has_representation():
			return
		if _placeholder:
			var aabb: AABB = _additional_properties[ADDITIONAL_PROPERTY_AABB]
			_placeholder.setup(aabb)


func _refresh_object_material() -> void:
	if Zone.is_host():
		return
	var meshes = Util.recursive_find_nodes_of_type(self, MeshInstance3D)
	var type = Enums.MATERIAL_TYPE.ASSET
	for i in range(meshes.size()):
		if not is_instance_valid(meshes[i]):
			continue
		var mesh: MeshInstance3D = meshes[i]
		var mesh_path = scaled_model.get_path_to(mesh)
		for surface_id in range(mesh.get_surface_override_material_count()):
			var key: String = "%s:surface_%d" % [mesh_path, surface_id]
			surface_material_id[key] = [type, material_id]
	scaled_model.refresh_model_materials()
	queue_update_network_object()


func _refresh_object_texture() -> void:
	if Zone.is_host():
		return
	scaled_model.refresh_model_main_texture(object_texture_id)


func set_preview_surface_material(mesh: MeshInstance3D, surface_id: int, material: Material) -> void:
	mesh.set_surface_override_material(surface_id, material)


func set_surface_material(mesh: MeshInstance3D, surface_id: int, material_id: String, is_asset: bool) -> void:
	var mesh_path = scaled_model.get_path_to(mesh)
	var key: String = "%s:surface_%d" % [mesh_path, surface_id]
	var type = Enums.MATERIAL_TYPE.ASSET if is_asset else Enums.MATERIAL_TYPE.INSTANCE
	if (
		surface_material_id.has(key)
		and surface_material_id[key] is Array
		and surface_material_id[key].size() == 2
		and surface_material_id[key][0] == type
		and surface_material_id[key][1] == material_id
	):
		return
	surface_material_id[key] = [type, material_id]
	await scaled_model.refresh_surface_material(mesh, surface_id)
	queue_update_network_object()


func set_shape_and_create_body(s: JShape3D) -> void:
	shape = s
	create_body()


func _on_net_sync_start_updating() -> void:
	scaled_model.show()
	_refresh_collision_layers()


func _on_net_sync_stop_updating() -> void:
	scaled_model.hide()
	set_layer_name(&"")
	body_mode = JBody3D.KINEMATIC


func _on_selected_peers_changed(o):
	if is_selected():
		if not Zone.instance_manager.remotely_selected_nodes.has(self):
			Zone.instance_manager.remotely_selected_nodes.push_back(self)
	else:
		Zone.instance_manager.remotely_selected_nodes.erase(self)

	if TMSceneSync.is_server():
		mark_as_changed()
	_refresh_collision_layers()
	_updates_selection_label()


func _updates_selection_label():
	# Updates the Selection Label
	if TMSceneSync.is_client():
		if is_selected():
			selection_label.show()
			var txt: String = ""
			var local_character = Zone.get_local_character()
			for p in selected_by_peers:
				if local_character and p == local_character.get_multiplayer_authority():
					continue
				var player: Player = Zone.find_player_by_peer(p)
				if player:
					txt += player.get_player_name() + "\n"
			selection_label.text = txt
		else:
			selection_label.hide()


func editmode_set_new_transform(new_transform: Transform3D):
	if TMSceneSync.is_server():
		return

	var nodes = TMSceneSync.local_controller_get_controlled_nodes()
	if nodes.size() != 1:
		return
	var local_character: TMCharacter3D = nodes[0]

	local_character.queue_interaction(self, &"_interaction_set_transform", new_transform)


func _interaction_set_transform(new_transform: Transform3D):
	global_transform = new_transform
	interpolated_node.update_space_object_transform(0.0, global_transform)


func get_creator() -> Dictionary:
	var creator_user_id: String = ""
	if space_object_data.has("creator"):
		if space_object_data["creator"] is Dictionary:
			creator_user_id = space_object_data["creator"].get("_id")
		elif space_object_data["creator"] is String:
			creator_user_id = space_object_data["creator"]
	else:
		# Compatibility: This is not used anymore for new objects.
		creator_user_id = space_object_data.get("receipt", {}).get("created_by_user", "")
	var result = {
		"user_id": creator_user_id,
		"name": _creator_name
	}
	if _creator_name.is_empty():
		var promise = Net.user_client.get_user_profile(creator_user_id)
		var user_data = await promise.wait_till_fulfilled()
		if promise.is_error():
			return result
		result["name"] = user_data.get("displayName", "Unknown")
		_creator_name = result["name"]
	return result


var npc_is_move_to_active: bool = false
var npc_steering_sphere: JSphereShape3D
var npc_target_position: Vector3
var npc_acceleration: float
var npc_deceleration: float
var npc_max_speed: float
var npc_step_height: float
var npc_max_push_force: float
var npc_supporting_height: float
var npc_gravity: float
var npc_min_target_distance: float
var npc_max_target_distance: float
var npc_base_position: Vector3
var npc_steering_ray_offset: Vector3
var npc_steering_ray_length: float
var npc_steering_ray_radius: float
var npc_steering_ignore: Array
var npc_rotation_offset: float
var npc_prev_position: Vector3
var npc_prev_position_heat: float = 0.0
var npc_prev_position_heat_max: float = 0.5
var npc_prev_position_heat_active: bool = false
var npc_prev_position_heat_motion: Vector3


func _process_npc(delta):
	if not is_kinematic():
		return

	var motion: Vector3

	var action := _npc_get_action()
	if action == "ON_TARGET" or action == "ON_BASE" or npc_is_move_to_active == false:
		npc_is_move_to_active = false
		server_npc_move_velocity(delta, Vector2(), npc_acceleration, npc_deceleration, 0.0, npc_step_height, npc_max_push_force, npc_supporting_height, npc_gravity)
		# Face toward the movement direction
		_npc_look_at(npc_target_position)
		return

	elif action == "MOVING_TO_TARGET":
		motion = npc_target_position - global_position

	else:
		motion = npc_target_position - global_position

	# The unstuck algorithm makes sure to provide a random location around the
	# SO when it detects that the NPC is stop implace for too long (1 sec)
	# This random location ensure the NPC to escape the hook.
	if npc_prev_position_heat_active:
		npc_prev_position_heat -= delta
		motion = npc_prev_position_heat_motion
		if npc_prev_position_heat <= 0.0:
			npc_prev_position_heat_active = false
	else:
		if (global_position - npc_prev_position).length() <= npc_steering_ray_radius:
			npc_prev_position_heat += delta
		else:
			npc_prev_position_heat -= delta
		npc_prev_position_heat = clamp(npc_prev_position_heat, 0.0, npc_prev_position_heat_max)
		if npc_prev_position_heat >= npc_prev_position_heat_max - 0.001:
			npc_prev_position_heat_active = true
			motion = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
			npc_prev_position_heat_motion = motion
	if npc_prev_position_heat <= 0.0:
		npc_prev_position = global_position

	if not is_instance_valid(npc_steering_sphere):
		npc_steering_sphere = JSphereShape3D.new()

	# The steering algorithm. Searches walls and try to avoid them.
	motion.y = 0.0
	var dir: Vector3 = motion.normalized()
	if not dir.is_zero_approx():
		npc_steering_sphere.radius = npc_steering_ray_radius
		var layers := [&"STATIC", &"KINEMATIC", &"CHARACTER", &"DYNAMIC"]
		var ignores := [self]
		ignores.append_array(npc_steering_ignore)
		var ray_length: float = max(0.0, min(npc_steering_ray_length, (global_position - npc_target_position).length() - npc_steering_ray_radius))
		var res: Array = Jolt.cast_shape(0, npc_steering_sphere, Transform3D(Basis(), global_position + npc_steering_ray_offset), dir * ray_length, layers, ignores)
		for hit in res:
			dir = (dir + hit.normal)
			dir.y = 0.0
			dir = dir.normalized()
			if dir.is_zero_approx():
				# There is a collision right in front of the character.
				# So, just move left.
				dir = motion.normalized()
				dir = Vector3.UP.cross(dir)
				dir.y = 0.0
				dir = dir.normalized()

		dir = motion.normalized().lerp(dir, 0.5)

	server_npc_move_velocity(
		delta,
		Vector2(dir.x, dir.z),
		npc_acceleration,
		npc_deceleration,
		npc_max_speed,
		npc_step_height,
		npc_max_push_force,
		npc_supporting_height,
		npc_gravity)

	# Face toward the movement direction
	_npc_look_at(global_position + linear_velocity.normalized())


func _npc_look_at(position: Vector3):
	if (position - global_position).length() < 0.1:
		return
	# Ensure the rotation is always around the Y axis.
	position.y = global_position.y
	look_at(position)
	# Look at uses -Z, while our NPC models are alligned toward +Z, therefore we need to rotate by 180 deg.
	rotate_y(PI + deg_to_rad(npc_rotation_offset))


func _npc_get_action() -> String:
	var motion: Vector3 = npc_target_position - global_position
	var motion_l: float = motion.length()
	if motion_l <= npc_min_target_distance:
		return "ON_TARGET"
	elif npc_max_target_distance > 0.0:
		if motion_l <= npc_max_target_distance:
			return "MOVING_TO_TARGET"
		else:
			motion = npc_base_position - global_position
			motion_l = motion.length()
			if motion_l <= npc_min_target_distance:
				return "ON_BASE"
			else:
				return "MOVING_TO_BASE"
	else:
		return "MOVING_TO_TARGET"


func npc_move_to(target_position: Vector3, acceleration: float, deceleration: float, max_speed: float, step_height: float, max_push_force: float, supporting_height: float, gravity: float, min_target_distance: float, max_target_distance: float, base_position: Vector3, steering_ray_offset: Vector3, steering_ray_length: float, steering_ray_radius: float, steering_ignore: Array, rotation_offset: float) -> String:
	npc_is_move_to_active = true
	npc_target_position = target_position
	npc_acceleration = acceleration
	npc_deceleration = deceleration
	npc_max_speed = max_speed
	npc_step_height = step_height
	npc_max_push_force = max_push_force
	npc_supporting_height = supporting_height
	npc_gravity = gravity
	npc_min_target_distance = min_target_distance
	npc_max_target_distance = max_target_distance
	npc_base_position = base_position
	npc_steering_ray_offset = steering_ray_offset
	npc_steering_ray_length = steering_ray_length
	npc_steering_ray_radius = steering_ray_radius
	npc_steering_ignore = steering_ignore
	npc_rotation_offset = rotation_offset

	return _npc_get_action()

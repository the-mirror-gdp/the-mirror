class_name SpaceGlobalScripts
extends Node


signal scripts_changed()

var _script_instances: Array[ScriptInstance]
var _queue_update_network_object_frames: int = 0


func _process(_delta: float) -> void:
	_queue_update_network_object_frames -= 1
	if _queue_update_network_object_frames == 0:
		_request_global_scripts_change_over_network()


func get_script_instances() -> Array[ScriptInstance]:
	return _script_instances


func add_script_instance(script_instance: ScriptInstance) -> void:
	_script_instances.append(script_instance)
	queue_update_network_object()
	scripts_changed.emit()


func delete_script_instance(script_instance: ScriptInstance) -> void:
	_script_instances.erase(script_instance)
	queue_update_network_object()
	scripts_changed.emit()


func queue_update_network_object() -> void:
	_queue_update_network_object_frames = 10


func load_global_script_instances(serialized_script_instances: Array) -> void:
	var existing: Array = serialize_global_script_instances()
	if str(serialized_script_instances) == str(existing):
		return # The data we were asked to load is the same as what we have.
	for script_instance in _script_instances:
		script_instance.cleanup_script_instance()
		script_instance.free()
	_script_instances.clear()
	for script_inst_dict in serialized_script_instances:
		var script_instance := ScriptInstance.create(script_inst_dict)
		await script_instance.setup(self, script_inst_dict)
		script_instance.request_save_script_instance.connect(_on_request_save_script_instance)
		_script_instances.append(script_instance)
	scripts_changed.emit()


func serialize_global_script_instances() -> Array:
	var serialized_script_instances: Array = []
	for script_inst in _script_instances:
		var serialized: Dictionary = script_inst.serialize_to_json()
		serialized_script_instances.append(serialized)
	return serialized_script_instances


func _request_global_scripts_change_over_network() -> void:
	var serialized: Array = serialize_global_script_instances()
	if Zone.is_host():
		Zone.server.server_update_global_scripts(serialized)
	else:
		Zone.send_data_to_server([Packet.TYPE.GLOBAL_SCRIPTS_CHANGE, serialized])


func _on_request_save_script_instance() -> void:
	queue_update_network_object()

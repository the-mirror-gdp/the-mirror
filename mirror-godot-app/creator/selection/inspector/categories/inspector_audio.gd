extends InspectorCategoryBase


var target_node: AudioStreamPlayer3D
var target_surface: int = -1

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _auto_play: Control = _property_list.get_node(^"AutoPlay")
@onready var _loop_audio: Control = _property_list.get_node(^"LoopAudio")
@onready var _base_volume: Control = _property_list.get_node(^"BaseVolume")
@onready var _speed_pitch: Control = _property_list.get_node(^"SpeedPitch")
@onready var _spatial_checkbox: Control = _property_list.get_node(^"SpatialCheckbox")
@onready var _spatial_subset: Control = _property_list.get_node(^"SpatialSubset/PropertyList")
@onready var _range: Control = _spatial_subset.get_node(^"Range")
@onready var _max_volume: Control = _spatial_subset.get_node(^"MaxVolume")


func _ready() -> void:
	refresh()
	super()
	if not target_node is SpaceObjectAudioPlayer3D:
		# If this method is missing, this isn't SpaceObject audio the inspector can modify.
		# Could be imported from GLTF. So prevent changing these properties.
		set_custom_suffix(" (read-only)")
		var overlay = Control.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		$Properties.add_child(overlay)


func refresh() -> void:
	update_active_fields_by_permissions()
	_auto_play.current_value = target_node.autoplay
	_speed_pitch.current_value = target_node.pitch_scale * 100.0
	if target_node is TMAudioPlayer3D:
		_loop_audio.current_value = target_node.loop_audio
		_base_volume.current_value = target_node.base_volume_percentage
		_spatial_checkbox.current_value = target_node.is_spatial
		_max_volume.current_value = target_node.spatial_max_volume_percentage
		_range.current_value = target_node.spatial_range
	else:
		_loop_audio.hide()
		_base_volume.current_value = db_to_linear(target_node.volume_db) * 100.0
		_spatial_checkbox.current_value = target_node.unit_size != INF
		_max_volume.current_value = db_to_linear(target_node.max_db) * 100.0
		_range.current_value = target_node.unit_size
	_spatial_subset.visible = _spatial_checkbox.current_value
	_base_volume.refresh()
	_speed_pitch.refresh()
	_range.refresh()
	_max_volume.refresh()


func _on_auto_play_value_changed(new_value: bool) -> void:
	target_node.autoplay = new_value
	if new_value and not target_node.playing:
		target_node.play()
	else:
		target_node.stop()
	_inspected_object_updated(target_node.get_parent())


func _on_loop_audio_value_changed(new_value: bool) -> void:
	if target_node is TMAudioPlayer3D:
		target_node.loop_audio = new_value
	else:
		Notify.error("Failed To Set Loop", "This audio player can't have its loopiness changed.")
		return
	_inspected_object_updated(target_node.get_parent())


func _on_base_volume_value_changed(new_value: float) -> void:
	if not _spatial_subset.visible:
		_max_volume.current_value = new_value
		_max_volume.refresh()
	if target_node is TMAudioPlayer3D:
		target_node.base_volume_percentage = new_value
	_inspected_object_updated(target_node.get_parent())


func _on_speed_pitch_value_changed(new_value: float) -> void:
	target_node.pitch_scale = new_value / 100.0
	_inspected_object_updated(target_node.get_parent())


func _on_spatial_checkbox_value_changed(new_value: bool) -> void:
	if target_node is SpaceObjectAudioPlayer3D:
		target_node.set_spatial(new_value)
	if target_node is TMAudioPlayer3D:
		target_node.is_spatial = new_value
	else:
		Notify.error("Failed To Set Spatial", "This audio player can't have its spatialness changed.")
		_spatial_checkbox.current_value = _spatial_subset.visible
		return
	_spatial_subset.visible = new_value
	_inspected_object_updated(target_node.get_parent())


func _on_range_value_changed(new_value: float) -> void:
	if target_node is TMAudioPlayer3D:
		target_node.spatial_range = new_value
	else:
		target_node.max_distance = new_value
	_inspected_object_updated(target_node.get_parent())


func _on_max_volume_value_changed(new_value: float) -> void:
	if target_node is TMAudioPlayer3D:
		target_node.spatial_max_volume_percentage = new_value
	else:
		target_node.max_db = linear_to_db(new_value / 100.0)
	_inspected_object_updated(target_node.get_parent())

class_name SpaceObjectAudioPlayer3D
extends TMAudioPlayer3D


const _AUDIO_GLOBAL_TEXTURE = preload("AudioStreamPlayer.svg")
const _AUDIO_SPATIAL_TEXTURE = preload("AudioStreamPlayer3D.svg")
const _AUDIO_SPRITE_SCENE = preload("audio_sprite.tscn")

var _audio_sprite: Sprite3D


func _ready() -> void:
	if Zone.is_in_edit_mode:
		_audio_sprite = _AUDIO_SPRITE_SCENE.instantiate()
		add_child(_audio_sprite)
		Zone.mode_changed.connect(_zone_mode_changed)


func set_spatial(in_is_spatial: bool) -> void:
	set_is_spatial(in_is_spatial)
	if _audio_sprite:
		_audio_sprite.texture = _AUDIO_SPATIAL_TEXTURE if is_spatial else _AUDIO_GLOBAL_TEXTURE


func populate(space_object_data: Dictionary) -> void:
	autoplay = space_object_data.get("audioAutoPlay", true)
	loop_audio = space_object_data.get("audioLoop", true)
	pitch_scale = space_object_data.get("audioPitch", 100.0) / 100.0
	set_spatial(space_object_data.get("audioIsSpatial", true))
	base_volume_percentage = space_object_data.get("audioBaseVolume", 100.0)
	spatial_range = space_object_data.get("audioSpatialRange", 0.0)
	spatial_max_volume_percentage = space_object_data.get("audioSpatialMaxVolume", 150.0)


func serialize_to_dictionary(space_object_data: Dictionary, delta_dict : Dictionary = Dictionary()) -> void:
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioAutoPlay", autoplay)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioLoop", loop_audio)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioPitch", pitch_scale * 100.0)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioBaseVolume", base_volume_percentage)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioIsSpatial", is_spatial)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioSpatialRange", spatial_range)
	Util.apply_delta_to_dict(space_object_data, delta_dict, "audioSpatialMaxVolume", spatial_max_volume_percentage)


func _zone_mode_changed(mode: ZoneClass.ZONE_MODE) -> void:
	# The audio sprite should never render when in play-mode.
	if not _audio_sprite:
		return
	_audio_sprite.visible = mode == ZoneClass.ZONE_MODE.EDIT

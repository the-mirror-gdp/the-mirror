class_name AudioClipAssetPlayer
extends TMAudioPlayer3D


func _init() -> void:
	name = "__AudioClipAssetPlayer" + str(get_instance_id())
	autoplay = true


func _ready() -> void:
	finished.connect(queue_free)


func play_from_asset_id(in_audio_asset_id: String, in_base_volume_percentage: float, in_speed: float, in_is_spatial: bool, in_spatial_range: float, in_spatial_max_volume_percentage: float) -> void:
	base_volume_percentage = in_base_volume_percentage
	spatial_max_volume_percentage = in_spatial_max_volume_percentage
	pitch_scale = in_speed
	spatial_range = in_spatial_range
	set_is_spatial(in_is_spatial)
	_load_audio_from_asset_id(in_audio_asset_id)


func _load_audio_from_asset_id(audio_asset_id: String) -> void:
	var audio_stream = await Net.asset_client.get_asset_file(audio_asset_id)
	if audio_stream is AudioStream:
		setup_audio(audio_stream)

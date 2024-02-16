extends BaseSetting


@onready var dropdown := $InspectorPropertyScroller

func _ready() -> void:
	super()
	_add_quality_settings()


func _add_quality_settings() -> void:
	var index = 0
	for key in GameplaySettings.RenderQuality.keys():
		dropdown.add_item(key)
		if GameplaySettings.RenderQuality[key] == current_value:
			dropdown.current_value = index
		index += 1
	dropdown.values = GameplaySettings.RenderQuality.keys()


func is_value_valid(value: Variant) -> bool:
	return value is int and (value >= GameplaySettings.RenderQuality.LOW and value <= GameplaySettings.RenderQuality.HIGH)


func apply_setting_to_ui(value: int) -> void:
	dropdown.current_value = value
	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.render_quality = dropdown.current_value


func convert_gameplay_value_for_ui():
	return GameplaySettings.render_quality

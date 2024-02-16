extends "res://ui/main_menu/pages/settings/sections/settings_section.gd"


@onready var _enable_microphone: PanelContainer = $Options/EnableMicrophone


func _ready() -> void:
	super()
	_enable_microphone.visible = GameplaySettings.CAN_DETECT_AUDIO_FROM_MIC

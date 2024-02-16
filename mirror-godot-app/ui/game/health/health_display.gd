class_name HealthDisplay
extends Control


const _DAMAGE_INDICATOR_SCENE_PATH = preload("res://ui/game/health/damage_indicator.tscn")

@export var _death_sound: AudioStream = null
@export var _respawn_sound: AudioStream = null

@onready var _damage_screen: Control = %DamageScreen
@onready var _damage_indicators_parent: Control = %DamageIndicators
@onready var _health_label: Label = %HealthLabel
@onready var _audio_player: AudioStreamPlayer = %AudioStreamPlayer

var _damage_screen_fade_speed: float = 1.5

const player_damage_is_enabled = "player_damage_is_enabled"

var are_variables_ready = false

func _ready() -> void:
	assert(_health_label)
	Zone.script_network_sync.global_variable_changed.connect(_space_var_updated)
	# We wait to make sure that the space_var is loaded,
	# and not just null because of being not-yet-loaded
	Zone.script_network_sync.variables_ready.connect( func ():
		are_variables_ready = true
	)


func _process(delta) -> void:
	_damage_screen.modulate.a = lerpf(_damage_screen.modulate.a, 0.0, delta * _damage_screen_fade_speed)


func show_damage_screen() -> void:
	_damage_screen.modulate.a = 1.0


func add_damage_indicator(attacker_position: Vector3) -> void:
	var indicator: Control = _DAMAGE_INDICATOR_SCENE_PATH.instantiate()
	_damage_indicators_parent.add_child(indicator)
	indicator.set_target(attacker_position)


func set_health(value: int) -> void:
	_health_label.text = str(value)


func play_death_sound() -> void:
	_audio_player.stream = _death_sound
	_audio_player.play()


func play_respawn_sound() -> void:
	_audio_player.stream = _respawn_sound
	_audio_player.play()


func update_visibility_by_space_var(
	space_var_value = Zone.script_network_sync.get_global_variable(player_damage_is_enabled)
) -> String:
	# We want to be invisible if the space_var is absent, so when it is null
	if space_var_value == null :
		visible = false
	else:
		visible = space_var_value
	var str_enableness = "enabled" if space_var_value else "disabled"
	return str_enableness


func _space_var_updated(variable_name: String, variable_value: Variant) -> void:
	if variable_name in [player_damage_is_enabled]:
		var str_enableness = update_visibility_by_space_var(variable_value)
		if GameUI and GameUI.chat_ui:
			GameUI.chat_ui.add_message_clientside("Player damage is now [i]%s[/i] on this space" % str_enableness)


func try_hide() -> void:
	# We make sure to reset this
	# It allows to make it work
	#   correctly on the next space connection
	are_variables_ready = false
	self.hide()


func try_show() -> void:
	if not are_variables_ready:
		await Zone.script_network_sync.variables_ready
	var str_enableness = self.update_visibility_by_space_var()
	if GameUI and GameUI.chat_ui:
		GameUI.chat_ui.add_message_clientside("Player damage is [i]%s[/i] on this space" % str_enableness)

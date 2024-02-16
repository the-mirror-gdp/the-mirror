extends HBoxContainer


@export var statistic_name: String = ""
@export var maximum: int = 10_000_000
## The text to show as a tooltip when hovering.
## Use this instead of Godot's tooltip_text property.
@export var hover_tooltip_text: String = ""

var _label_suffix: String = ""

@onready var _texture: TextureProgressBar = $TextureProgressBar
@onready var _name_label: Label = $Labels/NameLabel
@onready var _num_label: Label = $Labels/NumberLabel


func _ready():
	_name_label.text = statistic_name
	set_maximum(maximum)


func set_maximum(new_maximum: int) -> void:
	maximum = new_maximum
	_label_suffix = " of " + _large_integer_to_friendly_string(maximum).trim_prefix(" ")
	_texture.max_value = maximum


func set_progress(progress: int) -> void:
	_texture.value = progress
	var ratio: float = clamp(progress / float(_texture.max_value), 0.0, 1.0)
	_texture.tint_progress = Color.from_hsv((1.0 - ratio * ratio) / 3.0, 1.0, 1.0)
	_num_label.text = _large_integer_to_friendly_string(progress) + _label_suffix


## Returns a friendly-formatted number. Always returns 4 characters.
func _large_integer_to_friendly_string(number: int) -> String:
	if number < 2000:
		return "%4d" % number
	elif number < 10_000:
		@warning_ignore("integer_division")
		return "%3.1fK" % (number / 100 / 10.0)
	elif number < 1_000_000:
		@warning_ignore("integer_division")
		return "%3dK" % (number / 1000)
	elif number < 10_000_000:
		@warning_ignore("integer_division")
		return "%3.1fM" % (number / 100_000 / 10.0)
	elif number < 1_000_000_000:
		@warning_ignore("integer_division")
		return "%3dM" % (number / 1_000_000)
	elif number < 10_000_000_000:
		@warning_ignore("integer_division")
		return "%3.1fB" % (number / 100_000_000 / 10.0)
	else:
		@warning_ignore("integer_division")
		return "%3dB" % (number / 1_000_000_000)


func _on_hoverable_button_mouse_entered() -> void:
	if hover_tooltip_text == "":
		return
	GameUI.set_hover_tooltip_text(hover_tooltip_text)


func _on_hoverable_button_mouse_exited() -> void:
	GameUI.hide_hover_tooltip_text()

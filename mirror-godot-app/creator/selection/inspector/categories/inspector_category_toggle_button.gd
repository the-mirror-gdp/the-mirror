extends ButtonHighlight


signal inspector_category_visibility_changed(new_visibility: bool)

@export var expand_speed: float = 10.0
@export var properties: Node

## The text to show as a tooltip when hovering.
## Use this instead of Godot's tooltip_text property.
@export var hover_tooltip_text: String = ""

var _is_category_visible: bool = false
var _properties_child: Control
var _plus_texture: TextureRect
var _minus_texture: TextureRect
var _category_base: Control


func _ready() -> void:
	_properties_child = properties.get_child(0)
	_plus_texture = $Name/Plus
	_minus_texture = $Name/Minus
	_category_base = get_parent().get_parent()


func _process(delta: float) -> void:
	var size_y = _category_base.custom_minimum_size.y
	if _is_category_visible:
		size_y = lerpf(size_y, get_maximum_size_y(), delta * expand_speed)
	else:
		if size_y <= custom_minimum_size.y + 8.0:
			properties.visible = false
		if size_y <= custom_minimum_size.y + 0.1:
			size_y = custom_minimum_size.y
		else:
			size_y = lerpf(size_y, custom_minimum_size.y, delta * expand_speed)
	set_size_y(size_y)


func get_maximum_size_y() -> float:
	return size.y + maxf(_properties_child.size.y, _properties_child.custom_minimum_size.y)


func set_size_y(size_y) -> void:
	_category_base.custom_minimum_size.y = size_y
	_category_base.set_deferred("size.y", size_y)


func set_category_visible(new_is_visible):
	_is_category_visible = new_is_visible
	_plus_texture.visible = not _is_category_visible
	_minus_texture.visible = _is_category_visible
	if _is_category_visible:
		# When setting not visible, we let the animation play.
		properties.visible = true
	inspector_category_visibility_changed.emit(_is_category_visible)


func _on_toggle_button_pressed():
	set_category_visible(not _is_category_visible)


func _on_hoverable_button_mouse_entered() -> void:
	if hover_tooltip_text == "":
		return
	GameUI.set_hover_tooltip_text(hover_tooltip_text)


func _on_hoverable_button_mouse_exited() -> void:
	GameUI.hide_hover_tooltip_text()


func _on_hoverable_button_pressed() -> void:
	GameUI.hide_hover_tooltip_text()

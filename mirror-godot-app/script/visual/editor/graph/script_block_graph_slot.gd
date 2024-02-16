extends HBoxContainer


signal request_input_value_edit(input_port: ScriptBlock.ScriptBlockInputPort)

# Keep this in sync with ScriptBlockInputValueDialog's inspector primitives.
const _EDITABLE_PORT_TYPES = [
	ScriptBlock.PortType.ANY_DATA,
	ScriptBlock.PortType.BOOL,
	ScriptBlock.PortType.INT,
	ScriptBlock.PortType.FLOAT,
	ScriptBlock.PortType.STRING,
	ScriptBlock.PortType.VECTOR2,
	ScriptBlock.PortType.VECTOR3,
	ScriptBlock.PortType.COLOR,
]

@onready var _left_icon: TextureButton = $LeftIcon
@onready var _left_value: Button = $LeftValue
@onready var _left_label: Label = $LeftLabel
@onready var _right_icon: TextureRect = $RightIcon
@onready var _right_label: Label = $RightLabel
@onready var _error_label: Label = $CenterSpacer/ErrorLabel


func setup_right(port_name: String, port_type: int) -> void:
	_right_label.text = port_name
	_right_icon.texture = _get_port_type_icon(port_type)


func setup_left_sequence() -> void:
	_left_icon.texture_normal = preload("res://script/visual/editor/icons/sequence.svg")
	_left_icon.texture_hover = preload("res://script/visual/editor/icons/sequence_hover.svg")
	_left_icon.pressed.connect(_run_block)


func setup_left_data(input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	_left_label.text = input_port.port_name
	_left_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_icon.texture_normal = _get_port_type_icon(input_port.port_type)
	if input_port.connected_output != -1 or input_port.port_type not in _EDITABLE_PORT_TYPES:
		return # Don't show value button for connected or non-editable ports.
	_left_value.text = str(input_port.value)
	_left_value.pressed.connect(_edit_input_value.bind(input_port))
	_left_value.value_dropped.connect(_set_input_value.bind(input_port))
	_left_value.drop_enabled = input_port.port_type == ScriptBlock.PortType.ANY_DATA \
			or input_port.port_type == ScriptBlock.PortType.STRING
	_left_value.show()


func hide_left() -> void:
	_left_icon.hide()
	_left_label.hide()
	_left_value.hide()


func hide_right() -> void:
	_right_icon.hide()
	_right_label.hide()


func show_error(error_text: String) -> void:
	_error_label.text = error_text
	_error_label.show()


func hide_error() -> void:
	_error_label.text = ""
	_error_label.hide()


func _run_block():
	# While it may be slightly more organized to make this another signal and
	# connect it in the graph node script, honestly, that would be a ton of
	# extra signal connection for basically no practical benefit in this case.
	get_parent().execute()


func _edit_input_value(input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	request_input_value_edit.emit(input_port)


func _set_input_value(value, input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if input_port.port_type != ScriptBlock.PortType.ANY_DATA:
		value = type_convert(value, input_port.port_type)
	input_port.value = value
	_left_value.text = str(value)


func _get_port_type_icon(port_type: ScriptBlock.PortType) -> Texture2D:
	match port_type:
		ScriptBlock.PortType.ANY_DATA:
			return preload("res://script/visual/editor/icons/any_variant.svg")
		ScriptBlock.PortType.BOOL:
			return preload("res://script/visual/editor/icons/bool.svg")
		ScriptBlock.PortType.INT:
			return preload("res://script/visual/editor/icons/int.svg")
		ScriptBlock.PortType.FLOAT:
			return preload("res://script/visual/editor/icons/float.svg")
		ScriptBlock.PortType.STRING:
			return preload("res://script/visual/editor/icons/string.svg")
		ScriptBlock.PortType.VECTOR2:
			return preload("res://script/visual/editor/icons/vector2.svg")
		ScriptBlock.PortType.VECTOR3:
			return preload("res://script/visual/editor/icons/vector3.svg")
		ScriptBlock.PortType.COLOR:
			return preload("res://script/visual/editor/icons/color.svg")
		ScriptBlock.PortType.OBJECT:
			return preload("res://script/visual/editor/icons/object.svg")
		ScriptBlock.PortType.DICTIONARY:
			return preload("res://script/visual/editor/icons/dictionary.svg")
		ScriptBlock.PortType.ARRAY:
			return preload("res://script/visual/editor/icons/array.svg")
		ScriptBlock.PortType.SEQUENCE:
			return preload("res://script/visual/editor/icons/sequence.svg")
		ScriptBlock.PortType.CONNECTION:
			return preload("res://script/visual/editor/icons/any_variant.svg")
	return preload("res://script/visual/editor/icons/error.svg")


func _on_left_value_mouse_entered() -> void:
	GameUI.set_hover_tooltip_text("Click here to edit the " + _left_label.text + " input.")


func _on_left_sequence_run_icon_mouse_entered() -> void:
	GameUI.set_hover_tooltip_text("Click here to run this block. This is useful for testing pieces of your script.")


func _on_mouse_exited() -> void:
	GameUI.hide_hover_tooltip_text()

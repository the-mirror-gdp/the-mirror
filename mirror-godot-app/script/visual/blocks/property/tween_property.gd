class_name ScriptBlockTweenProperty
extends ScriptBlockOperationProperty


const TRANSITION_NAMES_TO_VALUES: Dictionary = {
	"Linear": Tween.TRANS_LINEAR,
	"Sine": Tween.TRANS_SINE,
	"Quint": Tween.TRANS_QUINT,
	"Quart": Tween.TRANS_QUART,
	"Quad": Tween.TRANS_QUAD,
	"Expo": Tween.TRANS_EXPO,
	"Elastic": Tween.TRANS_ELASTIC,
	"Cubic": Tween.TRANS_CUBIC,
	"Circ": Tween.TRANS_CIRC,
	"Bounce": Tween.TRANS_BOUNCE,
	"Back": Tween.TRANS_BACK,
}

const EASING_NAMES_TO_VALUES: Dictionary = {
	"In": Tween.EASE_IN,
	"Out": Tween.EASE_OUT,
	"In Out": Tween.EASE_IN_OUT,
	"Out In": Tween.EASE_OUT_IN,
}


func _execute_callback(stack_count: int) -> Error:
	assert(inputs.size() == 5) # Should be exactly five inputs for the target object and value.
	var target_object: Object = get_operation_target_object()
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	if not target_object is Node:
		log_error.emit("The target object is not a node, but tweening properties is only supported on nodes for now.")
		return ERR_INVALID_PARAMETER
	if not property_name in target_object:
		log_error.emit("The target object does not have the requested property (" + String(property_name) + ").")
		return ERR_METHOD_NOT_FOUND
	var property_value: Variant = target_object.get(property_name)
	var final_value: Variant = inputs[1].value
	if final_value is Object:
		log_error.emit("Cannot tween an Object value.")
		return ERR_INVALID_PARAMETER
	var duration: float = inputs[2].value
	var transition: Tween.TransitionType = TRANSITION_NAMES_TO_VALUES.get(inputs[3].value, Tween.TRANS_LINEAR)
	var easing: Tween.EaseType = EASING_NAMES_TO_VALUES.get(inputs[4].value, Tween.EASE_IN_OUT)
	# This will also tween it locally on the next frame (avoids race conditions).
	Zone.script_network_sync.tween_property_on_node(target_object, property_name, final_value, duration, transition, easing)
	if outputs.size() > 0:
		outputs[0].value = target_object
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[3] or input_port == inputs[4]


func get_enum_values(input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	if input_port == inputs[3]:
		return TRANSITION_NAMES_TO_VALUES.keys()
	if input_port == inputs[4]:
		return EASING_NAMES_TO_VALUES.keys()
	assert(false, "Should not be reached, the code should never try to get the enum values from a non-enumerated port.")
	return []


func get_script_block_type() -> String:
	return "tween_property"

extends ScriptBlock


func evaluate() -> void:
	evaluate_inputs()
	var minimum: float = inputs[0].value
	var maximum: float = inputs[1].value
	var step: float = inputs[2].value
	if step == 0.0:
		outputs[0].value = randf_range(minimum, maximum)
	else:
		# Unfortunately Godot's random numbers are inclusive, so the built-in
		# randomness is not very helpful and we need to do things manually.
		# The end result is still inclusive though.
		var buckets: int = roundi((maximum - minimum) / step) + 1
		outputs[0].value = (randi() % buckets) * step + minimum


func get_script_block_type() -> String:
	return "random_number"

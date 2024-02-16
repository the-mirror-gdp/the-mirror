class_name ScriptBlockConstantExpression
extends ScriptBlock


func setup(block_json: Dictionary) -> void:
	_setup_base(block_json)
	# This is technically not necessary, but it gives us the
	# opportunity to remind users that their script is broken.
	parse_and_execute_expression(inputs[0].value)


func evaluate() -> void:
	# Nothing to evaluate, all evaluation is done while the user is coding.
	evaluated = true


func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	parse_and_execute_expression(edited_input_port.value)


func parse_and_execute_expression(expression_text: String) -> void:
	var expression := Expression.new()
	var err = expression.parse(expression_text)
	if err == OK:
		if graph_node:
			graph_node.hide_error()
	else:
		log_error.emit("Could not parse the expression " + expression_text)
		return
	outputs[0].value = expression.execute()
	outputs[0].port_type = typeof(outputs[0].value)


func get_script_block_type() -> String:
	return "constant_math_expression"

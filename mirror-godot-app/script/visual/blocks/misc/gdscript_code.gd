class_name ScriptBlockGDScriptCode
extends ScriptBlockSequenced


var gdscript_code: String = ""


func setup(block_json: Dictionary) -> void:
	super(block_json)
	if block_json.has("code"):
		gdscript_code = String(block_json["code"])
	compile()


func compile() -> void:
	pass # TODO compile GDScript and perform validation/whitelisting/safety checks.


func _execute_callback(_stack_count: int) -> Error:
	for input in inputs:
		pass # TODO handle inputting data to the GDScript code (use vars?).
	# TODO execute the GDScript code.
	for output in outputs:
		pass # TODO handle outputting data from the GDScript code (use vars?).
	return OK


func get_script_block_type() -> String:
	return "gdscript_code"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "gdscript_code"
	ret["code"] = gdscript_code
	return ret

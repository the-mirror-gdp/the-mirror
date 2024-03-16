extends CodeEdit


const _ENTRY_GUTTER_INDEX: int = 1
const _SCRIPT_CALLBACK_GUTTER_ICON = preload("res://script/gd/editor/icons/script_callback.svg")
const _SCRIPT_ENTRY_GUTTER_ICON = preload("res://script/gd/editor/icons/script_entry.svg")


func _init() -> void:
	add_gutter(_ENTRY_GUTTER_INDEX)
	set_gutter_type(_ENTRY_GUTTER_INDEX, TextEdit.GUTTER_TYPE_ICON)
	set_gutter_name(_ENTRY_GUTTER_INDEX, "tm_entry_gutter")
	set_gutter_draw(_ENTRY_GUTTER_INDEX, true)


func clear_entry_connection_decoration() -> void:
	set_gutter_width(_ENTRY_GUTTER_INDEX, get_line_height())
	for line_index in range(get_line_count()):
		set_line_gutter_icon(line_index, _ENTRY_GUTTER_INDEX, null)


func load_entry_connection_decoration(gdscript_instance: GDScriptInstance) -> void:
	clear_entry_connection_decoration()
	# Set up callback icons. Keep this in sync with GDScriptInstance _preprocess_and_apply_code.
	var source_code: String = gdscript_instance.get_source_code()
	var start: int = -1
	if gdscript_instance.target_node is SpaceObject:
		start = source_code.find("func _ready(")
		if start != -1:
			var line_number: int = source_code.count("\n", 0, start)
			set_line_gutter_icon(line_number, _ENTRY_GUTTER_INDEX, _SCRIPT_CALLBACK_GUTTER_ICON)
	start = source_code.find("func _physics_process(")
	if start != -1:
		var line_number: int = source_code.count("\n", 0, start)
		set_line_gutter_icon(line_number, _ENTRY_GUTTER_INDEX, _SCRIPT_CALLBACK_GUTTER_ICON)
	start = source_code.find("func _process(")
	if start != -1:
		var line_number: int = source_code.count("\n", 0, start)
		set_line_gutter_icon(line_number, _ENTRY_GUTTER_INDEX, _SCRIPT_CALLBACK_GUTTER_ICON)
	# Set up entry function lines using the entry icon.
	for entry_line_number in gdscript_instance.get_entry_line_numbers():
		set_line_gutter_icon(entry_line_number, _ENTRY_GUTTER_INDEX, _SCRIPT_ENTRY_GUTTER_ICON)


func set_code_text_but_keep_navigation(source_code: String) -> void:
	var nav_state: Dictionary = _save_navigation_state()
	text = source_code
	_load_navigation_state(nav_state)


func _save_navigation_state() -> Dictionary:
	var carets: Array[Dictionary] = []
	for i in range(get_caret_count()):
		carets.append({
			"column": get_caret_column(i),
			"line": get_caret_line(i),
		})
	return {
		"carets": carets,
		"scroll_horizontal": scroll_horizontal,
		"scroll_vertical": scroll_vertical,
	}


func _load_navigation_state(nav_state: Dictionary) -> void:
	remove_secondary_carets()
	var carets: Array[Dictionary] = nav_state["carets"]
	var caret_count: int = carets.size()
	for caret_index in range(caret_count):
		var caret_dict: Dictionary = carets[caret_index]
		if caret_index == 0:
			set_caret_line(caret_dict["line"], false, caret_index)
			set_caret_column(caret_dict["column"], false, caret_index)
		else:
			add_caret(caret_dict["line"], caret_dict["column"])
	scroll_horizontal = nav_state["scroll_horizontal"]
	scroll_vertical = nav_state["scroll_vertical"]

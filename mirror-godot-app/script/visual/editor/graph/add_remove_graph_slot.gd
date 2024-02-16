extends HBoxContainer


func setup_add_remove_slot(add: Callable, remove: Callable, custom_name: String = "") -> void:
	var add_case: Button = get_node(^"AddSlotButton")
	add_case.pressed.connect(add)
	var remove_case: Button = get_node(^"RemoveSlotButton")
	remove_case.pressed.connect(remove)
	if not custom_name.is_empty():
		add_case.text = "Add " + custom_name
		remove_case.text = "Remove " + custom_name

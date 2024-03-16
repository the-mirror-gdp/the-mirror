extends BasePopup


func create_popup(title: String, description: String, is_closable: bool = true) -> void:
	if not description.is_empty():
		description = "[center]" + description + "[/center]"
	super(title, description, is_closable)

extends ConfirmationDialog


const _DELETE_PROMPT_TEXT = "Are you sure you wish to delete this %s? This cannot be undone."

@onready var delete_are_you_sure: Label = $DeleteAreYouSure


func prompt_for_deletion(target_name: String, where: Vector2i) -> void:
	title = "Delete " + target_name
	delete_are_you_sure.text = _DELETE_PROMPT_TEXT % target_name.to_lower()
	popup(Rect2i(where, Vector2i(0, 0)))

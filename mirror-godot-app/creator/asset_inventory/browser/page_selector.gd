class_name PageSelector
extends HBoxContainer


signal page_changed(new_page_num)

var page_amount:
	get: return current_page.max_value

@onready var current_page: Range = $CurrentPage


func _ready() -> void:
	current_page.value = 1
	current_page.min_value = 1
	current_page.max_value = 1
	var line_edit = $CurrentPage.get_line_edit()
	line_edit.focus_entered.connect(_on_focus_entered)
	line_edit.focus_exited.connect(_on_focus_exited)


func set_range(pg_amount: int) -> void:
	current_page.min_value = 1
	current_page.max_value = pg_amount


func get_page() -> int:
	return int(current_page.value)


func _on_page_changed(new_page_num: int) -> void:
	page_changed.emit(new_page_num)


func _on_first_page_pressed() -> void:
	current_page.value = current_page.min_value


func _on_last_page_pressed() -> void:
	current_page.value = current_page.max_value


func _on_prev_page_pressed():
	current_page.value -= 1.0


func _on_next_page_pressed():
	current_page.value += 1.0


func _on_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.instance.release_input_lock(self)

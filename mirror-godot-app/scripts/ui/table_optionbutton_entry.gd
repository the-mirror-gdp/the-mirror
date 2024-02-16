extends OptionButton

signal option_selected()

# used for assigning correct index based on id
@onready var value_id: int = -1:
	set(value):
		value_id = value
		select(get_item_index(value))


func _ready() -> void:
	item_selected.connect(_on_item_selected)


func _on_item_selected(index: int) -> void:
	value_id = get_item_id(index)
	# Emit a signal without arguments to comply with Table API
	option_selected.emit()

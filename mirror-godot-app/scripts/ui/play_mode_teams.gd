class_name TeamWindowPlayMode
extends Control


signal close_team_menu()

@onready var table: Table = $Control/body/VBoxContainer/table_container


func _ready():
	# The data mapping
	# This is used to extract the properties and reset the input row
	# An example is provided with the correct columns for teams
	table.default_data_mapping = {
		# specify the team name by the text mapping on the column "team_name"
		# when the "text_changed" signal is called bind the row and column information
		# and call the table changed signal
		"team_name": {
			"mapping": "text"
		},
		# specify team color, and which column to take the data for the state
		# color changed is the signal used for when the state is updated
		# to push the row and column state to the parent component
		"team_color": {
			"mapping": "color"
		},
		# when the button is pressed map the pressed signal for the row to a row and column
		"join_team_button": {
			# calls the table changed event with one nuance the signal has less arguments, requires two signals to be bound.
			"internal_event" : "pressed"
		}
	}


func close_button_pressed() -> void:
	close_team_menu.emit()

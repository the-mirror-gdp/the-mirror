extends Label


@export var tool_number = 1


func _ready():
	var os_cmd: String = "CMD" if OS.get_name() == "macOS" else "CTRL"
	self.text = "%s + %s" % [os_cmd, str(tool_number)]

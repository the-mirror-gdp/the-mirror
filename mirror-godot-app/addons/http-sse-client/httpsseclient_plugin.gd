@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("HTTPSSEClient", "_node", preload("http_sse_client.gd"), preload("icon.png"))


func _exit_tree():
	remove_custom_type("HTTPSSEClient")

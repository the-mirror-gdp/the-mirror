@tool
extends EditorPlugin


var _export_plugin: ExportCompressedBinary = ExportCompressedBinary.new()


func _enter_tree():
	add_export_plugin(_export_plugin)


func _exit_tree():
	remove_export_plugin(_export_plugin)

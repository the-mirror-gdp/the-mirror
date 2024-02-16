@tool
extends Control


func _on_clear_cache_btn_pressed() -> void:
	# Delete everything. Use git clean if git is available.
	OS.move_to_trash(ProjectSettings.globalize_path("user://"))
	OS.move_to_trash(ProjectSettings.globalize_path("res://.godot/"))
	OS.execute("git", PackedStringArray(["clean", "-fdX"]))
	# Now that we've nuked all the cache, we need to regenerate it.
	# One option is to do this: editor_interface.get_resource_filesystem().reimport_files(files)
	# If we try to reimport files while this editor is running, Godot will
	# spam errors while it is reimporting files, and the editor will still
	# not work quite right until restarted anyway. When we restart, it will
	# successfully reimport the files. Therefore, we need to restart Godot.
	EditorInterface.restart_editor()


func _on_clear_client_assets_pressed() -> void:
	OS.move_to_trash(ProjectSettings.globalize_path("user://files"))

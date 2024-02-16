@tool
class_name ExportCompressedBinary
extends EditorExportPlugin


const UtilsClass = preload("res://scripts/autoload/util_funcs.gd")

var _export_platform: String = ""
var _features: PackedStringArray = PackedStringArray()
var _path: String = ""


func _get_name() -> String:
	return "ExportCompressedBinary"


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int):
	print("started export, features: ", features, " path: ", path)
	_features = features
	_path = path


func _export_end() -> void:
	print("finished export - making cicd specific binaries")
	assert(not _path.is_empty())
	assert(not _features.is_empty())
	if _export_platform.is_empty():
		return
	# We compress platforms we support, but not game server builds
	# The game server builds are a special case and are uploaded in two files.
	# They are uncompressed to gcp.
	build_single_platform_for_distribution(_export_platform, _path)


static func _get_platform_name(platform: EditorExportPlatform) -> String:
# There is not complete documentation in the godot sources how to do this kind of thing
# So I am leaving these prints to make it clearer how to get the platform
# There isn't something you can directly query since it is using an interface
#	print("platform: ", platform)
#	print("linux match: ", platform is EditorExportPlatformLinuxBSD)
#	print("windows match ", platform is EditorExportPlatformWindows)
#	print("macos match ", platform is EditorExportPlatformMacOS)
# note: platforms here are very specific for CICD not for internal godot type names
# refactoring these is not a good idea as the mirror-server looks for these names in the zip.
	if platform is EditorExportPlatformLinuxBSD:
		return "linuxbsd"
	elif platform is EditorExportPlatformWindows:
		return "windows"
	elif platform is EditorExportPlatformMacOS:
		return "macos"
	return ""


func _begin_customize_scenes(platform, features):
	print("platform is ", platform)
	_export_platform = _get_platform_name(platform)
	return false


# Build platform
# Creates json files and assosiate md5's for all the files
# Packages the file download size and the executable name
# Compresses the build into appropriate .zip and tar.gz files for the CICD buckets.
static func build_single_platform_for_distribution(platform_name: String, path: String):
	var app_version_string: String = UtilsClass.get_version_string()
	var manifest_version: Dictionary = {
		"version": app_version_string
	}
	var directory: String = path.get_base_dir()
	# Used for importing the data into the CICD environment variables
	# Reference: see "Retrieve version information from platform data" in the client_build_tool.yaml
	# This also names the output binary based on the platform name when being uploaded to the Google cloud buckets.
	# i.e. macos.zip
	# windows.zip
	# etc.
	UtilsClass.write_text_file(directory.path_join("version.json"), JSON.stringify(manifest_version, "    "))
	UtilsClass.write_text_file(directory.path_join("version.txt"), app_version_string)
	UtilsClass.write_text_file(directory.path_join("platform_name.txt"), platform_name)
	var compressed_filename: String = directory.path_join(platform_name + ".tar.gz")
	print("Compressing platform: ", platform_name, " into file ", compressed_filename)
	if _compress_build(path, compressed_filename):
		var build_hash = _get_file_sha256(compressed_filename)
		var file = FileAccess.open(compressed_filename, FileAccess.READ)
		if not file:
			push_error("Critical: Could not open the new compressed file because of this Error: %s" % FileAccess.get_open_error())
			return false
		var download_size: int = file.get_length()
		if build_hash.is_empty():
			push_error("Critical: Empty hash detected in build, cancelling platform build.")
			return false
		var packed_dict: Dictionary = {
			"packed_md5_hash": build_hash,
			"file_download_size": download_size,
			"executable_name": path.get_file(),
		}
		print("Writing ", platform_name, ".json. contents: ", packed_dict)
		UtilsClass.write_text_file(directory + "/" + platform_name + ".json", JSON.stringify(packed_dict, "\t"))
		if UtilsClass.compare_hash(compressed_filename, build_hash):
			print("Successfully packaged platform: ", platform_name)
			return true
		push_error("Critical: Hash validation failed - it is unlikely this build will work: ", platform_name, ", version: ", app_version_string)
	push_error("Critial: Compression failed for the platform: ", platform_name, ", version: ", app_version_string)
	return false


static func _compress_build(executable_path: String, build_compression_tar_gz: String) -> bool:
	print("Compressing build for storage consumption")
	print("Compressing ", build_compression_tar_gz)
	var base_dir = executable_path.get_base_dir()
	var file_name = executable_path.get_file()
	var tar_args: PackedStringArray = ["-C", base_dir, "-czvf", build_compression_tar_gz, file_name]
	var output: Array = []
	# Compress build for storage and distribution.
	if UtilsClass.get_current_platform_name() == "macos":
		print("tar", tar_args)
		var err: int = OS.execute("tar", tar_args, output, true)
		return err == OK
	else:
		var executable_name: PackedStringArray = executable_path.get_file().rsplit(".", true, 1)
		var pck_name: String = executable_name[0] + ".pck"
		print("pck name: ", pck_name)
		tar_args.append(pck_name)
		print("tar", tar_args)
		var err: int = OS.execute("tar", tar_args, output, true)
		return err == OK
	print("Failed to compress tar archive: ", output)
	return false


static func _get_file_sha256(local_file: String) -> String:
	if local_file.is_empty():
		push_error("Invalid local file to compare hash for.")
		return ""
	if FileAccess.file_exists(local_file):
		return FileAccess.get_sha256(local_file)
	return ""

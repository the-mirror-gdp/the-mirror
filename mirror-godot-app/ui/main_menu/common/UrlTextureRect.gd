class_name UrlTextureRect
extends TextureRect


var _url: String = ""


func set_image_from_url(url: String, priority: Enums.DownloadPriority = Enums.DownloadPriority.HIGHEST) -> void:
	_url = url
	if url.is_empty():
		return
	if Net.file_client.files.has(url):
		texture = Net.file_client.files[url]
		return
	var promise = Net.file_client.get_file(url, priority)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error loadig url image: %s Err: %s" % [url, promise.get_error_message()])
		return
	texture = promise.get_result()

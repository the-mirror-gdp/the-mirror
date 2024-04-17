## Notify: Autoload singleton for notifications, not dependent on GameUI.instance.
extends Node


var _notifications_ui: NotificationsUI = null


func _ready() -> void:
	## TODO: Fix this to use a signal to wait for the UI, this code is dumb
	await get_tree().process_frame
	if Zone.is_client() and has_node(^"/root/GameUI/instance"):
		_notifications_ui = get_node(^"/root/GameUI/instance").notifications_ui
		Zone.notifications_ready = true
		Zone.notifications_started.emit()


## used so we can get the popup and clear it.
func get_notifications_ui():
	return _notifications_ui


## Use for generic informational messages.
@rpc("call_remote", "authority", "reliable")
func info(title: String, description: String, click_callable = null, is_static: bool = false, is_closable: bool = true, clickable_url = null) -> void:
	if Zone.is_host():
		info.rpc(title, description)
	if _notifications_ui:
		_notifications_ui.notify(title, description, click_callable, is_static, is_closable, clickable_url)
	else:
		_print_with_color("blue", title, description)


## Use for success messages.
@rpc("call_remote", "authority", "reliable")
func success(title: String, description: String, click_callable = null) -> void:
	if Zone.is_host():
		success.rpc(title, description)
	if _notifications_ui:
		_notifications_ui.notify_success(title, description, click_callable)
	else:
		_print_with_color("green", title, description)


## Use for warning messages.
@rpc("call_remote", "authority", "reliable")
func warning(title: String, description: String, click_callable = null) -> void:
	if Zone.is_host():
		warning.rpc(title, description)
	if _notifications_ui:
		_notifications_ui.notify_warning(title, description, click_callable)
	else:
		_print_with_color("yellow", title, description)


## Use for error messages.
@rpc("call_remote", "authority", "reliable")
func error(title: String, description: String, click_callable = null, is_static: bool = false, is_closable: bool = true) -> void:
	if Zone.is_host():
		error.rpc(title, description)
	if _notifications_ui:
		_notifications_ui.notify_error(title, description, click_callable, is_static, is_closable)
	else:
		_print_with_color("red", title, description)


@rpc("call_remote", "authority", "reliable")
func status(title: String, description: String, status_enum: Enums.NotifyStatus, click_callable = null) -> void:
	if Zone.is_host():
		status.rpc(title, description, status_enum)
	if _notifications_ui:
		_notifications_ui.notify_status(title, description, status_enum, click_callable)
	else:
		match status:
			Enums.NotifyStatus.INFO:
				_print_with_color("blue", title, description)
			Enums.NotifyStatus.SUCCESS:
				_print_with_color("green", title, description)
			Enums.NotifyStatus.WARNING:
				_print_with_color("yellow", title, description)
			Enums.NotifyStatus.ERROR:
				_print_with_color("red", title, description)

func _print_with_color(color: String, text: String, description: String) -> void:
	print_rich("[color=" + color + "][b]" + text + "[/b]: " + description + "[/color]")

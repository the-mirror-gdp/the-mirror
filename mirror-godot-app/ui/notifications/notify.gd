## Notify: Autoload singleton for notifications, not dependent on GameUI.
extends Node


var _notifications_ui: NotificationsUI = null


func _ready() -> void:
	await get_tree().process_frame
	if Zone.is_client() and has_node(^"/root/GameUI"):
		_notifications_ui = get_node(^"/root/GameUI").notifications_ui
		Zone.notifications_ready = true
		Zone.notifications_started.emit()


## used so we can get the popup and clear it.
func get_notifications_ui():
	return _notifications_ui


## Use for generic informational messages.
func info(title: String, description: String, click_callable = null, is_static: bool = false, is_closable: bool = true, clickable_url = null) -> void:
	if _notifications_ui:
		_notifications_ui.notify(title, description, click_callable, is_static, is_closable, clickable_url)
	else:
		_print_with_color("blue", title, description)


## Use for success messages.
func success(title: String, description: String, click_callable = null) -> void:
	if _notifications_ui:
		_notifications_ui.notify_success(title, description, click_callable)
	else:
		_print_with_color("green", title, description)


## Use for warning messages.
func warning(title: String, description: String, click_callable = null) -> void:
	if _notifications_ui:
		_notifications_ui.notify_warning(title, description, click_callable)
	else:
		_print_with_color("yellow", title, description)


## Use for error messages.
func error(title: String, description: String, click_callable = null, is_static: bool = false, is_closable: bool = true) -> void:
	if _notifications_ui:
		_notifications_ui.notify_error(title, description, click_callable, is_static, is_closable)
	else:
		_print_with_color("red", title, description)


func status(title: String, description: String, status: Enums.NotifyStatus, click_callable = null) -> void:
	if _notifications_ui:
		_notifications_ui.notify_status(title, description, status, click_callable)
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

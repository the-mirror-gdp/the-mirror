extends Node
class_name WebSocketClient

@export var handshake_headers : PackedStringArray
@export var supported_protocols : PackedStringArray
@export var tls_trusted_certificate : X509Certificate
@export var tls_verify := true


var _socket : WebSocketPeer = WebSocketPeer.new()
var _first_connection = true
var _just_closed = true


signal connected_to_server()
signal connection_closed()
signal message_received(message: Variant)


func connect_to_url(url) -> int:
	_socket.set_inbound_buffer_size(_socket.get_inbound_buffer_size() * 16)
	_socket.set_outbound_buffer_size(_socket.get_outbound_buffer_size() * 16)
	_socket.supported_protocols = supported_protocols
	_socket.handshake_headers = handshake_headers
	var tls := TLSOptions.client(tls_trusted_certificate)
	var err = _socket.connect_to_url(url, tls) #, tls_verify, tls_trusted_certificate)
	if err != OK:
		return err
	return OK


func send(message) -> int:
	if typeof(message) == TYPE_STRING:
		return _socket.send_text(message)
	return _socket.send(var_to_bytes(message))


func decode_packet(packet : PackedByteArray) -> String:
	if _socket.was_string_packet():
		return packet.get_string_from_utf8()
	return bytes_to_var(packet)


func close(code := 1000, reason := "") -> void:
	_socket.close(code, reason)


func clear() -> void:
	_socket = WebSocketPeer.new()


func get_socket() -> WebSocketPeer:
	return _socket


func _process(_delta):
	_socket.poll()
	var state = _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		# first connection
		if _first_connection:
			print("Connected to server WS")
			connected_to_server.emit()
			_first_connection = false
			_just_closed = true
		# packet decoding
		while _socket.get_available_packet_count():
			var raw_packet : PackedByteArray = _socket.get_packet()
			var decoded_packet = decode_packet(raw_packet)
			# print("Incoming web socket packet: raw: decoded: ", decoded_packet)
			message_received.emit(decoded_packet)
	elif state == WebSocketPeer.STATE_CLOSING:
		push_error("Server requested web socket closure")
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		if _just_closed:
			print("Web Socket Closed")
			_just_closed = false
			_first_connection = true
			connection_closed.emit()

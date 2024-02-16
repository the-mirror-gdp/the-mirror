class_name JWT


enum Error {
	OK = 0,
	ERR_INVALID_DATA = 1,
	ERR_UNSUPPORTED_ALGORITHM = 2,
	ERR_EXPIRED = 3,
}


static func _convert_base64(base64: String) -> String:
	var mod = base64.length() % 4
	if mod > 0:
		for _i in range(4 - mod):
			base64 += "="
	return base64.replace("-", "+").replace("_", "/")


# IMPORTANT SECURITY NOTE: THIS ONLY PARSES/DECODES A JWT. IT DOES NOT VALIDATE IT. VALIDATION NEEDS TO BE DONE VIA THE FIREBASE SDK
static func parse(jwt_string: String, key: String) -> Dictionary:
	var return_dict = {
		"Error": OK,
	}
	var parts = jwt_string.split(".")
	# Ensure there are only 3 parts
	if parts.size() != 3:
		return_dict.Error = Error.ERR_INVALID_DATA
		return return_dict

	var header = parts[0]
	var payload = parts[1]
	var signature = parts[2]

	var header_decoded = Marshalls.base64_to_utf8(_convert_base64(header))
	var payload_decoded = Marshalls.base64_to_utf8(_convert_base64(payload))
	var signature_decoded = Marshalls.base64_to_raw(_convert_base64(signature))

	var header_json_contents: Dictionary
	var payload_json_contents: Dictionary
	var json = JSON.new()
	var header_parse_result := json.parse(header_decoded)
	if header_parse_result == OK:
		header_json_contents = json.get_data() as Dictionary
		json = JSON.new()

	json = JSON.new()
	var payload_parse_result := json.parse(payload_decoded)
	if payload_parse_result == OK:
		payload_json_contents = json.get_data() as Dictionary

	if header_parse_result != OK or payload_parse_result != OK:
		return_dict.Error = Error.ERR_INVALID_DATA
		return return_dict

	if not "alg" in header_json_contents:
		return_dict.Error = Error.ERR_INVALID_DATA
		return return_dict

	if not is_valid_by_time_expiration(payload_json_contents.exp):
		return_dict.Error = Error.ERR_EXPIRED
		return return_dict

	return_dict["header"] = header_json_contents
	return_dict["payload"] = payload_json_contents

	var _signature_valid = false

	match header_json_contents.alg:
		"HS256":
			_signature_valid = verify_signature_hs256(header, payload, key, signature_decoded)

	return return_dict


# IMPORTANT SECURITY NOTE: THIS ONLY PARSES/DECODES A JWT. IT DOES NOT VALIDATE IT. VALIDATION NEEDS TO BE DONE VIA THE FIREBASE SDK
static func get_user_id_from_jwt(jwt_string: String, key: String) -> String:
	var result = parse(jwt_string, key)
	if result["Error"] != OK:
		print("Invalid JWT")
		return ""
	if result.has("payload"):
		return result["payload"].user_id
	return ""


## IMPORTANT SECURITY NOTE: THIS ONLY PARSES/DECODES A JWT.
## IT DOES NOT VALIDATE IT.
## VALIDATION NEEDS TO BE DONE VIA THE FIREBASE SDK
static func verify_signature_hs256(
	header: String, payload: String, key: String, expected_signature: PackedByteArray
) -> bool:
	var context = HMACContext.new()
	if context.start(HashingContext.HASH_SHA256, key.to_utf8_buffer()) != OK:
		return false

	if context.update((header + "." + payload).to_utf8_buffer()) != OK:
		return false

	var signature = context.finish()
	return signature == expected_signature


static func is_valid_by_time_expiration(expiration) -> bool:
	if expiration < Time.get_unix_time_from_system():
		return false
	return true

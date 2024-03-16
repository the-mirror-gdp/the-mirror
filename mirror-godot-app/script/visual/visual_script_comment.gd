class_name VisualScriptComment
extends Object


signal script_comment_received_network_update()

# Keep this in sync with the GraphNode comment style box color.
const _DEFAULT_COLOR := Color(0.0, 0.0, 0.0, 0.6)

var color: Color = _DEFAULT_COLOR
var position := Vector2.ZERO
var size := Vector2.ZERO
var text: String = ""
var title: String = "Comment"


func duplicate() -> VisualScriptComment:
	var ret := VisualScriptComment.new()
	ret.color = color
	ret.position = position
	ret.size = size
	ret.text = text
	ret.title = title
	return ret


func serialize_visual_script_comment_to_json() -> Dictionary:
	var ret: Dictionary = {}
	if not color.is_equal_approx(_DEFAULT_COLOR):
		# The default color is a common case, so let's just not save it in those cases.
		ret["color"] = Serialization.color_to_array(color)
	ret["position"] = Serialization.vector2_to_array(position)
	if size != Vector2.ZERO:
		ret["size"] = Serialization.vector2_to_array(size)
	if not text.is_empty():
		# The text being empty is a common case, so let's just not save it in those cases.
		ret["text"] = text
	ret["title"] = title
	return ret


func setup_from_json(comment_json: Dictionary) -> void:
	if comment_json.has("color"):
		color = Serialization.array_to_color(comment_json["color"])
	if comment_json.has("position"):
		position = Serialization.array_to_vector2(comment_json["position"])
	if comment_json.has("size"):
		size = Serialization.array_to_vector2(comment_json["size"])
	text = comment_json.get("text", "")
	title = comment_json.get("title", "")
	script_comment_received_network_update.emit()

@tool
## @meta-authors SIsilicon, fenix-hub
## @meta-version 2.2
## A generic resource used by Firebase Database.

class_name FirebaseResource extends Resource

var key : String
var data

func _init(key : String, data):
	self.key = key.lstrip("/")
	self.data = data

func _to_string():
	return "{ key:{key}, data:{data} }".format({key = key, data = data})

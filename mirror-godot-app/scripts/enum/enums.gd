class_name Enums


## In order to add additional Types, add a const and the new type to values() and Keys()
## New Type Properties are managed through asset_data.gd and asset_instance
class ASSET_TYPE:
	const MESH = "MESH"
	const IMAGE = "IMAGE"
	const MATERIAL = "MATERIAL"
	const TEXTURE = "TEXTURE"
	const AUDIO = "AUDIO"
	const MAP = "MAP"
	const SCRIPT = "SCRIPT"
	const OTHER = "OTHER"


class MATERIAL_TYPE:
	const ASSET = "ASSET"
	const INSTANCE = "INSTANCE"


enum ENV {
	DEV = 0,
	STAGING = 1,
	PROD = 2,
	LOCAL = 3,
}

## Correlates with the RESTful API Space requirement.
class SPACE_TYPES:
	const OPEN_WORLD = "OPEN_WORLD"


enum CAMERA_TYPE {First_person, Third_person, Cinematic, Two_Dimension, Free}
enum PLAYER_DAMAGE_TYPE {No_Damage, Basic_Damage_Model, Advanced_Damage_Model}
enum BUILDING_TYPE {Free_Build, Limited_Build, Timed_Build, No_Build}
enum GRAVITY_TYPE {Earth_Normal, Moon_Normal}


class AVATAR_TYPE:
	const READY_PLAYER_ME = "READY_PLAYER_ME"
	const MIRROR_AVATAR_V1 = 'MIRROR_AVATAR_V1'


enum EDIT_MODE {
	None = -1,
	Asset = 0,
	Terrain = 1,
	Model = 2,
	Map = 3,
}


enum GIZMO_TYPE {
	MOVE = 0,
	ROTATE = 1,
	SCALE = 2,
	GRAB = 3,
}


enum TERRAIN_MODE {
	Add = 0,
	Subtract = 1,
	Flatten = 2,
	Paint = 3,
}

enum DownloadPriority {
	UNDEFINED = -10000,
	UI_MODELS = -2,
	UI_THUMBNAILS = -1,
	DEFAULT = 0,
	SPACE_OBJECT_LOWEST = 1,
	SPACE_OBJECT_LOW = 2,
	SPACE_OBJECT_MEDIUM = 3,
	SPACE_OBJECT_HIGH = 4,
	MAP_HEIGHTMAP = 5,
	AVATAR_DEFAULT = 6,
	HIGHEST = 6
}

enum NotifyStatus {
	INFO = 0,
	SUCCESS = 1,
	WARNING = 2,
	ERROR = 3,
}

enum ROLE {
	OWNER = 1000,
	# can create/read/update/delete, but not edit role permissions
	MANAGER = 700,
	# can create/read, but not update/delete
	CONTRIBUTOR = 400,
	# Entity, e.g. a Space, can be entered/observed
	OBSERVER = 100,
	# Provider
	PROVIDER = 150,
	# Entity will appear in search results, but that's it
	DISCOVER = 50,
	# Entity will not appear in search results. Returns a 404 when someone with NO_ROLE attempts to access
	NO_ROLE = 0,
	# Intentionally blocked; this is different from NO_ROLE. Negative numbers override all positive roles (e.g. a block on a user overrides any other ROLE they have, unless they are an owner)
	BLOCK = -100
}

static func as_string(enum_def: Dictionary, enum_value: int) -> StringName:
	return enum_def.find_key(enum_value)

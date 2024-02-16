extends AssetData
class_name AssetDataTexture

var texture_property_applies_to: String = ""
var texture_file_hash_md5: String = ""
var texture_low_quality_file_hash_md5: String = ""

func populate(dict: Dictionary) -> void:
	if dict == null:
		return
	assert(dict.get("__t", "") == "Texture")
	if dict.has("textureImagePropertyAppliesTo"):
		texture_property_applies_to = dict.get("textureImagePropertyAppliesTo", "")
	if dict.has("materialTransparencyMode"):
		texture_file_hash_md5 = dict.get("textureImageFileHashMD5", "")
	if dict.has("textureLowQualityFileHashMD5"):
		texture_low_quality_file_hash_md5 = dict.get("textureLowQualityFileHashMD5", "")
	super.populate(dict)


extends GutTest


const WAV_FILE_PATH = "res://test/test_files/test_wav.wav"
const MP3_FILE_PATH = "res://test/test_files/test_mp3.mp3"
const OGG_FILE_PATH = "res://test/test_files/test_ogg.ogg"


func test_load_wav_from_disk():
	var wav = Util.load_audio(WAV_FILE_PATH)
	assert_not_null(wav)
	assert_true(wav is AudioStreamWAV)


func test_load_mp3_from_disk():
	var mp3 = Util.load_audio(MP3_FILE_PATH)
	assert_not_null(mp3)
	assert_true(mp3 is AudioStreamMP3)


# TODO: Fix OGG audio import.
# Blocked by: https://github.com/godotengine/godot/issues/61091
#func test_load_ogg_from_disk():
#	var ogg = Util.load_audio(OGG_FILE_PATH)
#	assert_not_null(ogg)
#	assert_true(ogg is AudioStreamOggVorbis)


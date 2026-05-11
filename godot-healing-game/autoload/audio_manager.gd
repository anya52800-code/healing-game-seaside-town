extends Node
# Audio manager: procedural SFX and ambient sound via AudioStreamGenerator

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

func play_sfx(type: String) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.5
	_sfx_player.stream = gen
	_sfx_player.play()
	var playback := _sfx_player.get_stream_playback()
	_fill_sfx(playback, gen.mix_rate, type)

func play_ambient(type: String) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 3.0
	_bgm_player.stream = gen
	_bgm_player.play()
	var playback := _bgm_player.get_stream_playback()
	_fill_ambient(playback, gen.mix_rate, type)

func stop_ambient() -> void:
	_bgm_player.stop()

func set_ambient_volume(vol: float) -> void:
	_bgm_player.volume_db = linear_to_db(vol)

func _fill_sfx(playback: AudioStreamGeneratorPlayback, sample_hz: float, type: String) -> void:
	var phase := 0.0
	match type:
		"click":
			for i in int(sample_hz * 0.08):
				var env := exp(-float(i) / 150.0)
				var sample := sin(phase * 800.0) * env * 0.25
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz
		"pickup":
			for i in int(sample_hz * 0.35):
				var freq := 500.0 + 300.0 * sin(float(i) / 400.0)
				var env := 1.0 - float(i) / (sample_hz * 0.35)
				var sample := sin(phase * freq) * env * 0.2
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz
		"transition":
			for i in int(sample_hz * 0.2):
				var env := 1.0 - float(i) / (sample_hz * 0.2)
				var sample := sin(phase * 440.0) * env * 0.15
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz

func _fill_ambient(playback: AudioStreamGeneratorPlayback, sample_hz: float, type: String) -> void:
	var phase := 0.0
	var n_frames := int(sample_hz * 3.0)
	match type:
		"ocean":
			for i in n_frames:
				var noise := randf() * 2.0 - 1.0
				var low := sin(phase * 180.0) * 0.08
				var sample := (noise * 0.25 + low) * 0.3
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz
		"teahouse":
			for i in n_frames:
				var hum := sin(phase * 100.0) * 0.1 + sin(phase * 150.0) * 0.06
				var sample := hum * 0.2
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz
		"night":
			for i in n_frames:
				var noise := randf() * 2.0 - 1.0
				var sample := (noise * 0.04 + sin(phase * 55.0) * 0.08) * 0.15
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz
		"storm":
			for i in n_frames:
				var noise := randf() * 2.0 - 1.0
				var low := sin(phase * 80.0) * 0.05
				var sample := (noise * 0.8 + low) * 0.35
				playback.push_frame(Vector2(sample, sample))
				phase += 1.0 / sample_hz

extends Node
# Scene director: manages background colors, character silhouettes, and atmosphere

const SCENE_PALETTES := {
	"opening_start":    { "top": Color(0.910, 0.784, 0.627), "bottom": Color(0.420, 0.357, 0.310) },
	"opening_room":     { "top": Color(0.910, 0.784, 0.627), "bottom": Color(0.420, 0.357, 0.310) },
	"opening_leave":    { "top": Color(0.420, 0.357, 0.310), "bottom": Color(0.161, 0.141, 0.196) },
	"arrival_train":    { "top": Color(0.102, 0.122, 0.196), "bottom": Color(0.059, 0.071, 0.122) },
	"arrival_station":  { "top": Color(0.173, 0.243, 0.314), "bottom": Color(0.102, 0.145, 0.184) },
	"meet_ashu_first":  { "top": Color(0.173, 0.243, 0.314), "bottom": Color(0.102, 0.145, 0.184) },
	"walk_to_teahouse": { "top": Color(0.533, 0.310, 0.122), "bottom": Color(0.173, 0.243, 0.314) },
	"ashu_laugh":       { "top": Color(0.533, 0.310, 0.122), "bottom": Color(0.173, 0.243, 0.314) },
	"arrive_teahouse":  { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"ashu_tea_wisdom":  { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"first_night":      { "top": Color(0.102, 0.165, 0.251), "bottom": Color(0.039, 0.082, 0.145) },
	"night_mp3":        { "top": Color(0.051, 0.082, 0.125), "bottom": Color(0.020, 0.041, 0.071) },
	"first_night_lighthouse": { "top": Color(0.102, 0.165, 0.251), "bottom": Color(0.039, 0.082, 0.145) },
	"morning_first":    { "top": Color(0.800, 0.580, 0.380), "bottom": Color(0.600, 0.500, 0.450) },
	"morning_explore":  { "top": Color(0.800, 0.580, 0.380), "bottom": Color(0.600, 0.500, 0.450) },
	"meet_laochen_first": { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_hello":    { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_talk_work": { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_sea":       { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_silent":    { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_photo_trigger": { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_dont_sorry":    { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_silent_support": { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"laochen_goodbye_first": { "top": Color(0.353, 0.416, 0.478), "bottom": Color(0.102, 0.165, 0.227) },
	"back_to_teahouse":    { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"back_to_teahouse_evening": { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"ashu_about_laochen": { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"ashu_nod":          { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) },
	"chapter1_transition": { "top": Color(0.102, 0.165, 0.251), "bottom": Color(0.039, 0.082, 0.145) },
	"chapter1_end":      { "top": Color(0.102, 0.165, 0.251), "bottom": Color(0.039, 0.082, 0.145) },
	"explore_dock":      { "top": Color(0.400, 0.550, 0.650), "bottom": Color(0.200, 0.350, 0.500) },
	"explore_dock_sit":  { "top": Color(0.400, 0.550, 0.650), "bottom": Color(0.200, 0.350, 0.500) },
	"explore_noodle":    { "top": Color(0.867, 0.667, 0.400), "bottom": Color(0.600, 0.450, 0.300) },
	"explore_noodle_chat": { "top": Color(0.867, 0.667, 0.400), "bottom": Color(0.600, 0.450, 0.300) },
}

const DEFAULT_PALETTE := { "top": Color(0.290, 0.208, 0.157), "bottom": Color(0.165, 0.102, 0.063) }

var bg_rect: ColorRect
var char_area: Control
var atmosphere_overlay: ColorRect
var chars := {}

func setup(bg: ColorRect, characters: Control, overlay: ColorRect) -> void:
	bg_rect = bg
	char_area = characters
	atmosphere_overlay = overlay
	set_atmosphere("warm")

func set_background(scene_id: String) -> void:
	var palette: Dictionary = SCENE_PALETTES.get(scene_id, DEFAULT_PALETTE)
	var tween := create_tween()
	tween.tween_method(_interpolate_bg.bindv([palette.top, palette.bottom]), 0.0, 1.0, 0.5)
	# Map scene to atmosphere
	if "night" in scene_id or "evening" in scene_id or scene_id.begins_with("first_night"):
		set_atmosphere("night")
	elif "morning" in scene_id:
		set_atmosphere("morning")
	elif "train" in scene_id or "station" in scene_id or "arrival" in scene_id:
		set_atmosphere("night")
	elif "laochen" in scene_id or "lighthouse" in scene_id or "dock" in scene_id:
		set_atmosphere("ocean")
	elif "noodle" in scene_id:
		set_atmosphere("warm")
	elif "chapter1_transition" in scene_id or "chapter1_end" in scene_id:
		set_atmosphere("night")
	else:
		set_atmosphere("warm")

func set_atmosphere(type: String) -> void:
	match type:
		"night":
			atmosphere_overlay.color = Color(0.0, 0.0, 0.2, 0.15)
		"morning":
			atmosphere_overlay.color = Color(1.0, 0.9, 0.7, 0.08)
		"ocean":
			atmosphere_overlay.color = Color(0.6, 0.7, 0.9, 0.1)
		"warm":
			atmosphere_overlay.color = Color(1.0, 0.8, 0.5, 0.05)

func show_character(char_id: String, emotion: String = "neutral") -> void:
	if chars.has(char_id):
		chars[char_id].modulate.a = 1.0
		_set_char_emotion(chars[char_id], emotion)
		return
	var ch := _create_character_silhouette(char_id, emotion)
	char_area.add_child(ch)
	chars[char_id] = ch

func hide_character(char_id: String) -> void:
	if chars.has(char_id):
		chars[char_id].modulate.a = 0.3

func _create_character_silhouette(char_id: String, emotion: String) -> Control:
	var container := Control.new()
	container.position = Vector2(80 + chars.size() * 140, 100)
	container.size = Vector2(120, 300)

	var body := ColorRect.new()
	body.size = Vector2(60, 180)
	body.position = Vector2(30, 80)

	match char_id:
		"ashu":
			body.color = Color(0.4, 0.55, 0.35, 0.85)
		"laochen":
			body.color = Color(0.35, 0.4, 0.5, 0.85)
		_:
			body.color = Color(0.5, 0.45, 0.4, 0.85)
	container.add_child(body)

	# Head
	var head := ColorRect.new()
	head.size = Vector2(36, 36)
	head.position = Vector2(42, 40)
	if char_id == "laochen":
		head.color = Color(0.4, 0.42, 0.45, 0.9)
	elif char_id == "ashu":
		head.color = Color(0.55, 0.5, 0.4, 0.9)
	else:
		head.color = Color(0.6, 0.55, 0.45, 0.9)
	container.add_child(head)

	# Name label
	var label := Label.new()
	label.text = _char_name(char_id)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6))
	label.position = Vector2(10, 270)
	label.size = Vector2(100, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

	return container

func _set_char_emotion(ch: Control, emotion: String) -> void:
	pass # Future: adjust silhouette color/size for emotions

func _char_name(char_id: String) -> String:
	match char_id:
		"ashu": return "阿树"
		"laochen": return "老陈"
		_: return char_id

var _bg_top := Color.WHITE
var _bg_bottom := Color.WHITE
func _interpolate_bg(t: float, top: Color, bottom: Color) -> void:
	_bg_top = _bg_top.lerp(top, t * 2.0).clamp(Color.BLACK, Color.WHITE)
	_bg_bottom = _bg_bottom.lerp(bottom, t * 2.0).clamp(Color.BLACK, Color.WHITE)
	if bg_rect:
		var shader := bg_rect.material as ShaderMaterial
		if shader:
			shader.set_shader_parameter("top_color", _bg_top)
			shader.set_shader_parameter("bottom_color", _bg_bottom)
		else:
			bg_rect.color = _bg_top.lerp(_bg_bottom, 0.5)

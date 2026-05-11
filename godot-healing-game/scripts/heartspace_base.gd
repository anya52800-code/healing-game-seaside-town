extends Control
# Heart space base: rain shader, lightning, memory fragments (all Control-based)

signal completed

var storm_intensity := 1.0
var fragments_collected := 0
var total_fragments := 7

var rain_rect: ColorRect
var lightning_rect: ColorRect
var fragments_parent: Control
var narration_label: Label
var completion_overlay: ColorRect
var rain_timer: Timer

func _apply_rain_shader() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float time : hint_range(0.0, 100.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	float rain = 0.0;
	for (int i = 0; i < 20; i++) {
		float x = float(i) * 0.047 + sin(float(i) * 13.7) * 0.1;
		x = fract(x);
		float y_offset = fract(float(i) * 0.173 + time * (0.4 + float(i) * 0.03));
		float dist = abs(uv.x - x) * 20.0;
		float drop = 1.0 - smoothstep(0.0, 0.02, dist);
		drop *= 0.6 + 0.4 * sin(uv.y * 200.0 + time * 5.0);
		rain += drop * 0.5 * intensity;
	}
	vec4 base = vec4(0.039, 0.051, 0.078, 1.0);
	vec4 rain_color = vec4(0.65, 0.75, 0.85, 1.0);
	COLOR = mix(base, rain_color, rain);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("intensity", storm_intensity)
	mat.set_shader_parameter("time", 0.0)
	rain_rect.material = mat

func start() -> void:
	_apply_rain_shader()
	_show_narration("intro")
	if not rain_timer.timeout.is_connected(_on_rain_timeout):
		rain_timer.timeout.connect(_on_rain_timeout)
	rain_timer.start()

func _process(_delta: float) -> void:
	if rain_rect and rain_rect.material:
		rain_rect.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
		rain_rect.material.set_shader_parameter("intensity", storm_intensity)

func _on_rain_timeout() -> void:
	if storm_intensity <= 0.05:
		return
	_show_narration("collecting")
	_spawn_fragments()
	_start_lightning()
	rain_timer.stop()

func _show_narration(phase: String) -> void:
	match phase:
		"intro":
			narration_label.text = "你走进了一场暴风雨。\n这不是普通的风雨——这是老陈心里下了七年的那场。"
		"collecting":
			narration_label.text = "风雨中有微弱的光点。那是他散落的记忆。\n触碰它们——让它们重新被看见。"
		_:
			narration_label.text = ""

func _spawn_fragments() -> void:
	var memories := [
		"她笑着在灯塔前拍照。那天风很大，她的头发被吹得乱七八糟。她说\"快点拍！\"你按下快门的时候，她的笑容被风吹歪了——那是你见过的最好看的笑容。",
		"你们在码头一起看日出。她说海上的太阳像一颗糖心蛋。\"你啊，总是看什么都像吃的。\"她打你一下。那一下很轻。",
		"她生病后的第一个冬天。你每天从灯塔下来，走四十分钟路去医院。她骂你\"别来了，灯塔没人管\"。但每次你来，她都醒着。",
		"那晚暴风雨——你本来应该回去的。但灯塔的备用发电机坏了。你花了三个小时修好它。等你回到家——雨太大了。太大了。",
		"\"不是你的错。\"她说过很多次。但你没有相信。你从来没有相信过。你宁愿相信是自己的错——因为内疚比失去更有形状。",
		"她走后第一个月，你在灯塔顶上坐了一整夜。天快亮的时候，你看到海面上有一道很长的光。你不知道那是什么。但你决定继续点亮灯塔。",
		"七年了。你每天都擦那盏旧灯——她的遗物，那盏不亮的灯。你擦它不是因为相信它会亮。你擦它是因为——不擦的话，你不知道该做什么。",
	]
	total_fragments = memories.size()
	var viewport_size := get_viewport_rect().size

	for i in memories.size():
		var frag := Button.new()
		frag.flat = true
		frag.size = Vector2(44, 44)
		frag.position = Vector2(randf_range(60, viewport_size.x - 100), randf_range(120, viewport_size.y - 200))

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.95, 0.6, 0.6)
		style.set_corner_radius_all(22)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.85, 0.4, 0.5)
		frag.add_theme_stylebox_override("normal", style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(1.0, 0.95, 0.6, 0.85)
		hover_style.set_corner_radius_all(22)
		hover_style.border_width_left = 3
		hover_style.border_width_right = 3
		hover_style.border_width_top = 3
		hover_style.border_width_bottom = 3
		hover_style.border_color = Color(1.0, 0.9, 0.5, 0.8)
		frag.add_theme_stylebox_override("hover", hover_style)

		frag.pressed.connect(_on_fragment_collected.bind(i, memories[i], frag))
		fragments_parent.add_child(frag)

		# Float animation
		var tw := create_tween().set_loops()
		tw.tween_property(frag, "position:y", frag.position.y - 12, 2.0 + randf()).set_trans(Tween.TRANS_SINE)

func _on_fragment_collected(idx: int, memory: String, frag: Button) -> void:
	AudioManager.play_sfx("pickup")
	frag.disabled = true
	fragments_collected += 1

	# Collection animation
	var tw := create_tween()
	tw.tween_property(frag, "modulate:a", 0.0, 0.5)
	tw.tween_property(frag, "scale", Vector2(2.5, 2.5), 0.5)
	tw.tween_callback(frag.queue_free)

	# Show memory text
	narration_label.text = memory + "\n\n" + str(fragments_collected) + "/" + str(total_fragments) + " 段记忆"

	# Reduce storm intensity
	storm_intensity = maxf(0.02, 1.0 - (float(fragments_collected) / total_fragments) * 0.98)

	if fragments_collected >= total_fragments:
		await get_tree().create_timer(3.5).timeout
		_complete()

func _start_lightning() -> void:
	while storm_intensity > 0.05:
		if randf() < 0.3 * storm_intensity:
			lightning_rect.modulate.a = 0.08
			await get_tree().create_timer(0.12).timeout
			lightning_rect.modulate.a = 0.0
		await get_tree().create_timer(2.0 + randf() * 4.0).timeout

func _complete() -> void:
	storm_intensity = 0.0
	lightning_rect.modulate.a = 0.0

	completion_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(completion_overlay, "modulate:a", 1.0, 2.0)

	narration_label.text = "暴风雨停了。\n七段记忆，七年。\n它们一直在那里——只是需要有人看见。\n\n老陈抬起头。灯塔的光变得比之前亮了。"

	await get_tree().create_timer(4.0).timeout
	completed.emit()

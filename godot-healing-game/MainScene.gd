extends Control
# Main scene: builds UI tree programmatically, coordinates dialog/scene/heartspace

# Node references (set during _ready)
var bg_rect: ColorRect
var bg_shader_mat: ShaderMaterial
var char_area: Control
var atmosphere_overlay: ColorRect
var dialog_panel: Panel
var title_label: Label
var text_label: RichTextLabel
var choices_box: VBoxContainer
var continue_btn: Button
var dialog_ctrl: Node
var scene_director: Node
var heartspace_layer: Control
var anim_player: AnimationPlayer
var heartspace_active := false

var _dg_script := preload("res://scripts/dialog_controller.gd")
var _sd_script := preload("res://scripts/scene_director.gd")
var _hs_script := preload("res://scripts/heartspace_base.gd")

func _ready() -> void:
	setup_ui()
	setup_animation_player()
	setup_dialog_controller()
	setup_scene_director()
	setup_heartspace_layer()

	# Connect dialog signals
	dialog_ctrl.scene_loaded.connect(_on_scene_loaded)
	dialog_ctrl.story_ended.connect(_on_story_ended)

	# Start
	dialog_ctrl.load_data("res://data/chapter1.json")
	dialog_ctrl.start("opening_start")

func setup_ui() -> void:
	# Full-screen background
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)

	# Load gradient shader
	var shader_file := load("res://assets/backgrounds/gradient_bg.gdshader")
	if shader_file:
		bg_shader_mat = ShaderMaterial.new()
		bg_shader_mat.shader = shader_file
		bg_rect.material = bg_shader_mat

	# Atmosphere overlay
	atmosphere_overlay = ColorRect.new()
	atmosphere_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere_overlay)

	# Character area
	char_area = Control.new()
	char_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	char_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(char_area)

	# Dialog panel at the bottom
	dialog_panel = Panel.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -530
	dialog_panel.offset_bottom = -20
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.102, 0.078, 0.063, 0.92)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	dialog_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(dialog_panel)

	# Dialog content
	var content_box := VBoxContainer.new()
	content_box.name = "ContentBox"
	content_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog_panel.add_child(content_box)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.831, 0.753, 0.627))
	content_box.add_child(title_label)

	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.add_theme_font_size_override("normal_font_size", 15)
	text_label.add_theme_color_override("default_color", Color(0.878, 0.839, 0.784))
	text_label.bbcode_enabled = true
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(0, 80)
	text_label.size_flags_horizontal = Control.SIZE_FILL
	text_label.size_flags_vertical = Control.SIZE_FILL
	content_box.add_child(text_label)

	choices_box = VBoxContainer.new()
	choices_box.name = "ChoicesBox"
	choices_box.add_theme_constant_override("separation", 6)
	choices_box.size_flags_horizontal = Control.SIZE_FILL
	content_box.add_child(choices_box)

	continue_btn = Button.new()
	continue_btn.name = "ContinueBtn"
	continue_btn.text = "继续..."
	continue_btn.add_theme_font_size_override("font_size", 14)
	continue_btn.add_theme_color_override("font_color", Color(0.831, 0.753, 0.627))
	continue_btn.flat = true
	continue_btn.visible = false
	content_box.add_child(continue_btn)

func setup_animation_player() -> void:
	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)

	# Create fade_out animation
	var lib := AnimationLibrary.new()
	var fade_out := Animation.new()
	fade_out.length = 0.3
	fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(0, ".")
	fade_out.track_insert_key(0, 0.0, Color(1, 1, 1, 1))
	fade_out.track_insert_key(0, 0.3, Color(1, 1, 1, 0))
	lib.add_animation("fade_out", fade_out)

	var fade_in := Animation.new()
	fade_in.length = 0.3
	fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(0, ".")
	fade_in.track_insert_key(0, 0.0, Color(1, 1, 1, 0))
	fade_in.track_insert_key(0, 0.3, Color(1, 1, 1, 1))
	lib.add_animation("fade_in", fade_in)

	anim_player.add_animation_library("default", lib)

func setup_dialog_controller() -> void:
	dialog_ctrl = Node.new()
	dialog_ctrl.name = "DialogController"
	dialog_ctrl.set_script(_dg_script)
	add_child(dialog_ctrl)
	# Wire child node references for dialog controller
	dialog_ctrl.content_box = dialog_panel.get_node("ContentBox")
	dialog_ctrl.title_label = title_label
	dialog_ctrl.text_label = text_label
	dialog_ctrl.choices_box = choices_box
	dialog_ctrl.continue_btn = continue_btn
	dialog_ctrl.panel = dialog_panel
	# AnimationPlayer for fades
	dialog_ctrl.animation_player = anim_player
	dialog_ctrl.setup()

func setup_scene_director() -> void:
	scene_director = Node.new()
	scene_director.name = "SceneDirector"
	scene_director.set_script(_sd_script)
	add_child(scene_director)
	scene_director.setup(bg_rect, char_area, atmosphere_overlay)

func setup_heartspace_layer() -> void:
	heartspace_layer = Control.new()
	heartspace_layer.name = "HeartSpaceLayer"
	heartspace_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heartspace_layer.visible = false
	heartspace_layer.set_script(_hs_script)
	add_child(heartspace_layer)

	# Rain: ColorRect with shader
	var rain := ColorRect.new()
	rain.name = "RainRect"
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heartspace_layer.add_child(rain)

	# Lightning
	var lightning := ColorRect.new()
	lightning.name = "LightningRect"
	lightning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lightning.color = Color(1.0, 1.0, 0.95, 0.0)
	heartspace_layer.add_child(lightning)

	# Fragments area
	var fragments := Control.new()
	fragments.name = "Fragments"
	fragments.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fragments.mouse_filter = Control.MOUSE_FILTER_PASS
	heartspace_layer.add_child(fragments)

	# Rain timer (5s intro delay)
	var timer := Timer.new()
	timer.name = "RainTimer"
	timer.wait_time = 5.0
	timer.one_shot = true
	heartspace_layer.add_child(timer)
	heartspace_layer.rain_timer = timer

	# Narration
	var narration := Label.new()
	narration.name = "NarrationLabel"
	narration.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	narration.offset_top = -130
	narration.offset_bottom = -30
	narration.add_theme_font_size_override("font_size", 15)
	narration.add_theme_color_override("font_color", Color(0.784, 0.722, 0.596))
	narration.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heartspace_layer.add_child(narration)

	# Completion overlay
	var completion := ColorRect.new()
	completion.name = "CompletionOverlay"
	completion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	completion.color = Color(0.039, 0.051, 0.078, 0.0)
	completion.visible = false
	var comp_label := Label.new()
	comp_label.text = "暴风雨停了。"
	comp_label.add_theme_font_size_override("font_size", 20)
	comp_label.add_theme_color_override("font_color", Color(0.878, 0.816, 0.690))
	comp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	comp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	completion.add_child(comp_label)
	heartspace_layer.add_child(completion)

	# Wire references
	heartspace_layer.rain_rect = rain
	heartspace_layer.lightning_rect = lightning
	heartspace_layer.fragments_parent = fragments
	heartspace_layer.narration_label = narration
	heartspace_layer.completion_overlay = completion

func _on_scene_loaded(scene_id: String) -> void:
	scene_director.set_background(scene_id)
	_update_ambient_for_scene(scene_id)

	# Handle onEnter markers
	var scene = dialog_ctrl.story_data.get(scene_id, {})
	var on_enter = scene.get("onEnter", "")
	if on_enter == "opening_room_counter":
		dialog_ctrl.handle_on_enter(scene_id)

	# Heart space trigger
	if scene_id == "chapter1_transition":
		await get_tree().create_timer(3.0).timeout
		_enter_heartspace()

func _update_ambient_for_scene(scene_id: String) -> void:
	if heartspace_active:
		return
	if "night" in scene_id or "evening" in scene_id:
		AudioManager.play_ambient("night")
	elif "laochen" in scene_id or "lighthouse" in scene_id or "dock" in scene_id or "sea" in scene_id:
		AudioManager.play_ambient("ocean")
	else:
		AudioManager.play_ambient("teahouse")

func _enter_heartspace() -> void:
	heartspace_active = true
	dialog_panel.visible = false
	heartspace_layer.visible = true
	heartspace_layer.start()
	heartspace_layer.completed.connect(_on_heartspace_complete)

func _on_heartspace_complete() -> void:
	heartspace_active = false
	dialog_panel.visible = true
	heartspace_layer.visible = false
	dialog_ctrl.go_to("chapter1_end")

func _on_story_ended() -> void:
	pass

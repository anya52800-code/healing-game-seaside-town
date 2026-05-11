extends Node
# Dialog controller: reads JSON story data, drives dialog UI

signal scene_loaded(scene_id: String)
signal story_ended

var story_data := {}
var current_scene_id := ""

var content_box: VBoxContainer
var title_label: Label
var text_label: RichTextLabel
var choices_box: VBoxContainer
var continue_btn: Button
var panel: Panel
var animation_player: AnimationPlayer

var typewriter_tween: Tween
var target_text := ""
var _all_paragraphs: Array = []
var _current_para_idx := 0

func setup() -> void:
	continue_btn.pressed.connect(_on_continue)

func load_data(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		var json := JSON.new()
		if json.parse(text) == OK:
			story_data = json.data
		file.close()

func start(first_scene: String = "opening_start") -> void:
	go_to(first_scene)

func go_to(scene_id: String) -> void:
	if not story_data.has(scene_id):
		push_error("Scene not found: " + scene_id)
		return
	current_scene_id = scene_id
	_render(story_data[scene_id])
	scene_loaded.emit(scene_id)

func _render(scene: Dictionary) -> void:
	clear_choices()
	title_label.text = scene.get("title", "")
	title_label.visible = not title_label.text.is_empty()

	_all_paragraphs = scene.get("paragraphs", [])
	_current_para_idx = 0
	if _all_paragraphs.is_empty():
		text_label.text = ""
		_show_choices_or_continue(scene)
		return

	# Show first paragraph with typewriter
	_type_paragraph(_all_paragraphs[0])
	_show_choices_or_continue(scene)

func _type_paragraph(text: String) -> void:
	if typewriter_tween and typewriter_tween.is_running():
		typewriter_tween.kill()
	target_text = text
	text_label.text = ""
	typewriter_tween = create_tween()
	var char_count := text.length()
	var duration: float = clamp(char_count * 0.03, 1.0, 4.0)
	typewriter_tween.tween_method(_set_typed_text.bind(text), 0.0, float(char_count), duration)

func _set_typed_text(idx: float, full_text: String) -> void:
	text_label.text = full_text.substr(0, int(idx))

func _show_choices_or_continue(scene: Dictionary) -> void:
	var choices: Array = scene.get("choices", [])
	# Filter by conditions
	var visible := []
	for c in choices:
		if _check_condition(c.get("condition", {})):
			visible.append(c)

	if visible.is_empty() and scene.has("next"):
		continue_btn.text = "继续..."
		continue_btn.visible = true
		continue_btn.grab_focus()
	elif visible.size() > 0:
		continue_btn.visible = false
		for c in visible:
			var btn := Button.new()
			btn.text = c.get("text", "")
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_color_override("font_color", Color(0.831, 0.753, 0.627))
			btn.flat = true
			btn.custom_minimum_size = Vector2(400, 40)
			btn.pressed.connect(_on_choice_selected.bind(c, scene))
			choices_box.add_child(btn)
		# Auto-focus first choice
		if choices_box.get_child_count() > 0:
			choices_box.get_child(0).grab_focus()

func _check_condition(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	if cond.has("flag"):
		return GameState.has_flag(cond["flag"])
	if cond.has("notFlag"):
		return not GameState.has_flag(cond["notFlag"])
	if cond.has("hasItem"):
		return GameState.has_item(cond["hasItem"])
	if cond.has("relationship"):
		var r: Dictionary = cond["relationship"]
		return GameState.get_relationship(r.get("npc", "")) >= r.get("min", 0)
	return true

func _on_choice_selected(choice: Dictionary, scene: Dictionary) -> void:
	# Apply side effects
	if choice.has("setFlag"):
		GameState.set_flag(choice["setFlag"])
	if choice.has("addItem"):
		GameState.add_item(choice["addItem"])
	if choice.has("setRelationship"):
		var r: Dictionary = choice["setRelationship"]
		GameState.change_relationship(r["npc"], r["change"])

	AudioManager.play_sfx("click")
	var target: String = choice.get("next", scene.get("next", ""))
	if target:
		_fade_transition(target)

func _on_continue() -> void:
	var scene: Dictionary = story_data.get(current_scene_id, {})
	# If there are more paragraphs, show the next one
	_current_para_idx += 1
	if _current_para_idx < _all_paragraphs.size():
		_type_paragraph(_all_paragraphs[_current_para_idx])
		continue_btn.visible = false
		continue_btn.text = "继续..."
		return
	# No more paragraphs, advance scene
	if scene.has("next"):
		_fade_transition(scene["next"])

func _fade_transition(target: String) -> void:
	AudioManager.play_sfx("transition")
	animation_player.play("fade_out")
	await animation_player.animation_finished
	go_to(target)
	animation_player.play("fade_in")

func clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()

# onEnter support: called by MainScene after scene_loaded signal
func handle_on_enter(scene_id: String) -> void:
	# opening_room: show item counter
	if scene_id == "opening_room":
		_update_opening_room_counter()

func _update_opening_room_counter() -> void:
	var opening_items := ["旧照片", "手织围巾", "未寄出的信", "光滑的石头", "旧MP3", "快枯死的植物", "旧书", "旧游戏机"]
	var count := GameState.get_inventory_count(opening_items)
	var remaining := 3 - count

	# Remove all choice buttons, add counter + reduced set
	clear_choices()
	continue_btn.visible = false

	if count >= 3:
		# Show only leave button
		var p := Label.new()
		p.text = "行李箱满了。三样东西——不多不少。是时候出发了。"
		p.add_theme_color_override("font_color", Color(0.784, 0.659, 0.376))
		p.add_theme_font_size_override("font_size", 13)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choices_box.add_child(p)

		var btn := Button.new()
		btn.text = "关上箱子，该出发了"
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(0.831, 0.753, 0.627))
		btn.flat = true
		btn.custom_minimum_size = Vector2(400, 44)
		btn.pressed.connect(func(): _fade_transition("opening_leave"))
		choices_box.add_child(btn)
		return

	if count > 0:
		var p := Label.new()
		p.text = "行李箱里放了 " + str(count) + " 样东西。还能再塞 " + str(remaining) + " 件。"
		p.add_theme_color_override("font_color", Color(0.784, 0.659, 0.376))
		p.add_theme_font_size_override("font_size", 13)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		choices_box.add_child(p)

	# Re-add choices from scene (excluding taken items)
	var scene: Dictionary = story_data.get("opening_room", {})
	var choices: Array = scene.get("choices", [])
	for c in choices:
		if _check_condition(c.get("condition", {})):
			var btn := Button.new()
			btn.text = c.get("text", "")
			btn.add_theme_font_size_override("font_size", 14)
			btn.add_theme_color_override("font_color", Color(0.831, 0.753, 0.627))
			btn.flat = true
			btn.custom_minimum_size = Vector2(400, 40)
			btn.pressed.connect(_on_choice_selected.bind(c, scene))
			choices_box.add_child(btn)
	if choices_box.get_child_count() > 0:
		choices_box.get_child(0).grab_focus()

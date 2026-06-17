extends Panel

# QuestPanel displays daily quest objectives, progress bars, and claims — Cartoon 3D UI

@onready var quests_container: VBoxContainer = $Scroll/VBox/QuestsContainer
@onready var header_banner: PanelContainer = $HeaderBanner

func _ready():
	SignalBus.quest_progress_updated.connect(_on_quest_progress_updated)
	
	# Apply green ribbon style to header
	header_banner.add_theme_stylebox_override("panel", Themes.get_ribbon_style("green"))
	
	populate_quests()

func populate_quests():
	for child in quests_container.get_children():
		child.queue_free()
		
	if not has_node("/root/QuestManager"):
		return
		
	for q_id in QuestManager.quests.keys():
		var q_data = QuestManager.quests[q_id]
		var item = _create_quest_item_ui(q_id, q_data)
		quests_container.add_child(item)

func _create_quest_item_ui(q_id: String, q_data: Dictionary) -> PanelContainer:
	var container = PanelContainer.new()
	# Quest card uses Blue Card theme
	container.add_theme_stylebox_override("panel", Themes.get_card_style("blue"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(vbox)
	
	# Quest Title
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "🎯 " + q_data["name"]
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0, 1)) # Bright Cyan-Blue
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	name_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_lbl)
	
	# Quest Description
	var desc_lbl = Label.new()
	desc_lbl.text = q_data["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.9))
	vbox.add_child(desc_lbl)
	
	# Progress HBox (Progressbar + Progress Label)
	var prog_hbox = HBoxContainer.new()
	prog_hbox.name = "ProgHBox"
	prog_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(prog_hbox)
	
	var pbar = ProgressBar.new()
	pbar.name = "ProgressBar"
	pbar.custom_minimum_size = Vector2(0, 16)
	pbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pbar.show_percentage = false
	
	# Custom progress bar styling: thick border + neon green fill
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.04, 0.06, 0.12, 1)
	sb_bg.border_width_left = 2
	sb_bg.border_width_top = 2
	sb_bg.border_width_right = 2
	sb_bg.border_width_bottom = 2
	sb_bg.border_color = Color(0, 0, 0, 0.8)
	sb_bg.corner_radius_top_left = 8
	sb_bg.corner_radius_top_right = 8
	sb_bg.corner_radius_bottom_right = 8
	sb_bg.corner_radius_bottom_left = 8
	
	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.25, 0.9, 0.15, 1) # Glossy neon green
	sb_fg.corner_radius_top_left = 8
	sb_fg.corner_radius_top_right = 8
	sb_fg.corner_radius_bottom_right = 8
	sb_fg.corner_radius_bottom_left = 8
	
	pbar.add_theme_stylebox_override("background", sb_bg)
	pbar.add_theme_stylebox_override("fill", sb_fg)
	prog_hbox.add_child(pbar)
	
	var prog_lbl = Label.new()
	prog_lbl.name = "ProgressLabel"
	prog_lbl.add_theme_font_size_override("font_size", 12)
	prog_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prog_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	prog_lbl.add_theme_constant_override("outline_size", 3)
	prog_hbox.add_child(prog_lbl)
	
	# Claim Button
	var btn = Button.new()
	btn.name = "ClaimButton"
	btn.custom_minimum_size = Vector2(94, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_claim_pressed(q_id))
	Themes.style_button(btn, "orange")
	hbox.add_child(btn)
	
	container.set_meta("quest_id", q_id)
	_update_quest_item(container, q_data)
	
	return container

func _update_quest_item(container: PanelContainer, q_data: Dictionary):
	var pbar = container.get_node("HBox/VBox/ProgHBox/ProgressBar") as ProgressBar
	var prog_lbl = container.get_node("HBox/VBox/ProgHBox/ProgressLabel") as Label
	var btn = container.get_node("HBox/ClaimButton") as Button
	
	var progress = q_data["progress"]
	var target = q_data["target"]
	var claimed = q_data["claimed"]
	
	pbar.max_value = target
	pbar.value = progress
	
	prog_lbl.text = "%d/%d" % [progress, target]
	
	if claimed:
		btn.text = "✅ DONE"
		btn.disabled = true
		Themes.style_button(btn, "blue")
	elif progress >= target:
		btn.text = "🎁 CLAIM\n🪙 %.0f" % q_data["reward"]
		btn.disabled = false
		Themes.style_button(btn, "orange")
		
		# Bounce animation for claimable rewards
		var tween = btn.create_tween().set_loops()
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.35)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.35)
	else:
		btn.text = "🎁 CLAIM\n🪙 %.0f" % q_data["reward"]
		btn.disabled = true
		Themes.style_button(btn, "orange")
		btn.scale = Vector2.ONE

func _on_claim_pressed(q_id: String):
	if not has_node("/root/QuestManager"):
		return
		
	if QuestManager.claim_quest(q_id):
		AudioManager.play_sfx("tap_cash")
		SaveManager.save_game()

func _on_quest_progress_updated(q_id: String, _progress: int, _target: int):
	# Find node for quest and update it
	for item in quests_container.get_children():
		if item.get_meta("quest_id") == q_id:
			var q_data = QuestManager.quests[q_id]
			_update_quest_item(item, q_data)
			break

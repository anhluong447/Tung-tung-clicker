extends Node

# Main Scene Manager for Tung Tung Clicker

@onready var hud: Control = $UI/HUD
@onready var panels_container: Control = $UI/Panels
@onready var tap_area: Control = $UI/TapArea

# Panel Node References
@onready var shop_panel: Control = $UI/Panels/ShopPanel
@onready var collection_panel: Control = $UI/Panels/CollectionPanel
@onready var quest_panel: Control = $UI/Panels/QuestPanel
@onready var settings_panel: Control = $UI/Panels/SettingsPanel

# Drag and Drop State
var dragging_from_slot_index: int = -1
var drag_preview_node: ColorRect = null

# Combo and BGM State
var combo_count: int = 0
var last_tap_time: float = 0.0
var time_since_last_tap: float = 0.0
var current_bgm_state: String = "chill"
var background_preset: int = 0 # 0: Sahur Night, 1: Brainrot Sunset, 2: Italy??

func _ready():
	# Connect HUD navigation signals
	hud.nav_tab_changed.connect(_on_nav_tab_changed)
	
	# Connect Tap Area input
	tap_area.gui_input.connect(_on_tap_area_input)
	
	# Connect tap events to trigger juice stack
	SignalBus.tap_registered.connect(_on_tap_registered)
	
	# Connect player level-up signal
	SignalBus.player_level_up.connect(_on_level_up)
	
	# Dynamic Setup for SettingsPanel Background Cycle Button
	var bg_btn = Button.new()
	bg_btn.name = "CycleBgButton"
	bg_btn.text = "🌅 Đổi Background: Sahur Night 🌙"
	bg_btn.custom_minimum_size = Vector2(240, 50)
	bg_btn.anchors_preset = Control.PRESET_CENTER
	bg_btn.anchor_left = 0.5
	bg_btn.anchor_right = 0.5
	bg_btn.anchor_top = 0.5
	bg_btn.anchor_bottom = 0.5
	bg_btn.offset_left = -120
	bg_btn.offset_right = 120
	bg_btn.offset_top = -25
	bg_btn.offset_bottom = 25
	
	settings_panel.add_child(bg_btn)
	bg_btn.pressed.connect(func():
		cycle_background()
		bg_btn.text = "🌅 Đổi Background: " + _get_background_name()
		AudioManager.play_sfx("ui_click")
	)
	Themes.style_button(bg_btn, "blue")
	
	# Show Clicker stage by default (hide all other panels)
	_show_panel("clicker")

func _on_nav_tab_changed(tab_name: String):
	_show_panel(tab_name)

func _show_panel(tab_name: String):
	# Hide all panels first
	for child in panels_container.get_children():
		child.visible = false
		
	# Handle specific tabs
	match tab_name:
		"clicker":
			# Clicker mode just shows the main stage (which is visible beneath panels)
			pass
		"shop":
			shop_panel.visible = true
		"collection":
			collection_panel.visible = true
		"quest":
			quest_panel.visible = true
		"settings":
			settings_panel.visible = true

func _on_tap_area_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Pass tap to GameManager with click position
			GameManager.tap(event.position)

func _on_tap_registered(pos: Vector2, is_critical: bool, coins_gained: float):
	# Combo system logic
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_tap_time < 0.65:
		combo_count += 1
	else:
		combo_count = 1
	last_tap_time = now
	time_since_last_tap = 0.0
	
	if combo_count >= 5:
		# Trigger dynamic upbeat music
		if current_bgm_state == "chill":
			current_bgm_state = "upbeat"
			AudioManager.set_bgm_state("upbeat")
		
		# Spawn a cool floating combo text popup
		_spawn_combo_floating_text(pos, combo_count)

	# Spawn Floating Tap Label
	var label_scene = preload("res://scenes/fx/TapNumber.tscn")
	var label = label_scene.instantiate()
	label.position = pos
	label.amount = coins_gained
	label.is_critical = is_critical
	$UI.add_child(label)
	
	# Spawn Coin Particle burst
	var particle_scene = preload("res://scenes/fx/CoinParticle.tscn")
	var particle = particle_scene.instantiate()
	particle.position = pos
	$UI.add_child(particle)
	
	# Play sound effect
	if is_critical:
		AudioManager.play_sfx("tap_tung")
	else:
		# Play a random sound from a pool
		var sfx_pool = ["tap_boing", "tap_cash", "tap_sahur", "tap_fart"]
		var random_sfx = sfx_pool[randi() % sfx_pool.size()]
		AudioManager.play_sfx(random_sfx)

# Drag and Drop Merge Implementation
func start_dragging(slot_idx: int, initial_pos: Vector2):
	var slot_node = _get_slot_node(slot_idx)
	if not slot_node or slot_node.character_id == "":
		return
		
	dragging_from_slot_index = slot_idx
	
	# Hide visual representation
	slot_node.mesh_pivot.visible = false
	
	# Create 2D preview icon under mouse
	drag_preview_node = ColorRect.new()
	drag_preview_node.custom_minimum_size = Vector2(60, 60)
	drag_preview_node.size = Vector2(60, 60)
	drag_preview_node.pivot_offset = drag_preview_node.size / 2.0
	
	var mat = slot_node.mesh_instance.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		drag_preview_node.color = mat.albedo_color
	else:
		drag_preview_node.color = Color(1.0, 1.0, 1.0)
		
	# Add slight transparency and outline
	drag_preview_node.color.a = 0.8
	
	# Set position
	drag_preview_node.position = initial_pos - drag_preview_node.size / 2.0
	$UI.add_child(drag_preview_node)
	
	# Tiny visual juice scale pop
	var tween = drag_preview_node.create_tween()
	drag_preview_node.scale = Vector2.ZERO
	tween.tween_property(drag_preview_node, "scale", Vector2.ONE, 0.1)

func _input(event: InputEvent):
	if dragging_from_slot_index == -1:
		return
		
	if event is InputEventMouseMotion and drag_preview_node:
		# Drag preview follows cursor
		drag_preview_node.position = event.position - drag_preview_node.size / 2.0
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# Mouse released, execute drop
		var drop_pos = event.position
		var target_slot_idx = _get_slot_under_mouse(drop_pos)
		
		var slot_node = _get_slot_node(dragging_from_slot_index)
		if slot_node:
			# Make visual visible again
			slot_node.mesh_pivot.visible = true
			
		# Clean up preview
		if drag_preview_node:
			drag_preview_node.queue_free()
			drag_preview_node = null
			
		# Trigger merge check
		if target_slot_idx != -1 and target_slot_idx != dragging_from_slot_index:
			var success = GameManager.merge_slots(dragging_from_slot_index, target_slot_idx)
			if success:
				# Play orchestral hit + explosion sound
				AudioManager.play_sfx("merge", false)
				# Play cartoon bounce scale juice on target slot
				var target_slot_node = _get_slot_node(target_slot_idx)
				if target_slot_node:
					target_slot_node.play_tap_punch()
				# Trigger save
				SaveManager.save_game()
		elif target_slot_idx == dragging_from_slot_index:
			# Dropped on same slot -> count as a tap!
			var slot_n = _get_slot_node(dragging_from_slot_index)
			if slot_n:
				var viewport = get_viewport()
				var camera3d = viewport.get_camera_3d()
				var screen_pos = camera3d.unproject_position(slot_n.global_position)
				GameManager.tap(screen_pos)
				slot_n.play_tap_punch()
				
		dragging_from_slot_index = -1

func _get_slot_under_mouse(screen_position: Vector2) -> int:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return -1
		
	var space_state = camera.get_world_3d().direct_space_state
	var origin = camera.project_ray_origin(screen_position)
	var normal = camera.project_ray_normal(screen_position)
	var end = origin + normal * 100.0
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		if result.collider.has_method("update_slot"):
			return result.collider.slot_index
			
	return -1

func _get_slot_node(index: int) -> Area3D:
	return get_node_or_null("World3D/CharacterStage/Slot%d" % index)

func _process(delta: float):
	time_since_last_tap += delta
	if time_since_last_tap > 3.0 and current_bgm_state == "upbeat":
		current_bgm_state = "chill"
		combo_count = 0
		AudioManager.set_bgm_state("chill")

func _on_level_up(new_level: int):
	# Camera shake
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("shake"):
		camera.shake(0.5)
		
	# Show glorious dropdown banner
	_show_level_up_banner(new_level)

func _show_level_up_banner(level: int):
	var banner = PanelContainer.new()
	var label = Label.new()
	banner.add_child(label)
	
	label.text = "🎉 LEVEL UP! BẠN ĐẠT CẤP %d! 🎉" % level
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2)) # gold
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.3, 0.1) # Bright Orange Ribbon
	style.border_width_bottom = 4
	style.border_color = Color(0.55, 0.12, 0.05)
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	banner.add_theme_stylebox_override("panel", style)
	
	# Position at the top, span full width
	banner.anchors_preset = Control.PRESET_TOP_WIDE
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$UI.add_child(banner)
	
	# Position dropdown (top bar ends at 108, so we drop to 112)
	banner.position = Vector2(0, -90)
	
	var tween = banner.create_tween()
	# Slide down
	tween.tween_property(banner, "position:y", 112, 0.35).set_ease(Tween.EASE_OUT)
	# Shake camera slightly again on hit
	tween.tween_callback(func():
		var camera = get_viewport().get_camera_3d()
		if camera and camera.has_method("shake"):
			camera.shake(0.2)
	)
	# Hold
	tween.tween_interval(2.2)
	# Slide back up
	tween.tween_property(banner, "position:y", -90, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_callback(banner.queue_free)

func _spawn_combo_floating_text(screen_pos: Vector2, combo: int):
	var label = Label.new()
	
	var brainrot_words = ["TUNG!", "SAHUR!", "SKIBIDI!", "SIGMA!", "RIZZ!", "OHIO!", "GYATT!", "WOBBLE!"]
	var random_word = brainrot_words[randi() % brainrot_words.size()]
	
	label.text = "x%d %s" % [combo, random_word]
	label.add_theme_font_size_override("font_size", 20 + min(combo, 15)) # grows larger!
	label.add_theme_color_override("font_color", Color.from_hsv(randf(), 0.9, 0.95)) # Rainbow cartoon colors!
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.pivot_offset = Vector2(50, 15)
	
	$UI.add_child(label)
	label.position = screen_pos + Vector2(randf_range(-40, 40), randf_range(-60, -30))
	
	# Bounce & punch scale entrance
	var tween = label.create_tween()
	label.scale = Vector2.ZERO
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.06)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.28)
	tween.tween_callback(label.queue_free)

func cycle_background():
	background_preset = (background_preset + 1) % 3
	_apply_background_preset()
	SignalBus.toast_notification.emit("🌅 BACKGROUND: %s" % _get_background_name())

func _get_background_name() -> String:
	match background_preset:
		0: return "Sahur Night 🌙"
		1: return "Brainrot Sunset 🌇"
		2: return "Italy?? 🇮🇹"
	return ""

func _apply_background_preset():
	var env = $World3D/WorldEnvironment.environment
	var platform = $World3D/StagePlatform
	
	# Retrieve ProceduralSkyMaterial safely
	var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
	if not sky_mat:
		return
		
	match background_preset:
		0: # Sahur Night
			sky_mat.sky_top_color = Color(0.12, 0.05, 0.26)
			sky_mat.sky_horizon_color = Color(0.25, 0.1, 0.45)
			sky_mat.ground_bottom_color = Color(0.08, 0.02, 0.15)
			env.ambient_light_color = Color(0.3, 0.25, 0.45)
			var mat = platform.material as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.2, 0.1, 0.35)
				mat.emission = Color(0.1, 0.05, 0.2)
		1: # Brainrot Sunset
			sky_mat.sky_top_color = Color(0.9, 0.35, 0.15)
			sky_mat.sky_horizon_color = Color(1.0, 0.2, 0.6)
			sky_mat.ground_bottom_color = Color(0.25, 0.08, 0.15)
			env.ambient_light_color = Color(0.7, 0.35, 0.45)
			var mat = platform.material as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.5, 0.15, 0.3)
				mat.emission = Color(0.35, 0.1, 0.2)
		2: # Italy??
			sky_mat.sky_top_color = Color(0.2, 0.6, 0.3) # Mint green
			sky_mat.sky_horizon_color = Color(0.95, 0.95, 0.95) # White
			sky_mat.ground_bottom_color = Color(0.75, 0.15, 0.2) # Red
			env.ambient_light_color = Color(0.5, 0.65, 0.5)
			var mat = platform.material as StandardMaterial3D
			if mat:
				mat.albedo_color = Color(0.85, 0.8, 0.75) # Marble
				mat.emission = Color(0.3, 0.3, 0.25)

func trigger_unlock_fx(char_id: String):
	var fx_scene = preload("res://scenes/ui/UnlockFX.tscn")
	var fx = fx_scene.instantiate()
	$UI.add_child(fx)
	fx.setup_unlock(char_id)




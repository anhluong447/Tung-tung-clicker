extends Node3D

# ActiveCharacter script for the large interactive central character (Talking Tom Style)

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var mesh_instance: MeshInstance3D = $MeshPivot/MeshInstance3D
@onready var head_area: Area3D = $HeadArea
@onready var body_area: Area3D = $BodyArea
@onready var feet_area: Area3D = $FeetArea

var character_id: String = ""
var character_data: CharacterData = null

# Animation parameters
var idle_bob_speed: float = 1.8
var idle_bob_height: float = 0.08
var base_y: float = 0.0
var time_passed: float = 0.0
var is_reacting: bool = false

const BRAINROT_QUOTES = [
	"ĐẤM ĐẦU TỚ À?! 💥",
	"Hế lôôô Tung Tung! 🐣",
	"EH EH EH! Đừng gãi chân! 💀",
	"Skibidi Sahur no cap! 🔥",
	"TUNG TUNG Sahur is life!",
	"Sigma rooster is here! 🐓",
	"Rizz me up bro!",
	"Oh my god, TUNG TUNG!",
	"Lắc lư cái mình nè! 🥁",
	"Măm măm coin ngon quá! 🪙"
]

const SPEECH_COLORS = [
	Color(1, 0.3, 0.6),    # Pink
	Color(0.2, 0.7, 1.0),  # Blue
	Color(1, 0.6, 0.1),    # Orange
	Color(0.3, 0.9, 0.4),    # Green
]

func _ready():
	base_y = mesh_pivot.position.y
	
	# Connect Area3D input events
	head_area.input_event.connect(func(c, e, pos, n, s): _on_zone_input("head", e, pos))
	body_area.input_event.connect(func(c, e, pos, n, s): _on_zone_input("body", e, pos))
	feet_area.input_event.connect(func(c, e, pos, n, s): _on_zone_input("feet", e, pos))
	
	# Listen for merges/unlocks to auto-update
	SignalBus.character_merged.connect(func(f, t): update_character())
	SignalBus.character_unlocked.connect(func(c): update_character())
	
	update_character()

func _process(delta):
	# Idle animation bobbing
	time_passed += delta
	if not is_reacting:
		mesh_pivot.position.y = base_y + sin(time_passed * idle_bob_speed) * idle_bob_height
		# Soft breathing scale
		var scale_val = 1.0 + sin(time_passed * 2.5) * 0.02
		mesh_pivot.scale = Vector3(scale_val, 1.0 / scale_val, scale_val)

func update_character():
	# Scan the grid slots to find the highest level character
	var highest_char = "tung_tung_jr"
	var max_tier = -1
	
	for char_id in GameManager.characters_in_slots:
		if char_id and GameManager.all_characters.has(char_id):
			var data = GameManager.all_characters[char_id] as CharacterData
			if data.rarity > max_tier or (data.rarity == max_tier and char_id != highest_char):
				max_tier = data.rarity
				highest_char = char_id
				
	if character_id != highest_char:
		character_id = highest_char
		character_data = GameManager.all_characters.get(character_id)
		_setup_visuals()

func _setup_visuals():
	if not character_data:
		return
		
	var mat = StandardMaterial3D.new()
	mat.metallic = 0.2
	mat.roughness = 0.4
	
	# Assign color based on active character type
	match character_data.id:
		"tung_tung_jr":
			mat.albedo_color = Color(1.0, 0.52, 0.0) # Orange
		"tung_tung_tung":
			mat.albedo_color = Color(1.0, 0.15, 0.2) # Crimson Red
		"tralalero_piccolo":
			mat.albedo_color = Color(0.1, 0.65, 1.0) # Light blue
		_:
			mat.albedo_color = Color(0.75, 0.25, 0.95) # Default Purple
			
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.25
	mat.emission_energy_multiplier = 0.4
	
	mesh_instance.set_surface_override_material(0, mat)
	
	# Juicy scale pop on evolution
	var tween = create_tween()
	mesh_pivot.scale = Vector3.ZERO
	tween.tween_property(mesh_pivot, "scale", Vector3(1.4, 1.4, 1.4), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_pivot, "scale", Vector3.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)

func _on_zone_input(zone: String, event: InputEvent, click_position: Vector3):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Unproject 3D position to get 2D screen position for floating tap numbers
			var camera3d = get_viewport().get_camera_3d()
			var screen_pos = Vector2.ZERO
			if camera3d:
				screen_pos = camera3d.unproject_position(click_position)
			
			# Trigger core tap logic
			GameManager.tap(screen_pos)
			
			# React to specific zone click
			match zone:
				"head":
					_react_head()
				"body":
					_react_body()
				"feet":
					_react_feet()

func _react_head():
	if is_reacting: return
	is_reacting = true
	
	# Jump up & Spin reaction (Tom head slap)
	GameManager.hype = min(GameManager.hype + 15.0, 100.0)
	AudioManager.play_sfx("tap_boing")
	
	var tween = create_tween()
	var start_y = base_y
	tween.tween_property(mesh_pivot, "position:y", start_y + 1.5, 0.18).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mesh_pivot, "rotation:y", mesh_pivot.rotation.y + PI * 2, 0.35)
	tween.tween_property(mesh_pivot, "position:y", start_y, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_reacting = false)
	
	_spawn_toast_bubble("ui_head_hit", "UỐI GIỜI ƠI ĐAU ĐẦU!!! 🧠💥")

func _react_body():
	# Squish-stretch punch animation (Tom belly tap)
	GameManager.chaos = min(GameManager.chaos + 12.0, 100.0)
	
	var sfx_pool = ["tap_tung", "tap_cash", "tap_sahur"]
	var random_sfx = sfx_pool[randi() % sfx_pool.size()]
	AudioManager.play_sfx(random_sfx)
	
	var tween = create_tween()
	tween.tween_property(mesh_pivot, "scale", Vector3(1.35, 0.65, 1.35), 0.06).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_pivot, "scale", Vector3(0.85, 1.3, 0.85), 0.06)
	tween.tween_property(mesh_pivot, "scale", Vector3.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)
	
	# Random brainrot quote
	var random_quote = BRAINROT_QUOTES[randi() % BRAINROT_QUOTES.size()]
	_spawn_toast_bubble("ui_quote", random_quote)

func _react_feet():
	if is_reacting: return
	is_reacting = true
	
	# Rock side-to-side reaction (Tom tickle feet)
	GameManager.brainrot = min(GameManager.brainrot + 18.0, 100.0)
	AudioManager.play_sfx("tap_fart")
	
	var tween = create_tween()
	tween.tween_property(mesh_pivot, "rotation:z", 0.4, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_pivot, "rotation:z", -0.4, 0.12)
	tween.tween_property(mesh_pivot, "rotation:z", 0.2, 0.08)
	tween.tween_property(mesh_pivot, "rotation:z", -0.2, 0.08)
	tween.tween_property(mesh_pivot, "rotation:z", 0.0, 0.08)
	tween.tween_callback(func(): is_reacting = false)
	
	_spawn_toast_bubble("ui_feet_tickle", "EH EH EH! TUNG TUNG TUNG! 🦶💨")

func _spawn_toast_bubble(type: String, text: String):
	# Spawn cartoon speech bubble above the character
	var camera3d = get_viewport().get_camera_3d()
	if not camera3d: return
	
	var screen_pos = camera3d.unproject_position(global_position + Vector3(0, 2.0, 0))
	var main_ui = get_tree().root.get_node_or_null("Main/UI")
	if not main_ui: return
	
	var bubble = PanelContainer.new()
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	bubble.add_child(label)
	
	var style = StyleBoxFlat.new()
	style.bg_color = SPEECH_COLORS[randi() % SPEECH_COLORS.size()]
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.5)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bubble.add_theme_stylebox_override("panel", style)
	
	bubble.position = screen_pos - Vector2(100, 30)
	bubble.pivot_offset = Vector2(100, 30)
	bubble.scale = Vector2.ZERO
	main_ui.add_child(bubble)
	
	var bt = bubble.create_tween()
	bt.tween_property(bubble, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	bt.tween_property(bubble, "scale", Vector2.ONE, 0.06)
	bt.tween_property(bubble, "scale", Vector2.ONE, 1.2)
	bt.tween_property(bubble, "modulate:a", 0.0, 0.2)
	bt.tween_callback(bubble.queue_free)

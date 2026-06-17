extends Area3D

# CharacterSlot handles the 3D representation and interaction of a character in the grid

@export var slot_index: int = 0

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance: MeshInstance3D = $MeshPivot/MeshInstance3D

var character_id: String = ""
var character_data: CharacterData = null

# Animation variables
var idle_bob_speed: float = 2.0
var idle_bob_height: float = 0.12
var base_y: float = 0.0
var time_passed: float = 0.0

# Brainrot quotes
const BRAINROT_QUOTES = [
	"TUNG TUNG TUNG!",
	"BOMBARDINOOO!",
	"Tralalero Tralala!",
	"Skibidi Sahur!!",
	"Rizz me up at 3AM!",
	"Sigma rooster screams!",
	"Adidas sneakers on!",
	"TUNG TUNG Sahur is life!",
	"No cap, this coin is shiny!",
	"Glow up time!"
]

# Bubble color palette for speech bubbles (kid-friendly)
const BUBBLE_COLORS = [
	Color(0.85, 0.2, 0.5, 0.92),   # Hot pink
	Color(0.2, 0.7, 0.95, 0.92),   # Sky blue
	Color(0.95, 0.55, 0.1, 0.92),  # Orange
	Color(0.3, 0.85, 0.4, 0.92),   # Green
	Color(0.65, 0.3, 0.9, 0.92),   # Purple
	Color(0.95, 0.85, 0.1, 0.92),  # Yellow
]

func _ready():
	# Store the original Y position
	base_y = mesh_pivot.position.y
	time_passed = randf_range(0.0, 10.0) # Desynchronize bobbing
	
	# Connect click event
	input_event.connect(_on_input_event)
	
	# Initial update
	update_slot()
	
	# Listen to updates
	SignalBus.character_unlocked.connect(func(_char_id): update_slot())
	SignalBus.character_merged.connect(func(_from, _to): update_slot())
	
	# Start brainrot timer loop randomly (every 4-9 seconds per character)
	_start_brainrot_timer()

func _process(delta):
	if character_id == "":
		return
		
	# Bobbing idle animation
	time_passed += delta
	mesh_pivot.position.y = base_y + sin(time_passed * idle_bob_speed) * idle_bob_height
	mesh_pivot.rotate_y(0.3 * delta) # Slightly faster rotation

func update_slot():
	# Check if GameManager has a character in this slot
	var new_id = GameManager.characters_in_slots[slot_index]
	if new_id != character_id:
		character_id = new_id if new_id else ""
		if character_id != "":
			character_data = GameManager.all_characters.get(character_id)
			_setup_character_visuals()
			visible = true
			collision_shape.disabled = false
		else:
			character_data = null
			visible = false
			collision_shape.disabled = true

func _setup_character_visuals():
	if not character_data:
		return
		
	# Setup colors based on character type/rarity
	var mat = StandardMaterial3D.new()
	mat.metallic = 0.15
	mat.roughness = 0.5
	
	# Color code by Rarity or character ID
	match character_data.id:
		"tung_tung_jr":
			mat.albedo_color = Color(1.0, 0.5, 0.0) # Orange
		"tung_tung_tung":
			mat.albedo_color = Color(1.0, 0.2, 0.2) # Intense Red-Orange
		"tralalero_piccolo":
			mat.albedo_color = Color(0.2, 0.6, 1.0) # Blue
		_:
			# Fallback based on rarity
			match character_data.rarity:
				0: mat.albedo_color = Color(0.8, 0.8, 0.8) # Gray (Common)
				1: mat.albedo_color = Color(0.2, 0.85, 0.3) # Green (Uncommon)
				2: mat.albedo_color = Color(0.3, 0.5, 1.0) # Blue (Rare)
				3: mat.albedo_color = Color(0.7, 0.25, 0.9) # Purple (Epic)
				4: mat.albedo_color = Color(1.0, 0.85, 0.1) # Gold (Legendary)
	
	# Add emission glow — characters softly glow their own color (kid-friendly toy look)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.35
	mat.emission_energy_multiplier = 0.5
	
	mesh_instance.set_surface_override_material(0, mat)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and character_id != "":
			var viewport = get_viewport()
			var camera3d = viewport.get_camera_3d()
			var screen_pos = camera3d.unproject_position(global_position)
			
			var main = get_tree().root.get_node_or_null("Main")
			if main and main.has_method("start_dragging"):
				main.start_dragging(slot_index, screen_pos)

func play_tap_punch():
	var tween = create_tween()
	mesh_pivot.scale = Vector3.ONE # Reset
	tween.tween_property(mesh_pivot, "scale", Vector3(1.3, 0.7, 1.3), 0.05).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_pivot, "scale", Vector3(0.9, 1.2, 0.9), 0.05)
	tween.tween_property(mesh_pivot, "scale", Vector3.ONE, 0.1).set_ease(Tween.EASE_IN_OUT)

func _start_brainrot_timer():
	await get_tree().create_timer(randf_range(3.0, 8.0)).timeout
	if character_id != "":
		trigger_brainrot_event()
	_start_brainrot_timer()

func trigger_brainrot_event():
	if character_id == "":
		return
		
	# 1. Do a crazy 3D animation (e.g. jump & spin)
	var tween = create_tween()
	var start_pos = mesh_pivot.position
	
	# Jump up
	tween.tween_property(mesh_pivot, "position:y", start_pos.y + 1.2, 0.2).set_ease(Tween.EASE_OUT)
	# Spin around
	tween.parallel().tween_property(mesh_pivot, "rotation:y", mesh_pivot.rotation.y + PI * 2, 0.4)
	# Fall back down
	tween.tween_property(mesh_pivot, "position:y", start_pos.y, 0.15).set_ease(Tween.EASE_IN)
	
	# 2. Spawn a speech bubble with a quote
	var random_quote = BRAINROT_QUOTES[randi() % BRAINROT_QUOTES.size()]
	_spawn_speech_bubble(random_quote)
	
	# 3. Play sound clip if set, or generic silly SFX
	if character_data.sound_id != "":
		AudioManager.play_sfx("tap_" + character_data.sound_id)
	else:
		AudioManager.play_sfx("tap_tung")

func _spawn_speech_bubble(text_content: String):
	# Get Screen position of slot
	var camera3d = get_viewport().get_camera_3d()
	if not camera3d:
		return
	var screen_pos = camera3d.unproject_position(global_position + Vector3(0, 1.8, 0))
	
	# Find Main UI layer to add bubble to
	var main_node = get_tree().root.get_node_or_null("Main/UI")
	if not main_node:
		return
		
	# Create a colorful PanelContainer for speech bubble
	var bubble = PanelContainer.new()
	var label = Label.new()
	label.text = text_content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	
	bubble.add_child(label)
	
	# Add colorful style — pick random bubble color
	var bubble_color = BUBBLE_COLORS[randi() % BUBBLE_COLORS.size()]
	var style = StyleBoxFlat.new()
	style.bg_color = bubble_color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	bubble.add_theme_stylebox_override("panel", style)
	
	# Positioning
	bubble.position = screen_pos - Vector2(60, 30) # Approximate offset
	bubble.scale = Vector2.ZERO
	bubble.pivot_offset = Vector2(60, 30)
	main_node.add_child(bubble)
	
	# Animate speech bubble — bouncy entrance
	var bubble_tween = bubble.create_tween()
	bubble_tween.tween_property(bubble, "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT)
	bubble_tween.tween_property(bubble, "scale", Vector2.ONE, 0.08).set_ease(Tween.EASE_IN_OUT)
	bubble_tween.tween_property(bubble, "scale", Vector2.ONE, 1.5) # Wait
	bubble_tween.tween_property(bubble, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	bubble_tween.tween_callback(bubble.queue_free)

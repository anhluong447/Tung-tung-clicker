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

func _ready():
	# Connect HUD navigation signals
	hud.nav_tab_changed.connect(_on_nav_tab_changed)
	
	# Connect Tap Area input
	tap_area.gui_input.connect(_on_tap_area_input)
	
	# Connect tap events to trigger juice stack
	SignalBus.tap_registered.connect(_on_tap_registered)
	
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



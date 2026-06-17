extends Control

# HUD Script for Tung Tung Clicker — Clash-Style Cartoon UI

@onready var coin_label: Label = $TopBar/HBox/CurrenciesVBox/CoinContainer/Capsule/HBox/CoinLabel
@onready var gem_label: Label = $TopBar/HBox/CurrenciesVBox/GemContainer/Capsule/HBox/GemLabel
@onready var cps_label: Label = $TopBar/HBox/CPSLabel
@onready var level_label: Label = $TopBar/HBox/ProfileContainer/StarLevel/LevelLabel
@onready var xp_bar: ProgressBar = $XPBar

# Mood Bars
@onready var hype_bar: ProgressBar = $MoodMeters/HypeBox/Bar
@onready var chaos_bar: ProgressBar = $MoodMeters/ChaosBox/Bar
@onready var brainrot_bar: ProgressBar = $MoodMeters/BrainrotBox/Bar

# Plus buttons
@onready var gem_plus_btn: Button = $TopBar/HBox/CurrenciesVBox/GemContainer/Capsule/HBox/AddButton
@onready var coin_plus_btn: Button = $TopBar/HBox/CurrenciesVBox/CoinContainer/Capsule/HBox/AddButton

# Navigation Buttons
@onready var shop_btn: Button = $BottomNav/HBox/ShopButton
@onready var collection_btn: Button = $BottomNav/HBox/CollectionButton
@onready var clicker_btn: Button = $BottomNav/HBox/ClickerButton
@onready var quest_btn: Button = $BottomNav/HBox/QuestButton
@onready var settings_btn: Button = $BottomNav/HBox/SettingsButton

signal nav_tab_changed(tab_name: String)

var target_coins: float = 0.0
var displayed_coins: float = 0.0
var active_tab: String = "clicker"

# Color types for tabs
const TAB_TYPES = {
	"shop": "blue",
	"collection": "purple",
	"clicker": "green",
	"quest": "orange",
	"settings": "red"
}

func _ready():
	# Connect to GameManager signals
	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.cps_changed.connect(_on_cps_changed)
	SignalBus.player_level_up.connect(_on_level_up)
	SignalBus.xp_changed.connect(_on_xp_changed)
	SignalBus.mood_changed.connect(_on_mood_changed)
	SignalBus.toast_notification.connect(spawn_toast_notification)
	
	# Connect buttons
	shop_btn.pressed.connect(func(): _on_nav_pressed("shop"))
	collection_btn.pressed.connect(func(): _on_nav_pressed("collection"))
	clicker_btn.pressed.connect(func(): _on_nav_pressed("clicker"))
	quest_btn.pressed.connect(func(): _on_nav_pressed("quest"))
	settings_btn.pressed.connect(func(): _on_nav_pressed("settings"))
	
	# Plus buttons click
	gem_plus_btn.pressed.connect(_on_plus_pressed)
	coin_plus_btn.pressed.connect(_on_plus_pressed)
	
	# Style plus buttons
	Themes.style_button(gem_plus_btn, "green")
	Themes.style_button(coin_plus_btn, "green")
	gem_plus_btn.text = "+"
	coin_plus_btn.text = "+"
	
	# Default fake gems count matching the premium feel
	gem_label.text = "888"
	
	# Initial displays
	target_coins = GameManager.coins
	displayed_coins = target_coins
	_update_coin_display()
	_on_cps_changed(GameManager.total_cps)
	_on_level_up(GameManager.player_level)
	_on_xp_changed(GameManager.player_xp, GameManager.get_xp_needed())
	
	# Style mood bars fill color
	_setup_mood_bar_styles()
	
	# Refresh UI selection states
	_update_nav_states()

func _setup_mood_bar_styles():
	var hb_style = StyleBoxFlat.new()
	hb_style.bg_color = Color(1.0, 0.25, 0.2) # Orange-Red Hype
	hb_style.corner_radius_top_left = 4
	hb_style.corner_radius_top_right = 4
	hb_style.corner_radius_bottom_right = 4
	hb_style.corner_radius_bottom_left = 4
	hype_bar.add_theme_stylebox_override("fill", hb_style)
	
	var cb_style = StyleBoxFlat.new()
	cb_style.bg_color = Color(0.7, 0.2, 0.9) # Purple Chaos
	cb_style.corner_radius_top_left = 4
	cb_style.corner_radius_top_right = 4
	cb_style.corner_radius_bottom_right = 4
	cb_style.corner_radius_bottom_left = 4
	chaos_bar.add_theme_stylebox_override("fill", cb_style)
	
	var bb_style = StyleBoxFlat.new()
	bb_style.bg_color = Color(1.0, 0.8, 0.1) # Yellow Rot
	bb_style.corner_radius_top_left = 4
	bb_style.corner_radius_top_right = 4
	bb_style.corner_radius_bottom_right = 4
	bb_style.corner_radius_bottom_left = 4
	brainrot_bar.add_theme_stylebox_override("fill", bb_style)

func _process(delta):
	# Smoothly animate coin counter if there's a difference
	if abs(displayed_coins - target_coins) > 0.01:
		displayed_coins = lerp(displayed_coins, target_coins, 15.0 * delta)
		if abs(displayed_coins - target_coins) < 0.1:
			displayed_coins = target_coins
		_update_coin_display()

func _on_coins_changed(new_amount: float):
	var diff = new_amount - target_coins
	if diff > 0.1:
		spawn_coin_popup(diff)
	target_coins = new_amount
	# Scale punch effect on change
	_punch_scale(coin_label, 0.15)

func _on_cps_changed(new_cps: float):
	cps_label.text = "💰 Income:\n+%s/s" % format_number(new_cps)

func _on_level_up(new_level: int):
	level_label.text = "Lv.%d" % new_level
	_punch_scale($TopBar/HBox/ProfileContainer/StarLevel, 0.35)

func _on_xp_changed(current_xp: float, max_xp: float):
	xp_bar.max_value = max_xp
	xp_bar.value = current_xp

func _on_mood_changed(hype: float, chaos: float, rot: float):
	hype_bar.value = hype
	chaos_bar.value = chaos
	brainrot_bar.value = rot

func spawn_coin_popup(amount: float):
	var label = Label.new()
	label.text = "+%s" % format_number(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2)) # Yellow
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	$CoinPopAnchor.add_child(label)
	
	# Random initial placement offset
	label.position = Vector2(randf_range(-25, 25), randf_range(-10, 10))
	
	# Bounce slide upward tween
	var tween = label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 45.0, 0.55).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.25)
	tween.tween_callback(label.queue_free)

func spawn_toast_notification(message: String):
	var panel = PanelContainer.new()
	var label = Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	panel.add_child(label)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.24, 0.95)
	style.border_width_left = 4
	style.border_color = Color(0.0, 0.85, 1.0, 1) # Glowing Cyan border indicator
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 2
	style.corner_radius_top_left = 2
	panel.add_theme_stylebox_override("panel", style)
	
	$ToastContainer.add_child(panel)
	
	# Animation from bottom-right slide in
	panel.modulate.a = 0.0
	var original_pos_x = panel.position.x
	panel.position.x += 120.0
	
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(panel, "position:x", original_pos_x, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "position:x", panel.position.x + 200.0, 0.25).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(panel.queue_free)

func _update_coin_display():
	coin_label.text = format_number(displayed_coins)

func _on_plus_pressed():
	AudioManager.play_sfx("ui_click")
	# Trigger coin reward for clicker feedback
	GameManager.add_coins(500.0)
	var tween = create_tween()
	tween.tween_property(coin_label, "modulate", Color(0.2, 1.0, 0.4), 0.1)
	tween.tween_property(coin_label, "modulate", Color(1.0, 1.0, 1.0), 0.2)

func _on_nav_pressed(tab_name: String):
	if active_tab == tab_name:
		return
		
	active_tab = tab_name
	nav_tab_changed.emit(tab_name)
	AudioManager.play_sfx("ui_click")
	
	# Refresh visual styles
	_update_nav_states()
	
	# Punch scale on select
	var btn_map = {
		"shop": shop_btn,
		"collection": collection_btn,
		"clicker": clicker_btn,
		"quest": quest_btn,
		"settings": settings_btn,
	}
	if btn_map.has(tab_name):
		_punch_scale(btn_map[tab_name], 0.12)

func _update_nav_states():
	var btn_map = {
		"shop": shop_btn,
		"collection": collection_btn,
		"clicker": clicker_btn,
		"quest": quest_btn,
		"settings": settings_btn,
	}
	
	for tab in btn_map:
		var btn = btn_map[tab] as Button
		var type = TAB_TYPES[tab]
		
		# If this tab is active, apply the "pressed" visual state (depressed 3D border)
		if tab == active_tab:
			btn.add_theme_stylebox_override("normal", Themes.get_button_style(type, "pressed"))
			btn.add_theme_stylebox_override("hover", Themes.get_button_style(type, "pressed"))
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3)) # yellow highlight text
		else:
			# Apply the 3D normal/hover cartoon styles
			btn.add_theme_stylebox_override("normal", Themes.get_button_style(type, "normal"))
			btn.add_theme_stylebox_override("hover", Themes.get_button_style(type, "hover"))
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			
		# Keep outline style
		btn.add_theme_constant_override("outline_size", 5)
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))

# Number formatting utility
func format_number(val: float) -> String:
	if val < 1000.0:
		return "%.0f" % val if val == int(val) else "%.1f" % val
	elif val < 1000000.0:
		return "%.2fK" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.2fM" % (val / 1000000.0)
	elif val < 1000000000000.0:
		return "%.2fB" % (val / 1000000000.0)
	else:
		return "%.2fT" % (val / 1000000000000.0)

# Visual Juice: Scale Punch
func _punch_scale(node: Control, strength: float):
	var tween = create_tween()
	var orig_scale = Vector2.ONE
	node.pivot_offset = node.size / 2.0
	tween.tween_property(node, "scale", orig_scale * (1.0 + strength), 0.05).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", orig_scale, 0.1).set_ease(Tween.EASE_IN_OUT)

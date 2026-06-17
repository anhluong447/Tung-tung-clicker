extends Control

# HUD Script for Tung Tung Clicker — Clash-Style Cartoon UI

@onready var coin_label: Label = $TopBar/HBox/CurrenciesVBox/CoinContainer/Capsule/HBox/CoinLabel
@onready var gem_label: Label = $TopBar/HBox/CurrenciesVBox/GemContainer/Capsule/HBox/GemLabel
@onready var cps_label: Label = $TopBar/HBox/CPSLabel
@onready var multiplier_label: Label = $TopBar/MultiplierLabel

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
	SignalBus.boost_activated.connect(_on_boost_activated)
	
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
	gem_label.text = "480"
	
	# Initial displays
	target_coins = GameManager.coins
	displayed_coins = target_coins
	_update_coin_display()
	_on_cps_changed(GameManager.total_cps)
	multiplier_label.visible = false
	
	# Refresh UI selection states
	_update_nav_states()

func _process(delta):
	# Smoothly animate coin counter if there's a difference
	if abs(displayed_coins - target_coins) > 0.01:
		displayed_coins = lerp(displayed_coins, target_coins, 15.0 * delta)
		if abs(displayed_coins - target_coins) < 0.1:
			displayed_coins = target_coins
		_update_coin_display()

func _on_coins_changed(new_amount: float):
	target_coins = new_amount
	# Scale punch effect on change
	_punch_scale(coin_label, 0.15)

func _on_cps_changed(new_cps: float):
	cps_label.text = "💰 Income:\n+%s/s" % format_number(new_cps)

func _on_boost_activated(boost_id: String, duration: float):
	if boost_id == "double_earnings":
		multiplier_label.visible = true
		multiplier_label.text = "🔥 2x BOOST ACTIVE! 🔥"
		var tween = create_tween()
		tween.tween_property(multiplier_label, "modulate:a", 1.0, 0.2)
		get_tree().create_timer(duration).timeout.connect(func():
			var fade_tween = create_tween()
			fade_tween.tween_property(multiplier_label, "modulate:a", 0.0, 0.5)
			fade_tween.tween_callback(func(): multiplier_label.visible = false)
		)

func _update_coin_display():
	coin_label.text = format_number(displayed_coins)

func _on_plus_pressed():
	AudioManager.play_sfx("ui_click")
	# Trigger fake coin pack reward for kids feedback
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

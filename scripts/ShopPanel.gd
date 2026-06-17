extends Panel

# ShopPanel handles upgrade purchases and character buying — Cartoon 3D UI

@onready var upgrades_container: VBoxContainer = $Scroll/VBox/UpgradesContainer
@onready var characters_container: VBoxContainer = $Scroll/VBox/CharactersContainer
@onready var header_banner: PanelContainer = $HeaderBanner

func _ready():
	# Connect to signals to update buttons
	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.upgrade_purchased.connect(_on_upgrade_purchased)
	SignalBus.character_unlocked.connect(_on_character_unlocked)
	
	# Apply orange ribbon style to header
	header_banner.add_theme_stylebox_override("panel", Themes.get_ribbon_style("orange"))
	
	# Initial populate
	populate_shop()

func populate_shop():
	# Clear old items
	for child in upgrades_container.get_children():
		child.queue_free()
	for child in characters_container.get_children():
		child.queue_free()
		
	# Populate Upgrades
	for upgrade_id in GameManager.all_upgrades.keys():
		var up_data = GameManager.all_upgrades[upgrade_id]
		var item = _create_upgrade_item_ui(upgrade_id, up_data)
		upgrades_container.add_child(item)
		
	# Populate Characters (Only show characters that are Tier 1 - Common)
	for char_id in GameManager.all_characters.keys():
		var char_data = GameManager.all_characters[char_id] as CharacterData
		if char_data.rarity == 0:
			var item = _create_character_item_ui(char_id, char_data)
			characters_container.add_child(item)
			
	_update_shop_buttons()

func _create_upgrade_item_ui(upgrade_id: String, up_data: Dictionary) -> PanelContainer:
	var container = PanelContainer.new()
	# Upgrades cards get styled as Blue Cards
	container.add_theme_stylebox_override("panel", Themes.get_card_style("blue"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	# Emoji icon
	var icon_lbl = Label.new()
	icon_lbl.text = "⚡"
	icon_lbl.add_theme_font_size_override("font_size", 28)
	icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_lbl)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	# Name & Level
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4, 1)) # Gold
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	name_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_lbl)
	
	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = up_data["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	# Buy Button — Glossy Green
	var btn = Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_buy_upgrade_pressed(upgrade_id))
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
	# Store references in metadata
	container.set_meta("upgrade_id", upgrade_id)
	_update_upgrade_item_text(container, upgrade_id, up_data)
	
	return container

func _create_character_item_ui(char_id: String, char_data: CharacterData) -> PanelContainer:
	var container = PanelContainer.new()
	# Character cards get styled as Green Cards (matching Pine Forest look)
	container.add_theme_stylebox_override("panel", Themes.get_card_style("green"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	# Color indicator box/circle
	var avatar_panel = PanelContainer.new()
	var style_avatar = StyleBoxFlat.new()
	style_avatar.bg_color = Color(0.05, 0.25, 0.05, 0.8)
	style_avatar.border_width_left = 2
	style_avatar.border_width_top = 2
	style_avatar.border_width_right = 2
	style_avatar.border_width_bottom = 2
	style_avatar.border_color = Color(0.5, 0.8, 0.2, 0.6)
	style_avatar.corner_radius_top_left = 10
	style_avatar.corner_radius_top_right = 10
	style_avatar.corner_radius_bottom_right = 10
	style_avatar.corner_radius_bottom_left = 10
	avatar_panel.add_theme_stylebox_override("panel", style_avatar)
	avatar_panel.custom_minimum_size = Vector2(48, 48)
	avatar_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(avatar_panel)
	
	var emoji_lbl = Label.new()
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.add_theme_font_size_override("font_size", 24)
	if char_id == "tung_tung_jr":
		emoji_lbl.text = "🐣"
	elif char_id == "tralalero_piccolo":
		emoji_lbl.text = "🦈"
	else:
		emoji_lbl.text = "🐓"
	avatar_panel.add_child(emoji_lbl)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	# Name
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.4, 1)) # Bright Green-Yellow
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.text = char_data.display_name
	vbox.add_child(name_lbl)
	
	# Stats display
	var stats_lbl = Label.new()
	stats_lbl.text = "💰 Income: +%s/s" % format_number(char_data.base_cps)
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.85, 0.9))
	vbox.add_child(stats_lbl)
	
	# Buy Button — Glossy Green
	var btn = Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_buy_character_pressed(char_id))
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
	# Store references in metadata
	container.set_meta("char_id", char_id)
	_update_char_item_text(container, char_id)
	
	return container

func _update_upgrade_item_text(container: PanelContainer, upgrade_id: String, up_data: Dictionary):
	var name_lbl = container.get_node("HBox/VBox/NameLabel") as Label
	var btn = container.get_node("HBox/BuyButton") as Button
	
	var current_lv = GameManager.upgrades.get(upgrade_id, 0)
	var max_lv = up_data["max_level"]
	
	name_lbl.text = "%s (Lv %d/%d)" % [up_data["display_name"], current_lv, max_lv]
	
	var cost = GameManager.get_upgrade_cost(upgrade_id)
	if current_lv >= max_lv:
		btn.text = "✅ MAX"
		btn.disabled = true
		Themes.style_button(btn, "blue") # Styled blue when maxed
	else:
		btn.text = "🪙 %s" % format_number(cost)
		btn.disabled = GameManager.coins < cost
		Themes.style_button(btn, "green")

func _update_char_item_text(container: PanelContainer, char_id: String):
	var btn = container.get_node("HBox/BuyButton") as Button
	var cost = GameManager.get_character_buy_cost(char_id)
	
	btn.text = "🪙 %s" % format_number(cost)
	
	# Check if grid is full
	var empty_slot_idx = GameManager.characters_in_slots.find(null)
	var is_grid_full = empty_slot_idx == -1
	
	if is_grid_full:
		btn.disabled = true
		btn.text = "❌ Full"
		Themes.style_button(btn, "red")
	else:
		btn.disabled = GameManager.coins < cost
		Themes.style_button(btn, "green")

func _update_shop_buttons():
	# Update all upgrades
	for item in upgrades_container.get_children():
		var up_id = item.get_meta("upgrade_id")
		var up_data = GameManager.all_upgrades[up_id]
		_update_upgrade_item_text(item, up_id, up_data)
		
	# Update all characters
	for item in characters_container.get_children():
		var char_id = item.get_meta("char_id")
		_update_char_item_text(item, char_id)

func _on_buy_upgrade_pressed(upgrade_id: String):
	if GameManager.buy_upgrade(upgrade_id):
		AudioManager.play_sfx("tap_cash")
		SaveManager.save_game()

func _on_buy_character_pressed(char_id: String):
	if GameManager.unlock_character(char_id):
		AudioManager.play_sfx("tap_cash")
		SaveManager.save_game()

func _on_coins_changed(_new_amount: float):
	_update_shop_buttons()

func _on_upgrade_purchased(_up_id: String, _new_lv: int):
	_update_shop_buttons()

func _on_character_unlocked(_char_id: String):
	_update_shop_buttons()

# Utility formatting
func format_number(val: float) -> String:
	if val == INF: return "MAX"
	if val < 1000.0:
		return "%.0f" % val if val == int(val) else "%.1f" % val
	elif val < 1000000.0:
		return "%.2fK" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.2fM" % (val / 1000000.0)
	else:
		return "%.2fB" % (val / 1000000000.0)

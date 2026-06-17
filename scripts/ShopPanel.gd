extends Panel

# ShopPanel handles upgrade purchases and character buying — My Talking Tom Category Layout

@onready var char_tab_btn: Button = $CategoryTabs/CharTabBtn
@onready var upgrade_tab_btn: Button = $CategoryTabs/UpgradeTabBtn
@onready var boost_tab_btn: Button = $CategoryTabs/BoostTabBtn

@onready var featured_container: VBoxContainer = $Scroll/VBox/FeaturedContainer
@onready var items_container: VBoxContainer = $Scroll/VBox/ItemsContainer
@onready var main_header: Label = $Scroll/VBox/MainHeader
@onready var header_banner: PanelContainer = $HeaderBanner

var current_category: String = "char" # char, upgrade, boost
var glow_timer: float = 0.0

func _ready():
	# Connect signals
	SignalBus.coins_changed.connect(_on_coins_changed)
	SignalBus.upgrade_purchased.connect(_on_upgrade_purchased)
	SignalBus.character_unlocked.connect(_on_character_unlocked)
	
	# Tab button clicks
	char_tab_btn.pressed.connect(func(): _switch_tab("char"))
	upgrade_tab_btn.pressed.connect(func(): _switch_tab("upgrade"))
	boost_tab_btn.pressed.connect(func(): _switch_tab("boost"))
	
	# Apply header style
	header_banner.add_theme_stylebox_override("panel", Themes.get_ribbon_style("orange"))
	
	# Style category tabs initially
	_update_tab_styles()
	
	# Populate
	populate_shop()

func _process(delta):
	# Animated border glow for the Featured Card (if present)
	if current_category == "char" and featured_container.get_child_count() > 0:
		glow_timer += delta * 6.0
		var featured_card = featured_container.get_child(0) as PanelContainer
		if featured_card:
			var border_color = Color.from_hsv(sin(glow_timer) * 0.15 + 0.1, 0.9, 0.95)
			var style = featured_card.get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				style.border_color = border_color

func _switch_tab(tab: String):
	if current_category == tab:
		return
	current_category = tab
	AudioManager.play_sfx("ui_click")
	_update_tab_styles()
	populate_shop()

func _update_tab_styles():
	var tabs = {
		"char": char_tab_btn,
		"upgrade": upgrade_tab_btn,
		"boost": boost_tab_btn
	}
	for key in tabs:
		var btn = tabs[key]
		if key == current_category:
			Themes.style_button(btn, "orange")
		else:
			Themes.style_button(btn, "blue")

func populate_shop():
	# Clear old items
	for child in featured_container.get_children():
		child.queue_free()
	for child in items_container.get_children():
		child.queue_free()
		
	match current_category:
		"char":
			main_header.text = "🐣 DANH SÁCH NHÂN VẬT"
			_populate_characters()
		"upgrade":
			main_header.text = "⚡ NÂNG CẤP VĨNH VIỄN"
			_populate_upgrades()
		"boost":
			main_header.text = "💥 TĂNG TỐC TỨ THỜI"
			_populate_boosts()

func _populate_characters():
	# 1. Create a Featured Item Card at the top (e.g. Tung Tung Tung - Tier 3 Epic)
	if GameManager.all_characters.has("tung_tung_tung"):
		var feat_data = GameManager.all_characters["tung_tung_tung"] as CharacterData
		var feat_card = _create_featured_character_card("tung_tung_tung", feat_data)
		featured_container.add_child(feat_card)
		
	# 2. Rebuild the regular character list
	for char_id in GameManager.all_characters.keys():
		# Skip featured in regular items list
		if char_id == "tung_tung_tung":
			continue
		var char_data = GameManager.all_characters[char_id] as CharacterData
		var card = _create_character_item_ui(char_id, char_data)
		items_container.add_child(card)
		
	_update_shop_buttons()

func _populate_upgrades():
	# List only upgrades (excluding auto_tap)
	var upgrade_ids = ["tap_level", "critical_level", "offline_vault_level"]
	for up_id in upgrade_ids:
		if GameManager.all_upgrades.has(up_id):
			var up_data = GameManager.all_upgrades[up_id]
			var card = _create_upgrade_item_ui(up_id, up_data)
			items_container.add_child(card)
	_update_shop_buttons()

func _populate_boosts():
	# 1. List Auto-Tap Bot
	if GameManager.all_upgrades.has("auto_tap_level"):
		var up_data = GameManager.all_upgrades["auto_tap_level"]
		var card = _create_upgrade_item_ui("auto_tap_level", up_data)
		items_container.add_child(card)
		
	# 2. Add an Ad-Reward Double Income card
	var ad_card = _create_ad_boost_card()
	items_container.add_child(ad_card)
	
	_update_shop_buttons()

func _create_featured_character_card(char_id: String, char_data: CharacterData) -> PanelContainer:
	var container = PanelContainer.new()
	# Shiny gold border card initially
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.bg_color = Color(0.18, 0.08, 0.28, 0.95) # Dark purple glow background
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 8
	style.border_color = Color(1.0, 0.8, 0.2)
	container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "RootVBox"
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)
	
	# Ribbon Container
	var ribbon = PanelContainer.new()
	var ribbon_style = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(1.0, 0.2, 0.4) # Glowing pink
	ribbon_style.border_width_bottom = 2
	ribbon_style.border_color = Color(0.6, 0.0, 0.2)
	ribbon_style.corner_radius_top_left = 6
	ribbon_style.corner_radius_top_right = 6
	ribbon_style.content_margin_left = 8
	ribbon_style.content_margin_right = 8
	ribbon_style.content_margin_top = 3
	ribbon_style.content_margin_bottom = 3
	ribbon.add_theme_stylebox_override("panel", ribbon_style)
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	
	var ribbon_lbl = Label.new()
	ribbon_lbl.text = "🔥 ĐẶC BIỆT (SIÊU CẤP)"
	ribbon_lbl.add_theme_font_size_override("font_size", 10)
	ribbon_lbl.add_theme_color_override("font_color", Color.WHITE)
	ribbon.add_child(ribbon_lbl)
	vbox.add_child(ribbon)
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)
	
	# Giant Emoji Icon
	var emoji_lbl = Label.new()
	emoji_lbl.name = "EmojiLabel"
	emoji_lbl.text = "🔥🐓"
	emoji_lbl.add_theme_font_size_override("font_size", 34)
	emoji_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(emoji_lbl)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.name = "VBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "TUNG TUNG TUNG"
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	text_vbox.add_child(name_lbl)
	
	var stat_lbl = Label.new()
	stat_lbl.name = "StatsLabel"
	stat_lbl.text = "Tốc độ sản sinh: +%s/s" % format_number(char_data.base_cps)
	stat_lbl.add_theme_font_size_override("font_size", 11)
	text_vbox.add_child(stat_lbl)
	
	var btn = Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_buy_character_pressed(char_id))
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
	container.set_meta("char_id", char_id)
	return container

func _create_character_item_ui(char_id: String, char_data: CharacterData) -> PanelContainer:
	var container = PanelContainer.new()
	var rarity = char_data.rarity
	container.add_theme_stylebox_override("panel", Themes.get_rarity_card_style(rarity))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	# Emoji Panel
	var avatar_panel = PanelContainer.new()
	avatar_panel.name = "AvatarPanel"
	var style_avatar = StyleBoxFlat.new()
	style_avatar.bg_color = Color(0, 0, 0, 0.6)
	style_avatar.corner_radius_top_left = 10
	style_avatar.corner_radius_top_right = 10
	style_avatar.corner_radius_bottom_right = 10
	style_avatar.corner_radius_bottom_left = 10
	avatar_panel.add_theme_stylebox_override("panel", style_avatar)
	avatar_panel.custom_minimum_size = Vector2(48, 48)
	avatar_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(avatar_panel)
	
	var emoji_lbl = Label.new()
	emoji_lbl.name = "EmojiLabel"
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
	
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_lbl)
	
	var stats_lbl = Label.new()
	stats_lbl.name = "StatsLabel"
	stats_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(stats_lbl)
	
	# TAP TO UNLOCK bounce text
	var lock_lbl = Label.new()
	lock_lbl.name = "LockLabel"
	lock_lbl.text = "🔒 TAP TO UNLOCK"
	lock_lbl.add_theme_font_size_override("font_size", 11)
	lock_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lock_lbl.visible = false
	vbox.add_child(lock_lbl)
	
	var btn = Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_buy_character_pressed(char_id))
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
	container.set_meta("char_id", char_id)
	_update_char_item_text(container, char_id)
	
	return container

func _create_upgrade_item_ui(upgrade_id: String, up_data: Dictionary) -> PanelContainer:
	var container = PanelContainer.new()
	container.add_theme_stylebox_override("panel", Themes.get_card_style("blue"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
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
	
	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = up_data["description"]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.name = "BuyButton"
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): _on_buy_upgrade_pressed(upgrade_id))
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
	container.set_meta("upgrade_id", upgrade_id)
	_update_upgrade_item_text(container, upgrade_id, up_data)
	
	return container

func _create_ad_boost_card() -> PanelContainer:
	var container = PanelContainer.new()
	container.add_theme_stylebox_override("panel", Themes.get_card_style("yellow"))
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)
	
	var icon_lbl = Label.new()
	icon_lbl.text = "📺"
	icon_lbl.add_theme_font_size_override("font_size", 30)
	icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_lbl)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = "X2 THU NHẬP (10 Phút)"
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = "Xem quảng cáo ngắn để nhân đôi tốc độ đào coin của toàn bộ trang trại."
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 46)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.text = "XEM AD"
	btn.pressed.connect(func():
		AudioManager.play_sfx("ui_click")
		SignalBus.ad_reward_earned.emit("shop_boost")
		SignalBus.toast_notification.emit("🔥 ĐÃ BẬT X2 THU NHẬP TRONG 10 PHÚT!")
	)
	Themes.style_button(btn, "green")
	hbox.add_child(btn)
	
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
		Themes.style_button(btn, "blue")
	else:
		btn.text = "🪙 %s" % format_number(cost)
		btn.disabled = GameManager.coins < cost
		Themes.style_button(btn, "green")

func _update_char_item_text(container: PanelContainer, char_id: String):
	var char_data = GameManager.all_characters[char_id] as CharacterData
	
	var hbox: HBoxContainer = null
	if container.has_node("HBox"):
		hbox = container.get_node("HBox")
	elif container.has_node("RootVBox/HBox"):
		hbox = container.get_node("RootVBox/HBox")
		
	if not hbox:
		return
		
	var btn = hbox.get_node("BuyButton") as Button
	var vbox = hbox.get_node("VBox") as VBoxContainer
	var name_lbl = vbox.get_node("NameLabel") as Label
	var stats_lbl = vbox.get_node("StatsLabel") as Label
	var lock_lbl = vbox.get_node_or_null("LockLabel") as Label
	
	var emoji_lbl: Label = null
	if hbox.has_node("EmojiLabel"):
		emoji_lbl = hbox.get_node("EmojiLabel")
	elif hbox.has_node("AvatarPanel/EmojiLabel"):
		emoji_lbl = hbox.get_node("AvatarPanel/EmojiLabel")
		
	if not emoji_lbl:
		return
	
	var is_unlocked = GameManager.characters_unlocked.has(char_id)
	
	if is_unlocked:
		name_lbl.text = char_data.display_name
		stats_lbl.text = "Tốc độ: +%s/s" % format_number(char_data.base_cps)
		emoji_lbl.modulate = Color.WHITE
		if lock_lbl: lock_lbl.visible = false
		
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
	else:
		# Locked character silhouette setup
		name_lbl.text = "???"
		stats_lbl.text = "Tốc độ: ???/s"
		emoji_lbl.modulate = Color(0.08, 0.08, 0.08) # Silhouette pitch black
		if lock_lbl: 
			lock_lbl.visible = true
			# Bounce animation effect on label text
			var lock_tween = lock_lbl.create_tween().set_loops()
			lock_tween.tween_property(lock_lbl, "modulate:a", 0.4, 0.5)
			lock_tween.tween_property(lock_lbl, "modulate:a", 1.0, 0.5)
			
		var cost = GameManager.get_character_buy_cost(char_id)
		btn.text = "🔒 %s" % format_number(cost)
		btn.disabled = GameManager.coins < cost
		Themes.style_button(btn, "blue")

func _update_shop_buttons():
	if current_category == "char":
		# Update featured card
		for item in featured_container.get_children():
			var char_id = item.get_meta("char_id")
			_update_char_item_text(item, char_id)
			
	# Update items container
	for item in items_container.get_children():
		if item.has_meta("char_id"):
			var char_id = item.get_meta("char_id")
			_update_char_item_text(item, char_id)
		elif item.has_meta("upgrade_id"):
			var up_id = item.get_meta("upgrade_id")
			var up_data = GameManager.all_upgrades[up_id]
			_update_upgrade_item_text(item, up_id, up_data)

func _on_buy_upgrade_pressed(upgrade_id: String):
	if GameManager.buy_upgrade(upgrade_id):
		AudioManager.play_sfx("tap_cash")
		SaveManager.save_game()

func _on_buy_character_pressed(char_id: String):
	var was_unlocked = GameManager.characters_unlocked.has(char_id)
	if GameManager.unlock_character(char_id):
		AudioManager.play_sfx("tap_cash")
		
		# If newly unlocked, trigger special evolution card reveal popup!
		if not was_unlocked:
			var main = get_tree().root.get_node_or_null("Main")
			if main and main.has_method("trigger_unlock_fx"):
				main.trigger_unlock_fx(char_id)
		
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

extends Node

# Themes autoload helper to construct cartoonish 3D StyleBoxes and styling elements programmatically

# Primary Color Palette
const COLOR_GREEN_BG = Color(0.24, 0.76, 0.15)
const COLOR_GREEN_DARK = Color(0.12, 0.44, 0.08)
const COLOR_GREEN_HOVER = Color(0.32, 0.84, 0.22)

const COLOR_ORANGE_BG = Color(1.0, 0.55, 0.0)
const COLOR_ORANGE_DARK = Color(0.65, 0.3, 0.0)
const COLOR_ORANGE_HOVER = Color(1.0, 0.65, 0.1)

const COLOR_BLUE_BG = Color(0.0, 0.55, 0.9)
const COLOR_BLUE_DARK = Color(0.0, 0.32, 0.62)
const COLOR_BLUE_HOVER = Color(0.15, 0.65, 1.0)

const COLOR_PURPLE_BG = Color(0.55, 0.28, 0.85)
const COLOR_PURPLE_DARK = Color(0.35, 0.15, 0.6)
const COLOR_PURPLE_HOVER = Color(0.65, 0.38, 0.95)

const COLOR_RED_BG = Color(0.9, 0.22, 0.28)
const COLOR_RED_DARK = Color(0.55, 0.08, 0.12)
const COLOR_RED_HOVER = Color(1.0, 0.35, 0.4)

const COLOR_DARK_BLUE = Color(0.06, 0.12, 0.25)
const COLOR_LIGHT_BLUE = Color(0.1, 0.2, 0.4)

# Cache styleboxes to prevent rebuilding
var _cache: Dictionary = {}

func get_button_style(type: String, state: String) -> StyleBoxFlat:
	var key = "%s_%s" % [type, state]
	if _cache.has(key):
		return _cache[key]
		
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	
	var base_col: Color
	var dark_col: Color
	
	match type:
		"green":
			base_col = COLOR_GREEN_BG
			dark_col = COLOR_GREEN_DARK
			if state == "hover": base_col = COLOR_GREEN_HOVER
		"orange":
			base_col = COLOR_ORANGE_BG
			dark_col = COLOR_ORANGE_DARK
			if state == "hover": base_col = COLOR_ORANGE_HOVER
		"blue":
			base_col = COLOR_BLUE_BG
			dark_col = COLOR_BLUE_DARK
			if state == "hover": base_col = COLOR_BLUE_HOVER
		"purple":
			base_col = COLOR_PURPLE_BG
			dark_col = COLOR_PURPLE_DARK
			if state == "hover": base_col = COLOR_PURPLE_HOVER
		"red":
			base_col = COLOR_RED_BG
			dark_col = COLOR_RED_DARK
			if state == "hover": base_col = COLOR_RED_HOVER
		_:
			base_col = Color(0.6, 0.6, 0.6)
			dark_col = Color(0.4, 0.4, 0.4)
			
	style.bg_color = base_col
	style.border_color = Color(1, 1, 1, 0.3)
	
	# Adjust margins and border bottom for 3D feeling
	if state == "pressed":
		style.border_width_bottom = 2
		style.border_color = Color(0, 0, 0, 0.3)
		style.bg_color = base_col.darkened(0.12)
		style.content_margin_top = 10
		style.content_margin_bottom = 4
	elif state == "disabled":
		style.bg_color = Color(0.45, 0.45, 0.48, 0.8)
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.3, 0.3, 0.5)
		style.content_margin_top = 7
		style.content_margin_bottom = 5
	else: # normal or hover
		style.border_width_bottom = 6
		# Draw the thick dark 3D base on bottom border
		style.border_color = dark_col
		# Set inner light outline by using draw effects or blend
		style.content_margin_top = 5
		style.content_margin_bottom = 7
		
	# Keep side margins comfortable
	style.content_margin_left = 12
	style.content_margin_right = 12
	
	_cache[key] = style
	return style

func get_card_style(type: String) -> StyleBoxFlat:
	var key = "card_%s" % type
	if _cache.has(key):
		return _cache[key]
		
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 6
	
	match type:
		"green": # Market Character Cards
			style.bg_color = Color(0.18, 0.52, 0.12, 0.95)
			style.border_color = Color(0.68, 0.85, 0.22, 1.0) # Yellow-Green border
		"blue": # Upgrade Cards
			style.bg_color = Color(0.08, 0.22, 0.45, 0.95)
			style.border_color = Color(0.2, 0.65, 0.95, 1.0) # Sky Blue border
		"yellow": # Special Highlight Cards
			style.bg_color = Color(0.72, 0.42, 0.05, 0.95)
			style.border_color = Color(1.0, 0.8, 0.2, 1.0) # Shiny Gold border
		_:
			style.bg_color = COLOR_DARK_BLUE
			style.border_color = Color(0.3, 0.4, 0.6)
			
	_cache[key] = style
	return style

func get_rarity_card_style(rarity: int) -> StyleBoxFlat:
	var key = "rarity_card_%d" % rarity
	if _cache.has(key):
		return _cache[key]
		
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 6
	
	# Common = 0 (green), Rare = 1 (blue), Epic = 2 (purple), Legendary = 3 (gold), Evolve = 4 (red)
	match rarity:
		0: # Common
			style.bg_color = Color(0.12, 0.28, 0.16, 0.95)
			style.border_color = Color(0.24, 0.76, 0.15)
		1: # Uncommon
			style.bg_color = Color(0.08, 0.22, 0.45, 0.95)
			style.border_color = Color(0.1, 0.6, 1.0)
		2: # Rare
			style.bg_color = Color(0.25, 0.12, 0.44, 0.95)
			style.border_color = Color(0.7, 0.25, 0.95)
		3, 4: # Epic / Legendary
			style.bg_color = Color(0.35, 0.22, 0.05, 0.95)
			style.border_color = Color(1.0, 0.8, 0.1) # Shimmer Gold
		_:
			style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
			style.border_color = Color(0.5, 0.5, 0.5)
			
	_cache[key] = style
	return style

func get_ribbon_style(color_type: String) -> StyleBoxFlat:
	var key = "ribbon_%s" % color_type
	if _cache.has(key):
		return _cache[key]
		
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	style.border_width_bottom = 4
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	
	match color_type:
		"orange": # Main Ribbons
			style.bg_color = Color(0.95, 0.45, 0.0)
			style.border_color = Color(0.6, 0.2, 0.0)
		"green": # Sub Ribbons
			style.bg_color = Color(0.2, 0.7, 0.15)
			style.border_color = Color(0.1, 0.4, 0.05)
		"blue":
			style.bg_color = Color(0.0, 0.5, 0.85)
			style.border_color = Color(0.0, 0.28, 0.55)
		"red":
			style.bg_color = Color(0.85, 0.15, 0.22)
			style.border_color = Color(0.5, 0.05, 0.08)
		_:
			style.bg_color = Color(0.3, 0.3, 0.3)
			style.border_color = Color(0.15, 0.15, 0.15)
			
	_cache[key] = style
	return style

func style_button(btn: Button, type: String = "blue"):
	btn.add_theme_stylebox_override("normal", get_button_style(type, "normal"))
	btn.add_theme_stylebox_override("hover", get_button_style(type, "hover"))
	btn.add_theme_stylebox_override("pressed", get_button_style(type, "pressed"))
	btn.add_theme_stylebox_override("disabled", get_button_style(type, "disabled"))
	
	# Comic-style text offsets & colors
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.8))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	btn.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.75, 0.6))
	
	# Thick outline
	btn.add_theme_constant_override("outline_size", 5)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

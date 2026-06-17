extends Label

# TapNumber script for floating tap indicators

var is_critical: bool = false
var amount: float = 0.0

func _ready():
	# Format text
	if is_critical:
		text = "TUNG!! +%s" % format_number(amount)
		modulate = Color(1.0, 0.3, 0.2, 1.0) # Vibrant Orange-Red
		add_theme_font_size_override("font_size", 32)
	else:
		text = "+%s" % format_number(amount)
		modulate = Color(1.0, 0.88, 0.2, 1.0) # Yellow-Gold
		add_theme_font_size_override("font_size", 22)
		
	# Scale punch animation for entry
	scale = Vector2.ZERO
	pivot_offset = size / 2.0
	
	var tween = create_tween()
	
	# Initial pop/scale punch
	tween.tween_property(self, "scale", Vector2.ONE * (1.5 if is_critical else 1.1), 0.1)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)\
		 .set_ease(Tween.EASE_IN_OUT)
		
	# Float upwards and fade out
	var target_y = position.y - randf_range(80.0, 140.0)
	var target_x = position.x + randf_range(-40.0, 40.0)
	
	tween.parallel().tween_property(self, "position", Vector2(target_x, target_y), 0.6)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)\
		 .set_delay(0.3)
		 
	# Free from memory
	tween.tween_callback(queue_free)

# Fast number formatter
func format_number(val: float) -> String:
	if val < 1000.0:
		return "%.0f" % val if val == int(val) else "%.1f" % val
	elif val < 1000000.0:
		return "%.2fK" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.2fM" % (val / 1000000.0)
	else:
		return "%.2fB" % (val / 1000000000.0)

extends CanvasLayer

# UnlockFX script for character evolution/unlock reveal sequence

@onready var overlay: ColorRect = $Overlay
@onready var card: PanelContainer = $Card
@onready var flash: ColorRect = $Flash
@onready var confetti_left: CPUParticles2D = $ConfettiLeft
@onready var confetti_right: CPUParticles2D = $ConfettiRight

@onready var emoji_frame: Label = $Card/VBox/EmojiFrame
@onready var name_lbl: Label = $Card/VBox/Name
@onready var stats_lbl: Label = $Card/VBox/Stats
@onready var awesome_btn: Button = $Card/VBox/AwesomeBtn

func _ready():
	awesome_btn.pressed.connect(_on_awesome_pressed)
	card.scale = Vector2.ZERO
	overlay.modulate.a = 0.0

func setup_unlock(char_id: String):
	# Fetch character data
	var char_data = GameManager.all_characters.get(char_id) as CharacterData
	if not char_data:
		return
		
	# Populate labels
	if char_id == "tung_tung_jr":
		emoji_frame.text = "🐣"
	elif char_id == "tralalero_piccolo":
		emoji_frame.text = "🦈"
	else:
		emoji_frame.text = "🐓"
		
	name_lbl.text = char_data.display_name
	stats_lbl.text = "Tốc độ sản sinh: +%s/s" % format_number(char_data.base_cps)
	
	# Start animation reveal
	_play_reveal()

func _play_reveal():
	AudioManager.play_sfx("unlock", false)
	
	# 1. Screen flash
	flash.color.a = 1.0
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)
	
	# 2. Fade in dark background overlay
	var overlay_tween = create_tween()
	overlay_tween.tween_property(overlay, "modulate:a", 1.0, 0.25)
	
	# 3. Bounce card zoom in
	var card_tween = create_tween()
	card_tween.tween_property(card, "scale", Vector2(1.15, 1.15), 0.22).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(card, "scale", Vector2(0.95, 0.95), 0.1)
	card_tween.tween_property(card, "scale", Vector2.ONE, 0.08)
	
	# 4. Fire confetti particles
	confetti_left.emitting = true
	confetti_right.emitting = true

func _on_awesome_pressed():
	AudioManager.play_sfx("ui_click")
	
	# Slide card down and fade out overlay
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2.ZERO, 0.18).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(overlay, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)

func format_number(val: float) -> String:
	if val < 1000.0:
		return "%.0f" % val if val == int(val) else "%.1f" % val
	elif val < 1000000.0:
		return "%.2fK" % (val / 1000.0)
	else:
		return "%.2fM" % (val / 1000000.0)

extends Control

# OfflinePopup handles claiming and doubling offline earnings — Cartoon 3D UI

@onready var title_label: Label = $Panel/VBox/HeaderBanner/TitleLabel
@onready var header_banner: PanelContainer = $Panel/VBox/HeaderBanner
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var claim_btn: Button = $Panel/VBox/HBox/ClaimButton
@onready var double_btn: Button = $Panel/VBox/HBox/DoubleButton

var earnings_amount: float = 0.0

func _ready():
	visible = false
	SignalBus.offline_earnings_ready.connect(_on_offline_earnings_ready)
	SignalBus.ad_reward_earned.connect(_on_ad_reward_earned)
	
	claim_btn.pressed.connect(_on_claim_pressed)
	double_btn.pressed.connect(_on_double_pressed)
	
	# Apply ribbon and button styling
	header_banner.add_theme_stylebox_override("panel", Themes.get_ribbon_style("red"))
	Themes.style_button(claim_btn, "green")
	Themes.style_button(double_btn, "orange")

func _on_offline_earnings_ready(amount: float, seconds_offline: float):
	earnings_amount = amount
	
	# Format duration
	var hours = int(seconds_offline / 3600)
	var minutes = int((int(seconds_offline) % 3600) / 60)
	var time_str = ""
	
	if hours > 0:
		time_str += "%dh " % hours
	time_str += "%dm" % minutes
	
	message_label.text = "You were offline for %s and accumulated:\n\n🪙 %s Sahur Coins!" % [time_str, format_number(earnings_amount)]
	
	# Scale punch animation for pop-up entrance
	visible = true
	$Panel.scale = Vector2.ZERO
	$Panel.pivot_offset = $Panel.size / 2.0
	var tween = create_tween()
	tween.tween_property($Panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	
	# Play orchestral hit / alert sound
	AudioManager.play_sfx("unlock")

func _on_claim_pressed():
	# Claim base reward
	GameManager.add_coins(earnings_amount)
	SaveManager.save_game()
	_close_popup()

func _on_double_pressed():
	# Trigger AdManager rewarded ad
	AdManager.show_rewarded_ad("double_offline")

func _on_ad_reward_earned(reward_type: String):
	if reward_type == "double_offline" and visible:
		# Double reward claimed
		GameManager.add_coins(earnings_amount * 2.0)
		SaveManager.save_game()
		
		# Show a floating critical-style notification or change message
		message_label.text = "Success! Doubled earnings claimed:\n\n🪙 %s Sahur Coins!" % format_number(earnings_amount * 2.0)
		claim_btn.visible = false
		double_btn.text = "Awesome!"
		double_btn.pressed.disconnect(_on_double_pressed)
		double_btn.pressed.connect(_close_popup)

func _close_popup():
	var tween = create_tween()
	tween.tween_property($Panel, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false)

func format_number(val: float) -> String:
	if val < 1000.0:
		return "%.0f" % val if val == int(val) else "%.1f" % val
	elif val < 1000000.0:
		return "%.2fK" % (val / 1000.0)
	elif val < 1000000000.0:
		return "%.2fM" % (val / 1000000.0)
	else:
		return "%.2fB" % (val / 1000000000.0)

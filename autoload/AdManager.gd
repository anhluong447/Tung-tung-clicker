extends Node

# AdManager handles native AdMob plugin wrapper & editor simulation fallback

const ADMOB_SINGLETON_NAME = "AdMob"

var admob_plugin = null
var current_reward_type: String = ""

# Simulation overlays for editor/dev
var sim_overlay: CanvasLayer = null

func _ready():
	if Engine.has_singleton(ADMOB_SINGLETON_NAME):
		admob_plugin = Engine.get_singleton(ADMOB_SINGLETON_NAME)
		print("[AdManager] Native AdMob singleton found. Initializing...")
		_initialize_native_admob()
	else:
		print("[AdManager] Native AdMob singleton NOT found. Running in simulation mode.")

func _initialize_native_admob():
	# Native AdMob configuration (assuming standard Godot AdMob plugin interface)
	admob_plugin.init(get_instance_id(), {
		"is_real": false, # Set to true in release build
		"banner_id": "ca-app-pub-3940256099942544/6300978111",
		"interstitial_id": "ca-app-pub-3940256099942544/1033173712",
		"rewarded_id": "ca-app-pub-3940256099942544/5224354917",
		"is_personalized": true,
		"max_ad_content_rating": "G"
	})
	
	# Connect callbacks from plugin
	# Note: Actual plugins may use signals or method callbacks.
	# We support standard signal patterns for popular Godot AdMob plugins
	if admob_plugin.has_signal("rewarded_ad_user_earned_reward"):
		admob_plugin.rewarded_ad_user_earned_reward.connect(_on_native_rewarded_earned)
	if admob_plugin.has_signal("rewarded_ad_failed_to_show"):
		admob_plugin.rewarded_ad_failed_to_show.connect(_on_native_ad_failed)

func load_rewarded_ad() -> void:
	if admob_plugin:
		admob_plugin.load_rewarded_ad()
	else:
		print("[AdManager Simulation] Rewarded ad preloaded.")

func show_rewarded_ad(reward_type: String) -> void:
	current_reward_type = reward_type
	print("[AdManager] Requesting rewarded ad show for: ", reward_type)
	
	if admob_plugin:
		if admob_plugin.is_rewarded_ad_loaded():
			admob_plugin.show_rewarded_ad()
		else:
			print("[AdManager] Ad not loaded. Attempting reload...")
			admob_plugin.load_rewarded_ad()
			SignalBus.ad_failed.emit("rewarded")
	else:
		# Run simulated ad watch
		_run_simulated_rewarded_ad()

func load_interstitial() -> void:
	if admob_plugin:
		admob_plugin.load_interstitial()
	else:
		print("[AdManager Simulation] Interstitial ad preloaded.")

func show_interstitial_if_ready() -> void:
	if admob_plugin:
		if admob_plugin.is_interstitial_loaded():
			admob_plugin.show_interstitial()
	else:
		print("[AdManager Simulation] Showing simulated interstitial ad...")
		_run_simulated_interstitial_ad()

# Native Callbacks
func _on_native_rewarded_earned(reward_currency: String, reward_amount: int):
	print("[AdManager] Native ad reward earned: ", reward_currency, " x", reward_amount)
	SignalBus.ad_reward_earned.emit(current_reward_type)

func _on_native_ad_failed():
	print("[AdManager] Native ad display failed.")
	SignalBus.ad_failed.emit("rewarded")

# Simulation Engine
func _run_simulated_rewarded_ad():
	_create_sim_overlay("WATCHING REWARDED AD...", 1.5, func():
		print("[AdManager Simulation] Reward earned: ", current_reward_type)
		SignalBus.ad_reward_earned.emit(current_reward_type)
	)

func _run_simulated_interstitial_ad():
	_create_sim_overlay("SPONSOR ADVERTISING", 1.0, func():
		print("[AdManager Simulation] Interstitial ad closed.")
	)

func _create_sim_overlay(title_text: String, duration: float, completion_callback: Callable):
	if sim_overlay:
		sim_overlay.queue_free()
		
	sim_overlay = CanvasLayer.new()
	sim_overlay.layer = 128 # Always draw on top of everything
	
	var rect = ColorRect.new()
	rect.color = Color(0.05, 0.05, 0.08, 0.98)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sim_overlay.add_child(rect)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rect.add_child(vbox)
	
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var status = Label.new()
	status.text = "Please wait (simulated ad)..."
	status.add_theme_font_size_override("font_size", 14)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status)
	
	get_tree().root.add_child(sim_overlay)
	
	# Close timer
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if sim_overlay:
			sim_overlay.queue_free()
			sim_overlay = null
		completion_callback.call()
	)

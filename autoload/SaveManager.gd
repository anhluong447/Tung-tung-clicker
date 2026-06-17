extends Node

# SaveManager handles JSON serialization, migration, autosaves, and mobile focus loss saves

const SAVE_PATH = "user://save_game.json"
const AUTOSAVE_INTERVAL = 30.0

var autosave_timer: Timer

func _ready():
	# Wait for GameManager to initialize before trying to load
	call_deferred("_initialize_save_system")

func _initialize_save_system():
	# Load existing game data
	var loaded_data = load_game()
	
	# Check for offline earnings
	if loaded_data.has("last_save_time"):
		var last_save_time = float(loaded_data["last_save_time"])
		var current_time = Time.get_unix_time_from_system()
		var elapsed = current_time - last_save_time
		
		if elapsed > 10.0 and GameManager.total_cps > 0:
			# Max offline limit is 8h (28800s), extended to 12h (43200s) if vault upgrade is bought
			var max_offline = 28800.0
			if GameManager.upgrades.get("offline_vault_level", 0) > 0:
				max_offline = 43200.0
				
			var base_earnings = GameManager.total_cps * 0.5 * min(elapsed, max_offline)
			if base_earnings > 0.1:
				GameManager.trigger_offline_earnings(base_earnings)
	
	# Set up autosave timer
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(save_game)
	add_child(autosave_timer)

func _notification(what):
	# Save game on close or when app loses focus (essential for mobile multitasking)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()

func save_game():
	var save_data = {
		"version": "1.0",
		"last_save_time": Time.get_unix_time_from_system(),
		"player_level": GameManager.player_level,
		"player_xp": GameManager.player_xp,
		"coins": GameManager.coins,
		"characters_in_slots": GameManager.characters_in_slots,
		"characters_unlocked": GameManager.characters_unlocked,
		"characters_bought": GameManager.characters_bought,
		
		"upgrades": {
			"tap_level": GameManager.upgrades.get("tap_level", 0),
			"auto_tap_level": GameManager.upgrades.get("auto_tap_level", 0),
			"critical_level": GameManager.upgrades.get("critical_level", 0),
			"offline_vault_level": GameManager.upgrades.get("offline_vault_level", 0)
		},
		
		"stats": {
			"total_taps": GameManager.stats.get("total_taps", 0),
			"total_merges": GameManager.stats.get("total_merges", 0),
			"total_ads_watched": GameManager.stats.get("total_ads_watched", 0)
		},
		
		"quests": {
			"tap_master": QuestManager.get_progress("tap_master") if has_node("/root/QuestManager") else 0,
			"merge_master": QuestManager.get_progress("merge_master") if has_node("/root/QuestManager") else 0,
			"coin_collector": QuestManager.get_progress("coin_collector") if has_node("/root/QuestManager") else 0,
			"claims": QuestManager.get_claims_dict() if has_node("/root/QuestManager") else {},
			"last_reset_time": QuestManager.last_reset_time if has_node("/root/QuestManager") else Time.get_unix_time_from_system()
		}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		print("[SaveManager] Error opening file for write: ", SAVE_PATH)
		return
		
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	print("[SaveManager] Game saved successfully.")

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] Save file not found, loading defaults.")
		return {}
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("[SaveManager] Error opening file for read: ", SAVE_PATH)
		return {}
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("[SaveManager] JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return {}
		
	var data = json.get_data()
	if not data is Dictionary:
		print("[SaveManager] Saved data is invalid type.")
		return {}
		
	# Apply migration / safe copy to GameManager to prevent null errors
	_apply_save_data_to_game(data)
	return data

func _apply_save_data_to_game(data: Dictionary):
	# Core metrics
	if data.has("player_level"):
		GameManager.player_level = int(data["player_level"])
	if data.has("player_xp"):
		GameManager.player_xp = float(data["player_xp"])
	if data.has("coins"):
		GameManager.coins = float(data["coins"])
		
	# Active grid slot migration (make sure size is 9)
	if data.has("characters_in_slots"):
		var slots = data["characters_in_slots"]
		if slots is Array:
			for i in range(min(slots.size(), GameManager.characters_in_slots.size())):
				GameManager.characters_in_slots[i] = slots[i] if slots[i] != null else ""
				
	# Unlocked checklist
	if data.has("characters_unlocked"):
		var unlocked = data["characters_unlocked"]
		if unlocked is Array:
			GameManager.characters_unlocked.clear()
			for char_id in unlocked:
				GameManager.characters_unlocked.append(str(char_id))
				
	# Characters Bought
	if data.has("characters_bought") and data["characters_bought"] is Dictionary:
		var bought = data["characters_bought"]
		GameManager.characters_bought.clear()
		for key in bought.keys():
			GameManager.characters_bought[key] = int(bought[key])

	# Upgrades
	if data.has("upgrades") and data["upgrades"] is Dictionary:
		var saved_upgrades = data["upgrades"]
		for key in saved_upgrades.keys():
			GameManager.upgrades[key] = int(saved_upgrades[key])
			
	# Stats
	if data.has("stats") and data["stats"] is Dictionary:
		var saved_stats = data["stats"]
		for key in saved_stats.keys():
			GameManager.stats[key] = int(saved_stats[key])
			
	# Quests
	if data.has("quests") and has_node("/root/QuestManager"):
		QuestManager.load_quest_data(data["quests"])

	# Recalculate CPS and Tap Power based on loaded upgrades
	GameManager.recalculate_cps()
	
	# Emit change signals to notify HUD/visuals
	SignalBus.coins_changed.emit(GameManager.coins)
	SignalBus.cps_changed.emit(GameManager.total_cps)
	print("[SaveManager] Load successful. Loaded coins: ", GameManager.coins)


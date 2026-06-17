extends Node

# Global Game Manager for Tung Tung Clicker

# Game State
var coins: float = 0.0
var lifetime_coins: float = 0.0
var base_tap: float = 1.0
var tap_upgrade_level: int = 0
var global_multiplier: float = 1.0
var total_cps: float = 0.0

# Player Level & XP
var player_level: int = 1
var player_xp: float = 0.0

# Talking Tom Needs/Mood metrics
var hype: float = 50.0
var chaos: float = 30.0
var brainrot: float = 80.0

# Slots (3x3 grid, size 9)
# Elements are String (character ID) or null
var characters_in_slots: Array = [null, null, null, null, null, null, null, null, null]
var characters_unlocked: Array[String] = []
var characters_bought: Dictionary = {}


# Upgrades & Boosts
var upgrades: Dictionary = {
	"tap_level": 0,
	"auto_tap_level": 0,
	"critical_level": 0,
	"offline_vault_level": 0
}
var multiplier_end_time: float = 0.0 # Unix timestamp when temporary boost ends

# Meta & Collections
var shards: Dictionary = {}
var stats: Dictionary = {
	"total_taps": 0,
	"total_merges": 0,
	"total_ads_watched": 0
}

# Resource Catalogs (Preloaded/loaded dynamically)
var all_characters: Dictionary = {} # character_id -> CharacterData
var all_upgrades: Dictionary = {}   # upgrade_id -> UpgradeData

func _ready():
	# Load all character resources from the resources directory
	_load_resources()
	
	# Start with default characters if empty (e.g. fresh game)
	_initialize_default_state()
	
	# Connect to Signal Bus events
	SignalBus.ad_reward_earned.connect(_on_ad_reward_earned)
	
	recalculate_cps()

func _process(delta: float):
	# Decay mood meters
	hype = max(hype - 3.0 * delta, 0.0)
	chaos = max(chaos - 2.5 * delta, 0.0)
	brainrot = max(brainrot - 2.0 * delta, 0.0)
	SignalBus.mood_changed.emit(hype, chaos, brainrot)

	# Calculate and apply idle/passive income
	var current_cps = total_cps
	
	# Add active boost multiplier if applicable
	var now = Time.get_unix_time_from_system()
	if multiplier_end_time > now:
		current_cps *= 2.0 # Double boost from ads
	
	# Passive auto-tap bot contribution
	var auto_tap_cps = 0.0
	if upgrades.get("auto_tap_level", 0) > 0:
		# Auto-tap bot generates 10% of tap power per level passively per second
		var tap_power = get_tap_power()
		auto_tap_cps = tap_power * (upgrades.get("auto_tap_level", 0) * 0.1)
		
	var final_tick = (current_cps + auto_tap_cps) * delta
	if final_tick > 0:
		add_coins(final_tick)

func get_xp_needed() -> float:
	return 100.0 * pow(1.35, player_level - 1)

func add_xp(amount: float):
	player_xp += amount
	var needed = get_xp_needed()
	var leveled_up = false
	while player_xp >= needed:
		player_xp -= needed
		player_level += 1
		leveled_up = true
		needed = get_xp_needed()
	SignalBus.xp_changed.emit(player_xp, needed)
	if leveled_up:
		SignalBus.player_level_up.emit(player_level)
		# Trigger toast notification for leveling up!
		SignalBus.toast_notification.emit("🆙 LEVEL UP! Bạn đã đạt Cấp %d!!" % player_level)
		SaveManager.save_game()

func _initialize_default_state():
	if characters_unlocked.is_empty():
		characters_unlocked.append("tung_tung_jr")
		# Place first character in the center slot (index 4 in 0-8)
		characters_in_slots[4] = "tung_tung_jr"

func _load_resources():
	# Define path for character resource folder
	var char_dir = "res://resources/characters/"
	var dir = DirAccess.open(char_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res = load(char_dir + file_name)
				if res is CharacterData:
					all_characters[res.id] = res
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open character resources directory.")
		
	# Setup upgrades data programmatically or through resource files
	# For simplicity, we initialize them here with default parameters
	_setup_upgrades()

func _setup_upgrades():
	# Upgrade data mapping
	all_upgrades["tap_level"] = {
		"display_name": "Tap Power",
		"description": "+0.5 tap power per level.",
		"base_cost": 50.0,
		"cost_multiplier": 1.8,
		"max_level": 50
	}
	all_upgrades["auto_tap_level"] = {
		"display_name": "Auto-Tap Bot",
		"description": "Auto-taps passively at 10% tap power/sec.",
		"base_cost": 150.0,
		"cost_multiplier": 2.0,
		"max_level": 10
	}
	all_upgrades["critical_level"] = {
		"display_name": "VIP Tapper",
		"description": "+2% Critical tap chance per level (Base 5%).",
		"base_cost": 300.0,
		"cost_multiplier": 2.5,
		"max_level": 10
	}
	all_upgrades["offline_vault_level"] = {
		"display_name": "Offline Vault",
		"description": "Extends offline earnings cap from 8h to 12h.",
		"base_cost": 500.0,
		"cost_multiplier": 3.0,
		"max_level": 1
	}

# Core Mechanics
func tap(pos: Vector2 = Vector2.ZERO):
	stats["total_taps"] += 1
	
	var tap_power = get_tap_power()
	var is_critical = false
	var coins_gained = tap_power
	
	# Critical tap calculation (base 5% + 2% per level)
	var crit_chance = 0.05 + upgrades.get("critical_level", 0) * 0.02
	if randf() < crit_chance:
		is_critical = true
		coins_gained = tap_power * 10.0
		
	add_coins(coins_gained)
	add_xp(1.0 + player_level * 0.1)
	
	# Emit signal to spawn particles & labels
	SignalBus.tap_registered.emit(pos, is_critical, coins_gained)

func get_tap_power() -> float:
	return base_tap * (1.0 + upgrades.get("tap_level", 0) * 0.5)

func add_coins(amount: float):
	coins += amount
	lifetime_coins += amount
	SignalBus.coins_changed.emit(coins)

func recalculate_cps():
	var active_cps = 0.0
	for char_id in characters_in_slots:
		if char_id and all_characters.has(char_id):
			var char_data = all_characters[char_id] as CharacterData
			active_cps += char_data.base_cps
			
	total_cps = active_cps * global_multiplier
	SignalBus.cps_changed.emit(total_cps)

# Character Management
func get_character_buy_cost(char_id: String) -> float:
	if not all_characters.has(char_id):
		return INF
	var char_data = all_characters[char_id]
	var times_bought = characters_bought.get(char_id, 0)
	return char_data.unlock_cost * pow(1.15, times_bought)

# Character Management
func unlock_character(char_id: String, cost_override: float = -1.0) -> bool:
	if not all_characters.has(char_id):
		return false
		
	var cost = cost_override if cost_override >= 0 else get_character_buy_cost(char_id)
	
	if coins < cost:
		return false
		
	# Find empty slot
	var empty_slot_idx = characters_in_slots.find(null)
	if empty_slot_idx == -1:
		# Grid is full
		return false
		
	coins -= cost
	characters_bought[char_id] = characters_bought.get(char_id, 0) + 1
	SignalBus.coins_changed.emit(coins)
	
	characters_in_slots[empty_slot_idx] = char_id
	if not characters_unlocked.has(char_id):
		characters_unlocked.append(char_id)
		
	SignalBus.character_unlocked.emit(char_id)
	add_xp(35.0)
	recalculate_cps()
	return true

func merge_slots(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or from_idx >= 9 or to_idx < 0 or to_idx >= 9 or from_idx == to_idx:
		return false
		
	var char_from = characters_in_slots[from_idx]
	var char_to = characters_in_slots[to_idx]
	
	# Can only merge if they are the exact same character and not empty
	if not char_from or char_from != char_to:
		return false
		
	var char_data = all_characters[char_from] as CharacterData
	var merge_result = char_data.merge_result_id
	
	if merge_result == "" or not all_characters.has(merge_result):
		# No higher tier available
		return false
		
	# Perform merge
	characters_in_slots[from_idx] = null
	characters_in_slots[to_idx] = merge_result
	
	stats["total_merges"] += 1
	if not characters_unlocked.has(merge_result):
		characters_unlocked.append(merge_result)
		
	SignalBus.character_merged.emit(char_from, merge_result)
	add_xp(20.0)
	recalculate_cps()
	return true

# Upgrades
func get_upgrade_cost(upgrade_id: String) -> float:
	if not all_upgrades.has(upgrade_id):
		return INF
		
	var up_data = all_upgrades[upgrade_id]
	var current_lv = upgrades.get(upgrade_id, 0)
	
	if current_lv >= up_data["max_level"]:
		return INF
		
	return up_data["base_cost"] * pow(up_data["cost_multiplier"], current_lv)

func buy_upgrade(upgrade_id: String) -> bool:
	var cost = get_upgrade_cost(upgrade_id)
	if coins < cost or cost == INF:
		return false
		
	coins -= cost
	upgrades[upgrade_id] = upgrades.get(upgrade_id, 0) + 1
	
	SignalBus.coins_changed.emit(coins)
	SignalBus.upgrade_purchased.emit(upgrade_id, upgrades[upgrade_id])
	add_xp(15.0)
	
	# Recalculate if it affects CPS (e.g. passive boosts)
	recalculate_cps()
	return true

# Ad Reward Callbacks
func _on_ad_reward_earned(reward_type: String):
	stats["total_ads_watched"] += 1
	match reward_type:
		"shop_boost":
			# x2 earnings multiplier for 10 minutes (600 seconds)
			var duration = 600.0
			var now = Time.get_unix_time_from_system()
			if multiplier_end_time > now:
				multiplier_end_time += duration # Stack duration
			else:
				multiplier_end_time = now + duration
			SignalBus.boost_activated.emit("double_earnings", duration)
		"coin_pack":
			# FREE 10,000 coins
			add_coins(10000.0)
		"unlock_assist":
			# Grant some help coins
			add_coins(1000.0)

# Offline Earnings
func trigger_offline_earnings(amount: float):
	# Called by SaveManager when the game resumes after being offline
	var elapsed = amount  # amount is already the calculated earnings
	SignalBus.offline_earnings_ready.emit(elapsed, elapsed / max(total_cps * 0.5, 0.01))

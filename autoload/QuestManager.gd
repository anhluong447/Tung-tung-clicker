extends Node

# QuestManager tracks daily quest objectives, rewards, resetting at midnight, and claims

var quests = {
	"tap_master": {
		"name": "Tap Master",
		"desc": "Tap 100 times",
		"progress": 0,
		"target": 100,
		"reward": 500.0,
		"claimed": false
	},
	"merge_master": {
		"name": "Merge Master",
		"desc": "Perform 5 slot merges",
		"progress": 0,
		"target": 5,
		"reward": 1000.0,
		"claimed": false
	},
	"coin_collector": {
		"name": "Coin Collector",
		"desc": "Reach 5,000 Coins total",
		"progress": 0,
		"target": 5000,
		"reward": 1500.0,
		"claimed": false
	}
}

var last_reset_time: float = 0.0

func _ready():
	last_reset_time = Time.get_unix_time_from_system()
	
	# Connect to SignalBus to track quest progress
	SignalBus.tap_registered.connect(_on_tap_registered)
	SignalBus.character_merged.connect(_on_character_merged)
	SignalBus.coins_changed.connect(_on_coins_changed)

func check_daily_reset():
	var now = Time.get_unix_time_from_system()
	var date_now = Time.get_datetime_dict_from_unix_time(int(now))
	var date_last = Time.get_datetime_dict_from_unix_time(int(last_reset_time))
	
	# Reset if the calendar day has changed
	if date_now["day"] != date_last["day"] or date_now["month"] != date_last["month"] or date_now["year"] != date_last["year"]:
		reset_quests()
		last_reset_time = now
		SaveManager.save_game()

func reset_quests():
	print("[QuestManager] Daily quest reset triggered.")
	for q_id in quests.keys():
		quests[q_id]["progress"] = 0
		quests[q_id]["claimed"] = false
		SignalBus.quest_progress_updated.emit(q_id, 0, quests[q_id]["target"])

func increment_progress(q_id: String, amount: int = 1):
	if not quests.has(q_id) or quests[q_id]["claimed"]:
		return
		
	var q = quests[q_id]
	var old_prog = q["progress"]
	q["progress"] = min(q["progress"] + amount, q["target"])
	
	if q["progress"] != old_prog:
		SignalBus.quest_progress_updated.emit(q_id, q["progress"], q["target"])
		
		# If completed just now
		if q["progress"] >= q["target"] and old_prog < q["target"]:
			SignalBus.quest_completed.emit(q_id)
			AudioManager.play_sfx("unlock") # Play celebration cue

func claim_quest(q_id: String) -> bool:
	if not quests.has(q_id):
		return false
		
	var q = quests[q_id]
	if q["progress"] >= q["target"] and not q["claimed"]:
		q["claimed"] = true
		GameManager.add_coins(q["reward"])
		SignalBus.quest_progress_updated.emit(q_id, q["progress"], q["target"])
		SaveManager.save_game()
		return true
		
	return false

# Signal Trackers
func _on_tap_registered(_pos: Vector2, _is_crit: bool, _gained: float):
	check_daily_reset()
	increment_progress("tap_master", 1)

func _on_character_merged(_from: String, _to: String):
	check_daily_reset()
	increment_progress("merge_master", 1)

func _on_coins_changed(new_amount: float):
	check_daily_reset()
	# Update coin collector quest progress
	var target = quests["coin_collector"]["target"]
	var progress = min(int(new_amount), target)
	
	var q = quests["coin_collector"]
	if not q["claimed"] and q["progress"] != progress:
		q["progress"] = progress
		SignalBus.quest_progress_updated.emit("coin_collector", progress, target)
		if progress >= target and q["progress"] - progress == 0:
			SignalBus.quest_completed.emit("coin_collector")

# Serialization helpers
func get_progress(q_id: String) -> int:
	return quests[q_id]["progress"] if quests.has(q_id) else 0

func get_claims_dict() -> Dictionary:
	var claims = {}
	for q_id in quests.keys():
		claims[q_id] = quests[q_id]["claimed"]
	return claims

func load_quest_data(data: Dictionary):
	if data.has("last_reset_time"):
		last_reset_time = float(data["last_reset_time"])
		
	for q_id in quests.keys():
		if data.has(q_id):
			quests[q_id]["progress"] = int(data[q_id])
		if data.has("claims") and data["claims"] is Dictionary and data["claims"].has(q_id):
			quests[q_id]["claimed"] = bool(data["claims"][q_id])
			
	check_daily_reset()
	
	# Force emit signals for UI update
	for q_id in quests.keys():
		SignalBus.quest_progress_updated.emit(q_id, quests[q_id]["progress"], quests[q_id]["target"])

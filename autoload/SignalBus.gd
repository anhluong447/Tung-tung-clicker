extends Node

# Global Signals for Tung Tung Clicker

# Currency signals
signal coins_changed(new_amount: float)
signal cps_changed(new_cps: float)

# Player action signals
signal tap_registered(position: Vector2, is_critical: bool, coins_gained: float)
signal character_unlocked(character_id: String)
signal character_merged(from_id: String, to_id: String)

# Shop & Upgrades
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal boost_activated(boost_id: String, duration: float)

# Quests
signal quest_progress_updated(quest_id: String, current_progress: int, target: int)
signal quest_completed(quest_id: String)

# Ads
signal ad_reward_earned(reward_type: String)
signal ad_failed(ad_type: String)

# Save/Offline System
signal offline_earnings_ready(amount: float, seconds_offline: float)
signal game_saved()

# My Talking Tom / Brainrot Overhaul Signals
signal player_level_up(new_level: int)
signal xp_changed(current_xp: float, max_xp: float)
signal mood_changed(hype: float, chaos: float, brainrot: float)
signal combo_triggered(combo_count: int, combo_name: String)
signal toast_notification(message: String)


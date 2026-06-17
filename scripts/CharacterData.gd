extends Resource
class_name CharacterData

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: String
@export var display_name: String
@export var rarity: Rarity = Rarity.COMMON
@export var base_cps: float = 0.0
@export var tap_bonus: float = 0.0
@export var unlock_cost: float = 100.0
@export var merge_result_id: String = ""
@export var sound_id: String = "" # ID for SFX to play (or path)
@export var description: String = ""
@export var icon_texture: Texture2D # Icon texture for HUD/Shop/Collection
@export var sprite_frames: SpriteFrames # SpriteFrames for animations (if using 2D sprites)

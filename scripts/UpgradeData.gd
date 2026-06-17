extends Resource
class_name UpgradeData

enum UpgradeType {
	TAP_POWER,
	AUTO_TAP,
	CPS_MULTIPLIER,
	CRITICAL_CHANCE,
	OFFLINE_VAULT
}

@export var id: String
@export var display_name: String
@export var description: String
@export var upgrade_type: UpgradeType = UpgradeType.TAP_POWER
@export var base_cost: float = 50.0
@export var cost_multiplier: float = 1.5
@export var max_level: int = 10
@export var icon: Texture2D

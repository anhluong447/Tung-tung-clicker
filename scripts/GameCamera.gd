extends Camera3D

# GameCamera script to handle screen shake effects in 3D

var shake_intensity: float = 0.0
var shake_decay: float = 8.0

func _ready():
	SignalBus.tap_registered.connect(_on_tap_registered)

func _process(delta):
	if shake_intensity > 0.001:
		h_offset = randf_range(-shake_intensity, shake_intensity)
		v_offset = randf_range(-shake_intensity, shake_intensity)
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
	else:
		shake_intensity = 0.0
		h_offset = 0.0
		v_offset = 0.0

func shake(intensity: float):
	shake_intensity = intensity

func _on_tap_registered(_pos: Vector2, is_critical: bool, _coins: float):
	if is_critical:
		shake(0.25)
	else:
		# Very subtle tap camera feedback
		shake(0.02)

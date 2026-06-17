extends CPUParticles2D

# CoinParticle script to trigger and cleanup 2D particles

func _ready():
	emitting = true
	# Auto delete after lifetime (plus a small safety margin)
	get_tree().create_timer(lifetime + 0.1).timeout.connect(queue_free)

extends Node

# AudioManager for Tung Tung Clicker
# Handles BGM and SFX pooling with pitch variation
# Procedural synth fallback produces soft, kid-friendly sounds

const SFX_DIR = "res://assets/audio/sfx/"
const BGM_DIR = "res://assets/audio/bgm/"

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 8

# Sound cache to avoid loading from disk repeatedly
var sfx_cache: Dictionary = {}
var bgm_cache: Dictionary = {}

# Master volume multiplier for synth sounds (0.0 - 1.0)
const SYNTH_VOLUME: float = 0.40

func _ready():
	# Create BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	
	# Create SFX player pool
	for i in range(max_sfx_channels):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.volume_db = -6.0  # Slightly quieter globally
		add_child(p)
		sfx_players.append(p)
		
	# Preload standard sounds if they exist
	_preload_sounds()

func _preload_sounds():
	# We list common sound names. If the files exist, we cache them.
	var common_sfx = [
		"tap_tung", "tap_tralalero", "tap_boing", "tap_cash", "tap_sahur", "tap_fart",
		"unlock", "merge", "ui_click"
	]
	
	for sfx in common_sfx:
		var path = SFX_DIR + sfx + ".wav"
		if ResourceLoader.exists(path):
			sfx_cache[sfx] = load(path)
		else:
			# Try ogg or mp3 as fallback
			path = SFX_DIR + sfx + ".ogg"
			if ResourceLoader.exists(path):
				sfx_cache[sfx] = load(path)

func play_sfx(sfx_id: String, vary_pitch: bool = true):
	var stream: AudioStream = null
	
	if sfx_cache.has(sfx_id):
		stream = sfx_cache[sfx_id]
	else:
		# Try to load on the fly
		var path_wav = SFX_DIR + sfx_id + ".wav"
		var path_ogg = SFX_DIR + sfx_id + ".ogg"
		if ResourceLoader.exists(path_wav):
			stream = load(path_wav)
			sfx_cache[sfx_id] = stream
		elif ResourceLoader.exists(path_ogg):
			stream = load(path_ogg)
			sfx_cache[sfx_id] = stream
		else:
			# Procedural synth fallback!
			stream = _generate_synth_sfx(sfx_id)
			sfx_cache[sfx_id] = stream
			
	if not stream:
		return
		
	# Find available player in pool
	var player = _get_available_sfx_player()
	player.stream = stream
	
	if vary_pitch:
		player.pitch_scale = randf_range(0.92, 1.08)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func _generate_synth_sfx(type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 16000  # Lower sample rate = warmer, softer tone
	stream.format = AudioStreamWAV.FORMAT_16_BITS  # 16-bit for smoother audio
	stream.stereo = false
	
	# Determine duration based on sound type
	var duration = 0.10
	if type == "merge":
		duration = 0.30
	elif type == "unlock":
		duration = 0.28
	elif type == "ui_click":
		duration = 0.04
		
	var num_samples = int(16000 * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)  # 2 bytes per sample for 16-bit
	
	for i in range(num_samples):
		var t = float(i) / 16000.0
		var val = 0.0
		
		# ===== SOFT SYNTHESIS FORMULAS =====
		if type == "tap_cash":
			# Gentle marimba-like ping: moderate freq with smooth decay
			var freq = 580.0 - (t * 300.0)
			val = sin(t * freq * TAU) * exp(-t * 12.0)
			# Add subtle harmonic warmth
			val += sin(t * freq * 2.0 * TAU) * 0.15 * exp(-t * 16.0)
			
		elif type == "merge":
			# Soft whoosh + rising chime (satisfying, not harsh)
			var freq = 200.0 + (t * 250.0)
			var noise = randf_range(-1.0, 1.0) * 0.08  # Very subtle noise
			val = sin(t * freq * TAU) * 0.6 * exp(-t * 6.0)
			val += sin(t * freq * 1.5 * TAU) * 0.25 * exp(-t * 8.0)  # Harmonic
			val += noise * exp(-t * 10.0)
			
		elif type == "unlock":
			# Playful ascending xylophone arpeggio: C5-E5-G5
			var freq = 523.0  # C5
			if t > 0.07: freq = 659.0  # E5
			if t > 0.14: freq = 784.0  # G5
			val = sin(t * freq * TAU) * exp(-t * 5.0)
			# Soft bell overtone
			val += sin(t * freq * 3.0 * TAU) * 0.08 * exp(-t * 12.0)
			
		elif type == "ui_click":
			# Very short, soft pop — like a bubble
			var freq = 380.0
			val = sin(t * freq * TAU) * exp(-t * 80.0)
			
		elif type.begins_with("tap_"):
			# Soft bouncy "bloop" — low frequency, quick decay
			var freq = 220.0 - (t * 400.0)
			if freq < 100.0: freq = 100.0
			val = sin(t * freq * TAU) * exp(-t * 18.0)
			# Subtle second harmonic for warmth
			val += sin(t * freq * 2.0 * TAU) * 0.12 * exp(-t * 25.0)
			
		else:
			# Default gentle beep
			var freq = 440.0
			val = sin(t * freq * TAU) * exp(-t * 20.0)
		
		# Apply master volume reduction
		val *= SYNTH_VOLUME
		
		# Convert float (-1.0 to 1.0) to signed 16-bit integer (-32768 to 32767)
		var sample_int = int(clampf(val, -1.0, 1.0) * 32767.0)
		
		# Store as little-endian 16-bit
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
		
	stream.data = data
	return stream

func play_bgm(bgm_id: String):
	var stream: AudioStream = null
	
	if bgm_cache.has(bgm_id):
		stream = bgm_cache[bgm_id]
	else:
		var path = BGM_DIR + bgm_id + ".ogg"
		if ResourceLoader.exists(path):
			stream = load(path)
			bgm_cache[bgm_id] = stream
			
	if not stream:
		print("[AudioManager] BGM not found: res://assets/audio/bgm/%s.ogg" % bgm_id)
		return
		
	if bgm_player.stream == stream and bgm_player.playing:
		return # Already playing
		
	bgm_player.stream = stream
	bgm_player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Search for a player that is not currently playing
	for p in sfx_players:
		if not p.playing:
			return p
	# If all are playing, override the first one (oldest)
	return sfx_players[0]

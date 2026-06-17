extends Node

# AudioManager for Tung Tung Clicker
# Handles BGM and SFX pooling with pitch variation
# Procedural synth fallback produces soft, kid-friendly sounds and dynamic BGM cross-fades

const SFX_DIR = "res://assets/audio/sfx/"

var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 8

# Two channels for BGM Cross-fading
var bgm_chill_player: AudioStreamPlayer
var bgm_upbeat_player: AudioStreamPlayer

var sfx_cache: Dictionary = {}
const SYNTH_VOLUME: float = 0.35

func _ready():
	# Create BGM players
	bgm_chill_player = AudioStreamPlayer.new()
	bgm_chill_player.name = "BGMChillPlayer"
	bgm_chill_player.volume_db = -6.0
	bgm_chill_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_chill_player)
	
	bgm_upbeat_player = AudioStreamPlayer.new()
	bgm_upbeat_player.name = "BGMUpbeatPlayer"
	bgm_upbeat_player.volume_db = -80.0
	bgm_upbeat_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_upbeat_player)
	
	# Create SFX player pool
	for i in range(max_sfx_channels):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.volume_db = -6.0
		add_child(p)
		sfx_players.append(p)
		
	# Generate and start procedural BGMs
	_start_procedural_bgm()
	
	# Preload standard sounds
	_preload_sounds()

func _preload_sounds():
	var common_sfx = [
		"tap_tung", "tap_tralalero", "tap_boing", "tap_cash", "tap_sahur", "tap_fart",
		"unlock", "merge", "ui_click"
	]
	
	for sfx in common_sfx:
		var path = SFX_DIR + sfx + ".wav"
		if ResourceLoader.exists(path):
			sfx_cache[sfx] = load(path)
		else:
			path = SFX_DIR + sfx + ".ogg"
			if ResourceLoader.exists(path):
				sfx_cache[sfx] = load(path)

func _start_procedural_bgm():
	# Procedurally synthesize two looping tracks
	var chill_stream = _generate_procedural_bgm_stream("chill")
	var upbeat_stream = _generate_procedural_bgm_stream("upbeat")
	
	bgm_chill_player.stream = chill_stream
	bgm_upbeat_player.stream = upbeat_stream
	
	bgm_chill_player.play()
	bgm_upbeat_player.play()

func _generate_procedural_bgm_stream(type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 11025
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	
	var duration = 2.0 if type == "chill" else 1.0
	var num_samples = int(11025 * duration)
	
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / 11025.0
		var val = 0.0
		
		if type == "chill":
			# Arpeggio loop (C4, E4, G4, C5)
			# Every 0.5s plays a new note
			var note_idx = int(t / 0.5) % 4
			var frequencies = [261.63, 329.63, 392.00, 523.25]
			var freq = frequencies[note_idx]
			
			# Note decay envelope
			var note_t = fmod(t, 0.5)
			var env = exp(-note_t * 6.0)
			
			# Soft sine tone + third harmonic
			val = sin(note_t * freq * TAU) * env
			val += sin(note_t * freq * 3.0 * TAU) * 0.12 * env
			
		elif type == "upbeat":
			# Fast bassline loop (C3, G3, A3, F3)
			# Every 0.25s plays a note
			var note_idx = int(t / 0.25) % 4
			var frequencies = [130.81, 196.00, 220.00, 174.61]
			var freq = frequencies[note_idx]
			
			var note_t = fmod(t, 0.25)
			var env = exp(-note_t * 8.0)
			
			# Triangle-like sweep (more upbeat retro pop)
			var tri_phase = fmod(note_t * freq, 1.0)
			var tri_val = 0.0
			if tri_phase < 0.25: tri_val = tri_phase * 4.0
			elif tri_phase < 0.75: tri_val = 2.0 - tri_phase * 4.0
			else: tri_val = tri_phase * 4.0 - 4.0
			
			val = tri_val * env
			
		# Reduce volume to keep BGM background-friendly
		val *= 0.12
		
		var sample_int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
		
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	
	return stream

func set_bgm_state(state: String):
	var tween = create_tween()
	if state == "upbeat":
		# Crossfade to Upbeat
		tween.tween_property(bgm_chill_player, "volume_db", -80.0, 1.2)
		tween.parallel().tween_property(bgm_upbeat_player, "volume_db", -6.0, 1.2)
	else:
		# Crossfade to Chill
		tween.tween_property(bgm_chill_player, "volume_db", -6.0, 1.2)
		tween.parallel().tween_property(bgm_upbeat_player, "volume_db", -80.0, 1.2)

func play_sfx(sfx_id: String, vary_pitch: bool = true):
	var stream: AudioStream = null
	
	if sfx_cache.has(sfx_id):
		stream = sfx_cache[sfx_id]
	else:
		var path_wav = SFX_DIR + sfx_id + ".wav"
		var path_ogg = SFX_DIR + sfx_id + ".ogg"
		if ResourceLoader.exists(path_wav):
			stream = load(path_wav)
			sfx_cache[sfx_id] = stream
		elif ResourceLoader.exists(path_ogg):
			stream = load(path_ogg)
			sfx_cache[sfx_id] = stream
		else:
			stream = _generate_synth_sfx(sfx_id)
			sfx_cache[sfx_id] = stream
			
	if not stream:
		return
		
	var player = _get_available_sfx_player()
	player.stream = stream
	
	if vary_pitch:
		player.pitch_scale = randf_range(0.90, 1.10)
	else:
		player.pitch_scale = 1.0
		
	player.play()

func _generate_synth_sfx(type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.mix_rate = 16000
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	
	var duration = 0.12
	if type == "merge":
		duration = 0.35
	elif type == "unlock":
		duration = 0.30
	elif type == "ui_click":
		duration = 0.05
		
	var num_samples = int(16000 * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / 16000.0
		var val = 0.0
		
		if type == "tap_cash":
			# Marimba chime
			var freq = 600.0 - (t * 280.0)
			val = sin(t * freq * TAU) * exp(-t * 15.0)
			val += sin(t * freq * 2.0 * TAU) * 0.15 * exp(-t * 20.0)
		elif type == "tap_fart":
			# Buzzy low sweep fart sound
			var freq = 120.0 - (t * 60.0)
			val = sin(t * freq * TAU) * exp(-t * 8.0)
			# Add buzz noise
			val += randf_range(-1.0, 1.0) * 0.25 * exp(-t * 10.0)
		elif type == "tap_boing":
			# Low-to-high springy sweep
			var freq = 150.0 + (t * 400.0)
			val = sin(t * freq * TAU) * exp(-t * 6.0)
		elif type == "merge":
			var freq = 200.0 + (t * 300.0)
			val = sin(t * freq * TAU) * 0.5 * exp(-t * 6.0)
			val += sin(t * freq * 1.5 * TAU) * 0.25 * exp(-t * 8.0)
		elif type == "unlock":
			# Playful ascending xylophone
			var freq = 523.0
			if t > 0.08: freq = 659.0
			if t > 0.16: freq = 784.0
			val = sin(t * freq * TAU) * exp(-t * 5.0)
			val += sin(t * freq * 3.0 * TAU) * 0.1 * exp(-t * 10.0)
		elif type == "ui_click":
			var freq = 400.0
			val = sin(t * freq * TAU) * exp(-t * 70.0)
		elif type.begins_with("tap_"):
			# Bouncy pop
			var freq = 220.0 - (t * 400.0)
			if freq < 100.0: freq = 100.0
			val = sin(t * freq * TAU) * exp(-t * 18.0)
		else:
			var freq = 440.0
			val = sin(t * freq * TAU) * exp(-t * 20.0)
		
		val *= SYNTH_VOLUME
		var sample_int = int(clampf(val, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF
		
	stream.data = data
	return stream

func _get_available_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

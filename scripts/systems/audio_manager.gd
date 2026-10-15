class_name AudioManager
extends Node

## Procedural Sound Manager for Last Stand: Signal Break
## Synthesizes sci-fi audio effects in memory using AudioStreamWAV.

static var instance: AudioManager

var _players: Array[AudioStreamPlayer] = []
var _sfx_pulse: AudioStreamWAV
var _sfx_stun: AudioStreamWAV
var _sfx_collect: AudioStreamWAV
var _sfx_hit: AudioStreamWAV
var _sfx_low_energy: AudioStreamWAV
var _sfx_victory: AudioStreamWAV
var _sfx_game_over: AudioStreamWAV

const SAMPLE_RATE := 22050


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	# Create pool of AudioStreamPlayers for simultaneous SFX playback
	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		
	_generate_all_sfx()


func _generate_all_sfx() -> void:
	_sfx_pulse = _build_pulse_sfx()
	_sfx_stun = _build_stun_sfx()
	_sfx_collect = _build_collect_sfx()
	_sfx_hit = _build_hit_sfx()
	_sfx_low_energy = _build_low_energy_sfx()
	_sfx_victory = _build_victory_sfx()
	_sfx_game_over = _build_game_over_sfx()


func _play(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if not stream:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# If all busy, reuse the first player
	_players[0].stream = stream
	_players[0].volume_db = volume_db
	_players[0].play()


func play_pulse() -> void:
	_play(_sfx_pulse, 1.0)


func play_stun() -> void:
	_play(_sfx_stun, -2.0)


func play_collect() -> void:
	_play(_sfx_collect, -1.0)


func play_hit() -> void:
	_play(_sfx_hit, 2.0)


func play_low_energy() -> void:
	_play(_sfx_low_energy, -3.0)


func play_victory() -> void:
	_play(_sfx_victory, 2.0)


func play_game_over() -> void:
	_play(_sfx_game_over, 1.0)


# --- SYNTHESIS GENERATORS ---

func _make_wav(duration: float, gen_func: Callable) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var progress := float(i) / float(num_samples)
		var val: float = gen_func.call(t, progress)
		var int_val := int(clampf(val, -1.0, 1.0) * 32767.0)
		if int_val < 0:
			int_val += 65536
		byte_data[i * 2] = int_val & 0xFF
		byte_data[i * 2 + 1] = (int_val >> 8) & 0xFF
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = byte_data
	return wav


func _build_pulse_sfx() -> AudioStreamWAV:
	# Resonant low-to-high frequency sweep (120Hz -> 650Hz) with sci-fi harmonics
	return _make_wav(0.35, func(t: float, p: float) -> float:
		var freq := lerpf(140.0, 680.0, p * p)
		var osc := sin(t * freq * TAU)
		var sub := sin(t * (freq * 0.5) * TAU) * 0.4
		var env := sin(p * PI) * exp(-p * 1.5)
		return (osc + sub) * env * 0.8
	)


func _build_stun_sfx() -> AudioStreamWAV:
	# Electrical discharge buzz (frequency modulation and noise)
	return _make_wav(0.28, func(t: float, p: float) -> float:
		var mod := sin(t * 180.0 * TAU) * 80.0
		var base := sin(t * (420.0 + mod) * TAU)
		var noise := (randf() * 2.0 - 1.0) * 0.3
		var env := exp(-p * 5.0)
		return (base * 0.7 + noise) * env * 0.75
	)


func _build_collect_sfx() -> AudioStreamWAV:
	# Bright two-tone crystal chime (587Hz -> 880Hz, D5 -> A5)
	return _make_wav(0.25, func(t: float, p: float) -> float:
		var freq := 587.33 if p < 0.45 else 880.0
		var env := exp(-(fmod(p, 0.45) if p < 0.45 else (p - 0.45)) * 14.0)
		var osc := sin(t * freq * TAU) + sin(t * freq * 2.0 * TAU) * 0.25
		return osc * env * 0.65
	)


func _build_hit_sfx() -> AudioStreamWAV:
	# Low crunch impact with descending thud
	return _make_wav(0.3, func(t: float, p: float) -> float:
		var freq := lerpf(180.0, 45.0, p)
		var thud := sin(t * freq * TAU)
		var crunch := (randf() * 2.0 - 1.0) * 0.5 * exp(-p * 8.0)
		var env := exp(-p * 6.0)
		return (thud * 0.8 + crunch) * env * 0.9
	)


func _build_low_energy_sfx() -> AudioStreamWAV:
	# Dual dull warning beep
	return _make_wav(0.18, func(t: float, p: float) -> float:
		var tone := sin(t * 220.0 * TAU)
		var pulse_window := sin(p * PI * 2.0)
		var env := 1.0 if pulse_window > 0.1 else 0.0
		return tone * env * 0.5
	)


func _build_victory_sfx() -> AudioStreamWAV:
	# Uplink success fanfare (ascending major arpeggio C5 -> E5 -> G5 -> C6)
	return _make_wav(0.65, func(t: float, p: float) -> float:
		var notes := [523.25, 659.25, 783.99, 1046.50]
		var idx := clampi(int(p * 4.0), 0, 3)
		var freq: float = notes[idx]
		var segment_p := fmod(p * 4.0, 1.0)
		var env := exp(-segment_p * 4.0)
		var osc := sin(t * freq * TAU) + sin(t * freq * 2.0 * TAU) * 0.2
		return osc * env * 0.7
	)


func _build_game_over_sfx() -> AudioStreamWAV:
	# Low descending signal lost drone
	return _make_wav(0.7, func(t: float, p: float) -> float:
		var freq := lerpf(320.0, 75.0, p * p)
		var osc := sin(t * freq * TAU) + sin(t * (freq * 0.5) * TAU) * 0.4
		var env := exp(-p * 2.5)
		return osc * env * 0.8
	)

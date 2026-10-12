class_name SoundManager
extends Node

## Gerenciador de Áudio Procedural Sci-Fi & Efeitos Sonoros para Neon Void.
## Sintetiza ondas PCM diretamente na memória em AudioStreamWAV (zero dependências externas).

static var instance: SoundManager

var _laser_stream: AudioStreamWAV
var _pulse_stream: AudioStreamWAV
var _plasma_stream: AudioStreamWAV
var _click_stream: AudioStreamWAV
var _spark_stream: AudioStreamWAV
var _boss_stream: AudioStreamWAV

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS: int = 12

var sfx_enabled: bool = true

func _init() -> void:
	instance = self
	_generate_audio_streams()

func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func _generate_audio_streams() -> void:
	_laser_stream = _synth_sweep(880.0, 220.0, 0.10, 0.35)
	_pulse_stream = _synth_sweep(130.0, 42.0, 0.35, 0.50)
	_plasma_stream = _synth_noise_burst(0.18, 0.40)
	_spark_stream = _synth_sweep(1600.0, 600.0, 0.06, 0.25)
	_click_stream = _synth_blip(1200.0, 0.03, 0.20)
	_boss_stream = _synth_sweep(240.0, 80.0, 0.60, 0.60)

func play_sfx(sfx_name: String, pitch_variance: float = 0.08) -> void:
	if not sfx_enabled:
		return
	var stream: AudioStreamWAV = null
	match sfx_name:
		"laser": stream = _laser_stream
		"pulse": stream = _pulse_stream
		"plasma": stream = _plasma_stream
		"spark": stream = _spark_stream
		"click": stream = _click_stream
		"boss": stream = _boss_stream
	if stream == null:
		return

	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
			p.play()
			return
	# Se todos ocupados, reusa o primeiro
	if _players.size() > 0:
		var p: AudioStreamPlayer = _players[0]
		p.stream = stream
		p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
		p.play()

# --- Geradores Procedurais de Áudio PCM (22050 Hz, 8-bit ou 16-bit) ---

static func _synth_sweep(freq_start: float, freq_end: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var freq: float = lerp(freq_start, freq_end, t)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
		var env: float = 1.0 - t
		var sample: float = sin(phase) * env * volume
		var b: int = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
		data[i] = b

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

static func _synth_noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		var env: float = (1.0 - t) * (1.0 - t)
		var noise: float = randf_range(-1.0, 1.0) * env * volume
		var b: int = int(clampf((noise + 1.0) * 127.5, 0.0, 255.0))
		data[i] = b

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

static func _synth_blip(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t: float = float(i) / float(num_samples)
		phase += (freq * TAU) / float(sample_rate)
		if phase > TAU:
			phase -= TAU
		var env: float = 1.0 - t
		var sample: float = sin(phase) * env * volume
		var b: int = int(clampf((sample + 1.0) * 127.5, 0.0, 255.0))
		data[i] = b

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

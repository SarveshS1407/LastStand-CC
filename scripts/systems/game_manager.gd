class_name GameManager
extends Node

## Core Game Manager for Last Stand: Signal Break.
## Coordinates game states, waves, scoring, screen shake, objectives, audio, and match restarts.

enum GameState { BRIEFING, PLAYING, GAME_OVER, VICTORY }

static var instance: GameManager

const RECORDS_PATH := "user://records.cfg"

@export var total_cores_needed: int = 12
@export var passive_score_interval: float = 1.0

var current_state: GameState = GameState.BRIEFING
var score: int = 0
var high_score: int = 0
var collected_cores: int = 0
var survival_time: float = 0.0
var current_wave: int = 1

var _score_timer: float = 0.0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0

var _player: Player
var _hud: Node
var _camera: Camera2D


func _enter_tree() -> void:
	instance = self
	add_to_group("game_manager")


func _ready() -> void:
	load_records()
	call_deferred("_initialize_game")


func _initialize_game() -> void:
	_find_references()
	_connect_signals()
	
	if _hud:
		_hud.show_briefing()
		_hud.update_cores(collected_cores, total_cores_needed)
		_hud.update_score(score)
		_hud.update_high_score(high_score)
		_hud.update_timer(survival_time)
		_hud.update_wave(1, "Infiltration")


func _find_references() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Player:
		_player = players[0] as Player
		
	var huds := get_tree().get_nodes_in_group("hud")
	if not huds.is_empty():
		_hud = huds[0]
	elif get_parent().has_node("HUD"):
		_hud = get_parent().get_node("HUD")
		
	var cameras := get_tree().get_nodes_in_group("main_camera")
	if not cameras.is_empty() and cameras[0] is Camera2D:
		_camera = cameras[0] as Camera2D
	elif get_parent().has_node("Camera2D"):
		_camera = get_parent().get_node("Camera2D") as Camera2D


func _connect_signals() -> void:
	if _player:
		_player.health_changed.connect(_on_player_health_changed)
		_player.energy_changed.connect(_on_player_energy_changed)
		_player.pulse_triggered.connect(_on_player_pulse_triggered)
		_player.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart_game()
		return
		
	_process_screen_shake(delta)
	
	match current_state:
		GameState.BRIEFING:
			_process_briefing()
		GameState.PLAYING:
			_process_playing(delta)
		GameState.GAME_OVER, GameState.VICTORY:
			if Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_accept"):
				restart_game()


func _process_screen_shake(delta: float) -> void:
	if not _camera:
		return
		
	var sm = get_node_or_null("/root/SettingsManager")
	var shake_enabled = sm.screen_shake_enabled if sm else true
	
	if _shake_timer > 0.0 and shake_enabled:
		_shake_timer -= delta
		var offset := Vector2(
			(randf() * 2.0 - 1.0) * _shake_intensity,
			(randf() * 2.0 - 1.0) * _shake_intensity
		)
		_camera.offset = offset
	else:
		_camera.offset = Vector2.ZERO


func trigger_screen_shake(duration: float, intensity: float) -> void:
	_shake_timer = duration
	_shake_intensity = intensity


func _process_briefing() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var pulse_pressed := Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_accept")
	
	if dir != Vector2.ZERO or pulse_pressed:
		start_match()


func start_match() -> void:
	current_state = GameState.PLAYING
	if _hud:
		_hud.hide_briefing()


func _process_playing(delta: float) -> void:
	survival_time += delta
	_score_timer += delta
	
	if _score_timer >= passive_score_interval:
		_score_timer -= passive_score_interval
		score += 5
		if _hud:
			_hud.update_score(score)
			
	if _hud:
		_hud.update_timer(survival_time)
		if _player:
			_hud.update_energy(_player.current_energy, _player.max_energy, _player.cooldown_timer > 0.0, _player.has_overcharge)


func register_core_collected(_pos: Vector2, reward_points: int) -> void:
	if current_state != GameState.PLAYING and current_state != GameState.BRIEFING:
		return
		
	if current_state == GameState.BRIEFING:
		start_match()
		
	collected_cores += 1
	score += reward_points
	
	_check_wave_progression()
	
	if _hud:
		_hud.update_cores(collected_cores, total_cores_needed)
		_hud.update_score(score)
		
	if collected_cores >= total_cores_needed:
		trigger_victory()


func _check_wave_progression() -> void:
	var new_wave := 1
	var title := "Infiltration"
	
	if collected_cores >= 9:
		new_wave = 4
		title = "Extraction Override"
	elif collected_cores >= 6:
		new_wave = 3
		title = "Sector Lockdown"
	elif collected_cores >= 3:
		new_wave = 2
		title = "Defense Grid Alert"
		
	if new_wave != current_wave:
		current_wave = new_wave
		score += 200 # Wave completion bonus
		if _hud:
			_hud.update_wave(current_wave, title)
			_hud.show_combo("THREAT LEVEL ESCALATED!")
		trigger_screen_shake(0.3, 8.0)


func register_drone_stunned(hit_count: int = 1) -> void:
	if current_state != GameState.PLAYING:
		return
		
	var pts := 25
	if hit_count >= 2:
		var combo_bonus := 50 * hit_count
		pts += combo_bonus
		if _hud:
			_hud.show_combo("MULTI-DISRUPT x%d! +%d" % [hit_count, pts])
	score += pts
	if _hud:
		_hud.update_score(score)


func register_shield_pickup(reward_points: int) -> void:
	score += reward_points
	if _hud:
		_hud.update_score(score)
		_hud.show_combo("SHIELD RESTORED! +%d" % reward_points)


func register_overcharge_pickup(reward_points: int) -> void:
	score += reward_points
	if _hud:
		_hud.update_score(score)
		_hud.show_combo("⚡ EMP OVERCHARGE READY! +%d" % reward_points)
	trigger_screen_shake(0.25, 7.0)


func trigger_victory() -> void:
	current_state = GameState.VICTORY
	var time_bonus := maxi(0, int(360.0 - survival_time) * 6)
	score += time_bonus
	
	save_records()
	
	if _hud:
		_hud.show_victory(score, high_score, collected_cores, survival_time)
		
	if AudioManager.instance:
		AudioManager.instance.play_victory()


func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	save_records()
	if _hud:
		_hud.show_game_over(score, high_score, collected_cores, total_cores_needed, survival_time)


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if _hud:
		_hud.update_health(current_hp, max_hp)


func _on_player_energy_changed(current_ep: float, max_ep: float) -> void:
	if _hud and _player:
		_hud.update_energy(current_ep, max_ep, _player.cooldown_timer > 0.0, _player.has_overcharge)


func _on_player_pulse_triggered(success: bool, _reason: String) -> void:
	if success:
		score += 10
		if _hud:
			_hud.update_score(score)


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func load_records() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RECORDS_PATH) == OK:
		high_score = cfg.get_value("records", "high_score", 0)


func save_records() -> void:
	if score > high_score:
		high_score = score
		var cfg := ConfigFile.new()
		cfg.set_value("records", "high_score", high_score)
		cfg.save(RECORDS_PATH)

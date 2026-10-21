class_name GameManager
extends Node

## Core Game Manager for Last Stand: Signal Break.
## Coordinates 20-level campaign progression, dynamic drone & pickup generation,
## threat waves, mid-level reinforcements, scoring, screen shake, audio, and match restarts.

enum GameState { BRIEFING, PLAYING, GAME_OVER, VICTORY }

static var instance: GameManager

const RECORDS_PATH := "user://records.cfg"

const CORE_SPAWN_POINTS: Array[Vector2] = [
	Vector2(220, 150), Vector2(800, 130), Vector2(1380, 150),
	Vector2(180, 450), Vector2(530, 310), Vector2(1070, 310),
	Vector2(1420, 450), Vector2(530, 590), Vector2(1070, 590),
	Vector2(220, 750), Vector2(800, 770), Vector2(1380, 750),
	Vector2(380, 450), Vector2(1220, 450), Vector2(800, 320),
	Vector2(800, 580), Vector2(650, 220), Vector2(950, 220)
]

const SHIELD_SPAWN_POINTS: Array[Vector2] = [
	Vector2(180, 280), Vector2(1420, 620), Vector2(180, 620), Vector2(1420, 280)
]

const OVERCHARGE_SPAWN_POINTS: Array[Vector2] = [
	Vector2(800, 450), Vector2(650, 680), Vector2(950, 680), Vector2(800, 220)
]

@export var total_cores_needed: int = 12
@export var passive_score_interval: float = 1.0

var current_state: GameState = GameState.BRIEFING
var score: int = 0
var high_score: int = 0
var collected_cores: int = 0
var survival_time: float = 0.0
var current_wave: int = 1
var current_level_id: int = 1
var level_data: Dictionary = {}

var _score_timer: float = 0.0
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _pending_reinforcements: Array = []

var _player: Player
var _hud: Node
var _camera: Camera2D
var _enemies_container: Node2D
var _collectibles_container: Node2D

var _drone_scene: PackedScene = preload("res://scenes/enemy/enemy.tscn")
var _fragment_scene: PackedScene = preload("res://scenes/collectible/fragment.tscn")
var _shield_scene: PackedScene = preload("res://scenes/collectible/shield_pickup.tscn")
var _overcharge_scene: PackedScene = preload("res://scenes/collectible/overcharge_pickup.tscn")


func _enter_tree() -> void:
	instance = self
	add_to_group("game_manager")


func _ready() -> void:
	load_records()
	call_deferred("_initialize_game")


func _initialize_game() -> void:
	_find_references()
	_connect_signals()
	_setup_level_data()
	_spawn_level_elements()
	
	if _hud:
		_hud.setup_briefing(current_level_id, level_data)
		_hud.show_briefing()
		_hud.update_level_badge(current_level_id, level_data.get("name", "Mission %02d" % current_level_id))
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

	var root := get_parent()
	if root.has_node("Enemies"):
		_enemies_container = root.get_node("Enemies") as Node2D
	if root.has_node("Collectibles"):
		_collectibles_container = root.get_node("Collectibles") as Node2D


func _connect_signals() -> void:
	if _player:
		_player.health_changed.connect(_on_player_health_changed)
		_player.energy_changed.connect(_on_player_energy_changed)
		_player.pulse_triggered.connect(_on_player_pulse_triggered)
		_player.player_died.connect(_on_player_died)


func _get_cm() -> Node:
	return get_node_or_null("/root/CampaignManager")


func _setup_level_data() -> void:
	var cm := _get_cm()
	if cm:
		current_level_id = cm.current_level_id
		level_data = cm.get_level_data(current_level_id)
	else:
		current_level_id = 1
		level_data = {
			"name": "Breach Point",
			"stage": 1,
			"stage_title": "Stage 1: The Beginning",
			"objective": "Infiltrate perimeter and secure 3 Energy Cores.",
			"cores_needed": 3,
			"par_time": 40.0,
			"shield_kits": 1,
			"overcharge_cells": 0,
			"drones": [
				{ "type": 0, "pos": Vector2(800, 300), "axis": Vector2(1, 0), "dist": 220.0 }
			],
			"reinforcements": []
		}
		
	total_cores_needed = level_data.get("cores_needed", 12)
	_pending_reinforcements = level_data.get("reinforcements", []).duplicate()


func _spawn_level_elements() -> void:
	# Clear existing children in containers
	if _enemies_container:
		for child in _enemies_container.get_children():
			child.queue_free()
			
	if _collectibles_container:
		for child in _collectibles_container.get_children():
			child.queue_free()

	# Spawn Drones
	if _enemies_container:
		var drones_def: Array = level_data.get("drones", [])
		for d in drones_def:
			var drone: Node2D = _drone_scene.instantiate()
			drone.position = d.get("pos", Vector2(800, 300))
			drone.set("drone_type", d.get("type", 0))
			drone.set("patrol_axis", d.get("axis", Vector2(1, 0)))
			drone.set("patrol_distance", d.get("dist", 200.0))
			_enemies_container.add_child(drone)

	# Spawn Collectibles
	if _collectibles_container:
		# Cores
		var num_cores: int = clampi(total_cores_needed, 1, CORE_SPAWN_POINTS.size())
		for i in range(num_cores):
			var core: Node2D = _fragment_scene.instantiate()
			core.position = CORE_SPAWN_POINTS[i]
			_collectibles_container.add_child(core)
			
		# Shield Kits
		var num_shields: int = clampi(level_data.get("shield_kits", 1), 0, SHIELD_SPAWN_POINTS.size())
		for i in range(num_shields):
			var shield: Node2D = _shield_scene.instantiate()
			shield.position = SHIELD_SPAWN_POINTS[i]
			_collectibles_container.add_child(shield)
			
		# Overcharge Cells
		var num_cells: int = clampi(level_data.get("overcharge_cells", 1), 0, OVERCHARGE_SPAWN_POINTS.size())
		for i in range(num_cells):
			var cell: Node2D = _overcharge_scene.instantiate()
			cell.position = OVERCHARGE_SPAWN_POINTS[i]
			_collectibles_container.add_child(cell)


func _unhandled_input(event: InputEvent) -> void:
	if (current_state == GameState.GAME_OVER or current_state == GameState.VICTORY or current_state == GameState.BRIEFING):
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			if current_state == GameState.BRIEFING:
				start_match()
			elif current_state == GameState.VICTORY:
				var cm := _get_cm()
				if cm:
					cm.next_level()
				else:
					restart_game()
			else:
				restart_game()


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
		GameState.GAME_OVER:
			if Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_accept"):
				restart_game()
		GameState.VICTORY:
			if Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_accept"):
				var cm := _get_cm()
				if cm:
					cm.next_level()
				else:
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
	_check_reinforcements()
	
	if _hud:
		_hud.update_cores(collected_cores, total_cores_needed)
		_hud.update_score(score)
		
	if collected_cores >= total_cores_needed:
		trigger_victory()


func _check_reinforcements() -> void:
	if _pending_reinforcements.is_empty() or not _enemies_container:
		return
		
	var i := 0
	while i < _pending_reinforcements.size():
		var r: Dictionary = _pending_reinforcements[i]
		if collected_cores >= r.get("trigger_cores", 999):
			# Spawn Reinforcement Drone
			var drone: Node2D = _drone_scene.instantiate()
			drone.position = r.get("pos", Vector2(800, 450))
			drone.set("drone_type", r.get("type", 0))
			drone.set("patrol_axis", r.get("axis", Vector2(0, 1)))
			drone.set("patrol_distance", r.get("dist", 180.0))
			_enemies_container.add_child(drone)
			
			trigger_screen_shake(0.35, 9.0)
			if _hud:
				_hud.show_combo(r.get("announcement", "ALERT: REINFORCEMENTS DETECTED!"))
			if AudioManager.instance:
				AudioManager.instance.play_damage()
				
			_pending_reinforcements.remove_at(i)
		else:
			i += 1


func _check_wave_progression() -> void:
	var progress_pct := float(collected_cores) / float(maxi(1, total_cores_needed))
	var new_wave := 1
	var title := "Infiltration"
	
	if progress_pct >= 0.75:
		new_wave = 4
		title = "Extraction Override"
	elif progress_pct >= 0.50:
		new_wave = 3
		title = "Sector Lockdown"
	elif progress_pct >= 0.25:
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
	var par: float = level_data.get("par_time", 60.0)
	var time_bonus: int = maxi(0, int((par * 2.0) - survival_time) * 8)
	score += time_bonus
	
	save_records()
	
	var health_left: int = _player.current_health if _player else 1
	var result := {}
	var cm := _get_cm()
	if cm:
		result = cm.complete_level(current_level_id, score, survival_time, health_left)
	else:
		result = {
			"level_id": current_level_id,
			"level_name": level_data.get("name", "Mission %02d" % current_level_id),
			"stars_earned": 3 if (health_left >= 2 and survival_time <= par) else (2 if health_left >= 2 else 1),
			"par_time": par,
			"is_campaign_complete": (current_level_id == 20)
		}
	
	if _hud:
		_hud.show_victory(result, score, high_score, collected_cores, survival_time, health_left)
		
	if AudioManager.instance:
		AudioManager.instance.play_victory()


func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	save_records()
	if _hud:
		_hud.show_game_over(current_level_id, level_data.get("name", "Mission"), score, high_score, collected_cores, total_cores_needed, survival_time)


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
	var cm := _get_cm()
	if cm:
		cm.restart_current_level()
	else:
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

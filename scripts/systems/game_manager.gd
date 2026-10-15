class_name GameManager
extends Node

## Core Game Manager for Last Stand: Signal Break.
## Coordinates game states, scoring, objectives, audio, and match restarts.

enum GameState { BRIEFING, PLAYING, GAME_OVER, VICTORY }

static var instance: GameManager

@export var total_cores_needed: int = 10
@export var passive_score_interval: float = 1.0

var current_state: GameState = GameState.BRIEFING
var score: int = 0
var collected_cores: int = 0
var survival_time: float = 0.0
var _score_timer: float = 0.0

var _player: Player
var _hud: Node


func _enter_tree() -> void:
	instance = self
	add_to_group("game_manager")


func _ready() -> void:
	call_deferred("_initialize_game")


func _initialize_game() -> void:
	_find_references()
	_connect_signals()
	
	if _hud:
		_hud.show_briefing()
		_hud.update_cores(collected_cores, total_cores_needed)
		_hud.update_score(score)
		_hud.update_timer(survival_time)


func _find_references() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Player:
		_player = players[0] as Player
		
	var huds := get_tree().get_nodes_in_group("hud")
	if not huds.is_empty():
		_hud = huds[0]
	elif get_parent().has_node("HUD"):
		_hud = get_parent().get_node("HUD")


func _connect_signals() -> void:
	if _player:
		_player.health_changed.connect(_on_player_health_changed)
		_player.energy_changed.connect(_on_player_energy_changed)
		_player.pulse_triggered.connect(_on_player_pulse_triggered)
		_player.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	# Global restart input check
	if Input.is_action_just_pressed("restart"):
		restart_game()
		return
		
	match current_state:
		GameState.BRIEFING:
			_process_briefing()
		GameState.PLAYING:
			_process_playing(delta)
		GameState.GAME_OVER, GameState.VICTORY:
			# Allow restart via Space as well when on game over / victory screen
			if Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_accept"):
				restart_game()


func _process_briefing() -> void:
	# Any directional movement or pulse start key dismisses briefing
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
	
	# Passive score accrual for surviving in hostile territory (+5 points per second)
	if _score_timer >= passive_score_interval:
		_score_timer -= passive_score_interval
		score += 5
		if _hud:
			_hud.update_score(score)
			
	if _hud:
		_hud.update_timer(survival_time)
		if _player:
			_hud.update_energy(_player.current_energy, _player.max_energy, _player.cooldown_timer > 0.0)


func register_core_collected(_pos: Vector2, reward_points: int) -> void:
	if current_state != GameState.PLAYING and current_state != GameState.BRIEFING:
		return
		
	if current_state == GameState.BRIEFING:
		start_match()
		
	collected_cores += 1
	score += reward_points
	
	if _hud:
		_hud.update_cores(collected_cores, total_cores_needed)
		_hud.update_score(score)
		
	# Check victory condition
	if collected_cores >= total_cores_needed:
		trigger_victory()


func register_drone_stunned() -> void:
	if current_state == GameState.PLAYING:
		score += 25
		if _hud:
			_hud.update_score(score)


func trigger_victory() -> void:
	current_state = GameState.VICTORY
	# Bonus score based on quick extraction time
	var time_bonus := maxi(0, int(300.0 - survival_time) * 5)
	score += time_bonus
	
	if _hud:
		_hud.show_victory(score, collected_cores, survival_time)
		
	if AudioManager.instance:
		AudioManager.instance.play_victory()


func _on_player_died() -> void:
	current_state = GameState.GAME_OVER
	if _hud:
		_hud.show_game_over(score, collected_cores, total_cores_needed, survival_time)


func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if _hud:
		_hud.update_health(current_hp, max_hp)


func _on_player_energy_changed(current_ep: float, max_ep: float) -> void:
	if _hud and _player:
		_hud.update_energy(current_ep, max_ep, _player.cooldown_timer > 0.0)


func _on_player_pulse_triggered(success: bool, _reason: String) -> void:
	if success:
		# Award points for tactical pulse deployment
		score += 10
		if _hud:
			_hud.update_score(score)


func restart_game() -> void:
	get_tree().reload_current_scene()

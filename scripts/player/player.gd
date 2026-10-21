class_name Player
extends CharacterBody2D

## Player controller for Last Stand: Signal Break.
## Handles normalized 8-directional movement, health, energy, disruption pulse,
## and overcharge states.

signal health_changed(current_hp: int, max_hp: int)
signal energy_changed(current_ep: float, max_ep: float)
signal pulse_triggered(success: bool, reason: String)
signal player_damaged()
signal player_died()

@export var speed: float = 250.0
@export var max_health: int = 3
@export var max_energy: float = 100.0
@export var pulse_cost: float = 25.0
@export var pulse_cooldown: float = 0.8
@export var passive_regen_rate: float = 1.8
@export var pulse_scene: PackedScene = preload("res://scenes/pulse/disruption_pulse.tscn")

var current_health: int = 3
var current_energy: float = 60.0
var cooldown_timer: float = 0.0
var is_dead: bool = false
var has_overcharge: bool = false
var touch_vector: Vector2 = Vector2.ZERO
var _invuln_timer: float = 0.0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var outline: Line2D = $Outline
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const COLOR_NORMAL := Color(0.18, 0.65, 1.0, 1.0)
const COLOR_OVERCHARGE := Color(1.0, 0.85, 0.2, 1.0)
const COLOR_INVULN := Color(1.0, 0.35, 0.35, 0.9)


func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	health_changed.emit(current_health, max_health)
	energy_changed.emit(current_energy, max_energy)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	_handle_timers(delta)
	_handle_movement()
	_handle_pulse_input()


func _handle_timers(delta: float) -> void:
	if current_energy < max_energy:
		current_energy = minf(max_energy, current_energy + passive_regen_rate * delta)
		energy_changed.emit(current_energy, max_energy)
		
	if cooldown_timer > 0.0:
		cooldown_timer = maxf(0.0, cooldown_timer - delta)
		
	if _invuln_timer > 0.0:
		_invuln_timer = maxf(0.0, _invuln_timer - delta)
		var flash := fmod(_invuln_timer * 12.0, 2.0) > 1.0
		body_visual.color = COLOR_INVULN if flash else (COLOR_OVERCHARGE if has_overcharge else COLOR_NORMAL)
	else:
		body_visual.color = COLOR_OVERCHARGE if has_overcharge else COLOR_NORMAL


func _handle_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction == Vector2.ZERO and touch_vector != Vector2.ZERO:
		direction = touch_vector
		
	velocity = direction * speed
	move_and_slide()
	
	if direction != Vector2.ZERO:
		var target_angle := direction.angle()
		rotation = lerp_angle(rotation, target_angle + PI * 0.5, 0.25)


func _handle_pulse_input() -> void:
	if Input.is_action_just_pressed("pulse") or Input.is_action_just_pressed("ui_select"):
		fire_disruption_pulse()


func fire_disruption_pulse() -> bool:
	if is_dead:
		return false
		
	if cooldown_timer > 0.0:
		pulse_triggered.emit(false, "COOLDOWN")
		return false
		
	if current_energy < pulse_cost and not has_overcharge:
		pulse_triggered.emit(false, "LOW_ENERGY")
		if AudioManager.instance:
			AudioManager.instance.play_low_energy()
		return false
		
	current_energy = maxf(0.0, current_energy - pulse_cost)
	cooldown_timer = pulse_cooldown
	energy_changed.emit(current_energy, max_energy)
	pulse_triggered.emit(true, "ACTIVATED")
	
	if pulse_scene:
		var pulse_instance = pulse_scene.instantiate()
		pulse_instance.global_position = global_position
		if has_overcharge:
			pulse_instance.is_overcharged = true
			has_overcharge = false
		get_parent().add_child(pulse_instance)
		
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("trigger_screen_shake"):
		gm.trigger_screen_shake(0.2, 5.0)
		
	if AudioManager.instance:
		AudioManager.instance.play_pulse()
		
	return true


func add_energy(amount: float) -> void:
	if is_dead:
		return
	current_energy = minf(max_energy, current_energy + amount)
	energy_changed.emit(current_energy, max_energy)


func heal_shield(amount: int = 1) -> void:
	if is_dead:
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func grant_overcharge() -> void:
	if is_dead:
		return
	has_overcharge = true
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)


func take_damage(amount: int = 1) -> void:
	if is_dead or _invuln_timer > 0.0:
		return
		
	current_health = maxi(0, current_health - amount)
	_invuln_timer = 1.2
	health_changed.emit(current_health, max_health)
	player_damaged.emit()
	
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("trigger_screen_shake"):
		gm.trigger_screen_shake(0.35, 12.0)
		
	if AudioManager.instance:
		AudioManager.instance.play_hit()
		
	if current_health <= 0:
		is_dead = true
		player_died.emit()
		if AudioManager.instance:
			AudioManager.instance.play_game_over()

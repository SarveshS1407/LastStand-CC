class_name EnemyDrone
extends CharacterBody2D

## Hostile security drone featuring a 4-state Finite State Machine:
## PATROL -> CHASE -> STUNNED -> RETURN.

enum State { PATROL, CHASE, STUNNED, RETURN }

@export var patrol_points: Array = []
@export var patrol_axis: Vector2 = Vector2.RIGHT
@export var patrol_distance: float = 120.0
@export var patrol_speed: float = 95.0
@export var chase_speed: float = 150.0
@export var detection_radius: float = 180.0
@export var lose_radius: float = 250.0
@export var contact_damage: int = 1

var current_state: State = State.PATROL
var current_patrol_index: int = 0
var stun_timer: float = 0.0
var _player: Player
var _spawn_pos: Vector2

@onready var body_visual: Polygon2D = $BodyVisual
@onready var core_eye: Polygon2D = $CoreEye
@onready var outline: Line2D = $Outline
@onready var state_label: Label = $StateLabel
@onready var hitbox: Area2D = $Hitbox

const COLOR_PATROL := Color(0.95, 0.65, 0.15, 1.0)
const COLOR_CHASE := Color(0.95, 0.22, 0.22, 1.0)
const COLOR_STUNNED := Color(0.12, 0.85, 0.95, 1.0)
const COLOR_RETURN := Color(0.7, 0.75, 0.8, 1.0)


func _ready() -> void:
	add_to_group("enemies")
	_spawn_pos = global_position
	
	# Default patrol route based on axis and distance
	if patrol_points.is_empty():
		var axis := patrol_axis.normalized() if patrol_axis != Vector2.ZERO else Vector2.RIGHT
		patrol_points.append(_spawn_pos - axis * patrol_distance)
		patrol_points.append(_spawn_pos + axis * patrol_distance)
		
	# Find player reference
	_find_player()
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	_update_visuals()


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Player:
		_player = players[0] as Player


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_find_player()
		
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.RETURN:
			_process_return(delta)
			
	move_and_slide()
	_update_visuals()


func _process_patrol(_delta: float) -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return
		
	var target: Vector2 = patrol_points[current_patrol_index]
	var to_target := target - global_position
	var dist := to_target.length()
	
	if dist < 12.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target = patrol_points[current_patrol_index]
		to_target = target - global_position
		
	velocity = to_target.normalized() * patrol_speed
	_face_direction(velocity)
	
	# Transition: Player detected within patrol range
	if _can_detect_player():
		current_state = State.CHASE


func _process_chase(_delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		current_state = State.RETURN
		return
		
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	
	# Transition: Player escaped chase range
	if dist > lose_radius:
		current_state = State.RETURN
		return
		
	velocity = to_player.normalized() * chase_speed
	_face_direction(velocity)


func _process_stunned(delta: float) -> void:
	velocity = Vector2.ZERO
	stun_timer -= delta
	
	# Electrical twitch/flicker effect
	rotation += (randf() - 0.5) * 0.2
	
	if stun_timer <= 0.0:
		stun_timer = 0.0
		# Resume chase if player is still near, otherwise return to patrol
		if _can_detect_player():
			current_state = State.CHASE
		else:
			current_state = State.RETURN


func _process_return(_delta: float) -> void:
	if patrol_points.is_empty():
		current_state = State.PATROL
		return
		
	var target: Vector2 = patrol_points[current_patrol_index]
	var to_target := target - global_position
	var dist := to_target.length()
	
	# Transition: Re-detect player while returning
	if _can_detect_player():
		current_state = State.CHASE
		return
		
	# Transition: Reached patrol waypoint, resume normal patrol
	if dist < 14.0:
		current_state = State.PATROL
		return
		
	velocity = to_target.normalized() * patrol_speed
	_face_direction(velocity)


func _can_detect_player() -> bool:
	if not is_instance_valid(_player) or _player.is_dead:
		return false
	return global_position.distance_to(_player.global_position) <= detection_radius


func _face_direction(move_vec: Vector2) -> void:
	if move_vec.length_squared() > 10.0:
		var target_angle := move_vec.angle() + PI * 0.5
		rotation = lerp_angle(rotation, target_angle, 0.2)


func apply_stun(duration: float) -> void:
	current_state = State.STUNNED
	stun_timer = duration
	velocity = Vector2.ZERO
	_update_visuals()


func _update_visuals() -> void:
	match current_state:
		State.PATROL:
			core_eye.color = COLOR_PATROL
			outline.default_color = COLOR_PATROL
			state_label.text = "PATROL"
			state_label.modulate = COLOR_PATROL
		State.CHASE:
			core_eye.color = COLOR_CHASE
			outline.default_color = COLOR_CHASE
			state_label.text = "! ALERT"
			state_label.modulate = COLOR_CHASE
		State.STUNNED:
			core_eye.color = COLOR_STUNNED
			outline.default_color = COLOR_STUNNED
			state_label.text = "⚡ STUN"
			state_label.modulate = COLOR_STUNNED
		State.RETURN:
			core_eye.color = COLOR_RETURN
			outline.default_color = COLOR_RETURN
			state_label.text = "RETURN"
			state_label.modulate = COLOR_RETURN


func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.STUNNED:
		return # Stunned drones cannot deal contact damage!
		
	if body is Player:
		body.take_damage(contact_damage)

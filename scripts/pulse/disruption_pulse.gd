class_name DisruptionPulse
extends Area2D

## Circular shockwave pulse that expands outward, stunning defense drones.

@export var max_radius: float = 175.0
@export var duration: float = 0.35
@export var stun_duration: float = 3.0

var current_radius: float = 10.0
var _elapsed: float = 0.0
var _hit_enemies: Array[Node] = []
var _circle_shape: CircleShape2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Ensure unique shape instance so expansion doesn't mutate other resources
	_circle_shape = CircleShape2D.new()
	_circle_shape.radius = current_radius
	collision_shape.shape = _circle_shape
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	
	# Ease-out cubic expansion
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	current_radius = lerpf(12.0, max_radius, eased)
	
	if _circle_shape:
		_circle_shape.radius = current_radius
		
	# Proactive distance check against all active enemies for frame-independent detection
	_check_enemies_in_radius()
	
	queue_redraw()
	
	if progress >= 1.0:
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var alpha := (1.0 - progress) * 0.85
	
	# Primary glowing shockwave ring
	var ring_color := Color(0.15, 0.85, 1.0, alpha)
	draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 48, ring_color, 3.5, true)
	
	# Secondary soft inner ripple
	var inner_radius := maxf(0.0, current_radius - 18.0)
	var inner_color := Color(0.4, 0.95, 1.0, alpha * 0.5)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 36, inner_color, 1.8, true)
	
	# Subtle translucent energy core fill
	var fill_color := Color(0.1, 0.6, 0.9, alpha * 0.12)
	draw_circle(Vector2.ZERO, current_radius, fill_color)


func _check_enemies_in_radius() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy in _hit_enemies or not is_instance_valid(enemy):
			continue
		if enemy is Node2D:
			var dist := global_position.distance_to(enemy.global_position)
			# Account for enemy radius (~16px)
			if dist <= current_radius + 16.0:
				_stun_target(enemy)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_stun_target(body)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_stun_target(area)
	elif area.get_parent() and area.get_parent().is_in_group("enemies"):
		_stun_target(area.get_parent())


func _stun_target(target: Node) -> void:
	if target in _hit_enemies:
		return
	_hit_enemies.append(target)
	
	if target.has_method("apply_stun"):
		target.apply_stun(stun_duration)
		if AudioManager.instance:
			AudioManager.instance.play_stun()
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("register_drone_stunned"):
			gm.register_drone_stunned()

class_name OverchargePickup
extends Area2D

## Overcharge EMP Cell. Refills energy to 100% and grants super-pulse radius.

@export var score_reward: int = 150
var _collected: bool = false
var _elapsed: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var glow_ring: Line2D = $GlowRing


func _ready() -> void:
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_elapsed += delta
	visual.position.y = sin(_elapsed * 4.0) * 3.5
	visual.rotation += delta * 3.0
	var s := 1.0 + sin(_elapsed * 6.0) * 0.18
	glow_ring.scale = Vector2(s, s)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		_collected = true
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# Give overcharge to player
		body.grant_overcharge()
		
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("register_overcharge_pickup"):
			gm.register_overcharge_pickup(score_reward)
			
		if AudioManager.instance:
			AudioManager.instance.play_collect()
			
		_spawn_effect()
		queue_free()


func _spawn_effect() -> void:
	var effect := Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)
	var tween := effect.create_tween()
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in range(25):
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	ring.points = pts
	ring.width = 3.5
	ring.default_color = Color(1.0, 0.85, 0.2, 0.95)
	effect.add_child(ring)
	tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.3)
	tween.parallel().tween_property(ring, "default_color:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

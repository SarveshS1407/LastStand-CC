class_name EnergyFragment
extends Area2D

## Collectible Energy Core / Signal Fragment.
## Restores player energy, contributes to extraction uplink, and awards score.

@export var energy_reward: float = 30.0
@export var score_reward: int = 100

var _collected: bool = false
var _elapsed: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var glow_ring: Line2D = $GlowRing
@onready var core_gem: Polygon2D = $Visual/CoreGem


func _ready() -> void:
	add_to_group("collectibles")
	body_entered.connect(_on_body_entered)
	_elapsed = randf() * TAU # Randomize phase


func _process(delta: float) -> void:
	if _collected:
		return
		
	_elapsed += delta
	# Floating bobbing animation
	visual.position.y = sin(_elapsed * 3.5) * 3.5
	visual.rotation = _elapsed * 1.5
	
	# Pulsing glow effect
	var glow_scale := 1.0 + sin(_elapsed * 5.0) * 0.15
	glow_ring.scale = Vector2(glow_scale, glow_scale)


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
		
	if body is Player:
		_collected = true
		# Prevent double collection immediately
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		
		# Award energy to player
		body.add_energy(energy_reward)
		
		# Notify Game Manager
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("register_core_collected"):
			gm.register_core_collected(global_position, score_reward)
			
		# Play audio
		if AudioManager.instance:
			AudioManager.instance.play_collect()
			
		# Create quick collection burst visual
		_spawn_collect_effect()
		queue_free()


func _spawn_collect_effect() -> void:
	# Clean lightweight pickup burst effect
	var effect := Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)
	
	var tween := effect.create_tween()
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	var segments := 24
	for i in range(segments + 1):
		var a := float(i) / segments * TAU
		pts.append(Vector2(cos(a), sin(a)) * 8.0)
	ring.points = pts
	ring.width = 3.0
	ring.default_color = Color(0.2, 1.0, 0.45, 0.9)
	effect.add_child(ring)
	
	tween.tween_property(ring, "scale", Vector2(3.5, 3.5), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "default_color:a", 0.0, 0.28)
	tween.tween_callback(effect.queue_free)

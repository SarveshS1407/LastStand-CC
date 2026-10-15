class_name Player
extends CharacterBody2D

## Movement speed in pixels per second.
@export var speed: float = 300.0


func _physics_process(_delta: float) -> void:
	# Query 8-directional input vector (normalized length <= 1.0)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Fallback to built-in UI directional actions if custom actions are not active
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = direction * speed
	move_and_slide()

class_name TouchControls
extends CanvasLayer

## Mobile On-Screen Virtual Controls for Last Stand: Signal Break.
## Features a floating analog thumbstick on the left quadrant, a large tactical EMP Pulse
## action button on the right, and an accessible Pause control in the top-right corner.
## Fully responsive across all phone viewport aspect ratios with dynamic positioning.

signal joystick_moved(direction: Vector2)
signal pulse_pressed()
signal pulse_released()

const JOYSTICK_MAX_RADIUS := 75.0
const JOYSTICK_DEADZONE := 0.15
const PULSE_BUTTON_RADIUS := 75.0
const PAUSE_BUTTON_SIZE := Vector2(56.0, 56.0)

var joystick_touch_id: int = -1
var joystick_center: Vector2 = Vector2(190.0, 700.0)
var joystick_knob_pos: Vector2 = Vector2(190.0, 700.0)
var current_direction: Vector2 = Vector2.ZERO

var pulse_touch_id: int = -1
var is_pulse_pressed: bool = false

var player_ref: Player = null
var pulse_glow_timer: float = 0.0

@onready var draw_surface: Control = $ControlRoot/DrawSurface


func _ready() -> void:
	layer = 15 # Above world and HUD, below pause menu
	_update_base_positions()
	_check_visibility()
	
	if SettingsManager:
		SettingsManager.settings_changed.connect(_check_visibility)
		
	draw_surface.draw.connect(_on_draw_surface)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	if joystick_touch_id == -1:
		_update_base_positions()
	draw_surface.queue_redraw()


func _update_base_positions() -> void:
	var base := get_joystick_base_pos()
	joystick_center = base
	joystick_knob_pos = base


func get_viewport_size() -> Vector2:
	var s := get_viewport().get_visible_rect().size
	if s.x <= 0 or s.y <= 0:
		return Vector2(1600.0, 900.0)
	return s


func get_joystick_base_pos() -> Vector2:
	var s := get_viewport_size()
	return Vector2(maxf(160.0, s.x * 0.12), s.y - maxf(150.0, s.y * 0.20))


func get_pulse_button_pos() -> Vector2:
	var s := get_viewport_size()
	return Vector2(s.x - maxf(160.0, s.x * 0.12), s.y - maxf(150.0, s.y * 0.20))


func get_pause_button_pos() -> Vector2:
	var s := get_viewport_size()
	return Vector2(s.x - 48.0, 48.0)


func _check_visibility() -> void:
	if SettingsManager and SettingsManager.has_method("should_show_touch_controls"):
		visible = SettingsManager.should_show_touch_controls()
	else:
		visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")


func _process(delta: float) -> void:
	if not visible:
		return
		
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Player
		
	pulse_glow_timer += delta * 3.5
	draw_surface.queue_redraw()


func _input(event: InputEvent) -> void:
	# Show touch controls on touch event if not explicitly disabled
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not visible and (not SettingsManager or SettingsManager.touch_controls_mode != 2):
			visible = true

	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var pos := event.position
	var s := get_viewport_size()
	
	if event.pressed:
		# 1. Pause button check (top-right corner)
		var pause_pos := get_pause_button_pos()
		var pause_rect := Rect2(pause_pos - PAUSE_BUTTON_SIZE * 0.5, PAUSE_BUTTON_SIZE)
		if pause_rect.grow(20.0).has_point(pos):
			Input.action_press("pause")
			get_viewport().set_input_as_handled()
			return

		# 2. Pulse button check (bottom-right region)
		var pulse_pos := get_pulse_button_pos()
		var pulse_dist := (pos - pulse_pos).length()
		if pulse_dist <= PULSE_BUTTON_RADIUS + 35.0:
			pulse_touch_id = event.index
			is_pulse_pressed = true
			Input.action_press("pulse")
			if is_instance_valid(player_ref):
				player_ref.fire_disruption_pulse()
			pulse_pressed.emit()
			get_viewport().set_input_as_handled()
			return

		# 3. Joystick touch check (floating anywhere in the lower-left quadrant)
		if joystick_touch_id == -1 and pos.x < s.x * 0.45 and pos.y > s.y * 0.35:
			joystick_touch_id = event.index
			var base_pos := get_joystick_base_pos()
			# If close to default base, keep base; otherwise float to finger
			if (pos - base_pos).length() < 100.0:
				joystick_center = base_pos
			else:
				joystick_center = pos
			joystick_knob_pos = pos
			_update_joystick_vector(pos)
			get_viewport().set_input_as_handled()
			return

	else: # Touch Released
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_center = get_joystick_base_pos()
			joystick_knob_pos = get_joystick_base_pos()
			_set_direction(Vector2.ZERO)
			get_viewport().set_input_as_handled()
		elif event.index == pulse_touch_id:
			pulse_touch_id = -1
			is_pulse_pressed = false
			Input.action_release("pulse")
			pulse_released.emit()
			get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_id:
		_update_joystick_vector(event.position)
		get_viewport().set_input_as_handled()
	elif event.index == pulse_touch_id:
		var pulse_pos := get_pulse_button_pos()
		var pulse_dist := (event.position - pulse_pos).length()
		is_pulse_pressed = (pulse_dist <= PULSE_BUTTON_RADIUS + 40.0)
		get_viewport().set_input_as_handled()


func _update_joystick_vector(touch_pos: Vector2) -> void:
	var offset := touch_pos - joystick_center
	var dist := offset.length()
	
	if dist > JOYSTICK_MAX_RADIUS:
		offset = offset.normalized() * JOYSTICK_MAX_RADIUS
		
	joystick_knob_pos = joystick_center + offset
	
	var dir := offset / JOYSTICK_MAX_RADIUS
	if dir.length() < JOYSTICK_DEADZONE:
		dir = Vector2.ZERO
	else:
		dir = dir.normalized() * clampf((dir.length() - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE), 0.0, 1.0)
		
	_set_direction(dir)


func _set_direction(dir: Vector2) -> void:
	current_direction = dir
	joystick_moved.emit(dir)
	
	if is_instance_valid(player_ref):
		player_ref.touch_vector = dir
		
	# Update simulated Input actions
	if dir.x > 0.25:
		Input.action_press("move_right", dir.x)
		Input.action_release("move_left")
	elif dir.x < -0.25:
		Input.action_press("move_left", -dir.x)
		Input.action_release("move_right")
	else:
		Input.action_release("move_right")
		Input.action_release("move_left")
		
	if dir.y > 0.25:
		Input.action_press("move_down", dir.y)
		Input.action_release("move_up")
	elif dir.y < -0.25:
		Input.action_press("move_up", -dir.y)
		Input.action_release("move_down")
	else:
		Input.action_release("move_down")
		Input.action_release("move_up")


func _on_draw_surface() -> void:
	_draw_joystick()
	_draw_pulse_button()
	_draw_pause_button()


func _draw_joystick() -> void:
	var base_alpha := 0.48 if joystick_touch_id != -1 else 0.32
	var cyan := Color(0.0, 0.94, 1.0, base_alpha)
	var fill := Color(0.04, 0.12, 0.22, base_alpha * 0.8)
	
	# Base disc & ring
	draw_surface.draw_circle(joystick_center, JOYSTICK_MAX_RADIUS + 12.0, fill)
	draw_surface.draw_arc(joystick_center, JOYSTICK_MAX_RADIUS + 12.0, 0.0, TAU, 36, cyan, 2.5)
	
	# Directional tick marks
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir_v := Vector2(cos(angle), sin(angle))
		var p1 := joystick_center + dir_v * (JOYSTICK_MAX_RADIUS - 6.0)
		var p2 := joystick_center + dir_v * (JOYSTICK_MAX_RADIUS + 10.0)
		draw_surface.draw_line(p1, p2, Color(0.0, 0.94, 1.0, base_alpha * 1.4), 2.0)
		
	# Inner Knob
	var knob_col := Color(0.0, 0.94, 1.0, 0.9 if joystick_touch_id != -1 else 0.6)
	var knob_fill := Color(0.08, 0.32, 0.55, 0.85 if joystick_touch_id != -1 else 0.5)
	draw_surface.draw_circle(joystick_knob_pos, 32.0, knob_fill)
	draw_surface.draw_arc(joystick_knob_pos, 32.0, 0.0, TAU, 28, knob_col, 2.5)
	draw_surface.draw_circle(joystick_knob_pos, 6.0, Color.WHITE)


func _draw_pulse_button() -> void:
	var pulse_pos := get_pulse_button_pos()
	var has_overcharge := is_instance_valid(player_ref) and player_ref.has_overcharge
	var is_cooldown := is_instance_valid(player_ref) and player_ref.cooldown_timer > 0.0
	var is_low_energy := is_instance_valid(player_ref) and player_ref.current_energy < player_ref.pulse_cost and not has_overcharge
	
	var primary_col := Color(0.0, 0.94, 1.0)
	var fill_col := Color(0.04, 0.18, 0.32, 0.5)
	
	if has_overcharge:
		# Glowing golden overcharge pulse
		var wave := (sin(pulse_glow_timer) + 1.0) * 0.5
		primary_col = Color(1.0, 0.75 + 0.25 * wave, 0.05)
		fill_col = Color(0.5, 0.32, 0.02, 0.65 + 0.2 * wave)
		# Outer aura
		draw_surface.draw_arc(pulse_pos, PULSE_BUTTON_RADIUS + 10.0 + 4.0 * wave, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, 0.5 * wave), 3.0)
	elif is_pulse_pressed:
		primary_col = Color.WHITE
		fill_col = Color(0.0, 0.85, 1.0, 0.8)
	elif is_cooldown or is_low_energy:
		primary_col = Color(0.4, 0.5, 0.6, 0.45)
		fill_col = Color(0.08, 0.1, 0.14, 0.35)

	# Main button circle
	draw_surface.draw_circle(pulse_pos, PULSE_BUTTON_RADIUS, fill_col)
	draw_surface.draw_arc(pulse_pos, PULSE_BUTTON_RADIUS, 0.0, TAU, 36, primary_col, 3.0)
	
	# Concentric shockwave shock rings inside
	draw_surface.draw_arc(pulse_pos, PULSE_BUTTON_RADIUS * 0.65, 0.0, TAU, 24, Color(primary_col.r, primary_col.g, primary_col.b, 0.55), 2.0)
	draw_surface.draw_arc(pulse_pos, PULSE_BUTTON_RADIUS * 0.35, 0.0, TAU, 18, Color(primary_col.r, primary_col.g, primary_col.b, 0.85), 2.0)
	draw_surface.draw_circle(pulse_pos, 8.0, primary_col)
	
	# Label text below button
	var font := ThemeDB.fallback_font
	var font_size := 16
	var text := "⚡ OVERCHARGE" if has_overcharge else ("COOLDOWN" if is_cooldown else "EMP PULSE")
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := pulse_pos + Vector2(-text_size.x * 0.5, PULSE_BUTTON_RADIUS + 22.0)
	draw_surface.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, primary_col)


func _draw_pause_button() -> void:
	var pause_pos := get_pause_button_pos()
	var rect := Rect2(pause_pos - PAUSE_BUTTON_SIZE * 0.5, PAUSE_BUTTON_SIZE)
	var border_col := Color(0.0, 0.94, 1.0, 0.55)
	var fill_col := Color(0.04, 0.12, 0.22, 0.5)
	
	draw_surface.draw_rect(rect, fill_col)
	draw_surface.draw_rect(rect, border_col, false, 2.0)
	
	# ❚❚ Pause bars
	var bar_w := 6.0
	var bar_h := 22.0
	var b1 := Rect2(pause_pos.x - 9.0, pause_pos.y - bar_h * 0.5, bar_w, bar_h)
	var b2 := Rect2(pause_pos.x + 3.0, pause_pos.y - bar_h * 0.5, bar_w, bar_h)
	draw_surface.draw_rect(b1, Color(0.0, 0.94, 1.0, 0.85))
	draw_surface.draw_rect(b2, Color(0.0, 0.94, 1.0, 0.85))

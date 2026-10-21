class_name TouchControls
extends CanvasLayer

## Mobile On-Screen Virtual Controls for Last Stand: Signal Break
## Provides an analog floating virtual thumbstick on the left, an EMP Pulse action button on the right,
## and a tactical pause button on the top-right.

signal joystick_moved(direction: Vector2)
signal pulse_pressed()
signal pulse_released()

const JOYSTICK_BASE_POS := Vector2(170.0, 730.0)
const JOYSTICK_MAX_RADIUS := 75.0
const JOYSTICK_DEADZONE := 0.15

const PULSE_BUTTON_POS := Vector2(1430.0, 730.0)
const PULSE_BUTTON_RADIUS := 70.0

const PAUSE_BUTTON_POS := Vector2(1530.0, 60.0)
const PAUSE_BUTTON_SIZE := Vector2(56.0, 56.0)

var joystick_touch_id: int = -1
var joystick_center: Vector2 = JOYSTICK_BASE_POS
var joystick_knob_pos: Vector2 = JOYSTICK_BASE_POS
var current_direction: Vector2 = Vector2.ZERO

var pulse_touch_id: int = -1
var is_pulse_pressed: bool = false

var player_ref: Player = null
var pulse_glow_timer: float = 0.0

@onready var draw_surface: Control = $ControlRoot/DrawSurface


func _ready() -> void:
	layer = 15 # Above world and HUD, below pause menu
	_check_visibility()
	
	if SettingsManager:
		SettingsManager.settings_changed.connect(_check_visibility)
		
	draw_surface.draw.connect(_on_draw_surface)


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
	# If any touch event occurs anywhere, ensure touch controls are shown
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
	
	if event.pressed:
		# 1. Pause button check (top-right)
		var pause_rect := Rect2(PAUSE_BUTTON_POS - PAUSE_BUTTON_SIZE * 0.5, PAUSE_BUTTON_SIZE)
		if pause_rect.grow(15.0).has_point(pos):
			Input.action_press("pause")
			get_viewport().set_input_as_handled()
			return

		# 2. Pulse button check (bottom-right)
		var pulse_dist := (pos - PULSE_BUTTON_POS).length()
		if pulse_dist <= PULSE_BUTTON_RADIUS + 30.0:
			pulse_touch_id = event.index
			is_pulse_pressed = true
			Input.action_press("pulse")
			if is_instance_valid(player_ref):
				player_ref.fire_disruption_pulse()
			pulse_pressed.emit()
			get_viewport().set_input_as_handled()
			return

		# 3. Joystick touch check (bottom-left quadrant: x < 700, y > 380)
		if joystick_touch_id == -1 and pos.x < 750.0 and pos.y > 360.0:
			joystick_touch_id = event.index
			# Dynamic positioning: center joystick where finger touches, or keep fixed if near base
			if (pos - JOYSTICK_BASE_POS).length() < 120.0:
				joystick_center = JOYSTICK_BASE_POS
			else:
				joystick_center = pos
			joystick_knob_pos = pos
			_update_joystick_vector(pos)
			get_viewport().set_input_as_handled()
			return

	else: # Touch Released
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_center = JOYSTICK_BASE_POS
			joystick_knob_pos = JOYSTICK_BASE_POS
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
		# If finger drags off button, maintain pressed or release
		var pulse_dist := (event.position - PULSE_BUTTON_POS).length()
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
	# 1. Draw Joystick
	_draw_joystick()
	
	# 2. Draw Pulse Button
	_draw_pulse_button()
	
	# 3. Draw Pause Button
	_draw_pause_button()


func _draw_joystick() -> void:
	var base_alpha := 0.45 if joystick_touch_id != -1 else 0.28
	var cyan := Color(0.0, 0.94, 1.0, base_alpha)
	var fill := Color(0.04, 0.12, 0.22, base_alpha * 0.75)
	
	# Base disc & ring
	draw_surface.draw_circle(joystick_center, JOYSTICK_MAX_RADIUS + 12.0, fill)
	draw_surface.draw_arc(joystick_center, JOYSTICK_MAX_RADIUS + 12.0, 0.0, TAU, 36, cyan, 2.5)
	
	# Inner directional tick marks
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir_v := Vector2(cos(angle), sin(angle))
		var p1 := joystick_center + dir_v * (JOYSTICK_MAX_RADIUS - 6.0)
		var p2 := joystick_center + dir_v * (JOYSTICK_MAX_RADIUS + 10.0)
		draw_surface.draw_line(p1, p2, Color(0.0, 0.94, 1.0, base_alpha * 1.3), 2.0)
		
	# Knob
	var knob_col := Color(0.0, 0.94, 1.0, 0.85 if joystick_touch_id != -1 else 0.5)
	var knob_fill := Color(0.08, 0.32, 0.55, 0.8 if joystick_touch_id != -1 else 0.45)
	draw_surface.draw_circle(joystick_knob_pos, 32.0, knob_fill)
	draw_surface.draw_arc(joystick_knob_pos, 32.0, 0.0, TAU, 28, knob_col, 2.5)
	draw_surface.draw_circle(joystick_knob_pos, 6.0, Color.WHITE)


func _draw_pulse_button() -> void:
	var has_overcharge := is_instance_valid(player_ref) and player_ref.has_overcharge
	var is_cooldown := is_instance_valid(player_ref) and player_ref.cooldown_timer > 0.0
	var is_low_energy := is_instance_valid(player_ref) and player_ref.current_energy < player_ref.pulse_cost and not has_overcharge
	
	var primary_col := Color(0.0, 0.94, 1.0)
	var fill_col := Color(0.04, 0.18, 0.32, 0.45)
	
	if has_overcharge:
		# Glowing golden overcharge pulse
		var wave := (sin(pulse_glow_timer) + 1.0) * 0.5
		primary_col = Color(1.0, 0.72 + 0.28 * wave, 0.0)
		fill_col = Color(0.45, 0.3, 0.02, 0.6 + 0.2 * wave)
		# Outer overcharge aura
		draw_surface.draw_arc(PULSE_BUTTON_POS, PULSE_BUTTON_RADIUS + 8.0 + 4.0 * wave, 0.0, TAU, 32, Color(1.0, 0.8, 0.1, 0.45 * wave), 3.0)
	elif is_pulse_pressed:
		primary_col = Color.WHITE
		fill_col = Color(0.0, 0.8, 1.0, 0.75)
	elif is_cooldown or is_low_energy:
		primary_col = Color(0.4, 0.5, 0.6, 0.4)
		fill_col = Color(0.08, 0.1, 0.14, 0.3)

	# Main button circle
	draw_surface.draw_circle(PULSE_BUTTON_POS, PULSE_BUTTON_RADIUS, fill_col)
	draw_surface.draw_arc(PULSE_BUTTON_POS, PULSE_BUTTON_RADIUS, 0.0, TAU, 36, primary_col, 3.0)
	
	# Concentric shockwave shock rings inside
	draw_surface.draw_arc(PULSE_BUTTON_POS, PULSE_BUTTON_RADIUS * 0.65, 0.0, TAU, 24, Color(primary_col.r, primary_col.g, primary_col.b, 0.5), 2.0)
	draw_surface.draw_arc(PULSE_BUTTON_POS, PULSE_BUTTON_RADIUS * 0.35, 0.0, TAU, 18, Color(primary_col.r, primary_col.g, primary_col.b, 0.8), 2.0)
	draw_surface.draw_circle(PULSE_BUTTON_POS, 8.0, primary_col)
	
	# Label text
	var font := ThemeDB.fallback_font
	var font_size := 18
	var text := "EMP" if has_overcharge else "PULSE"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := PULSE_BUTTON_POS + Vector2(-text_size.x * 0.5, PULSE_BUTTON_RADIUS + 24.0)
	draw_surface.draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, primary_col)


func _draw_pause_button() -> void:
	var rect := Rect2(PAUSE_BUTTON_POS - PAUSE_BUTTON_SIZE * 0.5, PAUSE_BUTTON_SIZE)
	var border_col := Color(0.0, 0.94, 1.0, 0.45)
	var fill_col := Color(0.04, 0.12, 0.22, 0.4)
	
	draw_surface.draw_rect(rect, fill_col)
	draw_surface.draw_rect(rect, border_col, false, 2.0)
	
	# ❚❚ Pause bars
	var bar_w := 6.0
	var bar_h := 22.0
	var b1 := Rect2(PAUSE_BUTTON_POS.x - 9.0, PAUSE_BUTTON_POS.y - bar_h * 0.5, bar_w, bar_h)
	var b2 := Rect2(PAUSE_BUTTON_POS.x + 3.0, PAUSE_BUTTON_POS.y - bar_h * 0.5, bar_w, bar_h)
	draw_surface.draw_rect(b1, Color(0.0, 0.94, 1.0, 0.8))
	draw_surface.draw_rect(b2, Color(0.0, 0.94, 1.0, 0.8))

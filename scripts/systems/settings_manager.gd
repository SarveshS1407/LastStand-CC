extends Node

## Global Settings & Window Manager for Last Stand: Signal Break
## Handles window scaling, fullscreen toggle (F11), audio volume, screen shake, and persistence.

signal settings_changed()

const SETTINGS_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var screen_shake_enabled: bool = true
var is_fullscreen: bool = false
var touch_controls_mode: int = 0  # 0: Auto, 1: Always On, 2: Always Off

var base_resolution := Vector2i(1600, 900)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_apply_window_settings()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _apply_window_settings() -> void:
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return
		
	DisplayServer.window_set_min_size(Vector2i(1024, 576))
	
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var screen_id := DisplayServer.window_get_current_screen()
		var screen_size := DisplayServer.screen_get_size(screen_id)
		
		# On smaller desktop displays, clamp safely to 85% screen size
		var target_w := mini(base_resolution.x, int(screen_size.x * 0.88))
		var target_h := mini(base_resolution.y, int(screen_size.y * 0.88))
		var win_size := Vector2i(target_w, target_h)
		
		DisplayServer.window_set_size(win_size)
		var pos := (screen_size - win_size) / 2
		DisplayServer.window_set_position(pos)


func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen)


func set_fullscreen(enable: bool) -> void:
	is_fullscreen = enable
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_window_settings()
	save_settings()
	settings_changed.emit()


func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume) if master_volume > 0.001 else -80.0)
	save_settings()
	settings_changed.emit()


func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	save_settings()
	settings_changed.emit()


func set_screen_shake(enable: bool) -> void:
	screen_shake_enabled = enable
	save_settings()
	settings_changed.emit()


func set_touch_controls_mode(mode: int) -> void:
	touch_controls_mode = mode
	save_settings()
	settings_changed.emit()


func should_show_touch_controls() -> bool:
	if touch_controls_mode == 1:
		return true
	if touch_controls_mode == 2:
		return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web")


func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		master_volume = cfg.get_value("audio", "master_volume", 1.0)
		sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
		screen_shake_enabled = cfg.get_value("graphics", "screen_shake", true)
		is_fullscreen = cfg.get_value("graphics", "fullscreen", false)
		touch_controls_mode = cfg.get_value("controls", "touch_controls_mode", 0)
	set_master_volume(master_volume)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("graphics", "screen_shake", screen_shake_enabled)
	cfg.set_value("graphics", "fullscreen", is_fullscreen)
	cfg.set_value("controls", "touch_controls_mode", touch_controls_mode)
	cfg.save(SETTINGS_PATH)

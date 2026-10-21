class_name PauseMenu
extends Control

## In-game pause menu with resume, settings, restart, and quit options.

@onready var resume_btn: Button = $CenterContainer/Panel/Margin/VBox/ResumeBtn
@onready var settings_btn: Button = $CenterContainer/Panel/Margin/VBox/SettingsBtn
@onready var level_select_btn: Button = $CenterContainer/Panel/Margin/VBox/LevelSelectBtn
@onready var restart_btn: Button = $CenterContainer/Panel/Margin/VBox/RestartBtn
@onready var settings_dialog: Control = $SettingsDialog


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	settings_dialog.visible = false
	
	resume_btn.pressed.connect(_on_resume_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	level_select_btn.pressed.connect(_on_level_select_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and (gm.current_state == gm.GameState.GAME_OVER or gm.current_state == gm.GameState.VICTORY):
			return
			
		if settings_dialog.visible:
			settings_dialog.visible = false
			get_viewport().set_input_as_handled()
			return
			
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	set_paused(not get_tree().paused)


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if not paused:
		settings_dialog.visible = false


func _on_resume_pressed() -> void:
	set_paused(false)


func _on_settings_pressed() -> void:
	settings_dialog.visible = true


func _on_level_select_pressed() -> void:
	var hud = get_parent()
	if hud and hud.has_method("open_level_select"):
		set_paused(false)
		hud.open_level_select()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

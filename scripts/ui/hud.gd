class_name GameHUD
extends CanvasLayer

## Heads-Up Display and UI overlay manager for Last Stand: Signal Break.
## Displays shields, energy, uplink cores, waves, combos, score, and overlays.

@onready var shield_container: HBoxContainer = $MarginContainer/TopBar/LeftPanel/ShieldContainer
@onready var energy_bar: ProgressBar = $MarginContainer/TopBar/LeftPanel/EnergyBar
@onready var energy_status_label: Label = $MarginContainer/TopBar/LeftPanel/EnergyStatusLabel

@onready var wave_label: Label = $MarginContainer/TopBar/CenterPanel/WaveLabel
@onready var combo_label: Label = $MarginContainer/TopBar/CenterPanel/ComboLabel

@onready var cores_label: Label = $MarginContainer/TopBar/RightPanel/CoresLabel
@onready var cores_progress: ProgressBar = $MarginContainer/TopBar/RightPanel/CoresProgress
@onready var score_label: Label = $MarginContainer/TopBar/RightPanel/ScoreLabel
@onready var timer_label: Label = $MarginContainer/TopBar/RightPanel/TimerLabel
@onready var high_score_label: Label = $MarginContainer/TopBar/RightPanel/HighScoreLabel

@onready var controls_hint: Label = $MarginContainer/BottomBar/ControlsHint

# Overlays
@onready var briefing_overlay: Control = $Overlays/BriefingOverlay
@onready var game_over_overlay: Control = $Overlays/GameOverOverlay
@onready var victory_overlay: Control = $Overlays/VictoryOverlay
@onready var pause_menu: Control = $PauseMenu

@onready var game_over_summary: Label = $Overlays/GameOverOverlay/CenterContainer/Panel/VBoxContainer/SummaryLabel
@onready var victory_summary: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/VBoxContainer/SummaryLabel

var _shield_pips: Array[ColorRect] = []
var _combo_tween: Tween


func _ready() -> void:
	add_to_group("hud")
	_setup_shields(3)
	hide_all_overlays()
	combo_label.modulate.a = 0.0


func _setup_shields(max_hp: int) -> void:
	for child in shield_container.get_children():
		child.queue_free()
	_shield_pips.clear()
	
	for i in range(max_hp):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(26, 16)
		pip.color = Color(0.18, 0.75, 1.0, 1.0)
		shield_container.add_child(pip)
		_shield_pips.append(pip)


func update_health(current: int, max_hp: int) -> void:
	if _shield_pips.size() != max_hp:
		_setup_shields(max_hp)
	for i in range(_shield_pips.size()):
		if i < current:
			_shield_pips[i].color = Color(0.18, 0.75, 1.0, 1.0)
		else:
			_shield_pips[i].color = Color(0.25, 0.28, 0.35, 0.5)


func update_energy(current: float, max_ep: float, cooldown_active: bool = false, is_overcharged: bool = false) -> void:
	energy_bar.max_value = max_ep
	energy_bar.value = current
	
	var pct := int((current / max_ep) * 100.0)
	if is_overcharged:
		energy_status_label.text = "⚡ OVERCHARGE EMP READY [SPACE]"
		energy_status_label.modulate = Color(1.0, 0.9, 0.2)
	elif cooldown_active:
		energy_status_label.text = "DISRUPT [SPACE]: COOLDOWN (" + str(pct) + "%)"
		energy_status_label.modulate = Color(1.0, 0.8, 0.3)
	elif current < 25.0:
		energy_status_label.text = "DISRUPT [SPACE]: LOW ENERGY (" + str(pct) + "%)"
		energy_status_label.modulate = Color(1.0, 0.35, 0.35)
	else:
		energy_status_label.text = "DISRUPT [SPACE]: READY (" + str(pct) + "%)"
		energy_status_label.modulate = Color(0.3, 0.95, 1.0)


func update_wave(wave_num: int, wave_title: String) -> void:
	wave_label.text = "THREAT LEVEL " + str(wave_num) + ": " + wave_title.to_upper()


func show_combo(text: String) -> void:
	combo_label.text = text
	combo_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	if _combo_tween:
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.1)
	_combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15)
	_combo_tween.tween_interval(1.2)
	_combo_tween.tween_property(combo_label, "modulate:a", 0.0, 0.4)


func update_cores(collected: int, total_needed: int) -> void:
	cores_label.text = "SIGNAL CORES: " + str(collected) + " / " + str(total_needed)
	cores_progress.max_value = total_needed
	cores_progress.value = collected


func update_score(score: int) -> void:
	score_label.text = "SCORE: %05d" % score


func update_high_score(high_score: int) -> void:
	high_score_label.text = "BEST: %05d" % high_score


func update_timer(seconds: float) -> void:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	timer_label.text = "TIME: %02d:%02d" % [mins, secs]


func show_briefing() -> void:
	hide_all_overlays()
	briefing_overlay.visible = true


func hide_briefing() -> void:
	briefing_overlay.visible = false


func show_game_over(score: int, high_score: int, cores: int, total_cores: int, time: float) -> void:
	hide_all_overlays()
	game_over_overlay.visible = true
	var mins := int(time) / 60
	var secs := int(time) % 60
	var is_new_record := score > high_score and score > 0
	var record_str := "★ NEW BEST RECORD! ★\n" if is_new_record else ""
	game_over_summary.text = "%sCORES SECURED: %d / %d\nTIME SURVIVED: %02d:%02d\nFINAL SCORE: %d\nRECORD BEST: %d\n\nPRESS [ R ] TO RETRY   •   ESC: MENU" % [record_str, cores, total_cores, mins, secs, score, maxi(score, high_score)]


func show_victory(score: int, high_score: int, cores: int, time: float) -> void:
	hide_all_overlays()
	victory_overlay.visible = true
	var mins := int(time) / 60
	var secs := int(time) % 60
	var is_new_record := score > high_score and score > 0
	var record_str := "★ NEW BEST RECORD! ★\n" if is_new_record else ""
	victory_summary.text = "%sALL %d CORES SECURED!\nMISSION TIME: %02d:%02d\nFINAL SCORE: %d\nRECORD BEST: %d\n\nPRESS [ R ] TO PLAY AGAIN   •   ESC: MENU" % [record_str, cores, mins, secs, score, maxi(score, high_score)]


func hide_all_overlays() -> void:
	briefing_overlay.visible = false
	game_over_overlay.visible = false
	victory_overlay.visible = false

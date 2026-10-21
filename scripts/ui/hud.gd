class_name GameHUD
extends CanvasLayer

## Heads-Up Display and UI overlay manager for Last Stand: Signal Break.
## Displays shields, energy, uplink cores, waves, combos, score, level badges, and overlays.

@onready var shield_container: HBoxContainer = $MarginContainer/TopBar/LeftPanel/ShieldContainer
@onready var energy_bar: ProgressBar = $MarginContainer/TopBar/LeftPanel/EnergyBar
@onready var energy_status_label: Label = $MarginContainer/TopBar/LeftPanel/EnergyStatusLabel

@onready var level_badge: Label = $MarginContainer/TopBar/CenterPanel/LevelBadge
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
@onready var level_select_dialog: Control = $LevelSelectDialog

# Briefing Nodes
@onready var briefing_title: Label = $Overlays/BriefingOverlay/CenterContainer/Panel/Margin/VBox/Title
@onready var briefing_subtitle: Label = $Overlays/BriefingOverlay/CenterContainer/Panel/Margin/VBox/Subtitle
@onready var briefing_text: Label = $Overlays/BriefingOverlay/CenterContainer/Panel/Margin/VBox/BriefingText
@onready var start_mission_btn: Button = $Overlays/BriefingOverlay/CenterContainer/Panel/Margin/VBox/BriefingActions/StartMissionBtn
@onready var briefing_mission_select_btn: Button = $Overlays/BriefingOverlay/CenterContainer/Panel/Margin/VBox/BriefingActions/MissionSelectBtn

# Game Over Nodes
@onready var game_over_title: Label = $Overlays/GameOverOverlay/CenterContainer/Panel/Margin/VBoxContainer/Title
@onready var game_over_subtitle: Label = $Overlays/GameOverOverlay/CenterContainer/Panel/Margin/VBoxContainer/Subtitle
@onready var game_over_summary: Label = $Overlays/GameOverOverlay/CenterContainer/Panel/Margin/VBoxContainer/SummaryLabel
@onready var game_over_retry_btn: Button = $Overlays/GameOverOverlay/CenterContainer/Panel/Margin/VBoxContainer/GameOverActions/RetryBtn
@onready var game_over_select_btn: Button = $Overlays/GameOverOverlay/CenterContainer/Panel/Margin/VBoxContainer/GameOverActions/SelectMissionBtn

# Victory Nodes
@onready var victory_title: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/Title
@onready var victory_subtitle: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/Subtitle
@onready var victory_stars_label: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/StarsLabel
@onready var victory_stars_detail: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/StarsDetailLabel
@onready var victory_summary: Label = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/SummaryLabel
@onready var victory_next_btn: Button = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/VictoryActions/NextLevelBtn
@onready var victory_replay_btn: Button = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/VictoryActions/ReplayBtn
@onready var victory_select_btn: Button = $Overlays/VictoryOverlay/CenterContainer/Panel/Margin/VBoxContainer/VictoryActions/SelectMissionBtn

var _shield_pips: Array[ColorRect] = []
var _combo_tween: Tween


func _ready() -> void:
	add_to_group("hud")
	_setup_shields(3)
	hide_all_overlays()
	combo_label.modulate.a = 0.0
	_connect_overlay_buttons()
	_check_controls_hint()


func _check_controls_hint() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	var is_touch: bool = false
	if sm and sm.has_method("should_show_touch_controls"):
		is_touch = sm.should_show_touch_controls()
	else:
		is_touch = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
		
	if is_touch:
		controls_hint.text = "VIRTUAL THUMBSTICK: Move   •   EMP BUTTON: Disruption Pulse   •   ❚❚: Pause"
	else:
		controls_hint.text = "WASD / ARROWS: Move   •   SPACE: Disruption Pulse   •   ESC: Pause/Settings   •   F11: Fullscreen"


func _connect_overlay_buttons() -> void:
	# Briefing
	if start_mission_btn:
		start_mission_btn.pressed.connect(_on_start_mission_pressed)
	if briefing_mission_select_btn:
		briefing_mission_select_btn.pressed.connect(open_level_select)
		
	# Game Over
	if game_over_retry_btn:
		game_over_retry_btn.pressed.connect(_on_retry_pressed)
	if game_over_select_btn:
		game_over_select_btn.pressed.connect(open_level_select)
		
	# Victory
	if victory_next_btn:
		victory_next_btn.pressed.connect(_on_next_mission_pressed)
	if victory_replay_btn:
		victory_replay_btn.pressed.connect(_on_retry_pressed)
	if victory_select_btn:
		victory_select_btn.pressed.connect(open_level_select)


func _setup_shields(max_hp: int) -> void:
	for child in shield_container.get_children():
		child.queue_free()
	_shield_pips.clear()
	
	for i in range(max_hp):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(32, 18)
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


func update_level_badge(level_id: int, level_name: String) -> void:
	level_badge.text = "MISSION %02d: %s" % [level_id, level_name.to_upper()]


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


func setup_briefing(level_id: int, level_data: Dictionary) -> void:
	var lname: String = level_data.get("name", "Sector Infiltration")
	var stitle: String = level_data.get("stage_title", "Campaign Mission")
	var obj: String = level_data.get("objective", "Secure all signal fragments.")
	var par: float = level_data.get("par_time", 60.0)
	var cores: int = level_data.get("cores_needed", 12)
	
	briefing_title.text = "MISSION %02d: %s" % [level_id, lname.to_upper()]
	briefing_subtitle.text = stitle.to_upper()
	
	briefing_text.text = "TACTICAL OBJECTIVE:\n• %s\n• Required Cores: %d   • Par Extraction Time: %ds\n\nDISRUPTION PULSE [SPACE]:\n• Emits EMP shockwave that stuns hostiles in range.\n• Collect blue shield kits to repair and gold cells to overcharge!\n\nCONTROLS:\n• WASD / Arrows / Touch: Movement   • SPACE: EMP Pulse   • ESC: Menu" % [obj, cores, int(par)]


func show_briefing() -> void:
	hide_all_overlays()
	briefing_overlay.visible = true


func hide_briefing() -> void:
	briefing_overlay.visible = false


func show_game_over(level_id: int, level_name: String, score: int, high_score: int, cores: int, total_cores: int, time: float) -> void:
	hide_all_overlays()
	game_over_overlay.visible = true
	var mins := int(time) / 60
	var secs := int(time) % 60
	game_over_title.text = "MISSION %02d FAILED" % level_id
	game_over_subtitle.text = "%s — Operative shields depleted." % level_name.to_upper()
	game_over_summary.text = "CORES SECURED: %d / %d\nTIME SURVIVED: %02d:%02d\nFINAL SCORE: %d\nRECORD BEST: %d\n\nPRESS [ R ] TO RETRY   •   ESC: MENU" % [cores, total_cores, mins, secs, score, maxi(score, high_score)]


func show_victory(result: Dictionary, score: int, high_score: int, cores: int, time: float, health_remaining: int) -> void:
	hide_all_overlays()
	victory_overlay.visible = true
	var mins := int(time) / 60
	var secs := int(time) % 60
	var is_new_record := score > high_score and score > 0
	var record_str := "★ NEW BEST RECORD! ★\n" if is_new_record else ""
	
	var lvl_id: int = result.get("level_id", 1)
	var lvl_name: String = result.get("level_name", "Mission")
	var stars: int = result.get("stars_earned", 1)
	var par: float = result.get("par_time", 60.0)
	var is_campaign_complete: bool = result.get("is_campaign_complete", false)
	
	# Star string
	var star_str := ""
	for i in range(3):
		star_str += "★ " if i < stars else "☆ "
	victory_stars_label.text = star_str
	
	var star2_text := "✔ 2+ Shields Intact" if health_remaining >= 2 else "✖ Shields Depleted"
	var star3_text := "✔ Under Par (%ds)" % int(par) if time <= par else "✖ Par Time Exceeded (%ds)" % int(par)
	victory_stars_detail.text = "★ Level Cleared   •   %s   •   %s" % [star2_text, star3_text]
	
	if is_campaign_complete:
		victory_title.text = "★ CAMPAIGN VICTORY: FACILITY LIBERATED ★"
		victory_subtitle.text = "TITAN OVERMIND NEUTRALIZED! ALL 20 SECTORS SECURED!"
		var cm := _get_cm()
		var total_stars: int = cm.get_total_stars() if cm else 60
		victory_summary.text = "%sCAMPAIGN COMPLETE! TOTAL STARS: %d / 60 ⭐\nFINAL SCORE: %d\nRECORD BEST: %d\n\nCONGRATULATIONS OPERATIVE — OPERATION SIGNAL BREAK IS WON!" % [record_str, total_stars, score, maxi(score, high_score)]
		victory_next_btn.text = "CAMPAIGN SELECT ☰"
	else:
		victory_title.text = "MISSION %02d CLEARED" % lvl_id
		victory_subtitle.text = "%s — Extractions Uplink Established" % lvl_name.to_upper()
		victory_summary.text = "%sALL %d CORES SECURED!\nMISSION TIME: %02d:%02d (PAR: %ds)\nFINAL SCORE: %d\nRECORD BEST: %d\n\nSELECT ACTION BELOW OR PRESS [ R ] TO REPLAY" % [record_str, cores, mins, secs, int(par), score, maxi(score, high_score)]
		victory_next_btn.text = "NEXT MISSION ▶"


func hide_all_overlays() -> void:
	briefing_overlay.visible = false
	game_over_overlay.visible = false
	victory_overlay.visible = false
	if level_select_dialog:
		level_select_dialog.visible = false


func open_level_select() -> void:
	hide_all_overlays()
	if level_select_dialog:
		level_select_dialog.open()


func _on_start_mission_pressed() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("start_match"):
		gm.start_match()


func _get_cm() -> Node:
	return get_node_or_null("/root/CampaignManager")


func _on_retry_pressed() -> void:
	var cm := _get_cm()
	if cm:
		cm.restart_current_level()
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_next_mission_pressed() -> void:
	var cm := _get_cm()
	if cm:
		if cm.has_next_level() and not (cm.current_level_id == 20):
			cm.next_level()
		else:
			open_level_select()
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()

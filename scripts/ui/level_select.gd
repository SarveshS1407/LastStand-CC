class_name LevelSelectDialog
extends Control

## Level Selection Screen for Last Stand: Signal Break.
## Displays all 20 campaign levels divided into 5 tactical stages,
## showing lock/unlock status, star ratings (0-3), best scores, and continue shortcut.

signal level_selected(level_id: int)
signal closed()

@onready var close_btn: Button = $Margin/VBox/Header/CloseBtn
@onready var continue_btn: Button = $Margin/VBox/Footer/ContinueBtn
@onready var back_btn: Button = $Margin/VBox/Footer/BackBtn
@onready var stars_total_label: Label = $Margin/VBox/Header/StatsBox/StarsTotalLabel
@onready var progress_label: Label = $Margin/VBox/Header/StatsBox/ProgressLabel
@onready var progress_bar: ProgressBar = $Margin/VBox/Header/StatsBox/ProgressBar
@onready var grid_container: VBoxContainer = $Margin/VBox/ScrollContainer/StagesContainer

var campaign_mgr: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	close_btn.pressed.connect(_on_close_pressed)
	back_btn.pressed.connect(_on_close_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	
	_find_campaign_manager()
	if campaign_mgr and campaign_mgr.has_signal("campaign_progress_updated"):
		campaign_mgr.campaign_progress_updated.connect(refresh_levels)


func _find_campaign_manager() -> void:
	if CampaignManager.instance:
		campaign_mgr = CampaignManager.instance
	elif get_node_or_null("/root/CampaignManager"):
		campaign_mgr = get_node("/root/CampaignManager")


func open() -> void:
	_find_campaign_manager()
	refresh_levels()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func refresh_levels() -> void:
	if not campaign_mgr:
		_find_campaign_manager()
	if not campaign_mgr:
		return

	# Update Top Stats
	var total_stars: int = campaign_mgr.get_total_stars()
	var completed_count: int = campaign_mgr.completed_levels.size()
	var highest_unlocked: int = campaign_mgr.highest_unlocked_level
	
	stars_total_label.text = "⭐ %d / 60 STARS" % total_stars
	progress_label.text = "MISSIONS: %d / 20 CLEARED" % completed_count
	progress_bar.value = completed_count

	continue_btn.text = "▶ CONTINUE MISSION %02d" % highest_unlocked

	# Clear previous items
	for child in grid_container.get_children():
		child.queue_free()

	# Group levels by stage (5 stages of 4 levels each)
	var all_defs: Array = campaign_mgr.get_all_level_defs()
	var stage_groups := { 1: [], 2: [], 3: [], 4: [], 5: [] }
	for def in all_defs:
		var st: int = def.get("stage", 1)
		stage_groups[st].append(def)

	var stage_names := {
		1: "STAGE 1: THE BEGINNING — RECONNAISSANCE & DRILLS",
		2: "STAGE 2: RISING THREAT — ARMORED SECTOR ESCALATION",
		3: "STAGE 3: SURVIVAL UNDER PRESSURE — HUNTER PROTOCOL",
		4: "STAGE 4: LAST STAND — BLACKOUT SQUADRON ELITES",
		5: "STAGE 5: THE FINAL ASSAULT — FACILITY CORE OVERMIND"
	}

	for stage_num in range(1, 6):
		var stage_levels: Array = stage_groups[stage_num]
		if stage_levels.is_empty():
			continue

		# Stage Header
		var header_label := Label.new()
		header_label.text = stage_names.get(stage_num, "STAGE %d" % stage_num)
		header_label.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
		header_label.add_theme_font_size_override("font_size", 15)
		grid_container.add_child(header_label)

		# Stage Grid for 4 Levels
		var h_grid := HFlowContainer.new()
		h_grid.add_theme_constant_override("h_separation", 14)
		h_grid.add_theme_constant_override("v_separation", 14)
		grid_container.add_child(h_grid)

		for def in stage_levels:
			var lvl_id: int = def["id"]
			var card := _create_level_card(def, lvl_id, highest_unlocked)
			h_grid.add_child(card)

		# Separator
		if stage_num < 5:
			var sep := HSeparator.new()
			sep.custom_minimum_size = Vector2(0, 10)
			grid_container.add_child(sep)


func _create_level_card(def: Dictionary, lvl_id: int, highest_unlocked: int) -> Control:
	var is_unlocked: bool = lvl_id <= highest_unlocked
	var rec: Dictionary = campaign_mgr.completed_levels.get(lvl_id, {})
	var is_completed: bool = rec.get("completed", false)
	var stars: int = rec.get("stars", 0)
	var is_boss: bool = (lvl_id == 20)
	var is_milestone: bool = (lvl_id in [4, 8, 12, 16, 20])

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 130)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Level Header: Number + Name + Status Badge
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)

	var title_lbl := Label.new()
	title_lbl.text = "%02d: %s" % [lvl_id, def.get("name", "Level %d" % lvl_id)]
	title_lbl.add_theme_font_size_override("font_size", 14)
	if is_boss:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
		title_lbl.text = "👑 " + title_lbl.text
	elif is_milestone:
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.25))
	elif is_unlocked:
		title_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	else:
		title_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	top_row.add_child(title_lbl)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	# Status icon / text
	var status_lbl := Label.new()
	status_lbl.add_theme_font_size_override("font_size", 12)
	if not is_unlocked:
		status_lbl.text = "🔒 LOCKED"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	elif is_completed:
		status_lbl.text = "✔ CLEARED"
		status_lbl.add_theme_color_override("font_color", Color(0.2, 0.95, 0.6))
	else:
		status_lbl.text = "ACTIVE"
		status_lbl.add_theme_color_override("font_color", Color(0.0, 0.94, 1.0))
	top_row.add_child(status_lbl)

	# Stars row
	var star_str := ""
	if is_unlocked:
		for s in range(3):
			star_str += "★ " if s < stars else "☆ "
	var stars_lbl := Label.new()
	stars_lbl.text = star_str if is_unlocked else "☆ ☆ ☆"
	stars_lbl.add_theme_font_size_override("font_size", 14)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.1) if stars > 0 else Color(0.4, 0.45, 0.55))
	vbox.add_child(stars_lbl)

	# Objective / Best record text
	var info_lbl := Label.new()
	info_lbl.add_theme_font_size_override("font_size", 11)
	if not is_unlocked:
		info_lbl.text = "Clear preceding sector mission to decrypt."
		info_lbl.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
	elif is_completed:
		var best_s: int = rec.get("best_score", 0)
		var best_t: float = rec.get("best_time", 0.0)
		info_lbl.text = "Cores: %d  •  Best: %d pts  •  Time: %02d:%02d" % [def.get("cores_needed", 12), best_s, int(best_t)/60, int(best_t)%60]
		info_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9))
	else:
		info_lbl.text = "Objective: Retrieve %d Energy Cores (Par: %ds)" % [def.get("cores_needed", 12), int(def.get("par_time", 60))]
		info_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(info_lbl)

	# Launch button
	var btn := Button.new()
	btn.text = "DEPLOY MISSION" if is_unlocked else "LOCKED"
	btn.disabled = not is_unlocked
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 12)
	if is_unlocked:
		btn.pressed.connect(func(): _on_level_card_pressed(lvl_id))
	vbox.add_child(btn)

	return panel


func _on_level_card_pressed(lvl_id: int) -> void:
	close()
	level_selected.emit(lvl_id)
	if campaign_mgr:
		campaign_mgr.start_level(lvl_id)


func _on_continue_pressed() -> void:
	close()
	if campaign_mgr:
		campaign_mgr.start_level(campaign_mgr.highest_unlocked_level)


func _on_close_pressed() -> void:
	close()

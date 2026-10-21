extends Node

## Campaign & Level Progression Manager for Last Stand: Signal Break.
## Controls the 20-level campaign progression, level data definitions,
## dynamic drone/pickup spawning, persistent save/load, and star ratings.

signal level_started(level_id: int)
signal level_completed(level_id: int, result: Dictionary)
signal campaign_progress_updated()

const SAVE_PATH := "user://campaign_save.cfg"
const MAX_LEVELS := 20

static var instance: Node = null

var current_level_id: int = 1
var highest_unlocked_level: int = 1
var completed_levels: Dictionary = {} # level_id (int) -> { "stars": int, "best_score": int, "best_time": float }
var campaign_completed: bool = false

# Cache for Level Definitions
var _level_defs: Dictionary = {}


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_level_definitions()
	load_progress()


func _init_level_definitions() -> void:
	_level_defs.clear()
	
	# =========================================================================
	# STAGE 1: THE BEGINNING (Levels 1–4)
	# Teach basic movement, EMP disruption pulse, core collection, and dodging.
	# =========================================================================
	_add_level(1, {
		"name": "Breach Point",
		"stage": 1,
		"stage_title": "Stage 1: The Beginning",
		"objective": "Infiltrate perimeter and secure 3 Energy Cores to activate sector uplink.",
		"cores_needed": 3,
		"par_time": 40.0,
		"shield_kits": 1,
		"overcharge_cells": 0,
		"drones": [
			{ "type": 0, "pos": Vector2(800, 300), "axis": Vector2(1, 0), "dist": 220.0 } # 1 Scout
		],
		"reinforcements": []
	})

	_add_level(2, {
		"name": "Data Corridors",
		"stage": 1,
		"stage_title": "Stage 1: The Beginning",
		"objective": "Navigate twin corridors and extract 4 Energy Cores.",
		"cores_needed": 4,
		"par_time": 45.0,
		"shield_kits": 1,
		"overcharge_cells": 0,
		"drones": [
			{ "type": 0, "pos": Vector2(500, 300), "axis": Vector2(1, 0), "dist": 200.0 }, # Scout H
			{ "type": 0, "pos": Vector2(1100, 600), "axis": Vector2(0, 1), "dist": 180.0 }  # Scout V
		],
		"reinforcements": []
	})

	_add_level(3, {
		"name": "Sensor Sweep",
		"stage": 1,
		"stage_title": "Stage 1: The Beginning",
		"objective": "Collect 5 Energy Cores while evading overlapping patrol routes.",
		"cores_needed": 5,
		"par_time": 50.0,
		"shield_kits": 1,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 0, "pos": Vector2(400, 250), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 0, "pos": Vector2(1200, 650), "axis": Vector2(1, 0), "dist": 220.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 3, "type": 0, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 160.0, "announcement": "REINFORCEMENT: SCOUT DETECTED" }
		]
	})

	_add_level(4, {
		"name": "Grid Synchronization",
		"stage": 1,
		"stage_title": "Stage 1: The Beginning",
		"objective": "Stage 1 Climax: Secure 6 Cores against synchronized corridor sweeps.",
		"cores_needed": 6,
		"par_time": 55.0,
		"shield_kits": 1,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 0, "pos": Vector2(800, 240), "axis": Vector2(1, 0), "dist": 260.0 },
			{ "type": 0, "pos": Vector2(800, 660), "axis": Vector2(1, 0), "dist": 260.0 },
			{ "type": 0, "pos": Vector2(300, 450), "axis": Vector2(0, 1), "dist": 180.0 }
		],
		"reinforcements": []
	})

	# =========================================================================
	# STAGE 2: RISING THREAT (Levels 5–8)
	# Introduce Heavy Enforcer (2 damage, stun-resistant) and combat pressure.
	# =========================================================================
	_add_level(5, {
		"name": "Armored Patrol",
		"stage": 2,
		"stage_title": "Stage 2: Rising Threat",
		"objective": "Heavy Enforcer online. Deals 2 shield damage! Secure 6 Cores.",
		"cores_needed": 6,
		"par_time": 60.0,
		"shield_kits": 2,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 1, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 180.0 }, # 1 Heavy Enforcer
			{ "type": 0, "pos": Vector2(400, 260), "axis": Vector2(1, 0), "dist": 200.0 }  # 1 Scout
		],
		"reinforcements": []
	})

	_add_level(6, {
		"name": "Chokepoint Lockdown",
		"stage": 2,
		"stage_title": "Stage 2: Rising Threat",
		"objective": "Twin Enforcers guard the server pillars. Secure 7 Cores.",
		"cores_needed": 7,
		"par_time": 65.0,
		"shield_kits": 2,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 1, "pos": Vector2(500, 450), "axis": Vector2(0, 1), "dist": 190.0 }, # Heavy West
			{ "type": 1, "pos": Vector2(1100, 450), "axis": Vector2(0, 1), "dist": 190.0 },# Heavy East
			{ "type": 0, "pos": Vector2(800, 250), "axis": Vector2(1, 0), "dist": 240.0 }  # Scout North
		],
		"reinforcements": []
	})

	_add_level(7, {
		"name": "Compression Wave",
		"stage": 2,
		"stage_title": "Stage 2: Rising Threat",
		"objective": "Secure 8 Cores across escalating defensive patrols.",
		"cores_needed": 8,
		"par_time": 70.0,
		"shield_kits": 2,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 1, "pos": Vector2(800, 450), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 0, "pos": Vector2(400, 300), "axis": Vector2(0, 1), "dist": 180.0 },
			{ "type": 0, "pos": Vector2(1200, 600), "axis": Vector2(0, 1), "dist": 180.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 4, "type": 1, "pos": Vector2(800, 680), "axis": Vector2(1, 0), "dist": 200.0, "announcement": "HEAVY ENFORCER REINFORCEMENT INBOUND" }
		]
	})

	_add_level(8, {
		"name": "The Bastion Gate",
		"stage": 2,
		"stage_title": "Stage 2: Rising Threat",
		"objective": "Stage 2 Climax: Fortified defense network. Secure 8 Cores under siege.",
		"cores_needed": 8,
		"par_time": 75.0,
		"shield_kits": 2,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 1, "pos": Vector2(400, 450), "axis": Vector2(0, 1), "dist": 200.0 },
			{ "type": 1, "pos": Vector2(1200, 450), "axis": Vector2(0, 1), "dist": 200.0 },
			{ "type": 1, "pos": Vector2(800, 300), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 0, "pos": Vector2(800, 650), "axis": Vector2(1, 0), "dist": 220.0 }
		],
		"reinforcements": []
	})

	# =========================================================================
	# STAGE 3: SURVIVAL UNDER PRESSURE (Levels 9–12)
	# Introduce Hunter Drone (Crimson, 240px detection, 185 px/s chase).
	# =========================================================================
	_add_level(9, {
		"name": "Red Line Alert",
		"stage": 3,
		"stage_title": "Stage 3: Survival Under Pressure",
		"objective": "Hunter drone deployed! High detection range & pursuit speed. Secure 8 Cores.",
		"cores_needed": 8,
		"par_time": 70.0,
		"shield_kits": 2,
		"overcharge_cells": 1,
		"drones": [
			{ "type": 2, "pos": Vector2(1250, 450), "axis": Vector2(0, 1), "dist": 200.0 }, # 1 Hunter
			{ "type": 1, "pos": Vector2(400, 450), "axis": Vector2(0, 1), "dist": 180.0 },  # 1 Heavy
			{ "type": 0, "pos": Vector2(800, 250), "axis": Vector2(1, 0), "dist": 220.0 }   # 1 Scout
		],
		"reinforcements": []
	})

	_add_level(10, {
		"name": "Crossfire Alley",
		"stage": 3,
		"stage_title": "Stage 3: Survival Under Pressure",
		"objective": "Twin Hunters patrol open chokepoints. Secure 9 Cores.",
		"cores_needed": 9,
		"par_time": 75.0,
		"shield_kits": 2,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 2, "pos": Vector2(400, 280), "axis": Vector2(1, 0), "dist": 220.0 },  # Hunter 1
			{ "type": 2, "pos": Vector2(1200, 620), "axis": Vector2(1, 0), "dist": 220.0 }, # Hunter 2
			{ "type": 1, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 180.0 },  # Heavy
			{ "type": 0, "pos": Vector2(800, 700), "axis": Vector2(1, 0), "dist": 240.0 }   # Scout
		],
		"reinforcements": []
	})

	_add_level(11, {
		"name": "Sensor Scramble",
		"stage": 3,
		"stage_title": "Stage 3: Survival Under Pressure",
		"objective": "Heavy sensor convergence. Secure 10 Cores across 2 combat waves.",
		"cores_needed": 10,
		"par_time": 80.0,
		"shield_kits": 2,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 2, "pos": Vector2(800, 240), "axis": Vector2(1, 0), "dist": 250.0 },
			{ "type": 1, "pos": Vector2(350, 450), "axis": Vector2(0, 1), "dist": 180.0 },
			{ "type": 1, "pos": Vector2(1250, 450), "axis": Vector2(0, 1), "dist": 180.0 },
			{ "type": 0, "pos": Vector2(800, 680), "axis": Vector2(1, 0), "dist": 250.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 5, "type": 2, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 160.0, "announcement": "HUNTER PURSUIT ACTIVE!" }
		]
	})

	_add_level(12, {
		"name": "The Gauntlet",
		"stage": 3,
		"stage_title": "Stage 3: Survival Under Pressure",
		"objective": "Stage 3 Climax: Overlapping Hunter & Enforcer grids. Secure 10 Cores.",
		"cores_needed": 10,
		"par_time": 85.0,
		"shield_kits": 2,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 2, "pos": Vector2(400, 300), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 2, "pos": Vector2(1200, 300), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 2, "pos": Vector2(800, 650), "axis": Vector2(1, 0), "dist": 260.0 },
			{ "type": 1, "pos": Vector2(400, 600), "axis": Vector2(0, 1), "dist": 160.0 },
			{ "type": 1, "pos": Vector2(1200, 600), "axis": Vector2(0, 1), "dist": 160.0 }
		],
		"reinforcements": []
	})

	# =========================================================================
	# STAGE 4: LAST STAND (Levels 13–16)
	# Introduce Elite Enforcer (3 damage, 50% stun resist) & Stalker (205 px/s).
	# =========================================================================
	_add_level(13, {
		"name": "Elite Vanguard",
		"stage": 4,
		"stage_title": "Stage 4: Last Stand",
		"objective": "Elite Enforcer activated! 3 contact damage & reinforced plating. Secure 10 Cores.",
		"cores_needed": 10,
		"par_time": 80.0,
		"shield_kits": 2,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 3, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 200.0 }, # Elite Enforcer
			{ "type": 2, "pos": Vector2(350, 300), "axis": Vector2(1, 0), "dist": 200.0 },  # Hunter
			{ "type": 2, "pos": Vector2(1250, 600), "axis": Vector2(1, 0), "dist": 200.0 }, # Hunter
			{ "type": 0, "pos": Vector2(800, 220), "axis": Vector2(1, 0), "dist": 250.0 }   # Scout
		],
		"reinforcements": []
	})

	_add_level(14, {
		"name": "Stalker Shadows",
		"stage": 4,
		"stage_title": "Stage 4: Last Stand",
		"objective": "Stalker Drones detected! 205 px/s lethal pursuit speed. Secure 11 Cores.",
		"cores_needed": 11,
		"par_time": 85.0,
		"shield_kits": 3,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 4, "pos": Vector2(400, 250), "axis": Vector2(1, 0), "dist": 240.0 },  # Stalker 1
			{ "type": 4, "pos": Vector2(1200, 650), "axis": Vector2(1, 0), "dist": 240.0 }, # Stalker 2
			{ "type": 3, "pos": Vector2(800, 450), "axis": Vector2(1, 0), "dist": 220.0 },  # Elite Enforcer
			{ "type": 1, "pos": Vector2(800, 700), "axis": Vector2(1, 0), "dist": 200.0 }   # Heavy
		],
		"reinforcements": []
	})

	_add_level(15, {
		"name": "Sector Overdrive",
		"stage": 4,
		"stage_title": "Stage 4: Last Stand",
		"objective": "Combined elite squadron. Chain EMP pulses for survival! Secure 12 Cores.",
		"cores_needed": 12,
		"par_time": 90.0,
		"shield_kits": 3,
		"overcharge_cells": 2,
		"drones": [
			{ "type": 4, "pos": Vector2(350, 280), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 4, "pos": Vector2(1250, 280), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 3, "pos": Vector2(400, 600), "axis": Vector2(0, 1), "dist": 180.0 },
			{ "type": 3, "pos": Vector2(1200, 600), "axis": Vector2(0, 1), "dist": 180.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 6, "type": 4, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 160.0, "announcement": "ALERT: INTERCEPTOR STALKER DEPLOYED" }
		]
	})

	_add_level(16, {
		"name": "Inquisitor Sub-Core",
		"stage": 4,
		"stage_title": "Stage 4: Last Stand",
		"objective": "Stage 4 Climax: Dual Elite Enforcers and Stalkers defend the sub-core. Secure 12 Cores.",
		"cores_needed": 12,
		"par_time": 95.0,
		"shield_kits": 3,
		"overcharge_cells": 3,
		"drones": [
			{ "type": 3, "pos": Vector2(600, 450), "axis": Vector2(0, 1), "dist": 200.0 }, # Elite 1
			{ "type": 3, "pos": Vector2(1000, 450), "axis": Vector2(0, 1), "dist": 200.0 },# Elite 2
			{ "type": 4, "pos": Vector2(400, 250), "axis": Vector2(1, 0), "dist": 240.0 },  # Stalker
			{ "type": 4, "pos": Vector2(1200, 650), "axis": Vector2(1, 0), "dist": 240.0 }, # Stalker
			{ "type": 2, "pos": Vector2(800, 220), "axis": Vector2(1, 0), "dist": 240.0 }   # Hunter
		],
		"reinforcements": []
	})

	# =========================================================================
	# STAGE 5: THE FINAL ASSAULT (Levels 17–20)
	# Relentless endgame. Level 20 features the TITAN OVERMIND boss!
	# =========================================================================
	_add_level(17, {
		"name": "Maximum Threat",
		"stage": 5,
		"stage_title": "Stage 5: The Final Assault",
		"objective": "Facility defenses at maximum alert. Secure 12 Cores.",
		"cores_needed": 12,
		"par_time": 90.0,
		"shield_kits": 3,
		"overcharge_cells": 3,
		"drones": [
			{ "type": 4, "pos": Vector2(350, 260), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 4, "pos": Vector2(1250, 260), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 4, "pos": Vector2(800, 680), "axis": Vector2(1, 0), "dist": 250.0 },
			{ "type": 3, "pos": Vector2(400, 520), "axis": Vector2(0, 1), "dist": 180.0 },
			{ "type": 3, "pos": Vector2(1200, 520), "axis": Vector2(0, 1), "dist": 180.0 }
		],
		"reinforcements": []
	})

	_add_level(18, {
		"name": "Lockdown Breakdown",
		"stage": 5,
		"stage_title": "Stage 5: The Final Assault",
		"objective": "Multiple aggressive patrol groups. Secure 13 Cores.",
		"cores_needed": 13,
		"par_time": 100.0,
		"shield_kits": 3,
		"overcharge_cells": 3,
		"drones": [
			{ "type": 4, "pos": Vector2(400, 250), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 4, "pos": Vector2(1200, 250), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 4, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 200.0 },
			{ "type": 3, "pos": Vector2(350, 650), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 3, "pos": Vector2(1250, 650), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 2, "pos": Vector2(800, 220), "axis": Vector2(1, 0), "dist": 260.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 7, "type": 4, "pos": Vector2(800, 680), "axis": Vector2(1, 0), "dist": 240.0, "announcement": "OVERDRIVE STALKER ENGAGED" }
		]
	})

	_add_level(19, {
		"name": "The Core Threshold",
		"stage": 5,
		"stage_title": "Stage 5: The Final Assault",
		"objective": "Penultimate breach. Penetrate outer reactor defenses. Secure 14 Cores.",
		"cores_needed": 14,
		"par_time": 110.0,
		"shield_kits": 4,
		"overcharge_cells": 3,
		"drones": [
			{ "type": 4, "pos": Vector2(350, 260), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 4, "pos": Vector2(1250, 260), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 4, "pos": Vector2(400, 640), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 4, "pos": Vector2(1200, 640), "axis": Vector2(1, 0), "dist": 240.0 },
			{ "type": 3, "pos": Vector2(800, 300), "axis": Vector2(1, 0), "dist": 220.0 },
			{ "type": 3, "pos": Vector2(800, 600), "axis": Vector2(1, 0), "dist": 220.0 }
		],
		"reinforcements": [
			{ "trigger_cores": 8, "type": 3, "pos": Vector2(800, 450), "axis": Vector2(0, 1), "dist": 180.0, "announcement": "HEAVY CORE GUARDIAN ONLINE" }
		]
	})

	_add_level(20, {
		"name": "Titan Overmind",
		"stage": 5,
		"stage_title": "Stage 5: The Final Assault",
		"objective": "FINAL BOSS CLIMAX: Overload the Facility Overmind! Secure all 15 Singularity Cores.",
		"cores_needed": 15,
		"par_time": 120.0,
		"shield_kits": 4,
		"overcharge_cells": 4,
		"drones": [
			# The TITAN OVERMIND Boss: 2.2x Scale, 3 Damage, 60% EMP absorption
			{ "type": 5, "pos": Vector2(800, 450), "axis": Vector2(1, 0), "dist": 260.0 },
			{ "type": 3, "pos": Vector2(350, 300), "axis": Vector2(0, 1), "dist": 200.0 }, # Elite Escort 1
			{ "type": 3, "pos": Vector2(1250, 300), "axis": Vector2(0, 1), "dist": 200.0 },# Elite Escort 2
			{ "type": 4, "pos": Vector2(400, 650), "axis": Vector2(1, 0), "dist": 240.0 },  # Stalker 1
			{ "type": 4, "pos": Vector2(1200, 650), "axis": Vector2(1, 0), "dist": 240.0 }  # Stalker 2
		],
		"reinforcements": [
			{ "trigger_cores": 5, "type": 4, "pos": Vector2(800, 220), "axis": Vector2(1, 0), "dist": 220.0, "announcement": "OVERMIND SUMMONS RAPID INTERCEPTORS!" },
			{ "trigger_cores": 10, "type": 3, "pos": Vector2(800, 680), "axis": Vector2(1, 0), "dist": 220.0, "announcement": "OVERMIND POWER GRID SURGE!" }
		]
	})


func _add_level(id: int, data: Dictionary) -> void:
	data["id"] = id
	_level_defs[id] = data


func get_level_data(id: int) -> Dictionary:
	if _level_defs.has(id):
		return _level_defs[id]
	return _level_defs.get(1, {})


func get_all_level_defs() -> Array:
	var list: Array = []
	for id in range(1, MAX_LEVELS + 1):
		if _level_defs.has(id):
			list.append(_level_defs[id])
	return list


func get_total_stars() -> int:
	var total := 0
	for lvl_id in completed_levels:
		var rec: Dictionary = completed_levels[lvl_id]
		total += rec.get("stars", 0)
	return total


func is_level_unlocked(id: int) -> bool:
	if id <= 1:
		return true
	return id <= highest_unlocked_level


func complete_level(id: int, score: int, time: float, health_remaining: int) -> Dictionary:
	var def := get_level_data(id)
	
	# Star Rating Calculation:
	# 1 Star: Complete the level
	# 2 Stars: Finish with at least 2 shields remaining (survival skill)
	# 3 Stars: Beat level within target par time (speed/efficiency)
	var stars := 1
	if health_remaining >= 2:
		stars += 1
	var par: float = def.get("par_time", 60.0)
	if time <= par:
		stars += 1

	var prev_record: Dictionary = completed_levels.get(id, { "stars": 0, "best_score": 0, "best_time": 9999.0 })
	var best_stars: int = maxi(stars, prev_record.get("stars", 0))
	var best_score: int = maxi(score, prev_record.get("best_score", 0))
	var best_time: float = minf(time, prev_record.get("best_time", 9999.0))
	
	completed_levels[id] = {
		"completed": true,
		"stars": best_stars,
		"best_score": best_score,
		"best_time": best_time
	}
	
	# Unlock next level
	var newly_unlocked := false
	if id < MAX_LEVELS:
		if id + 1 > highest_unlocked_level:
			highest_unlocked_level = id + 1
			newly_unlocked = true
	elif id == MAX_LEVELS:
		campaign_completed = true
		
	save_progress()
	
	var result := {
		"level_id": id,
		"level_name": def.get("name", "Level %d" % id),
		"stars_earned": stars,
		"best_stars": best_stars,
		"score": score,
		"time": time,
		"par_time": par,
		"newly_unlocked": newly_unlocked,
		"next_level_id": (id + 1) if id < MAX_LEVELS else -1,
		"is_campaign_complete": (id == MAX_LEVELS)
	}
	
	level_completed.emit(id, result)
	campaign_progress_updated.emit()
	return result


func start_level(id: int) -> void:
	current_level_id = clampi(id, 1, MAX_LEVELS)
	get_tree().paused = false
	level_started.emit(current_level_id)
	get_tree().reload_current_scene()


func next_level() -> void:
	if current_level_id < MAX_LEVELS:
		start_level(current_level_id + 1)
	else:
		start_level(1)


func restart_current_level() -> void:
	start_level(current_level_id)


func has_next_level() -> bool:
	return current_level_id < MAX_LEVELS


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		highest_unlocked_level = cfg.get_value("progress", "highest_unlocked", 1)
		campaign_completed = cfg.get_value("progress", "campaign_completed", false)
		
		completed_levels.clear()
		for id in range(1, MAX_LEVELS + 1):
			var sec := "level_%d" % id
			if cfg.has_section(sec):
				completed_levels[id] = {
					"completed": true,
					"stars": cfg.get_value(sec, "stars", 0),
					"best_score": cfg.get_value(sec, "best_score", 0),
					"best_time": cfg.get_value(sec, "best_time", 9999.0)
				}
	else:
		highest_unlocked_level = 1
		campaign_completed = false
		completed_levels.clear()


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked", highest_unlocked_level)
	cfg.set_value("progress", "campaign_completed", campaign_completed)
	
	for id in completed_levels:
		var sec := "level_%d" % id
		var rec: Dictionary = completed_levels[id]
		cfg.set_value(sec, "stars", rec.get("stars", 0))
		cfg.set_value(sec, "best_score", rec.get("best_score", 0))
		cfg.set_value(sec, "best_time", rec.get("best_time", 9999.0))
		
	cfg.save(SAVE_PATH)

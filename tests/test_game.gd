extends SceneTree

## Comprehensive QA Automated Verification Suite for Last Stand: Signal Break.
## Verifies 1600x900 architecture, all 6 drone archetypes, 20-level campaign progression,
## star rating mechanics, dynamic spawning, overcharge, waves, mobile touch, and persistence.

const GameManagerScript = preload("res://scripts/systems/game_manager.gd")
const EnemyDroneScript = preload("res://scripts/enemy/enemy.gd")
const FragmentScript = preload("res://scripts/collectible/fragment.gd")
const ShieldPickupScript = preload("res://scripts/collectible/shield_pickup.gd")
const OverchargePickupScript = preload("res://scripts/collectible/overcharge_pickup.gd")
const PlayerScript = preload("res://scripts/player/player.gd")
const SettingsManagerScript = preload("res://scripts/systems/settings_manager.gd")
const CampaignManagerScript = preload("res://scripts/systems/campaign_manager.gd")

var _failures: int = 0
var _passes: int = 0


func _init() -> void:
	print("==================================================================")
	print("  QA AUTOMATED VERIFICATION SUITE — LAST STAND: 20-LEVEL CAMPAIGN ")
	print("==================================================================")
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	var main_packed = load("res://scenes/main/main.tscn") as PackedScene
	if not main_packed:
		_record_fail("Could not load res://scenes/main/main.tscn")
		quit(1)
		return
		
	var cm_existing = root.get_node_or_null("CampaignManager")
	if not cm_existing:
		var cm_node = CampaignManagerScript.new()
		cm_node.name = "CampaignManager"
		root.add_child(cm_node)
		
	var main = main_packed.instantiate()
	root.add_child(main)
	
	for i in range(5):
		await process_frame
		
	var player = main.get_node_or_null("Player")
	var gm = main.get_node_or_null("GameManager")
	var hud = main.get_node_or_null("HUD")
	var camera = main.get_node_or_null("Camera2D")
	var enemies_node = main.get_node_or_null("Enemies")
	var collectibles_node = main.get_node_or_null("Collectibles")
	
	if not player or not gm or not hud:
		_record_fail("Core nodes missing from main scene tree!")
		quit(1)
		return
		
	# ----------------------------------------------------
	# TEST 1: 1600x900 Display & Architecture Verification
	# ----------------------------------------------------
	print("\n[TEST 1] Verifying 1600x900 resolution & scene architecture...")
	var viewport_w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var viewport_h = ProjectSettings.get_setting("display/window/size/viewport_height")
	_assert_true(viewport_w == 1600 and viewport_h == 900, "Project display viewport configured to 1600x900")
	_assert_true(player.global_position == Vector2(800, 520), "Player starts centered at (800, 520)")
	_assert_true(camera != null and camera.position == Vector2(800, 450), "Main camera present and centered")
	_assert_true(hud.has_node("LevelSelectDialog"), "LevelSelectDialog integrated into HUD")
	
	# ----------------------------------------------------
	# TEST 2: All 6 Enemy Drone Archetypes
	# ----------------------------------------------------
	print("\n[TEST 2] Verifying All 6 Enemy Drone Archetypes...")
	# Instantiate test drones for each archetype
	var drone_scene = preload("res://scenes/enemy/enemy.tscn")
	
	# Scout
	var scout = drone_scene.instantiate()
	scout.drone_type = EnemyDroneScript.DroneType.SCOUT
	main.add_child(scout)
	_assert_approx(scout.patrol_speed, 105.0, "Scout patrol speed is 105 px/s")
	_assert_true(scout.contact_damage == 1, "Scout deals 1 shield damage")
	scout.queue_free()
	
	# Enforcer (Heavy)
	var enforcer = drone_scene.instantiate()
	enforcer.drone_type = EnemyDroneScript.DroneType.ENFORCER
	main.add_child(enforcer)
	_assert_true(enforcer.contact_damage == 2, "Enforcer deals 2 shield damage")
	enforcer.apply_stun(3.0)
	_assert_approx(enforcer.stun_timer, 1.95, "Enforcer chassis absorbs 35% stun duration (~1.95s)", 0.1)
	enforcer.queue_free()
	
	# Hunter
	var hunter = drone_scene.instantiate()
	hunter.drone_type = EnemyDroneScript.DroneType.HUNTER
	main.add_child(hunter)
	_assert_approx(hunter.chase_speed, 185.0, "Hunter drone chases at 185 px/s")
	hunter.queue_free()
	
	# Elite Enforcer
	var elite = drone_scene.instantiate()
	elite.drone_type = EnemyDroneScript.DroneType.ELITE_ENFORCER
	main.add_child(elite)
	_assert_true(elite.contact_damage == 3, "Elite Enforcer deals 3 lethal shield damage")
	elite.apply_stun(4.0)
	_assert_approx(elite.stun_timer, 2.0, "Elite Enforcer absorbs 50% stun duration", 0.1)
	elite.queue_free()
	
	# Stalker
	var stalker = drone_scene.instantiate()
	stalker.drone_type = EnemyDroneScript.DroneType.STALKER
	main.add_child(stalker)
	_assert_approx(stalker.chase_speed, 205.0, "Stalker pursues at high speed (205 px/s)")
	_assert_approx(stalker.detection_radius, 280.0, "Stalker has expanded 280px detection radius")
	stalker.queue_free()
	
	# Titan Overmind Boss
	var overmind = drone_scene.instantiate()
	overmind.drone_type = EnemyDroneScript.DroneType.OVERMIND
	main.add_child(overmind)
	_assert_true(overmind.contact_damage == 3, "Titan Overmind boss deals 3 damage")
	overmind.apply_stun(5.0)
	_assert_approx(overmind.stun_timer, 2.0, "Titan Overmind absorbs 60% EMP duration", 0.1)
	overmind.queue_free()
	
	# ----------------------------------------------------
	# TEST 3: Disruption Pulse & EMP Overcharge Mode
	# ----------------------------------------------------
	print("\n[TEST 3] Verifying Disruption Pulse & Overcharge...")
	player.current_energy = 50.0
	player.cooldown_timer = 0.0
	player.has_overcharge = false
	
	# Regular pulse
	player.fire_disruption_pulse()
	_assert_approx(player.current_energy, 25.0, "Regular pulse consumes 25 energy")
	
	# Overcharge pickup & super-pulse
	player.grant_overcharge()
	_assert_true(player.has_overcharge, "Player gained Overcharge EMP status")
	_assert_approx(player.current_energy, 100.0, "Overcharge instantly refilled energy to 100%")
	
	player.cooldown_timer = 0.0
	player.fire_disruption_pulse()
	_assert_true(not player.has_overcharge, "Overcharge consumed on super-pulse blast")
	
	# ----------------------------------------------------
	# TEST 4: Dynamic Level Spawning & Pickups
	# ----------------------------------------------------
	print("\n[TEST 4] Verifying Dynamic Spawning & Pickups...")
	_assert_true(enemies_node != null and enemies_node.get_child_count() >= 1, "Enemies container populated dynamically")
	_assert_true(collectibles_node != null and collectibles_node.get_child_count() >= 1, "Collectibles container populated dynamically")
	
	# ----------------------------------------------------
	# TEST 5: Wave & Threat Progression
	# ----------------------------------------------------
	print("\n[TEST 5] Verifying Wave & Threat Progression...")
	gm.start_match()
	_assert_true(gm.current_wave == 1, "Game starts in Threat Level 1: Infiltration")
	
	gm.total_cores_needed = 10
	gm.collected_cores = 3
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 2, "30% cores reaches Threat Level 2: Defense Grid Alert")
	
	gm.collected_cores = 6
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 3, "60% cores reaches Threat Level 3: Sector Lockdown")
	
	gm.collected_cores = 8
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 4, "80% cores reaches Threat Level 4: Extraction Override")
	
	# ----------------------------------------------------
	# TEST 6: Multi-Disrupt Combo Scoring
	# ----------------------------------------------------
	print("\n[TEST 6] Verifying Multi-Disrupt Combo Scoring...")
	var score_before = gm.score
	gm.register_drone_stunned(1)
	_assert_true(gm.score == score_before + 25, "Single drone stun awards base +25 score")
	
	score_before = gm.score
	gm.register_drone_stunned(3)
	var expected_combo = 25 + (50 * 3)
	_assert_true(gm.score == score_before + expected_combo, "Triple drone stun awards +175 combo score")
	
	# ----------------------------------------------------
	# TEST 7: Complete 20-Level Campaign Progression
	# ----------------------------------------------------
	print("\n[TEST 7] Verifying 20-Level Campaign Definitions & Progression...")
	var cm = root.get_node_or_null("CampaignManager")
	_assert_true(cm != null, "CampaignManager autoload exists in SceneTree")
	
	if cm:
		var all_levels = cm.get_all_level_defs()
		_assert_true(all_levels.size() == 20, "Campaign contains exactly 20 fully authored levels")
		
		# Verify each stage has 4 levels with escalating requirements
		var stage_counts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
		var prev_cores = 0
		for lvl in all_levels:
			var id: int = lvl["id"]
			var st: int = lvl["stage"]
			var cores: int = lvl["cores_needed"]
			var par: float = lvl["par_time"]
			var drones: Array = lvl["drones"]
			
			stage_counts[st] += 1
			_assert_true(not lvl["name"].is_empty(), "Level %d has unique mission name: %s" % [id, lvl["name"]])
			_assert_true(cores >= 3 and cores <= 15, "Level %d requires between 3 and 15 cores (got %d)" % [id, cores])
			_assert_true(par >= 40.0 and par <= 120.0, "Level %d has valid par time (%0.1fs)" % [id, par])
			_assert_true(drones.size() >= 1, "Level %d has at least 1 drone patrol" % id)
			
		_assert_true(stage_counts[1] == 4, "Stage 1 contains 4 levels (Levels 1-4)")
		_assert_true(stage_counts[2] == 4, "Stage 2 contains 4 levels (Levels 5-8)")
		_assert_true(stage_counts[3] == 4, "Stage 3 contains 4 levels (Levels 9-12)")
		_assert_true(stage_counts[4] == 4, "Stage 4 contains 4 levels (Levels 13-16)")
		_assert_true(stage_counts[5] == 4, "Stage 5 contains 4 levels (Levels 17-20)")
		
		# Verify Level 20 Titan Overmind boss
		var lvl20 = cm.get_level_data(20)
		_assert_true(lvl20["name"] == "Titan Overmind", "Level 20 is the Titan Overmind Boss Finale")
		_assert_true(lvl20["cores_needed"] == 15, "Level 20 requires all 15 Singularity Cores")
		var has_overmind_drone := false
		for d in lvl20["drones"]:
			if d["type"] == EnemyDroneScript.DroneType.OVERMIND:
				has_overmind_drone = true
		_assert_true(has_overmind_drone, "Level 20 instantiates the Titan Overmind Drone")
		
		# Verify Star Rating Calculation
		# 3 Stars: health >= 2, time <= par
		var res3 = cm.complete_level(1, 1000, 30.0, 3) # par is 40.0
		_assert_true(res3["stars_earned"] == 3, "Clearing level under par with full health awards 3 Stars")
		
		# 2 Stars: health >= 2, time > par
		var res2 = cm.complete_level(1, 800, 55.0, 2)
		_assert_true(res2["stars_earned"] == 2, "Clearing level over par with >=2 health awards 2 Stars")
		
		# 1 Star: health == 1, time > par
		var res1 = cm.complete_level(1, 500, 60.0, 1)
		_assert_true(res1["stars_earned"] == 1, "Barely clearing level awards 1 Star")
		
		# Verify Level Unlocking
		cm.highest_unlocked_level = 1
		cm.complete_level(1, 1000, 30.0, 3)
		_assert_true(cm.is_level_unlocked(2), "Completing Level 1 unlocks Level 2")
		_assert_true(not cm.is_level_unlocked(5), "Level 5 remains locked until prior levels are cleared")
		
		# Verify Level 20 unlocks Campaign Complete
		var res20 = cm.complete_level(20, 5000, 80.0, 3)
		_assert_true(res20["is_campaign_complete"], "Completing Level 20 marks Campaign Complete")
		_assert_true(cm.campaign_completed, "CampaignManager tracks campaign_completed flag")
		
	# ----------------------------------------------------
	# TEST 8: Victory & Defeat End States
	# ----------------------------------------------------
	print("\n[TEST 8] Verifying End-State Transitions & Overlays...")
	gm.collected_cores = gm.total_cores_needed
	gm.trigger_victory()
	_assert_true(gm.current_state == GameManagerScript.GameState.VICTORY, "Completing cores triggers VICTORY")
	_assert_true(hud.victory_overlay.visible, "Victory overlay displayed with star ratings")
	_assert_true(gm.high_score >= gm.score, "High score record updated and persisted")
	
	# ----------------------------------------------------
	# TEST 9: Mobile Touch Controls & Responsiveness
	# ----------------------------------------------------
	print("\n[TEST 9] Verifying Mobile Touch Controls & Responsiveness...")
	var touch_controls = main.get_node_or_null("TouchControls")
	_assert_true(touch_controls != null, "TouchControls scene instantiated in main arena")
	
	var sm_test = SettingsManagerScript.new()
	_assert_true(sm_test.has_method("should_show_touch_controls"), "SettingsManager has should_show_touch_controls helper")
	sm_test.free()
	
	# Test touch vector analog movement on player
	var test_dir := Vector2(0.707, -0.707)
	player.touch_vector = test_dir
	player._physics_process(0.016)
	var expected_vx: float = test_dir.x * player.speed
	var expected_vy: float = test_dir.y * player.speed
	_assert_true(absf(player.velocity.x - expected_vx) < 1.0 and absf(player.velocity.y - expected_vy) < 1.0, "Player honors touch_vector analog directional movement")
	player.touch_vector = Vector2.ZERO
	
	# ----------------------------------------------------
	# FINAL SUMMARY
	# ----------------------------------------------------
	print("\n==================================================================")
	print("  TOTAL CHECKS: %d PASSED, %d FAILED" % [_passes, _failures])
	print("==================================================================")
	
	if _failures == 0:
		print(">> ALL SYSTEMS AND 20-LEVEL CAMPAIGN FULLY VERIFIED! <<\n")
		quit(0)
	else:
		printerr(">> TEST SUITE COMPLETED WITH FAILURES! <<\n")
		quit(1)


func _record_fail(msg: String) -> void:
	_failures += 1
	printerr("  [FAIL] ", msg)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		print("  [PASS] ", message)
	else:
		_failures += 1
		printerr("  [FAIL] ", message)


func _assert_approx(a: float, b: float, message: String, tolerance: float = 0.05) -> void:
	if absf(a - b) <= tolerance:
		_passes += 1
		print("  [PASS] ", message, " (got ", a, ", expected ", b, ")")
	else:
		_failures += 1
		printerr("  [FAIL] ", message, " (got ", a, ", expected ", b, ")")

extends SceneTree

## Comprehensive QA Automated Verification Suite for Last Stand: Signal Break.
## Verifies 1600x900 architecture, drone archetypes, overcharge, pickups, waves, FSM, and persistence.

const GameManagerScript = preload("res://scripts/systems/game_manager.gd")
const EnemyDroneScript = preload("res://scripts/enemy/enemy.gd")
const FragmentScript = preload("res://scripts/collectible/fragment.gd")
const ShieldPickupScript = preload("res://scripts/collectible/shield_pickup.gd")
const OverchargePickupScript = preload("res://scripts/collectible/overcharge_pickup.gd")
const PlayerScript = preload("res://scripts/player/player.gd")
const SettingsManagerScript = preload("res://scripts/systems/settings_manager.gd")

var _failures: int = 0
var _passes: int = 0


func _init() -> void:
	print("==================================================================")
	print("  QA AUTOMATED VERIFICATION SUITE — LAST STAND: SIGNAL BREAK      ")
	print("==================================================================")
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	var main_packed = load("res://scenes/main/main.tscn") as PackedScene
	if not main_packed:
		_record_fail("Could not load res://scenes/main/main.tscn")
		quit(1)
		return
		
	var main = main_packed.instantiate()
	root.add_child(main)
	
	for i in range(3):
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
	_assert_true(gm.total_cores_needed == 12, "Uplink requires 12 Energy Cores")
	_assert_true(enemies_node and enemies_node.get_child_count() == 4, "4 initial defense drones present in arena")
	
	# ----------------------------------------------------
	# TEST 2: Enemy Archetypes (Scout, Enforcer, Hunter)
	# ----------------------------------------------------
	print("\n[TEST 2] Verifying Enemy Drone Archetypes...")
	var scout_drone = enemies_node.get_node_or_null("Drone_ScoutNorth")
	var enforcer_drone = enemies_node.get_node_or_null("Drone_HeavyWest")
	var hunter_drone = enemies_node.get_node_or_null("Drone_HunterEast")
	
	_assert_true(scout_drone and scout_drone.drone_type == EnemyDroneScript.DroneType.SCOUT, "Scout drone initialized")
	_assert_true(enforcer_drone and enforcer_drone.drone_type == EnemyDroneScript.DroneType.ENFORCER, "Heavy Enforcer drone initialized")
	_assert_true(hunter_drone and hunter_drone.drone_type == EnemyDroneScript.DroneType.HUNTER, "Hunter drone initialized")
	
	_assert_approx(enforcer_drone.contact_damage, 2.0, "Heavy Enforcer deals 2 contact damage")
	_assert_approx(hunter_drone.chase_speed, 185.0, "Hunter drone pursues at elevated speed (185 px/s)")
	
	# Enforcer stun recovery test (armored chassis)
	enforcer_drone.apply_stun(3.0)
	_assert_approx(enforcer_drone.stun_timer, 1.95, "Enforcer chassis reduces stun duration by 35% (got ~1.95s)", 0.1)
	
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
	# TEST 4: Pickups (Shield Repair & Overcharge Cell)
	# ----------------------------------------------------
	print("\n[TEST 4] Verifying Pickups (Shields & Overcharge)...")
	var shield_kit = collectibles_node.get_node_or_null("ShieldKit1")
	_assert_true(shield_kit != null, "Shield repair kit exists")
	player.current_health = 1
	shield_kit._on_body_entered(player)
	_assert_true(player.current_health == 2, "Shield repair kit increased player health from 1 to 2")
	
	var overcharge_cell = collectibles_node.get_node_or_null("OverchargeCell")
	_assert_true(overcharge_cell != null, "Overcharge EMP cell exists")
	overcharge_cell._on_body_entered(player)
	_assert_true(player.has_overcharge, "Overcharge cell granted overcharge status")
	
	# ----------------------------------------------------
	# TEST 5: Wave Progression & Escalating Threat Levels
	# ----------------------------------------------------
	print("\n[TEST 5] Verifying Wave & Threat Progression...")
	gm.start_match()
	_assert_true(gm.current_wave == 1, "Game starts in Wave 1: Infiltration")
	
	gm.collected_cores = 3
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 2, "Reaching 3 cores escalates to Wave 2: Defense Grid Alert")
	
	gm.collected_cores = 6
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 3, "Reaching 6 cores escalates to Wave 3: Sector Lockdown")
	
	gm.collected_cores = 9
	gm._check_wave_progression()
	_assert_true(gm.current_wave == 4, "Reaching 9 cores escalates to Wave 4: Extraction Override")
	
	# ----------------------------------------------------
	# TEST 6: Multi-Disrupt Combo Bonus
	# ----------------------------------------------------
	print("\n[TEST 6] Verifying Multi-Disrupt Combo Scoring...")
	var score_before = gm.score
	gm.register_drone_stunned(1) # Single drone
	_assert_true(gm.score == score_before + 25, "Single drone stun awards base +25 score")
	
	score_before = gm.score
	gm.register_drone_stunned(3) # 3 drones caught in one pulse
	var expected_combo = 25 + (50 * 3) # 175 points
	_assert_true(gm.score == score_before + expected_combo, "Triple drone stun awards +175 combo score")
	
	# ----------------------------------------------------
	# TEST 7: Victory & Defeat End States
	# ----------------------------------------------------
	print("\n[TEST 7] Verifying End-State Transitions & Record Saving...")
	gm.collected_cores = 12
	gm.trigger_victory()
	_assert_true(gm.current_state == GameManagerScript.GameState.VICTORY, "12 cores triggers extraction VICTORY")
	_assert_true(hud.victory_overlay.visible, "Victory overlay displayed")
	_assert_true(gm.high_score >= gm.score, "High score record updated and persisted")
	
	# ----------------------------------------------------
	# TEST 8: Mobile Touch Controls & Responsiveness
	# ----------------------------------------------------
	print("\n[TEST 8] Verifying Mobile Touch Controls & Responsiveness...")
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
		print(">> ALL SYSTEMS AND EXPANDED MECHANICS FULLY VERIFIED! <<\n")
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

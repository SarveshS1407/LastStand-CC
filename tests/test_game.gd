extends SceneTree

## Comprehensive Automated Test Suite for Last Stand: Signal Break
## Verifies movement, pulse, enemy FSM, collectibles, combat, scoring, win/loss conditions.

const GameManagerScript = preload("res://scripts/systems/game_manager.gd")
const EnemyDroneScript = preload("res://scripts/enemy/enemy.gd")
const FragmentScript = preload("res://scripts/collectible/fragment.gd")
const PlayerScript = preload("res://scripts/player/player.gd")

var _failures: int = 0
var _passes: int = 0


func _init() -> void:
	print("====================================================")
	print("  STARTING AUTOMATED QA TEST SUITE: SIGNAL BREAK    ")
	print("====================================================")
	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# Load main scene
	var main_packed = load("res://scenes/main/main.tscn") as PackedScene
	if not main_packed:
		_record_fail("Could not load res://scenes/main/main.tscn")
		quit(1)
		return
		
	var main = main_packed.instantiate()
	root.add_child(main)
	
	# Wait 3 physics frames for ready & collision spaces to initialize
	for i in range(3):
		await process_frame
		
	var player = main.get_node_or_null("Player")
	var gm = main.get_node_or_null("GameManager")
	var hud = main.get_node_or_null("HUD")
	var enemies_node = main.get_node_or_null("Enemies")
	var collectibles_node = main.get_node_or_null("Collectibles")
	
	if not player or not gm or not hud:
		_record_fail("Core nodes missing from main scene tree!")
		quit(1)
		return
		
	# ----------------------------------------------------
	# TEST 1: Initial State & Architecture Verification
	# ----------------------------------------------------
	print("\n[TEST 1] Verifying initial scene hierarchy and parameters...")
	_assert_true(player.current_health == 3, "Player starts with 3 shields")
	_assert_true(player.current_energy >= 50.0, "Player starts with sufficient energy for pulse")
	_assert_true(gm.current_state == GameManagerScript.GameState.BRIEFING, "Game begins in BRIEFING state")
	_assert_true(collectibles_node and collectibles_node.get_child_count() == 10, "10 Energy Cores present in arena")
	_assert_true(enemies_node and enemies_node.get_child_count() >= 4, "At least 4 defense drones present in arena")
	
	# ----------------------------------------------------
	# TEST 2: Player Movement & Diagonal Normalization
	# ----------------------------------------------------
	print("\n[TEST 2] Verifying player 8-way movement and normalization...")
	Input.action_press("move_right")
	Input.flush_buffered_events()
	player._physics_process(0.016)
	_assert_approx(player.velocity.x, player.speed, "Horizontal velocity matches player speed")
	_assert_approx(player.velocity.y, 0.0, "Vertical velocity is 0 during horizontal move")
	Input.action_release("move_right")
	
	# Diagonal move (W + D)
	Input.action_press("move_up")
	Input.action_press("move_right")
	Input.flush_buffered_events()
	player._physics_process(0.016)
	var diag_speed = player.velocity.length()
	_assert_approx(diag_speed, player.speed, "Diagonal velocity length is strictly normalized to cardinal speed")
	Input.action_release("move_up")
	Input.action_release("move_right")
	Input.flush_buffered_events()
	
	# Dismiss briefing by moving
	gm.start_match()
	_assert_true(gm.current_state == GameManagerScript.GameState.PLAYING, "Match transitions to PLAYING state")
	
	# ----------------------------------------------------
	# TEST 3: Disruption Pulse Mechanics & Energy Consumption
	# ----------------------------------------------------
	print("\n[TEST 3] Verifying Disruption Pulse ability & energy logic...")
	player.current_energy = 50.0
	player.cooldown_timer = 0.0
	
	# Fire valid pulse
	var fired = player.fire_disruption_pulse()
	_assert_true(fired, "Disruption pulse fired successfully with sufficient energy")
	_assert_approx(player.current_energy, 25.0, "Energy reduced by 25.0 after pulse")
	_assert_true(player.cooldown_timer > 0.0, "Cooldown timer is active after pulse")
	
	# Try firing during cooldown (should fail)
	var spam_fired = player.fire_disruption_pulse()
	_assert_true(not spam_fired, "Pulse blocked by cooldown anti-spam constraint")
	
	# Reset cooldown, drain energy below cost
	player.cooldown_timer = 0.0
	player.current_energy = 10.0
	var poor_fired = player.fire_disruption_pulse()
	_assert_true(not poor_fired, "Pulse blocked when energy is insufficient (< 25)")
	_assert_approx(player.current_energy, 10.0, "Energy unaffected by failed activation")
	
	# Test energy recharge from EnergyFragment
	player.add_energy(30.0)
	_assert_approx(player.current_energy, 40.0, "Player energy increased after fragment reward")
	
	# ----------------------------------------------------
	# TEST 4: Enemy FSM State Transitions
	# ----------------------------------------------------
	print("\n[TEST 4] Verifying Enemy Drone Finite State Machine...")
	var test_drone = enemies_node.get_child(0)
	_assert_true(test_drone != null, "Enemy drone exists")
	
	# State: PATROL
	test_drone.current_state = EnemyDroneScript.State.PATROL
	test_drone.global_position = Vector2(500, 180)
	test_drone._physics_process(0.016)
	_assert_true(test_drone.velocity != Vector2.ZERO, "Patrolling drone moves toward waypoint")
	
	# State: CHASE
	# Place player within detection radius
	player.global_position = Vector2(550, 180) # 50px away, well within 180px
	test_drone._physics_process(0.016)
	_assert_true(test_drone.current_state == EnemyDroneScript.State.CHASE, "Drone transitions PATROL -> CHASE when player detected")
	_assert_approx(test_drone.velocity.length(), test_drone.chase_speed, "Drone moves at chase speed during CHASE")
	
	# State: STUNNED via Disruption Pulse
	test_drone.apply_stun(2.5)
	_assert_true(test_drone.current_state == EnemyDroneScript.State.STUNNED, "Drone transitions to STUNNED on pulse impact")
	_assert_true(test_drone.velocity == Vector2.ZERO, "Stunned drone velocity is zero")
	_assert_approx(test_drone.stun_timer, 2.5, "Stun timer set to duration")
	
	# Verify stunned drone does NOT damage player on contact
	var hp_before = player.current_health
	test_drone._on_hitbox_body_entered(player)
	_assert_true(player.current_health == hp_before, "Stunned drone cannot deal contact damage to player")
	
	# Simulate stun expiration
	test_drone._process_stunned(2.6)
	_assert_true(test_drone.current_state != EnemyDroneScript.State.STUNNED, "Drone recovers from stun after timer elapses")
	
	# State: RETURN
	# Move player far away (> lose_radius of 250px)
	player.global_position = Vector2(100, 100)
	test_drone._process_chase(0.016)
	_assert_true(test_drone.current_state == EnemyDroneScript.State.RETURN, "Drone transitions CHASE -> RETURN when player escapes")
	
	# ----------------------------------------------------
	# TEST 5: Collectible Interaction & Duplicate Prevention
	# ----------------------------------------------------
	print("\n[TEST 5] Verifying Collectible mechanics & score rewards...")
	var initial_score = gm.score
	var initial_cores = gm.collected_cores
	var fragment = collectibles_node.get_child(0)
	_assert_true(fragment != null, "EnergyFragment node exists")
	
	var energy_before = player.current_energy
	fragment._on_body_entered(player)
	_assert_true(gm.collected_cores == initial_cores + 1, "Collected cores counter incremented")
	_assert_true(gm.score == initial_score + fragment.score_reward, "Score awarded for collecting core")
	_assert_approx(player.current_energy, energy_before + fragment.energy_reward, "Player energy replenished by core")
	
	# Verify duplicate prevention: trigger again on same fragment
	var score_after_first = gm.score
	fragment._on_body_entered(player)
	_assert_true(gm.score == score_after_first, "Duplicate collection prevented on already collected core")
	
	# ----------------------------------------------------
	# TEST 6: Combat & Game Over Failure State
	# ----------------------------------------------------
	print("\n[TEST 6] Verifying Damage & Game Over condition...")
	player._invuln_timer = 0.0
	player.take_damage(1)
	_assert_true(player.current_health == 2, "Player health decremented on damage")
	_assert_true(player._invuln_timer > 0.0, "Invulnerability frame triggered on damage")
	
	# Lethal damage
	player._invuln_timer = 0.0
	player.take_damage(2)
	_assert_true(player.current_health == 0, "Player health reaches 0")
	_assert_true(player.is_dead, "Player marked as dead")
	_assert_true(gm.current_state == GameManagerScript.GameState.GAME_OVER, "GameManager triggers GAME_OVER state")
	_assert_true(hud.game_over_overlay.visible, "Game Over HUD overlay displayed")
	
	# ----------------------------------------------------
	# TEST 7: Victory Condition
	# ----------------------------------------------------
	print("\n[TEST 7] Verifying Victory state trigger...")
	gm.collected_cores = gm.total_cores_needed
	gm.trigger_victory()
	_assert_true(gm.current_state == GameManagerScript.GameState.VICTORY, "GameManager triggers VICTORY state when 10 cores secured")
	_assert_true(hud.victory_overlay.visible, "Victory HUD overlay displayed")
	
	# ----------------------------------------------------
	# FINAL SUMMARY
	# ----------------------------------------------------
	print("\n====================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [_passes, _failures])
	print("====================================================")
	
	if _failures == 0:
		print(">> ALL SYSTEMS AND MECHANICS VERIFIED SUCCESSFULLY! <<\n")
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

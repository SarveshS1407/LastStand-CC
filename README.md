# Last Stand: Signal Break

> **GDG TECH Recruitment Task Submission — 2D Game Development Track**  
> **Engine:** Godot 4.7.2 (GL Compatibility Renderer)  
> **Platform:** macOS (Apple Silicon native) & Cross-Platform  
> **Language:** GDScript  

---

## 1. Overview & Concept

**Last Stand: Signal Break** is a top-down tactical survival arcade game set in an isolated, corrupted server core. The sector's automated defense drones sweep the perimeter in active patrol patterns. When an operative is detected, the drones transition into persistent pursuit mode.

As the lone operative, your objective is to infiltrate the sector, collect **10 Energy Cores** to establish an extraction uplink, and survive. To combat the relentless drone network, you are equipped with the **Disruption Pulse**—an expanding electromagnetic shockwave that temporarily stuns hostiles in their tracks, opening vital escape windows.

---

## 2. Core Mechanics

### 2.1 The Disruption Pulse (Spacebar)
- **Shockwave Blast:** Emits an expanding circular EMP wave outward from the player up to a 175-pixel radius.
- **Drone Stun:** Any patrolling or chasing drones within the blast radius are instantly **STUNNED** for 3.0 seconds, rendering them motionless and neutralizing their contact damage.
- **Resource Management:** Each pulse consumes **25 Energy Units** (out of 100 max). The pulse cannot be fired without sufficient charge, preventing reckless spam.
- **Anti-Spam Cooldown:** A 0.8-second safety cooldown prevents rapid double-firing.
- **Recharge Mechanics:** Energy is replenished by collecting Energy Cores (+30 Energy each) as well as a slow ambient trickle (+1.5/s).

### 2.2 4-State Enemy Drone AI (Finite State Machine)
Defense drones operate on an explicit 4-state FSM:
1. **`PATROL` (Amber Core):** Drones pace methodically along assigned patrol corridors.
2. **`CHASE` (Red Core / Alert Pulse):** If the player enters the 180px detection radius, the drone sounds an alert, switches to high-speed pursuit (150 px/s), and tracks the player.
3. **`STUNNED` (Cyan Core / Electric Glitch):** When struck by the player's Disruption Pulse, drones freeze, play an electrical crackle animation, and cannot deal damage. After 3.0s, they re-evaluate player distance.
4. **`RETURN` (Yellow-Grey Core):** If the player breaks line of sight or outruns the 250px loss radius, the drone abandons pursuit and navigates back to its nearest patrol route.

### 2.3 Objective, Scoring & Progression
- **Primary Objective:** Locate and collect all **10 Signal Energy Cores** scattered across the arena corridors.
- **Dynamic Scoring:**
  - **+100 Points:** Each Energy Core retrieved.
  - **+25 Points:** Each defense drone successfully stunned with a pulse.
  - **+10 Points:** Tactical pulse deployment.
  - **+5 Points/Sec:** Sector survival bonus.
  - **Time Bonus:** Up to +1,500 points for rapid extraction upon victory.
- **Health / Shield Integrity:** Operatives have 3 Shield Pips. Touching an active drone inflicts 1 shield damage and grants a 1.2s invulnerability grace period.
- **Victory Condition:** Securing all 10 cores immediately triggers an extraction uplink victory.
- **Defeat Condition:** Shield failure (0 HP) results in a mission failure ("Signal Lost").
- **Quick Restart:** Press **[ R ]** at any time to instantly reset and restart the mission.

---

## 3. Controls

| Action | Primary Input | Alternate Input |
| :--- | :--- | :--- |
| **Move Up** | `W` | `Up Arrow` |
| **Move Down** | `S` | `Down Arrow` |
| **Move Left** | `A` | `Left Arrow` |
| **Move Right** | `D` | `Right Arrow` |
| **Disruption Pulse** | `Spacebar` | `Enter` / `UI Accept` |
| **Quick Restart** | `R` | Game Over / Victory Prompt |

*Note: 8-directional diagonal movement is strictly normalized so diagonal travel is never faster than cardinal movement.*

---

## 4. Architecture & Project Structure

The project adheres to Godot 4 architectural standards with decoupled modules and zero external asset dependencies:

```
last-stand/
├── project.godot                     # Engine configuration & input mappings
├── scenes/
│   ├── main/
│   │   └── main.tscn                 # Main arena, environment, obstacles, spawner layout
│   ├── player/
│   │   └── player.tscn               # Operative CharacterBody2D, collision & visuals
│   ├── enemy/
│   │   └── enemy.tscn                # Patrol drone CharacterBody2D with FSM & hitbox
│   ├── pulse/
│   │   └── disruption_pulse.tscn     # Expanding Area2D shockwave & visual arcs
│   ├── collectible/
│   │   └── fragment.tscn             # Animated Energy Core Area2D
│   └── ui/
│       └── hud.tscn                  # Shields, Energy meter, Objective progress & Overlays
├── scripts/
│   ├── player/
│   │   └── player.gd                 # Player physics, energy tracking, pulse activation
│   ├── enemy/
│   │   └── enemy.gd                  # 4-state Finite State Machine controller
│   ├── pulse/
│   │   └── disruption_pulse.gd       # Shockwave expansion, distance checks, stun trigger
│   ├── collectible/
│   │   └── fragment.gd               # Bobbing animation, pickup logic, duplicate guards
│   ├── systems/
│   │   ├── game_manager.gd           # Scoring, state loop (Briefing/Play/Over/Win), restart
│   │   └── audio_manager.gd          # 100% procedural PCM sound synthesizer
│   └── ui/
│       └── hud.gd                    # HUD reactive data binding and overlay transitions
└── tests/
    └── test_game.gd                  # Automated 39-assertion headless QA test suite
```

### Self-Contained Procedural Sound Design
To eliminate missing audio files and external asset licensing concerns, `scripts/systems/audio_manager.gd` synthesizes 7 distinct 16-bit PCM sound effects in memory using Godot's `AudioStreamWAV`:
- **Pulse SFX:** Resonant 140Hz $\rightarrow$ 680Hz harmonic sweep.
- **Stun SFX:** High-frequency electrical discharge buzz with noise modulation.
- **Collect SFX:** Bright two-tone crystal chime (587Hz $\rightarrow$ 880Hz).
- **Hit SFX:** Low crunch impact with decaying thud.
- **Low Energy Warning:** Dual low-frequency alert beeps.
- **Victory Fanfare:** Ascending 4-tone major arpeggio.
- **Game Over:** Low descending signal lost drone.

---

## 5. How to Launch and Play

### Option A: From the Godot 4 Editor
1. Open **Godot 4.7.2** on your machine.
2. Click **Import** and select the `/last-stand` project directory (where `project.godot` resides).
3. Open the project.
4. Press **F5** (or click the **Play** button in the top right).
5. Press **Space** or any movement key to dismiss the mission briefing and play!

### Option B: From Command Line (Terminal)
```bash
# Launch directly in windowed mode:
/Applications/Godot.app/Contents/MacOS/Godot --path /path/to/last-stand

# Or run the automated test suite headless:
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /path/to/last-stand --script res://tests/test_game.gd
```

---

## 6. Verification & QA Testing Report

An automated test suite containing 39 assertions was executed in Godot 4.7.2 headless mode (`tests/test_game.gd`).

### Results Summary: `39 PASSED, 0 FAILED`

| Category | Checks Performed | Result |
| :--- | :--- | :--- |
| **Scene & Hierarchy** | Player node, GameManager, HUD, 10 Cores, 4 Drones initialized correctly. | **PASS** |
| **Movement & Normalization** | Cardinal speed (240 px/s), Diagonal speed (strictly normalized to 240 px/s). | **PASS** |
| **Disruption Pulse** | Activation consumes 25 energy, cooldown blocks spam, low energy blocks firing. | **PASS** |
| **Enemy Patrol** | Drone traverses waypoints along designated axis at patrol speed (95 px/s). | **PASS** |
| **Enemy Chase** | Detecting player within 180px triggers high-speed pursuit (150 px/s). | **PASS** |
| **Enemy Stun** | Pulse triggers STUNNED state, freezes velocity, disables contact damage. | **PASS** |
| **Enemy Return** | Player escaping 250px loss radius triggers RETURN state back to patrol route. | **PASS** |
| **Collectibles** | Pickup adds +100 score, restores +30 energy, increments core counter. | **PASS** |
| **Duplicate Prevention** | Secondary contact on consumed core does not award duplicate points. | **PASS** |
| **Combat & Failure** | Damage decrements shield pips, grants invulnerability; 0 HP triggers Game Over. | **PASS** |
| **Victory Condition** | Collecting 10 cores immediately triggers Victory overlay and time bonus. | **PASS** |

---

## 7. Recruitment Requirements Mapping

| Evaluation Requirement | Implementation in Last Stand: Signal Break |
| :--- | :--- |
| **Original Concept / Creative Twist** | Disruption Pulse EMP mechanic: instead of standard projectile shooting, the player manages a non-lethal crowd-control pulse that stuns pursuers and demands careful tactical energy management. |
| **Meaningful Choices** | Risk/reward decisions: use energy to stun a closing drone now, or save it to grab a distant core? Evade through pillars or deploy a pulse? |
| **Core Mechanics via Code** | 4-state enemy FSM, dynamic circular pulse collision checking, procedural audio synthesis, normalized 8-way physics. |
| **Usability & Game Feel** | Screen flashing on damage, visual state labels and color cues on enemies, clean sci-fi HUD with shield pips and energy gauges, responsive rotation lerping. |
| **Progression & Win/Loss** | Clear 10-core objective, survival time bonus, failure on shield depletion, victory on uplink establishment, instant restart. |
| **Technical Correctness** | Clean GDScript adhering to Godot 4 idioms, frame-independent movement, robust collision masks/layers, 100% automated test coverage. |

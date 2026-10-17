# Last Stand: Signal Break

> **GDG TECH Recruitment Task Submission — 2D Game Development Track**  
> **Engine:** Godot 4.7.2 (GL Compatibility Renderer)  
> **Platform:** macOS (Apple Silicon native) & Cross-Platform  
> **Display Resolution:** 1600×900 Native Landscape (HiDPI / Retina Scaled)  
> **Language:** GDScript  

---

## 1. Overview & Concept

**Last Stand: Signal Break** is a tactical top-down sci-fi survival arcade game set inside an isolated, high-security server core. The facility's automated defense network deploys patrolling drones across the sector. When an operative is detected, the network triggers persistent pursuit.

As the operative, your objective is to infiltrate the 1600×900 sector, collect **12 Energy Cores** across **4 escalating threat waves**, and survive. Rather than standard projectile shooting, your primary defensive weapon is the **Disruption Pulse**—an expanding circular EMP shockwave that stuns hostiles, halts their pursuit, and disables contact damage.

---

## 2. Core Mechanics & Features

### 2.1 The Disruption Pulse & EMP Overcharge (Spacebar)
- **Standard Pulse:** Expands outward from the operative up to a **175-pixel radius**, stunning all hostiles within the blast wave for **3.0 seconds**.
- **EMP Overcharge:** Collecting a golden Overcharge Cell empowers your next pulse to expand to a massive **280-pixel radius**, stunning enemies for **4.2 seconds** with golden visual arcs!
- **Resource Management:** Firing costs **25 Energy Units** (out of 100 max). Firing is disabled when energy is depleted, preventing mindless spam.
- **Cooldown Constraint:** A 0.8-second safety cooldown prevents accidental double-activation.
- **Recharge Mechanics:** Energy recharges via Energy Cores (+30 Energy), Overcharge Cells (100% full refill), or passive trickle (+1.8/s).

### 2.2 Enemy Drone Archetypes & 4-State AI (FSM)
Security drones run on a robust 4-state Finite State Machine (`PATROL` $\rightarrow$ `CHASE` $\rightarrow$ `STUNNED` $\rightarrow$ `RETURN`):
1. **Scout Drone (Amber):** Fast reconnaissance unit (105 px/s patrol, 165 px/s chase). Rapid corridor sweeper.
2. **Heavy Enforcer Drone (Violet):** Armored security unit. Deals **2 shield damage** on contact and has a reinforced chassis that recovers from EMP stuns 35% faster.
3. **Hunter Drone (Crimson):** Relentless tracker with elevated detection radius (240 px) and aggressive pursuit speed (185 px/s).

### 2.3 Wave Progression & Objectives
- **Wave 1: INFILTRATION (0 - 3 Cores):** Sector defenses in routine patrol mode. Low threat.
- **Wave 2: DEFENSE GRID ALERT (4 - 6 Cores):** Sensor grid activated. Drones increase patrol alertness.
- **Wave 3: SECTOR LOCKDOWN (7 - 9 Cores):** Heavy Enforcers and Hunters actively sweep inner choke points.
- **Wave 4: EXTRACTION OVERRIDE (10 - 12 Cores):** Final cores secured. Extraction transport signals incoming.

### 2.4 Pickups & Power-Ups
- **Energy Core (+100 Score, +30 Energy):** Primary objective item required for uplink.
- **Shield Repair Kit (+75 Score, +1 Shield):** Restores lost operative shields (up to 3 max).
- **EMP Overcharge Cell (+150 Score, 100% Energy, Super-Pulse):** Empowers next pulse with 280px radius.

### 2.5 Multi-Disrupt Combo Scoring
- Stunning multiple drones simultaneously with a single pulse triggers **MULTI-DISRUPT** combo multipliers (+50 bonus points per additional drone!).
- **High Score Persistence:** Best score and survival time are automatically saved locally to `user://records.cfg`.

---

## 3. Controls & Usability

| Action | Primary Input | Alternate Input |
| :--- | :--- | :--- |
| **Move Up** | `W` | `Up Arrow` |
| **Move Down** | `S` | `Down Arrow` |
| **Move Left** | `A` | `Left Arrow` |
| **Move Right** | `D` | `Right Arrow` |
| **Disruption Pulse** | `Spacebar` | `UI Select` / `Enter` |
| **Pause & Settings** | `Escape` | `P` |
| **Toggle Fullscreen** | `F11` | Settings Menu |
| **Quick Restart** | `R` | Game Over / Victory Overlay |

*Note: 8-directional movement is strictly normalized so diagonal travel matches cardinal speed.*

---

## 4. Display & Window Size Fix

### Resolution Architecture
- **Base Resolution:** 1600×900 landscape.
- **Display Server Integration:** `SettingsManager` autoload handles window scaling, ensuring the game opens in a comfortable, centered 1600×900 window without appearing tiny on high-DPI/Retina screens.
- **Aspect Ratio:** `canvas_items` mode with `keep` aspect ratio ensures crisp, distortion-free graphics on displays of any resolution (from 720p to 4K and ultrawide).
- **Fullscreen Support:** Dedicated `F11` key and Settings checkbox allow seamless switching between windowed and fullscreen without distortion.

---

## 5. Standalone Release Build

A standalone, double-clickable macOS application package has been built and signed:
- **Location:** `builds/LastStand_SignalBreak_macOS.zip` (contains `LastStand_SignalBreak.app`)
- **Standalone Pack:** `builds/LastStand_SignalBreak.pck`
- **Architecture:** Apple Silicon Native (arm64) + x86_64 Universal macOS binary.
- **How to Run Standalone:**
  1. Unzip `builds/LastStand_SignalBreak_macOS.zip`.
  2. Double-click `LastStand_SignalBreak.app`.

---

## 6. How to Run in Godot 4 Editor

1. Open **Godot 4.7.2** on your machine.
2. Select the `last-stand` project from the project list.
3. Press **F5** (or click the **Play** button in the upper right).
4. The game opens in a large, centered 1600×900 window with the Mission Briefing. Press **Space** or move to begin!

---

## 7. Automated QA Testing Report

An automated test suite containing 28 comprehensive assertions was executed in Godot 4.7.2 headless mode (`tests/test_game.gd`).

### Results: `28 PASSED, 0 FAILED`

| Category | Checks Performed | Result |
| :--- | :--- | :--- |
| **1600×900 Architecture** | Viewport resolution, camera centering, 12 cores, 4 drones, player spawn. | **PASS** |
| **Drone Archetypes** | Scout, Heavy Enforcer (2 damage), Hunter (185 px/s chase), Enforcer stun reduction. | **PASS** |
| **Pulse & Overcharge** | Energy deduction (25 EP), Overcharge EMP status, 100% refill, super-pulse consumption. | **PASS** |
| **Pickups** | Shield repair (+1 HP), Overcharge cell pickup and activation. | **PASS** |
| **Wave Progression** | Wave 1 (Infiltration) $\rightarrow$ Wave 2 (Alert) $\rightarrow$ Wave 3 (Lockdown) $\rightarrow$ Wave 4 (Override). | **PASS** |
| **Combo Scoring** | Single drone (+25 score), Multi-drone stun combo calculation (+175 score). | **PASS** |
| **End States & Records** | 12 cores victory transition, overlay display, high-score file persistence. | **PASS** |

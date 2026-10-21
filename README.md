# Last Stand: Signal Break

<p align="center">
  <img src="assets/branding/logo-banner.png" alt="Last Stand: Signal Break Banner" width="700">
</p>

<p align="center">
  <strong>GDG TECH Recruitment Task Submission — 2D Game Development Track</strong><br>
  <em>Tactical Top-Down Sci-Fi Survival Arcade Game with 20-Level Campaign & EMP Shockwave Disruption Mechanics</em>
</p>

<p align="center">
  <a href="https://sarveshs1407.github.io/LastStand-CC/"><strong>🌐 Play Online (Mobile & Desktop PWA)</strong></a> •
  <a href="https://github.com/SarveshS1407/LastStand-CC/releases/tag/v1.0.0"><strong>📦 Standalone macOS Build</strong></a> •
  <a href="#4-mobile-controls--pwa-installation"><strong>📱 Install to Phone</strong></a>
</p>

---

## 🎮 Playable Web URL & Mobile Launch

The game is deployed as an **Installable Progressive Web App (PWA)** accessible directly in mobile and desktop browsers over HTTPS:

👉 **[https://sarveshs1407.github.io/LastStand-CC/](https://sarveshs1407.github.io/LastStand-CC/)**

- **Desktop:** Open the link to play in any modern browser using keyboard controls.
- **Mobile Phones (Android & iPhone):** Full responsive touch controls with floating analog thumbstick, tactical EMP Pulse button, and home-screen app installation.

---

## 1. Overview & Core Concept

**Last Stand: Signal Break** is a tactical top-down sci-fi survival arcade game set inside an isolated, high-security server core. The facility's automated defense network deploys patrolling drones across the sector. When an operative is detected, the network triggers persistent pursuit.

Rather than standard projectile shooting, your primary defensive weapon is the **Disruption Pulse**—an expanding circular EMP shockwave that stuns hostiles, halts their pursuit, and disables contact damage.

The game features a full **20-Level Structured Campaign** divided across **5 Distinct Tactical Stages**, with escalating difficulty, distinct objectives, 6 drone archetypes, 1–3 star ratings, persistent level select, and a climactic **Titan Overmind Boss Encounter** on Level 20.

---

## 2. The 20-Level Campaign & Difficulty Curve

The campaign is structured into 5 progressive stages of 4 levels each, introducing new mechanics, aggressive enemy archetypes, and tighter par times:

```
[ STAGE 1: THE BEGINNING ] ──▶ [ STAGE 2: RISING THREAT ] ──▶ [ STAGE 3: UNDER PRESSURE ] ──▶ [ STAGE 4: LAST STAND ] ──▶ [ STAGE 5: FINAL ASSAULT ]
  Levels 1–4                    Levels 5–8                     Levels 9–12                     Levels 13–16                   Levels 17–20 (BOSS)
  Recon & Scout Sweeps          Heavy Enforcers (2 Dmg)        Fast Hunters (240px Det)        Elite Units & Stalkers         Titan Overmind Finale
```

### Stage 1: The Beginning (Levels 1–4) — *Reconnaissance & Basic Drills*
*Teaches movement, pulse timing, core collection, and basic dodging against Scout drones.*
- **Level 01: Breach Point** — Objective: Infiltrate perimeter and secure 3 Energy Cores. (1 Scout, Par: 40s)
- **Level 02: Data Corridors** — Objective: Navigate twin corridors and extract 4 Energy Cores. (2 Scouts, Par: 45s)
- **Level 03: Sensor Sweep** — Objective: Collect 5 Cores while evading overlapping patrol routes; mid-level reinforcement alert. (2 Scouts + 1 Reinforcement, Par: 50s)
- **Level 04: Grid Synchronization [Stage 1 Climax]** — Objective: Secure 6 Cores against synchronized corridor sweeps. (3 Scouts, Par: 55s)

### Stage 2: Rising Threat (Levels 5–8) — *Armored Sector Escalation*
*Introduces the Heavy Enforcer—dealing 2 contact damage with reinforced plating that shrugs off 35% of EMP duration.*
- **Level 05: Armored Patrol** — Objective: Heavy Enforcer online. Deals 2 shield damage! Secure 6 Cores. (1 Enforcer, 1 Scout, Par: 60s)
- **Level 06: Chokepoint Lockdown** — Objective: Twin Enforcers guard the server pillars. Secure 7 Cores. (2 Enforcers, 1 Scout, Par: 65s)
- **Level 07: Compression Wave** — Objective: Secure 8 Cores; dynamic mid-level Enforcer reinforcement triggers at 4 cores. (1 Enforcer, 2 Scouts + 1 Enforcer Reinforcement, Par: 70s)
- **Level 08: The Bastion Gate [Stage 2 Climax]** — Objective: Fortified defense network. Secure 8 Cores under siege. (3 Enforcers, 1 Scout, Par: 75s)

### Stage 3: Survival Under Pressure (Levels 9–12) — *Hunter Pursuit Protocol*
*Introduces the Hunter Drone—relentless tracker with 240px detection range and 185 px/s chase speed.*
- **Level 09: Red Line Alert** — Objective: Hunter drone deployed! Relentless pursuit. Secure 8 Cores. (1 Hunter, 1 Enforcer, 1 Scout, Par: 70s)
- **Level 10: Crossfire Alley** — Objective: Twin Hunters patrol open chokepoints. Secure 9 Cores. (2 Hunters, 1 Enforcer, 1 Scout, Par: 75s)
- **Level 11: Sensor Scramble** — Objective: Heavy sensor convergence across 2 combat waves. Secure 10 Cores. (1 Hunter, 2 Enforcers, 1 Scout + 1 Hunter Reinforcement, Par: 80s)
- **Level 12: The Gauntlet [Stage 3 Climax]** — Objective: Overlapping Hunter and Enforcer grids. Secure 10 Cores. (3 Hunters, 2 Enforcers, Par: 85s)

### Stage 4: Last Stand (Levels 13–16) — *Blackout Squadron Elites*
*Introduces Elite Enforcers (3 contact damage, 50% stun reduction) and Stalkers (205 px/s lethal chase, 280px detection radius).*
- **Level 13: Elite Vanguard** — Objective: Elite Enforcer activated with 3 contact damage and reinforced armor. Secure 10 Cores. (1 Elite, 2 Hunters, 1 Scout, Par: 80s)
- **Level 14: Stalker Shadows** — Objective: Stalker Drones detected! 205 px/s lethal pursuit speed. Secure 11 Cores. (2 Stalkers, 1 Elite, 1 Enforcer, Par: 85s)
- **Level 15: Sector Overdrive** — Objective: Combined elite squadron. Chain EMP pulses for survival! Secure 12 Cores. (2 Stalkers, 2 Elites + 1 Stalker Reinforcement, Par: 90s)
- **Level 16: Inquisitor Sub-Core [Stage 4 Climax]** — Objective: Dual Elite Enforcers and Stalkers defend the sub-core. Secure 12 Cores. (2 Elites, 2 Stalkers, 1 Hunter, Par: 95s)

### Stage 5: The Final Assault (Levels 17–20) — *Facility Core Overmind Finale*
*Relentless endgame challenge culminating in the Titan Overmind Boss.*
- **Level 17: Maximum Threat** — Objective: Facility defenses at maximum alert. Secure 12 Cores. (3 Stalkers, 2 Elites, Par: 90s)
- **Level 18: Lockdown Breakdown** — Objective: Multiple aggressive patrol groups across 2 waves. Secure 13 Cores. (3 Stalkers, 2 Elites, 1 Hunter + 1 Stalker Reinforcement, Par: 100s)
- **Level 19: The Core Threshold** — Objective: Penultimate breach. Penetrate outer reactor defenses. Secure 14 Cores. (4 Stalkers, 2 Elites + 1 Elite Reinforcement, Par: 110s)
- **Level 20: Titan Overmind [FINAL BOSS CLIMAX]** — Objective: Overload the Facility Overmind! Secure all 15 Singularity Cores. Features the massive **Titan Overmind Boss** (2.2× scale, 3 contact damage, 60% EMP absorption) escorted by 2 Elite Enforcers and 2 Stalkers, plus mid-fight interceptor reinforcements at 5 and 10 cores! (Par: 120s)

---

## 3. Core Mechanics & Features

### 3.1 The Disruption Pulse & EMP Overcharge (Spacebar / On-Screen Button)
- **Standard Pulse:** Expands outward from the operative up to a **175-pixel radius**, stunning all hostiles within the blast wave for **3.0 seconds**.
- **EMP Overcharge:** Collecting a golden Overcharge Cell empowers your next pulse to expand to a massive **280-pixel radius**, stunning enemies for **4.2 seconds** with golden visual arcs!
- **Resource Management:** Firing costs **25 Energy Units** (out of 100 max). Firing is disabled when energy is depleted, preventing mindless spam.
- **Cooldown Constraint:** A 0.8-second safety cooldown prevents accidental double-activation.
- **Recharge Mechanics:** Energy recharges via Energy Cores (+30 Energy), Overcharge Cells (100% full refill), or passive trickle (+1.8/s).

### 3.2 Enemy Drone Archetypes & 4-State AI (FSM)
Security drones run on a robust 4-state Finite State Machine (`PATROL` $\rightarrow$ `CHASE` $\rightarrow$ `STUNNED` $\rightarrow$ `RETURN`):
1. **Scout Drone (Amber):** Fast reconnaissance unit (105 px/s patrol, 165 px/s chase). Rapid corridor sweeper.
2. **Heavy Enforcer Drone (Violet):** Armored security unit. Deals **2 shield damage** on contact and absorbs 35% of EMP stun duration.
3. **Hunter Drone (Crimson):** Relentless tracker with elevated detection radius (240 px) and aggressive pursuit speed (185 px/s).
4. **Elite Enforcer Drone (Electric Violet):** 1.5× scale heavy juggernaut dealing **3 lethal shield damage** with 50% stun resistance.
5. **Stalker Drone (Cyan/Red Flash):** High-speed interceptor (205 px/s pursuit, 280px detection radius).
6. **Titan Overmind Boss (Crimson-Gold Core):** 2.2× scale facility ruler with 3 damage and 60% EMP absorption capability.

### 3.3 Star Rating System (⭐ 0–3 Stars per Level, 60 Total)
Every level calculates performance across three criteria:
- **⭐ 1 Star:** Objective Cleared (collected all required Energy Cores and survived).
- **⭐⭐ 2 Stars:** Survival Mastery (finished with at least 2 shields remaining).
- **⭐⭐⭐ 3 Stars:** Speed Mastery (cleared the level within the par time).
All stars, high scores, best times, and unlocked progress are saved persistently (`user://campaign_save.cfg`).

### 3.4 Pickups & Power-Ups
- **Energy Core (+100 Score, +30 Energy):** Primary objective item required for uplink.
- **Shield Repair Kit (+75 Score, +1 Shield):** Restores lost operative shields (up to 3 max).
- **EMP Overcharge Cell (+150 Score, 100% Energy, Super-Pulse):** Empowers next pulse with 280px radius.

### 3.5 Multi-Disrupt Combo Scoring
- Stunning multiple drones simultaneously with a single pulse triggers **MULTI-DISRUPT** combo multipliers (+50 bonus points per additional drone!).

---

## 4. Mobile Controls & PWA Installation

### 4.1 Intuitive Mobile Touch Interface
When launched on phones or touch devices, the game automatically surfaces an on-screen tactical HUD:
- **Floating Virtual Thumbstick (Bottom-Left):** Smooth 360° analog thumbstick that tracks your finger, providing precise 8-way directional navigation.
- **Tactile EMP Pulse Button (Bottom-Right):** Large circular action button with live status feedback (cyan when ready, dim on cooldown, and radiant pulsing gold when EMP Overcharge is active).
- **Tactical Pause Button (Top-Right):** Instant in-game pause, settings, and level select access.
- **Touch-Friendly Level Select Screen:** Browse all 20 levels grouped by stage, see star ratings, and launch missions with large touch targets.

### 4.2 How to Install on Android
1. Open **[https://sarveshs1407.github.io/LastStand-CC/](https://sarveshs1407.github.io/LastStand-CC/)** in **Google Chrome**.
2. Tap the **"📲 INSTALL APP"** button at the top-right, or tap Chrome's menu (`⋮`) and select **"Add to Home screen"** or **"Install app"**.
3. Confirm the prompt.
4. **Last Stand** will now appear on your phone's home screen with its custom cyber shield app icon and launch in full-screen standalone mode!

### 4.3 How to Install on iPhone (iOS Safari)
1. Open **[https://sarveshs1407.github.io/LastStand-CC/](https://sarveshs1407.github.io/LastStand-CC/)** in **Safari**.
2. Tap the **Share** button (the square with an arrow pointing upward `⎋`) at the bottom of the screen.
3. Scroll down and tap **"Add to Home Screen"** (`⊞`).
4. Tap **"Add"** in the upper right.
5. Launch **LastStand** directly from your home screen for a seamless, borderless full-screen experience!

---

## 5. Controls Matrix

| Action | Mobile / Touch | Desktop Keyboard | Alternate Input |
| :--- | :--- | :--- | :--- |
| **Move Up / Down / Left / Right** | Virtual Thumbstick (Left) | `W` / `A` / `S` / `D` | `Arrow Keys` |
| **Trigger Disruption Pulse** | Tap "EMP PULSE" Button (Right) | `Spacebar` | `Enter` / `UI Select` |
| **Pause & Mission Select** | Tap `❚❚` Icon (Top Right) | `Escape` | `P` |
| **Toggle Fullscreen** | In Settings Menu | `F11` | Settings Dialog |
| **Quick Restart** | Tap Screen Anywhere | `R` | Spacebar / Enter |

---

## 6. Technology Stack & Deployment Architecture

- **Game Engine:** Godot Engine 4.7.2 (Single-Threaded GL Compatibility Renderer)
- **Programming Language:** GDScript
- **Web Export Target:** WebAssembly (Wasm) + WebGL 2 / HTML5
- **Single-Threaded Web Advantage:** Does not require SharedArrayBuffer or cross-origin isolation (COOP/COEP) headers, ensuring seamless compatibility across mobile Safari (iOS), Chrome (Android), and desktop browsers.
- **Branding Assets:** Custom SVG vector logos, 512×512 master icons, 192×192 mobile icons, 512×512 maskable adaptive icons, 180×180 Apple touch icons, and favicons.
- **PWA Service Worker:** Stale-while-revalidate / cache-first service worker (`sw.js`) that pre-caches game binaries for lightning-fast loads and offline readiness, with automated update detection.
- **Hosting & CI/CD Pipeline:** Hosted on **GitHub Pages** via GitHub Actions (`.github/workflows/deploy.yml`), deploying automatically on every commit to `main`.

---

## 7. Automated QA Testing Report

An automated test suite containing **168 rigorous assertions** was executed in Godot 4.7.2 headless mode (`tests/test_game.gd`).

### Results: `168 PASSED, 0 FAILED`

| Category | Checks Performed | Result |
| :--- | :--- | :--- |
| **1600×900 Architecture** | Viewport resolution, camera centering, LevelSelectDialog integration, player spawn. | **PASS** |
| **6 Drone Archetypes** | Scout (105 px/s), Enforcer (2 dmg, 35% stun resist), Hunter (185 px/s chase), Elite Enforcer (3 dmg, 50% stun resist), Stalker (205 px/s chase, 280px det), Titan Overmind (3 dmg, 60% EMP absorption). | **PASS** |
| **Pulse & Overcharge** | Energy deduction (25 EP), Overcharge EMP status, 100% refill, super-pulse consumption. | **PASS** |
| **Dynamic Spawning** | Arena enemies & collectibles containers dynamically populated per level definition. | **PASS** |
| **Wave Progression** | Dynamic percentage-based threat escalation (Infiltration $\rightarrow$ Alert $\rightarrow$ Lockdown $\rightarrow$ Override). | **PASS** |
| **Combo Scoring** | Single drone (+25 score), Multi-drone stun combo calculation (+175 score). | **PASS** |
| **20-Level Campaign** | All 20 levels validated (names, stages 1–5, cores 3–15, par times 40–120s, drone patrols, Level 20 Titan boss). | **PASS** |
| **Star Rating Logic** | 3-star (under par + full health), 2-star (over par + $\ge$2 health), 1-star calculations. | **PASS** |
| **Progression & Unlocking** | Level unlocking (Lvl 1 $\rightarrow$ 2 $\rightarrow$ ... $\rightarrow$ 20), persistent save tracking, Campaign Complete flag. | **PASS** |
| **End States & Records** | Victory overlay with star breakdown, game over dialog, high score persistence. | **PASS** |
| **Mobile Touch Controls** | TouchControls scene present, SettingsManager helper, Player analog touch vector. | **PASS** |
| **Touch Target Standards** | All interactive buttons in LevelSelect, HUD, PauseMenu, and Settings comply with $\ge 44$px touch target standards. | **PASS** |
| **Multi-Viewport Adaptation** | Responsive positioning validated across 5 mobile viewports: 320×568, 360×800, 375×812, 390×844, 412×915. | **PASS** |

---

## 8. How to Run Locally in Godot 4 Editor

1. Open **Godot 4.7.2** on your machine.
2. Select the `last-stand` project from the project list.
3. Press **F5** (or click the **Play** button in the upper right).
4. The game opens in a large, centered 1600×900 window with the Mission Briefing.

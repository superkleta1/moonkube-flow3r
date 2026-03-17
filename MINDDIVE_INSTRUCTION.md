# Mind Dive — Core Mechanics Specification

This document defines the game mechanics for the "Mind Dive" (意识潜入) system. It is the authoritative reference for implementation. All systems described here must be supported.

---

## 1. Grid System

### 1.1 Grid Structure

The game world is a 2D grid. Each cell has exactly one type:

| Cell Type | Code | Walkable by Soul | Can Place Concept Object | Notes |
|-----------|------|-------------------|--------------------------|-------|
| **Path** | `PATH` | Yes | Only Emotion Gates | Standard walkable tile |
| **Wall** | `WALL` | No | No | Physical obstacle, blocks movement and line-of-sight |
| **Concept Slot** | `SLOT` | No | Yes (any type except Emotion Gate) | Dedicated placement position for concept objects. Acts as obstacle when empty or occupied |
| **Door** | `DOOR` | Yes | No | Win condition checkpoint. Soul walks through to "open" it |
| **Start** | `START` | Yes | No | Soul spawn point |
| **End** | `END` | Yes | No | Level exit. Soul must reach this after opening all doors |

### 1.2 Grid Dimensions

Per-level. Tutorial level (John Doe / 无名氏) uses **14 columns × 9 rows**. Origin (0,0) is top-left. Coordinates are `(col, row)`.

### 1.3 Movement

The Soul moves on `PATH`, `DOOR`, `START`, and `END` cells. It cannot enter `WALL` or `SLOT` cells. Movement is grid-based (4-directional or 8-directional — TBD by implementation). The Soul has a **facing direction** based on its last movement.

---

## 2. Soul (魂魄)

### 2.1 Overview

The Soul is an AI-controlled agent. The player does NOT directly control it. The player influences its behavior by placing Concept Objects on the grid before the dive begins. Once the dive starts, the Soul moves autonomously based on the attraction field and its emotional state.

### 2.2 Emotion System

Each Soul has a **bipolar emotion axis** specific to the character. The axis has two poles and a numeric value ranging between them.

- **John Doe (无名氏):** Despair (绝望) ↔ Hope (希望)
- **Qiu (秋):** Pride (骄傲) ↔ Vulnerability (脆弱)
- Other characters will define their own axes.

**Emotion Value:** A single float. Negative = left pole, Positive = right pole, Zero = neutral. (e.g., -100 to +100, or -1.0 to +1.0 — implementation decides scale.)

**Emotion State:** When the emotion value crosses a threshold in either direction, the Soul enters that pole's **Emotion State**. The Soul can only be in one state at a time (left pole state, right pole state, or neutral/no state). Being in an Emotion State **amplifies** the Soul's sensitivity to emotion-related effects from Concept Objects.

### 2.3 Perception — Sensory Channels

Concept Objects influence the Soul through one of three sensory channels:

| Channel | Range | Condition |
|---------|-------|-----------|
| **Visual (视觉)** | Local — cone-shaped field of view, ~4-5 cells radius | Soul must be facing the object AND the object must be within the cone AND not blocked by walls. Influence is **only active while the object remains in the Soul's field of view.** Once the Soul turns away or moves past, the influence stops immediately. |
| **Auditory (听觉)** | Global — entire map | Always active regardless of position or facing. |
| **Olfactory (味觉/嗅觉)** | Global — entire map | Always active regardless of position or facing. |

**Line-of-sight:** Visual concept objects require unobstructed line of sight. Walls and Slots (occupied or empty) block line of sight.

### 2.4 Soul Decision Making

Each tick/step, the Soul evaluates all active Concept Object influences and computes a **net attraction vector**. It then moves toward the direction with the highest net attraction. If no meaningful attraction exists, the Soul wanders (implementation-defined default behavior — could be random walk, could be tendency to move toward grid center, etc.).

---

## 3. Synthesis System (合成系统)

### 3.1 Overview

Before placing Concept Objects on the grid, the player must **synthesize** them from collected **Items** (物品) and **Intel** (情报). Each Concept Object requires a specific combination of one Item + one Intel (or in rare cases, an Item alone).

### 3.2 Resource Constraint

**Each Item and each Intel can only be used once per attempt.** This means the player cannot create all possible Concept Objects in a single run — they must choose which ones to synthesize based on their strategy. This resource allocation IS the first layer of strategic decision-making, before any grid placement happens.

### 3.3 Synthesis Rules

- One Item + one Intel = one Concept Object (standard)
- One Item alone = one Concept Object (special case, e.g., Badge)
- If an Item or Intel has already been used in a synthesis, it is consumed and unavailable for other combinations
- Invalid combinations produce no result (the UI should indicate which combinations are valid)
- The player can undo/redo synthesis choices before confirming and entering the placement phase

---

## 4. Concept Objects (概念物)

### 4.1 Three Base Effects

Every Concept Object's influence on the Soul is reducible to exactly **three parameter types**. There are no other effect types (no "slow", "freeze", "stun", "teleport", etc.). All emergent behaviors arise from combinations of these three:

| Effect Type | Description |
|-------------|-------------|
| **Positive Attraction Weight** | Increases this object's pull on the Soul. Soul is drawn toward it. |
| **Negative Attraction Weight (Repulsion)** | Decreases this object's pull / pushes Soul away. Soul avoids it. |
| **Emotion Value Influence** | Shifts the Soul's emotion value toward one pole or the other. |

A single Concept Object can have one or more of these effects simultaneously. Effects can be **unconditional** (always active) or **conditional** (depends on the Soul's current emotion value/state).

### 4.2 Concept Object Placement Types

| Placement | Where | Notes |
|-----------|-------|-------|
| **Slot-placed** | `SLOT` cells only | Most concept objects. Placed during pre-dive phase. Cannot be on walkable cells. |
| **Emotion Gate (情绪门)** | `PATH` cells only | The only concept object type that can be placed on walkable cells. The Soul walks through it. |

### 4.3 Proximity Interaction Between Concept Objects

**Concept Objects affect each other's attraction weights based on distance.** This is NOT a simple universal rule — it is **individualized per pair of concept objects.** Each pair has a defined interaction:

| Interaction Type | Description |
|------------------|-------------|
| **Resonance (共振)** | Two nearby objects amplify each other's attraction weight |
| **Interference (干扰)** | Two nearby objects weaken each other's attraction weight |
| **Suppression (压制)** | One object weakens ALL nearby objects regardless of type |
| **Neutral** | No interaction — distance has no effect on each other |

The interaction strength scales with distance: stronger when closer, weaker when farther, zero beyond a threshold (implementation-defined falloff curve).

**Preset obstacles with concept object properties also participate in proximity interactions.** They are essentially immovable concept objects baked into the map.

### 4.4 Emotion Gate — Special Mechanics

The Emotion Gate is unique:

- Placed on a `PATH` cell (the only concept object that can be).
- The Soul walks **through** it, not past it.
- **Direction-dependent effect:** The emotion shift depends on which direction the Soul enters the gate from. For example, entering from the left might shift toward Hope, while entering from the right might shift toward Despair. The specific mapping is defined per Emotion Gate instance.
- Only one Emotion Gate can be placed per level (for tutorial level; later levels may allow more or have preset gates).

---

## 5. Win Condition

### 5.1 Level Completion

A level is complete when the Soul has:
1. Passed through **all Doors** on the map (any order).
2. Reached the **End** cell.

Doors open on contact — no additional conditions. There is **no step limit**. The player can retry as many times as needed.

### 5.2 Pre-Dive Phase

Before the dive begins, the player:
1. **Synthesizes** Concept Objects from available Items + Intel (see Section 3). Resource conflicts force strategic choices — not all objects can be created in one run.
2. Places synthesized objects on the grid — Slot-type objects on `SLOT` cells, Emotion Gate on any `PATH` cell.
3. Confirms placement. **All placement is final before the dive starts.** No real-time adjustment during the dive.

Then the dive runs and the Soul moves autonomously.

---

## 6. Level Data — John Doe (Tutorial)

### 6.1 Grid Layout (14×9)

```
Legend: . = PATH, # = WALL, S = START, E = END
        A/B/C = DOOR, 1-9 = SLOT (s1-s9)
        P = PRESET concept obstacle

Row 0: S . . . . # . . . . . . . .
Row 1: . . A . . # . # . . . . C .
Row 2: 1 2 # . 3 . . # 4 . 5 # . .
Row 3: . . . . . . . . . . 6 . . .
Row 4: . # . # . . . P . . # . . .
Row 5: . . . . . . # . # . . . . .
Row 6: . 7 # . . P # . B . # 8 9 .
Row 7: . . . . . . . . . . . . . .
Row 8: # # # # # # # # # # # # # E
```

**Coordinates (col, row):**
- Start: (0, 0)
- End: (13, 8)
- Door A: (2, 1)
- Door B: (8, 6)
- Door C: (12, 1)
- Slot s1: (0, 2), s2: (1, 2) — **twin horizontal**
- Slot s3: (4, 2)
- Slot s4: (8, 2)
- Slot s5: (10, 2), s6: (10, 3) — **twin vertical**
- Slot s7: (1, 6)
- Slot s8: (11, 6), s9: (12, 6) — **twin horizontal**
- Preset "Bed": (7, 4)
- Preset "Light": (5, 6)
- Chokepoint: (6, 0) — single-width path, natural position for Emotion Gate

### 6.2 Soul Profile — John Doe

- **Emotion Axis:** Despair ↔ Hope
- **Default State:** Slightly toward Despair (implementation decides exact starting value)
- **Behavior:** Wanderer. No strong directional intent. Moves based on attraction field. In absence of stimuli, drifts loosely (no fixed patrol route).

### 6.3 Synthesis Table

**Items (5):**

| ID | Name | Used By |
|----|------|---------|
| `wilted_flower` | Wilted Flower (枯萎的花) | `bouquet` OR `bandage` |
| `glass_bottle` | Glass Bottle (碎玻璃瓶) | `trash_art` OR `kaleidoscope` OR `echo` (pick ONE) |
| `twisted_wire` | Twisted Wire (扭曲的铁丝) | `kaleidoscope` |
| `badge_item` | Badge (工牌) | `badge` (no intel required) |
| `window_frame` | Window (窗户) | `window` |

**Intel (4):**

| ID | Name | Used By |
|----|------|---------|
| `dump_report` | Dump Sighting Report (垃圾场目击报告) | `trash_art` OR `window` (pick ONE) |
| `medical_record` | Medical Record (病历摘要) | `echo` |
| `scent` | Scent (香味) | `bouquet` OR `kaleidoscope` (pick ONE) |
| `self_harm` | Self-Harm Tendency (自残倾向) | `bandage` |

**Valid Recipes:**

| Item | + Intel | → Concept Object ID | Concept Object Name |
|------|---------|---------------------|---------------------|
| `wilted_flower` | `scent` | `bouquet` | Glowing Bouquet (闪着光的花束) |
| `glass_bottle` | `dump_report` | `trash_art` | "Trash" Art ("垃圾"作品) |
| `twisted_wire` | `scent` | `kaleidoscope` | Kaleidoscope (万花筒) |
| `wilted_flower` | `self_harm` | `bandage` | Bloody Bandage & Petals (染血绷带与花瓣) |
| `glass_bottle` | `medical_record` | `echo` | Echo Bottle (回声瓶子) |
| `badge_item` | *(none)* | `badge` | Badge (工牌) |
| `window_frame` | `dump_report` | `window` | Burned Windowsill (烧毁的窗沿) |

**Resource Conflicts (player must choose):**

- `glass_bottle` → 3 possible outputs, pick 1
- `wilted_flower` → 2 possible outputs, pick 1
- `scent` → 2 possible outputs, pick 1
- `dump_report` → 2 possible outputs, pick 1

**Max concept objects per run: 4-5** (depending on choices). Badge is always available (free slot).

### 6.4 Concept Object Properties

**Global (Auditory/Olfactory):**

| ID | Name | Channel | Effect |
|----|------|---------|--------|
| `bouquet` | Glowing Bouquet (闪着光的花束) | Olfactory / Global | Increases Hope value |
| `echo` | Echo Bottle (回声瓶子) | Auditory / Global | Increases Despair value |

**Local (Visual):**

| ID | Name | Channel | Effect |
|----|------|---------|--------|
| `trash_art` | "Trash" Art ("垃圾"作品) | Visual / Local | **Conditional:** Hope state → positive attraction. Despair state → negative attraction. |
| `kaleidoscope` | Kaleidoscope (万花筒) | Visual / Local | **Unconditional:** positive attraction |
| `bandage` | Bloody Bandage & Petals (染血绷带与花瓣) | Visual / Local | **Conditional:** Despair state → positive attraction. Hope state → negative attraction. (Inverse of trash_art) |
| `badge` | Badge (工牌) | Visual / Local | **Unconditional:** negative attraction (repulsion). **Suppression aura:** weakens all nearby concept objects. |

**Emotion Gate (Path-placed):**

| ID | Name | Placement | Effect |
|----|------|-----------|--------|
| `window` | Burned Windowsill (烧毁的窗沿) | Any PATH cell | **Direction-dependent:** entering from one direction → shifts toward Hope on exit. Entering from opposite direction → shifts toward Despair on exit. |

### 6.5 Concept Object Proximity Interactions

When two concept objects (including presets) are within proximity range of each other, they affect each other's attraction weights:

| Object A | Object B | Interaction | Narrative Reason |
|----------|----------|-------------|------------------|
| `bouquet` | `kaleidoscope` | **Resonance** — both strengthen | Light and flowers are the same memory of beauty |
| `bouquet` | `echo` | **Interference** — both weaken | Hope (flowers from outside) and solitary expression (night humming) belong to different emotional spaces |
| `trash_art` | `bandage` | **Resonance** — both strengthen (in matching emotion state) | Creation and pain are inseparable for John Doe |
| `echo` | `trash_art` | **Resonance** — echo's emotion effect amplified | Solitary humming and solitary creation are the same act |
| `badge` | ANY other | **Suppression** — weakens the other object | Institutional identity negates all individuality |
| `bouquet` | `bandage` | **Neutral** | No inherent connection |
| `kaleidoscope` | `echo` | **Neutral** | No inherent connection |

### 6.6 Preset Obstacle Properties

| Preset | Position | Properties |
|--------|----------|------------|
| **Bed** (病床的轮廓) | (7, 4) | Continuous weak **repulsion**. When Soul is in Hope state, repulsion decreases to near zero. (He fears the hospital bed, but hope diminishes that fear.) |
| **Light** (窗外的光) | (5, 6) | Continuous weak **positive attraction**. When Soul is in Despair state, attraction **greatly increases**. (The light outside the window becomes the only thing he wants when he's at his lowest.) |

---

## 7. Implementation Notes

### 7.1 Attraction Field Computation

Each tick, for each active concept object visible/audible to the Soul:
1. Compute base attraction weight (positive or negative) based on the object's effect definition.
2. Apply emotion-conditional modifier if applicable (check Soul's current emotion value/state).
3. Apply proximity interaction modifiers from nearby concept objects (scale by distance).
4. Sum all attraction vectors to produce a net direction.
5. Soul moves one cell in the direction of highest net attraction (with some noise/randomness to avoid perfectly deterministic paths — implementation decides amount).

### 7.2 Emotion Value Update

Each tick:
1. Apply emotion influence from all active global concept objects (always).
2. Apply emotion influence from active visual concept objects (only while in view).
3. If Soul stepped through an Emotion Gate this tick, apply the gate's direction-dependent emotion shift.
4. Clamp emotion value to axis range.
5. Check threshold crossings for Emotion State transitions.

### 7.3 Visual Field of View

The Soul has a **cone-shaped FOV** based on its facing direction:
- **Radius:** ~4-5 cells (exact value: implementation parameter, tunable)
- **Angle:** Implementation-defined (e.g., 90° or 120° cone)
- **Blocked by:** `WALL` cells, `SLOT` cells (whether empty or occupied)
- Concept objects in SLOT cells that are within the cone AND have line-of-sight are active. The SLOT cell itself blocks further line-of-sight behind it.

### 7.4 Proximity Interaction Range

- Concept objects within ~2-3 cells of each other trigger proximity interactions.
- Interaction strength falls off with distance (linear or inverse-square — tunable).
- Preset obstacles participate in proximity interactions as if they were placed concept objects.

### 7.5 Key Design Constraints

- **No step limit.** Players can retry freely.
- **No real-time placement.** All concept objects placed before dive starts.
- **Doors open on contact.** No additional conditions.
- **Door order is free.** Any sequence of A, B, C is valid.
- **Empty SLOT cells are obstacles.** They block movement and line of sight just like walls.
- **Visual influence requires sustained line-of-sight.** Once the Soul looks away or moves past, the influence stops immediately. This is NOT a "seen once = permanent" system.

---

## 8. System Extension Points

These are designed into the system but NOT needed for the tutorial level. Flag them in code architecture so they're easy to add later:

- **Multiple Emotion Gates per level** (tutorial uses exactly 1)
- **Preset Emotion Gates** baked into the map (tutorial has none)
- **Preset Concept Objects on SLOT cells** that the player cannot remove (tutorial's presets are obstacle-type, future levels may have slot-type presets)
- **Different emotion axes per character** (system must support arbitrary axis definition, not hardcode Despair/Hope)
- **Achievement / 3-star scoring system** (deferred, no implementation needed now)
- **Slot system for Items + Intel combination** (MVP uses simple 1-to-1 mapping; future: items have multiple slots for different intel pieces)

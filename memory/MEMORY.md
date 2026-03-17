# MoonKube Flow3r — Claude Memory

## Project Overview
Godot 4.5 game. Main mechanic: **MindDive** — the player places concept objects on a grid before a "Soul" AI character navigates autonomously toward a level exit.

## Key Architecture

### Autoloads
- `RunContext` — stores `crafted_concepts: Array[ConceptItem]` between prep and dive scenes
- `Database`, `CodexManager`

### MindDive Flow
1. `MindDivePrep.tscn` → player crafts concept items from base items + information
2. `MindDive.tscn` → player places items on grid, then Soul executes
3. `MindDiveCompleted.tscn` → win screen

### Core Scripts (res://scripts/minddive_planning_execution/)
- `minddive_manager.gd` — orchestrates PLANNING ↔ EXECUTION states
- `planning_mode.gd` (class: PlanningMode3D) — 3D raycast placement
- `execution_mode.gd` (class: ExecutionMode) — emotion axis, item influence calc, door/end detection
- `spirit_grid_mover.gd` (class: SpiritGridMover) — pathfinding, FOV, LOF, cell scoring
- `placed_concept_item.gd` (class: PlacedConceptItem) — holds concept + cell + 3D visual

### Resource Scripts (res://scripts/minddive_preparation/)
- `concept_item.gd` UID: `uid://603685oo3hdu`
- `proximity_rule.gd` UID: `uid://dtj3w6ptpyu6w`
- `base_item.gd` UID: `uid://c55vj86c1k1ps`
- `information.gd` UID: `uid://bxmmyjrshxol6`
- `concept_recipe.gd` UID: `uid://0xgkcidj3dgq`
- `prep_config.gd` UID: `uid://ccahui6vomi2i`

### GridMap IDs (must match mvp_mesh_library.tres)
- 0: PATH (plain walkable, absent in level GridMap = implicit)
- 1: START
- 2: END
- 3: DOOR
- 4: SLOT
- 5: WALL

## John Doe Tutorial Level — Implemented
See `resources/johndoe/` for all resources. See details in [minddive.md](minddive.md).

### John Doe — Emotion Axis
- Left pole: Despair, Right pole: Hope
- Starting value: -15 (neutral, slightly toward Despair)
- Thresholds: left ≤ -30, right ≥ 30

### Preset Items in MindDive.tscn
- Bed at cell Vector3i(7,0,4) — weak repulsion; Hope state neutralizes it
- Light at cell Vector3i(5,0,6) — weak attraction; Despair state greatly amplifies it

---
title: "feat: Tower Stacking Gameplay Loop"
type: feat
status: active
date: 2026-04-20
deepened: 2026-04-20
---

# Tower Stacking Gameplay Loop

## Enhancement Summary

**Deepened on:** 2026-04-20
**Research agents used:** physics-stacking, touch-input, camera-follow, architecture-review, performance-review

### Key Improvements
1. Physics tick rate 120Hz + interpolation for stable stacking (not just solver iterations)
2. Use `sleeping_state_changed` signal instead of manual frame counting for settle detection
3. Single `_draw()` per block instead of multiple ColorRect nodes (4x fewer draw calls)
4. Solver iterations reduced to 8 (from planned 32) — freeze strategy handles stability
5. Touch input unified via `emulate_touch_from_mouse` — single code path
6. Asymmetric camera follow (fast up, slow down) with collapse delay

### Architecture Changes from Review
- BlockInputHandler should be a component on the active Block (not standalone)
- UI buttons wire directly in main.gd (not through Events bus)
- Block exposes API methods, external code never sets physics properties directly

## Overview

Physics-based tower stacking game where different shapes drop from the top of the screen. Players position falling blocks horizontally and stack them as high as possible. Score is determined by tower height. Uses Godot's RigidBody2D physics for realistic gravity and collision.

## Problem Statement / Motivation

The project is bootstrapped with autoloads (Events, GameState) but has no gameplay. This plan implements the core gameplay loop: spawn → control → stack → score → game over → restart.

## Proposed Solution

### Input Model: Drag Horizontal + Tap Fast-Drop

- **Project Settings**: `emulate_touch_from_mouse = true`, `emulate_mouse_from_touch = false` — single code path using `InputEventScreenTouch`/`InputEventScreenDrag`
- **Touch/Mouse**: drag block left/right (finger 0), tap with finger 1 to rotate, swipe down for fast drop
- **Keyboard**: A/D or Left/Right to move, Q/E to rotate, Space for fast drop
- **Input handler**: `_unhandled_input` so UI buttons automatically block gameplay input
- **Smoothing**: exponential lerp (weight 0.15) on horizontal position prevents touchscreen jitter
- **Dead zone**: 8 viewport-px before registering drag intent
- **Swipe detection**: `InputEventScreenDrag.velocity.y > 1200` + min distance 80px + direction ratio check
- Block falls under gravity at all times; player only controls horizontal position

### Game Over Condition

- A block's center exits the viewport sides/bottom after placement → game over
- Kill zone Area2D below and beside viewport detects lost blocks

### Camera

- **Asymmetric follow**: fast lerp up (speed 6.0), slow lerp down (speed 3.0) in `_physics_process`
- **Look-ahead**: 150px offset above tower top so spawn area stays visible
- **Collapse handling**: 0.3s hold, then `move_toward` at max 400 px/s downward (prevents motion sickness)
- **Zoom**: gradual zoom-out as tower grows (1.0 → 0.5 over 2000px height)
- **Limits**: `limit_bottom` set so ground sits at screen bottom, `limit_smoothed = true`
- **Process callback**: `CAMERA2D_PROCESS_PHYSICS` to sync with RigidBody2D updates
- Spawn point rises with camera (Marker2D as sibling, position updated by controller)

### Block Shapes (MVP: 4 simple shapes)

1. **Square** (2×2 grid units)
2. **Rectangle Horizontal** (3×1)
3. **Rectangle Vertical** (1×3)
4. **L-Shape** (2×2 with one cell missing)

Grid unit = 48px (720px viewport / 15 columns). Blocks use a single `_draw()` override (not per-segment ColorRect) for rendering, and merged `RectangleShape2D` or `ConvexPolygonShape2D` for collision (not per-segment shapes). This reduces draw calls and broadphase entries by 4x.

### Physics Stability Strategy

- **Physics tick rate**: 120 Hz (`Engine.physics_ticks_per_second = 120`) — single most effective stacking stabilizer
- **Physics interpolation**: enabled (`physics/common/physics_interpolation = true`) — eliminates visual jitter
- **Solver iterations**: 8 (half default) — freeze strategy handles rest stability, not brute-force solving
- **CCD**: `CCD_MODE_CAST_RAY` on active falling block only, disabled on settled blocks
- **PhysicsMaterial**: friction 1.0, bounce 0.0, rough true (prevents sliding, no bouncing)
- **Freeze via `sleeping_state_changed` signal** — zero-cost detection, no per-frame polling
- Frozen blocks stay as RigidBody2D with `freeze = true, freeze_mode = FREEZE_MODE_STATIC` (do NOT convert to StaticBody2D — marginal gain, high complexity)
- `call_deferred("set", "freeze", true)` — never freeze inside physics callbacks (Godot issue #85371)
- Keep all blocks at uniform mass (1.0) — large mass ratios cause solver instability
- Max ~5 unfrozen blocks at any time (active piece + recently settled)

### Scoring

- `current_height` = distance from ground to topmost settled block's top edge (in pixels)
- Score = `int(current_height / 48.0)` (block units)
- `score_changed` fires on each `block_placed`
- `high_score_beaten` fires when score exceeds saved high score

### Ground

- StaticBody2D spanning full viewport width (720px) at y=1200 (near bottom)
- Visible as a platform sprite

## Technical Considerations

- **Physics jitter**: 120Hz tick rate + interpolation + aggressive freeze via `sleeping_state_changed`
- **Performance on web**: max 5 active bodies; single `_draw()` per block; solver iterations at 8; WASM is 30-50% slower than native for physics
- **Touch input**: unified via `emulate_touch_from_mouse`; `_unhandled_input` only; exponential lerp smoothing
- **Portrait layout**: 720×1280 viewport, UI at top via CanvasLayer, gameplay fills rest
- **Never set `position` directly on active RigidBody2D** — use velocity or `_integrate_forces`; direct sets desync physics state
- **Collision shapes slightly inset** (1-2px smaller than visual) to prevent micro-overlaps that cause push-apart
- **Spawn safety**: always spawn above tower with clear gap; raycast to find safe spawn Y

## System-Wide Impact

- **Signal chain**: Player drops block → block settles → `block_placed` emitted by block entity → gameplay controller hears it → updates GameState.current_height → emits `score_changed` → HUD updates. On lost block → `block_dropped` → gameplay controller → `game_over(final_height)`
- **Error propagation**: assert on all @export and @onready in _ready(). Push_error if block scene fails to instantiate.
- **State lifecycle**: GameState.is_playing gates spawning. On restart, queue_free all blocks, reset GameState, camera returns to start.
- **Scene interface parity**: main.tscn instantiates gameplay.tscn. No other scenes expose similar functionality yet.

## Acceptance Criteria

- [ ] Blocks spawn at top of screen and fall under gravity
- [ ] Player can drag blocks horizontally (touch + mouse + keyboard)
- [ ] Player can rotate blocks (tap on block / Q,E keys)
- [ ] Player can fast-drop (swipe down / Space)
- [ ] Blocks stack physically on each other and the ground
- [ ] Settled blocks freeze to prevent jitter
- [ ] Camera follows tower height upward
- [ ] Score displays current height in block units
- [ ] High score persists between sessions (GameState already handles this)
- [ ] Game over triggers when a block exits the play area
- [ ] Game over screen shows final score and high score
- [ ] Restart button resets everything
- [ ] Main menu with Play button
- [ ] At least 4 distinct block shapes
- [ ] No errors in debug output during normal gameplay
- [ ] Runs at 60fps on web export

## Implementation Phases

### Phase 1: Foundation (features/blocks/, features/tower/)

**Files to create:**

- `features/blocks/scenes/block.tscn` — base RigidBody2D block scene
- `features/blocks/scripts/block.gd` — block entity script (freeze logic, bounds check)
- `features/blocks/scripts/block_data.gd` — Resource class defining shape (array of Vector2i cell offsets)
- `features/blocks/resources/block_square.tres` — square shape data
- `features/blocks/resources/block_rect_h.tres` — horizontal rectangle
- `features/blocks/resources/block_rect_v.tres` — vertical rectangle
- `features/blocks/resources/block_l.tres` — L-shape
- `features/tower/scripts/ground.gd` — ground StaticBody2D script
- `features/tower/scenes/ground.tscn` — ground scene

**Key implementation:**
```gdscript
# features/blocks/scripts/block.gd
class_name Block
extends RigidBody2D

signal settled(block: Block)
signal lost(block: Block)

@export var block_data: BlockData
@export var block_color: Color = Color.WHITE

func _ready() -> void:
    assert(block_data != null, "Block requires block_data")
    set_process(false)
    set_physics_process(false)
    freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
    continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
    var mat := PhysicsMaterial.new()
    mat.friction = 1.0
    mat.bounce = 0.0
    mat.rough = true
    physics_material_override = mat
    sleeping_state_changed.connect(_on_sleeping_state_changed)

func _draw() -> void:
    for cell: Vector2i in block_data.cells:
        var rect := Rect2(Vector2(cell) * 48.0, Vector2(48.0, 48.0))
        draw_rect(rect, block_color)

func _on_sleeping_state_changed() -> void:
    if sleeping:
        call_deferred("_freeze_block")

func _freeze_block() -> void:
    continuous_cd = RigidBody2D.CCD_MODE_DISABLED
    freeze = true
    settled.emit(self)

func activate_fall() -> void:
    freeze = false
    sleeping = false
```

### Phase 2: Gameplay Controller (features/gameplay/)

**Files to create:**

- `features/gameplay/scenes/gameplay.tscn` — orchestrator scene (contains Camera2D, spawn marker, kill zones)
- `features/gameplay/scripts/gameplay_controller.gd` — spawning, input routing, game flow
- `features/gameplay/scripts/block_spawner.gd` — random block selection, instantiation
- `features/gameplay/scripts/block_input_handler.gd` — touch/mouse/keyboard input for active block

**Key implementation:**
```gdscript
# features/gameplay/scripts/gameplay_controller.gd
class_name GameplayController
extends Node2D

@onready var _camera: Camera2D = %Camera
@onready var _spawn_marker: Marker2D = %SpawnMarker
@onready var _block_container: Node2D = %BlockContainer
@onready var _kill_zone: Area2D = %KillZone

var _active_block: Block = null
var _block_spawner: BlockSpawner
```

### Phase 3: Camera (features/camera/)

**Files to create:**

- `features/camera/scripts/tower_camera.gd` — smooth follow component for Camera2D

**Key behavior:** lerp camera.position.y toward highest settled block minus padding. Clamp so ground is visible at start.

### Phase 4: UI (features/ui/)

**Files to create:**

- `features/ui/scenes/hud.tscn` — score label, height display (CanvasLayer)
- `features/ui/scripts/hud.gd` — listens to score_changed, high_score_beaten
- `features/ui/scenes/game_over_panel.tscn` — final score, high score, restart button
- `features/ui/scripts/game_over_panel.gd` — listens to game_over, emits ui_restart_pressed
- `features/ui/scenes/main_menu.tscn` — title, play button
- `features/ui/scripts/main_menu.gd` — emits ui_play_pressed

### Phase 5: Integration (main/)

**Files to modify:**

- `main/main.gd` — instantiate gameplay scene, connect UI scenes, handle game flow
- `main/main.tscn` — add CanvasLayer for UI, instance gameplay scene

**Files to potentially modify:**

- `autoload/Events.gd` — verify signal signatures match implementation (block: Block not Node2D)
- `project.godot` — physics_ticks_per_second=120, physics_interpolation=true, solver_iterations=8, emulate_touch_from_mouse=true

### Phase 6: Polish

- Difficulty curve: fall speed increases with height (gravity_scale ramp)
- Next-block preview in HUD
- Screen shake on block placement
- Color coding per shape type
- Sound effects (stretch goal)

## Architecture Diagram

```
main.tscn (Main)
├── CanvasLayer (UI)
│   ├── MainMenu
│   ├── HUD
│   └── GameOverPanel
└── Gameplay (Node2D)
    ├── Camera2D (TowerCamera)
    ├── Ground (StaticBody2D)
    ├── BlockContainer (Node2D)
    │   ├── Block (RigidBody2D) [settled, frozen]
    │   ├── Block (RigidBody2D) [settled, frozen]
    │   └── Block (RigidBody2D) [active, falling]
    ├── SpawnMarker (Marker2D)
    ├── KillZoneBottom (Area2D)
    ├── KillZoneLeft (Area2D)
    └── KillZoneRight (Area2D)
```

## Signal Flow

```
Player Input → BlockInputHandler → active Block (position/rotation)
Block lands → Block.settled signal → GameplayController
  → calculates height → GameState.current_height
  → Events.block_placed(block, height)
  → Events.score_changed(new_score)
  → spawns next block

Block lost → KillZone.body_entered → GameplayController
  → Events.block_dropped(block)
  → Events.game_over(final_height)

UI Play → Events.ui_play_pressed → main.gd → show gameplay
UI Restart → Events.ui_restart_pressed → main.gd → reset all
```

## Dependencies & Risks

- **Physics instability**: Mitigated by freeze strategy and solver iteration increase
- **Touch input precision**: 360px window width on mobile is narrow; may need larger blocks or snap-to-grid
- **Performance on web**: RigidBody2D count must stay low; freeze + convert strategy essential
- **No existing art**: Using ColorRect placeholders; can swap for sprites later

## Sources & References

- Events autoload: [Events.gd](autoload/Events.gd) — pre-defined signals for game flow
- GameState autoload: [GameState.gd](autoload/GameState.gd) — score and state tracking
- Project settings: [project.godot](project.godot) — viewport, physics defaults

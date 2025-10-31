# Ship-to-Ship Collision Disabled

## Summary
Disabled ship-to-ship collisions to prevent ships from bumping into each other while still allowing them to collide with resources and be hit by projectiles.

## Changes Made

### 1. BaseUnit.gd (Line 763-764)
**Commented out the line that enabled ship-to-ship collision checking:**
```gdscript
# Ship-to-ship collisions disabled - ships don't check layer 1 (Units)
# set_collision_mask_value(1, collision_enabled)
```

This prevents ships from checking for collisions with other units on Layer 1.

## Collision Layer System

The game uses the following collision layers (defined in `project.godot`):

| Layer | Name | Description |
|-------|------|-------------|
| 1 | Units | All ships (player and enemy) |
| 2 | Resources | Asteroids and resource nodes |
| 3 | Buildings | Stations, turrets, spawners |
| 4 | Projectiles | Bullets, missiles, projectiles |
| 5 | Selection | Selection/UI interactions |

## How It Works

### Ships (All types: Player, Enemy, Custom)
- **collision_layer = 1** (Units layer)
  - Ships exist on layer 1 so projectiles can detect and hit them
- **collision_mask = 2** (Resources layer only)
  - Ships only check for collisions with resources (asteroids)
  - Ships do NOT check layer 1, so they pass through other ships

### Projectiles
- **collision_layer = 16** (Layer 5 - Projectiles)
- **collision_mask = 1 + 2** (Layers 1-2: Units + Resources)
  - Projectiles can hit ships and resources

### Resources (Asteroids)
- **collision_layer = 2** (Resources layer)
- **collision_mask = 0** (No collision checking)
  - Asteroids are static obstacles

## Affected Units
All ship types automatically inherit this behavior from `BaseUnit.tscn`:
- Player ships: CommandShip, CustomShip, all drone types
- Enemy ships: EnemyFighter, EnemyCruiser, EnemyBomber

## Benefits
1. **Better movement**: Ships glide past each other smoothly
2. **Less physics overhead**: Fewer collision checks between ships
3. **Improved pathfinding**: Ships don't get stuck on each other
4. **Formation flying**: Ships can maintain tight formations without bouncing

## Technical Note
Ships still use `set_collision_layer_value(1, collision_enabled)` for performance optimization - this disables the ship's collision layer entirely when very far from camera, preventing projectiles from hitting off-screen ships. The collision_mask remains at layer 2 (Resources) only.


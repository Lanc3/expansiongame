# Ship Blueprints Directory

This directory contains saved ship blueprints created in the Cosmoteer-style ship builder.

## File Format

Blueprints are saved as Godot `.tres` resource files containing:
- Blueprint name
- Hull cell layout (20x20 grid)
- Component placements
- Grid size information

## Usage

### In-Game
1. **Create Blueprints:** Main Menu → "Blueprint" button
2. **Save Location:** Blueprints automatically save here as `[name].tres`
3. **Load in Builder:** Use "Load" button in ship builder
4. **Build Ships:** Construct a Shipyard building → Select blueprint from library

### Debug Testing
- Press **K** in-game to instantly spawn your last saved blueprint ship

## Example Blueprint Structure

```gdscript
[resource]
blueprint_name = "Fighter_MK1"
grid_size = Vector2i(20, 20)
hull_cells = {Vector2i(0,0): 0, Vector2i(1,0): 1, ...}  # position: hull_type
components = [
    {type: "power_core", grid_position: Vector2i(5,5), size: Vector2i(2,2)},
    {type: "engine", grid_position: Vector2i(7,7), size: Vector2i(2,2)},
    {type: "laser_weapon", grid_position: Vector2i(9,9), size: Vector2i(1,2)}
]
```

## Version Control

Blueprint files are tracked in git, so team members can share ship designs!


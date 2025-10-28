# Zone ID Migration Guide

## Status - ALL CRITICAL SYSTEMS COMPLETE ✅

**Core Systems**:
- EntityManager ✅
- ZoneManager ✅
- ZoneProcessingManager ✅
- ZoneBoundary ✅
- ZoneSetup ✅

**Data Systems**:
- BuildingDatabase ✅
- ResourceDatabase ✅

**Spawning Systems**:
- ResourceSpawner ✅
- EnemySpawnerSystem ✅
- LootDropSystem ✅

**Fog of War**:
- FogOfWarManager ✅
- FogOverlay ✅
- FogOverlayDirect ✅

**Managers**:
- BlueprintManager ✅
- SatelliteManager ✅
- SaveLoadManager ✅
- EventManager ✅

**Buildings**:
- BaseTurret ✅
- Shipyard ✅
- ResearchBuilding ✅
- EnemySpawner ✅
- ConstructionGhost ✅

**World/Units**:
- Wormhole ✅
- WormholeTravelAnimation ✅
- Planet ✅

**UI**:
- Minimap ✅
- ZoneSwitcher ✅
- WormholeInfoPanel ✅
- UIController ✅

**Other**:
- OrbitalAsteroidManager ✅
- TestScenarioSetup ✅
- BuilderDrone ✅

## MIGRATION COMPLETE ✅

All critical files have been successfully migrated to use String zone IDs. The game should now compile without errors!

## Overview
The zone system has been updated from integer-based zone IDs to String-based IDs to support dynamic zone generation. Many files still use `int` zone IDs and need to be updated.

---

## Files Requiring Updates

### CRITICAL (Game-Breaking - Must Fix)
These files will cause immediate errors and must be fixed before the game can run:

1. **`scripts/systems/ZoneProcessingManager.gd`** ⚠️ HIGH PRIORITY
   - `var active_zone_id: int = 1` → `var active_zone_id: String = ""`
   - `func set_active_zone(zone_id: int)` → `func set_active_zone(zone_id: String)`
   - `func move_entities_to_inactive(zone_id: int)` → String
   - `func move_entities_to_active(zone_id: int)` → String
   - `func get_zone_buildings(zone_id: int)` → String
   - `func on_unit_spawned(unit, zone_id: int)` → String
   - `func on_building_created(building, zone_id: int)` → String

2. **`scripts/systems/ZoneBoundary.gd`** ⚠️ HIGH PRIORITY
   - `var zone_id: int = 1` → `var zone_id: String = ""`
   - `func setup_for_zone(p_zone_id: int, zone_bounds: Rect2)` → String

3. **`scripts/systems/FogOfWarManager.gd`** ⚠️ HIGH PRIORITY
   - All signal parameters: `int` → `String`
   - All function parameters accepting zone_id
   - Dictionary keys for fog_grids need to support String keys

4. **`scripts/systems/ResourceSpawner.gd`** ⚠️ HIGH PRIORITY
   - `func spawn_resources_for_zone(zone_id: int, zone_data: Dictionary)` → String
   - `func generate_zone_composition(asteroid, zone_id: int)` → String

5. **`scripts/systems/EnemySpawnerSystem.gd`** ⚠️ HIGH PRIORITY
   - All zone_id parameters: `int` → `String`

### IMPORTANT (UI & Features - Should Fix Soon)

6. **`scripts/ui/ZoneSwitcher.gd`** 🔸 MEDIUM PRIORITY
   - `var current_zone_id: int = 1` → `var current_zone_id: String = ""`
   - `func _on_zone_switched(from_zone_id: int, to_zone_id: int)` → String

7. **`scripts/ui/Minimap.gd`** 🔸 MEDIUM PRIORITY
   - `var current_zone_id: int = 1` → `var current_zone_id: String = ""`
   - `func _on_zone_switched(from_zone_id: int, to_zone_id: int)` → String

8. **`scripts/ui/FogOverlay.gd` & `scripts/ui/FogOverlayDirect.gd`** 🔸 MEDIUM PRIORITY
   - Update zone_id tracking and signal handlers

9. **`scripts/ui/WormholeInfoPanel.gd`** 🔸 MEDIUM PRIORITY
   - `signal travel_requested(target_zone_id: int)` → String
   - `var current_zone_id: int = -1` → `var current_zone_id: String = ""`

10. **`scripts/systems/UIController.gd`** 🔸 MEDIUM PRIORITY
    - `func _on_wormhole_travel_requested(target_zone_id: int)` → String

### LOW PRIORITY (Building/Unit Exports - Can Default)

11. **Building/Unit Scripts** 🔹 LOW PRIORITY
    - `scripts/buildings/BaseTurret.gd`
    - `scripts/buildings/Shipyard.gd`
    - `scripts/buildings/ResearchBuilding.gd`
    - `scripts/buildings/EnemySpawner.gd`
    - `scripts/buildings/ConstructionGhost.gd`
    - `scripts/world/Planet.gd`
    
    **Fix**: Change `@export var zone_id: int = 1` to `@export var zone_id: String = "d1_start"`
    
    **Note**: These can temporarily work with empty strings as EntityManager auto-detects zone

### DATA/HELPER (Non-Critical)

12. ~~**`scripts/data/BuildingDatabase.gd`**~~ ✅ COMPLETE

13. ~~**`scripts/data/ResourceDatabase.gd`**~~ ✅ COMPLETE

14. **`scripts/systems/EventManager.gd`** 🔹 LOW PRIORITY
    - Zone tracking variables

15. **`scripts/systems/LootDropSystem.gd`** 🔹 LOW PRIORITY
    - Zone parameter functions

16. **`scripts/autoloads/SatelliteManager.gd`** 🔹 LOW PRIORITY
    - Signal and function parameters

17. **`scripts/autoloads/BlueprintManager.gd`** 🔹 LOW PRIORITY
    - `func build_blueprint(..., zone_id: int, ...)` → String

---

## Quick Fix Template

### For Signal Declarations
```gdscript
# OLD
signal zone_switched(from_zone_id: int, to_zone_id: int)

# NEW
signal zone_switched(from_zone_id: String, to_zone_id: String)
```

### For Function Parameters
```gdscript
# OLD
func some_function(zone_id: int):
    if zone_id == -1:
        zone_id = ZoneManager.get_unit_zone(unit)

# NEW
func some_function(zone_id: String = ""):
    if zone_id.is_empty():
        zone_id = ZoneManager.get_unit_zone(unit) if ZoneManager else ""
```

### For Variables
```gdscript
# OLD
var current_zone_id: int = 1

# NEW
var current_zone_id: String = "d1_start"  # or "" for auto-detect
```

### For Comparisons
```gdscript
# OLD
if zone_id == 1:

# NEW  
if zone_id == "d1_start":  # Specific zone
# OR
if zone_id == ZoneManager.current_zone_id:  # Current zone
# OR
var zone = ZoneManager.get_zone(zone_id)
if zone.difficulty == 1:  # Check difficulty
```

---

## Temporary Workaround

To get the game running quickly without fixing all files:

1. **Comment out non-critical systems**: 
   - Enemy spawning
   - Events
   - Some UI elements

2. **Focus on core systems first**:
   - ✅ ZoneManager (done)
   - ✅ EntityManager (done)
   - ⚠️ ZoneProcessingManager (do next)
   - ⚠️ ZoneBoundary (do next)
   - ⚠️ FogOfWarManager (do next)
   - ⚠️ ResourceSpawner (do next)

3. **Test with minimal setup**:
   - Single zone
   - Basic wormhole travel
   - Galaxy map display

---

## Migration Priority Order

**Phase 1 - Core Systems** (Required for game to run):
1. ZoneProcessingManager ⚠️
2. ZoneBoundary ⚠️
3. FogOfWarManager ⚠️
4. ResourceSpawner ⚠️
5. EnemySpawnerSystem ⚠️

**Phase 2 - UI Systems** (Required for full functionality):
6. ZoneSwitcher 🔸
7. Minimap 🔸
8. FogOverlay/FogOverlayDirect 🔸
9. WormholeInfoPanel 🔸
10. UIController 🔸

**Phase 3 - Buildings/Units** (Can use defaults):
11. All building/unit @export vars 🔹

**Phase 4 - Data/Helpers** (Low impact):
12. Databases and helper systems 🔹

---

## Testing After Migration

After each phase, test:
- [ ] Game starts without errors
- [ ] Can load into starting zone
- [ ] Can see and select units
- [ ] Wormholes appear and are clickable
- [ ] Can travel through wormholes
- [ ] New zones generate correctly
- [ ] Galaxy map opens (M key)
- [ ] Zone markers display correctly
- [ ] Resources spawn in zones
- [ ] Fog of war works

---

## Common Errors & Fixes

### Error: "Invalid argument for function: argument X should be String but is int"
**Fix**: Update the function call site to pass String instead of int

### Error: "Cannot compare int with String"
**Fix**: Update comparison to use String comparison or check difficulty level instead

### Error: "Cannot use int as Dictionary key when String expected"
**Fix**: Update Dictionary keys to String type

### Error: "zone_id is empty/null"
**Fix**: Ensure zone_id is set when registering entities. Use `ZoneManager.current_zone_id` as default.

---

## Completed Fixes

✅ `scripts/autoloads/ZoneManager.gd` - Complete rewrite for dynamic zones  
✅ `scripts/autoloads/EntityManager.gd` - All methods updated to String  
✅ `scripts/world/Wormhole.gd` - Updated to String zone IDs  
✅ `scripts/systems/ZoneSetup.gd` - Updated for dynamic generation  
✅ `scripts/systems/WormholeTravelAnimation.gd` - Fixed zone switching  
✅ `scripts/data/BuildingDatabase.gd` - All zone functions updated to String  
✅ `scripts/data/ResourceDatabase.gd` - Zone tier lookup updated to use difficulty

---

## Notes

- String zone IDs enable unlimited procedural generation
- Empty string `""` means "auto-detect zone" 
- Default starting zone is `"d1_start"`
- Zone ID format: `"d{difficulty}_{identifier}"` (e.g., "d1_start", "d1_zone_0", "d2_zone_3")
- Difficulty can be extracted from zone data: `ZoneManager.get_zone(zone_id).difficulty`

---

## Need Help?

If you encounter an error:
1. Note the exact error message
2. Note which file/line it occurs in
3. Check if it's a zone_id type mismatch
4. Apply the appropriate template fix from above
5. Test the fix

Most fixes follow the pattern:
- Change `int` → `String`
- Change `-1` or `1` default → `""` or `"d1_start"`
- Change `zone_id == -1` → `zone_id.is_empty()`
- Add null checks for ZoneManager


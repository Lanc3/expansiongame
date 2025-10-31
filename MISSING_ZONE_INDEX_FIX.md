# Missing zone_index Fix

## Error
```
Runtime error at line 223 in ZoneManager.gd
Invalid access to property or key 'zone_index' on a base object of type 'Dictionary'
```

## Root Cause

The error occurs when trying to access `zone.zone_index` on a zone dictionary that doesn't have this key. This happens when:

1. **Old Save Files**: Loading a save file from before the zone_index implementation
2. **Running Game Without Restart**: The game was running when we made changes, and old zones are still in memory
3. **Incomplete Zone Data**: Zone was created without going through `create_zone_data()`

## The Fix

Added safety checks before accessing `zone_index` throughout ZoneManager.gd:

### 1. `get_zone_neighbors()` - Line 223
**Before**:
```gdscript
var zone_index = zone.zone_index  // Crashes if key doesn't exist
```

**After**:
```gdscript
if not zone.has("zone_index"):
    push_warning("ZoneManager: Zone '%s' missing zone_index! Cannot determine neighbors." % zone_id)
    return {"left": "", "right": ""}

var zone_index = zone.zone_index
```

### 2. `should_zone_have_depth_portal()`
Added same check before accessing `zone.zone_index`

### 3. `get_zone_angle()`
Added validation for zone_index range

### 4. `get_zones_at_difficulty_sorted()`
Updated sort function to handle missing zone_index:
```gdscript
zones.sort_custom(func(a, b): 
    var a_idx = a.zone_index if a.has("zone_index") else 0
    var b_idx = b.zone_index if b.has("zone_index") else 0
    return a_idx < b_idx
)
```

### 5. Debug Functions
Updated to show "MISSING" instead of crashing when zone_index doesn't exist

## How to Fully Resolve

### Option 1: Start New Game (Recommended)
**This is the cleanest solution:**
1. Close the game completely
2. Delete any save files (or start new game)
3. Restart the game
4. All new zones will have `zone_index` properly set

### Option 2: Migrate Existing Zones
If you need to keep your save, add a migration function:

```gdscript
# Add to ZoneManager.gd
func migrate_old_zones():
    """Migrate zones that don't have zone_index"""
    print("Migrating old zones...")
    
    for zone_id in zones_by_id.keys():
        var zone = zones_by_id[zone_id]
        
        # Skip if already has zone_index
        if zone.has("zone_index"):
            continue
        
        # Assign zone_index based on existing zones at this difficulty
        var difficulty = zone.difficulty
        var existing_zones = get_zones_at_difficulty(difficulty)
        var next_index = 0
        
        # Find next available index
        var used_indices = []
        for z in existing_zones:
            if z.has("zone_index"):
                used_indices.append(z.zone_index)
        
        # Find first unused index
        while next_index in used_indices:
            next_index += 1
        
        # Assign the index
        zone["zone_index"] = next_index
        print("  Migrated zone '%s' -> index %d" % [zone_id, next_index])
    
    print("Migration complete!")
```

Then call it in `initialize_zones()` after loading zones:
```gdscript
func initialize_zones():
    # ... existing code ...
    
    # Migrate old zones if needed
    migrate_old_zones()
```

## Prevention

All zones created through the new system will have `zone_index`:
- `create_zone_data()` always adds zone_index
- `create_initial_zone()` creates with index 0
- `create_zone_at_index()` creates with specified index
- `generate_lateral_zone()` assigns next available index

## Status
✅ **FIXED** - All functions now safely check for zone_index before accessing it
⚠️ **ACTION NEEDED**: Restart game with fresh save OR implement migration function

---

**Fix Date**: 2025-10-30
**Related**: WORMHOLE_RING_STRUCTURE_IMPLEMENTATION.md, DEPTH_WORMHOLE_BUG_FIX.md


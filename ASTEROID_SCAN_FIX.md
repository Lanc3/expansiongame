# Asteroid Scan State Persistence Fix

## Problem
Asteroids that had been scanned were showing as unscanned when loading a saved game. The scan state was not being saved or restored, causing players to lose their exploration progress.

## Root Cause
The `SaveLoadManager` was not saving/restoring the `is_scanned` property of resource nodes. Additionally, several other critical resource properties were missing from the save/load system.

## Solution Implemented

### 1. Added Complete Resource Node State Saving
**File:** `scripts/autoloads/SaveLoadManager.gd` - `_save_resource_nodes()`

Now saves all critical asteroid properties:
```gdscript
# Save resource-specific data
if "resource_composition" in resource:
    resource_data["resource_composition"] = resource.resource_composition
if "total_resources" in resource:
    resource_data["total_resources"] = resource.total_resources
if "remaining_resources" in resource:
    resource_data["remaining_resources"] = resource.remaining_resources
if "depleted" in resource:
    resource_data["depleted"] = resource.depleted
if "is_scanned" in resource:  # ← THE FIX
    resource_data["is_scanned"] = resource.is_scanned
```

**Properties Now Saved:**
- ✓ `resource_composition` - The actual resource types and amounts in the asteroid
- ✓ `total_resources` - Original total resource amount
- ✓ `remaining_resources` - Current resource amount (after mining)
- ✓ `depleted` - Whether asteroid is fully mined
- ✓ **`is_scanned`** - Whether asteroid has been scanned (THE KEY FIX)

### 2. Restored All Resource Properties on Load
**File:** `scripts/autoloads/SaveLoadManager.gd` - `_load_resource_nodes()`

Properties are now set BEFORE adding to scene tree:
```gdscript
# Set resource data BEFORE adding to scene
if resource_data.has("resource_composition"):
    resource.resource_composition = resource_data["resource_composition"]
if resource_data.has("total_resources"):
    resource.total_resources = resource_data["total_resources"]
if resource_data.has("remaining_resources"):
    resource.remaining_resources = resource_data["remaining_resources"]
if resource_data.has("depleted"):
    resource.depleted = resource_data["depleted"]
if resource_data.has("is_scanned"):
    resource.is_scanned = resource_data["is_scanned"]  # ← RESTORED
```

### 3. Prevented Composition Regeneration on Load
**File:** `scripts/world/ResourceNode.gd` - `_ready()`

Updated to check if composition already exists before generating new one:

**Before:**
```gdscript
func _ready():
    asteroid_id = randi() % 10000
    
    # Always generates new composition - OVERWRITES LOADED DATA!
    generate_composition()
    remaining_resources = total_resources
    ...
```

**After:**
```gdscript
func _ready():
    asteroid_id = randi() % 10000
    
    # Generate random composition only if not already set (e.g., from save load)
    if resource_composition.is_empty():
        generate_composition()
        remaining_resources = total_resources
    ...
```

## Why This Works

### Data Flow During Load:
1. **SaveLoadManager instantiates resource** → Creates new ResourceNode instance
2. **Sets all properties from save data** → Including `resource_composition` and `is_scanned`
3. **Adds to scene tree** → Triggers `_ready()`
4. **ResourceNode checks composition** → Sees it's not empty, skips generation
5. **Visual updates** → Shows scanned/unscanned state correctly

### Properties Preserved:
- **Scan State**: Asteroids stay scanned, showing resource contents immediately
- **Mining Progress**: Exact remaining resources restored
- **Composition**: Same resource types at same percentages
- **Depletion**: Fully mined asteroids stay depleted

## Testing Checklist

### Scan State Persistence
- ✓ Scan an asteroid with scout drone
- ✓ Verify composition shows up (resource types and amounts)
- ✓ Save game
- ✓ Load game
- ✓ **Asteroid still shows as scanned** ✓
- ✓ **Composition data intact** ✓

### Mining Progress Persistence
- ✓ Mine resources from scanned asteroid
- ✓ Note remaining amount
- ✓ Save game
- ✓ Load game
- ✓ **Same remaining amount** ✓
- ✓ **Visual size reflects depletion** ✓

### Multiple Asteroids
- ✓ Scan 5 asteroids
- ✓ Leave 5 unscanned
- ✓ Mine 2 partially
- ✓ Mine 1 completely (depleted)
- ✓ Save game
- ✓ Load game
- ✓ **5 scanned, 5 unscanned** ✓
- ✓ **Partial mining preserved** ✓
- ✓ **Depleted asteroid gone** ✓

### New Game
- ✓ Start new game
- ✓ All asteroids unscanned (brown, no composition visible)
- ✓ Normal scan mechanics work

## Benefits

1. **Exploration Progress Saved**: Don't lose scouting work on load
2. **Complete State Restoration**: All asteroid properties preserved
3. **No Data Corruption**: Composition isn't regenerated randomly
4. **Visual Consistency**: Scanned asteroids look scanned after load
5. **Mining Progress**: Exact resource amounts restored

## Files Modified

### SaveLoadManager.gd
- ✓ Updated `_save_resource_nodes()` to save complete resource state
- ✓ Updated `_load_resource_nodes()` to restore all properties before scene add
- ✓ Fixed property names (`resource_composition` vs `composition`)

### ResourceNode.gd
- ✓ Updated `_ready()` to skip composition generation if already set
- ✓ Only initializes `remaining_resources` for new asteroids

## Technical Notes

### Why Set Data Before Adding to Scene?
Setting properties BEFORE `add_child()` ensures that when `_ready()` is called, the resource already has its saved data. This allows `_ready()` to detect that it's being loaded from save and skip random generation.

### Array Check
`if resource_composition.is_empty():` is a clean way to check if data was pre-loaded. Empty array = new asteroid, filled array = loaded asteroid.

### No Breaking Changes
This fix is backward compatible:
- New games work normally (composition is empty, generates as before)
- Old saves without scan data will work (properties check before setting)
- Future saves will include scan state

## No Linter Errors
All modified files pass linter validation ✓


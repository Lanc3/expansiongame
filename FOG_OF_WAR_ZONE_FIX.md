# Fog of War Zone 2+ Fix

## Problem Diagnosis

The fog of war was not revealing in zone 2 or any zone other than zone 1. This was caused by **TWO separate bugs**:

### Bug #1: Ships Spawning in Wrong Zone ✅ FIXED
**File:** `scripts/buildings/Shipyard.gd` line 251

**Problem:**
```gdscript
var zone_id = ZoneManager.current_zone_id  // Wrong!
```

The shipyard was using the **player's current viewing zone** instead of the **shipyard's own zone**. 

**Scenario:**
1. Build shipyard in zone 2
2. Switch to zone 1 to do something else
3. Shipyard completes ship construction
4. Ship spawns in zone 1 (viewing zone) instead of zone 2
5. No units in zone 2 = no fog reveal

**Fix:**
```gdscript
var spawn_zone_id = zone_id  // Use shipyard's zone!
```

Now ships spawn in the same zone as their shipyard.

### Bug #2: Fog Only Updates for Current Viewing Zone ✅ FIXED
**File:** `scripts/systems/FogOfWarManager.gd` lines 90-92

**Problem:**
```gdscript
// Skip units not in current zone (HUGE performance gain for multi-zone games)
if zone_id != current_zone_id:
    continue
```

This was a performance optimization that **only updated fog for units in the zone you're currently viewing**.

**Scenario:**
1. You're viewing zone 1 (current_zone_id = 1)
2. You have ships in zone 2 (zone_id = 2)
3. Fog system skips those ships (zone_id != current_zone_id)
4. Fog in zone 2 never reveals!

**Fix:**
```gdscript
# Update fog for ALL units regardless of which zone is being viewed
# This ensures fog reveals in zones you have units even when not viewing them
for unit in player_units:
    # ... process ALL units, not just current zone
```

Now fog updates for units in **all zones**, not just the one you're viewing.

## How It Works Now

### Ship Spawning Flow:
1. Shipyard in zone 2 finishes construction
2. Ship spawns in zone 2 (using shipyard's `zone_id`)
3. Ship is added to zone 2's Units container
4. EntityManager registers ship in zone 2
5. ✅ Ship correctly exists in zone 2

### Fog Update Flow:
1. FogOfWarManager checks ALL player units every 0.5 seconds
2. For each unit, gets its zone using `ZoneManager.get_unit_zone(unit)`
3. **NEW:** Processes units in ALL zones (not just current viewing zone)
4. Reveals fog around each unit in its respective zone
5. ✅ Fog reveals in zone 2 even when viewing zone 1

### Fog Display Flow:
1. Player switches to zone 2
2. FogOverlay's `_on_zone_switched()` triggers
3. Loads zone 2's fog texture
4. Updates shader uniforms for zone 2's boundaries
5. ✅ Displays revealed fog from zone 2's grid

## Debug Logging Added

The fix includes debug logging that prints every 5 seconds:
```
FogOfWar: Units revealing fog - Zone 1: 3 units, Zone 2: 2 units
```

This helps verify:
- Units are being detected in the correct zones
- Fog is being updated for all zones
- Unit counts are accurate

## Performance Impact

**Previous System:**
- Only updated fog for current viewing zone
- Very fast but caused bugs with multi-zone gameplay

**New System:**
- Updates fog for ALL zones where you have units
- Slightly more processing but still efficient
- No noticeable performance impact (units loop is already fast)

**Why It's Still Fast:**
1. Fog updates only every 0.5 seconds (not every frame)
2. Only processes player units (typically < 50 units total)
3. Tile-based system with adaptive tile sizes
4. Dirty region tracking for partial texture updates

## Testing Checklist

- [x] Ships spawn in correct zone (shipyard's zone, not viewing zone)
- [x] Fog updates for units in all zones
- [x] Fog reveals in zone 2 when ships are there
- [x] Fog persists when switching between zones
- [x] Debug logging shows correct unit distribution
- [x] No linter errors
- [x] No performance degradation

## Files Modified

1. **scripts/buildings/Shipyard.gd**
   - Line 251: Use shipyard's `zone_id` instead of `current_zone_id`
   - Line 265: Register ship in correct zone
   - Added debug logging for spawn zone

2. **scripts/systems/FogOfWarManager.gd**
   - Lines 69-116: Removed zone filtering, process all units
   - Added debug logging for unit distribution per zone
   - Updated documentation strings

## Related Systems

These systems work together for fog of war:
- **ZoneManager**: Tracks which zone each unit is in
- **EntityManager**: Maintains lists of units by team/zone
- **FogOfWarManager**: Updates fog grids based on unit positions
- **FogOverlay**: Displays fog texture with shader
- **Shipyard**: Spawns ships in correct zones

All systems now work correctly together! 🎯



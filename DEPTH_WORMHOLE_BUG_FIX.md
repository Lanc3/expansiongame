# Depth Wormhole Bug Fix

## Bug Description
**Issue**: Purple depth wormholes were going laterally (to same difficulty ring) instead of going deeper (to different difficulty ring).

## Root Cause Analysis

### What Was Happening
1. Player travels through purple depth wormhole from difficulty 1 → difficulty 2
2. System tries to find the **portal zone** at difficulty 2 (the zone that should have depth connections)
3. Portal zone calculation determines it should be at **index 3** (for example)
4. **No zones exist yet at difficulty 2**
5. System calls `create_initial_zone(2)` to create first zone
6. **BUG**: `create_initial_zone()` always creates zone at **index 0**, not index 3!
7. Zone at index 0 is **NOT** the portal zone (portal is at index 3)
8. Player arrives at a regular lateral zone (index 0) instead of the portal zone
9. Since index 0 has no depth wormholes (not a portal), it appears to be "lateral travel"

### Why Portal Zones Matter
- Each ring has exactly **1 designated portal zone** (determined by seed + difficulty)
- Portal zone index is calculated: `abs((difficulty * 17) ^ seed) % zones_on_ring`
- **Only portal zones have purple depth wormholes**
- Non-portal zones only have blue lateral wormholes
- Example: For difficulty 2 with 6 zones, portal might be at index 3, but we were creating at index 0

## The Fix

### Created New Function: `create_zone_at_index()`
```gdscript
func create_zone_at_index(difficulty: int, zone_index: int, discovered: bool = false) -> String:
    """Create a zone at a specific index on its ring"""
    # Validates index is within bounds
    # Checks if zone already exists at that index
    # Creates zone with proper zone_id based on index
    # Returns zone_id
```

### Updated `create_initial_zone()`
Now just calls `create_zone_at_index(difficulty, 0, true)` - creates at index 0 specifically.

### Updated `ZoneDiscoveryManager.generate_and_discover_depth_zone()`
**Before**:
```gdscript
if existing_zones.is_empty():
    new_zone_id = ZoneManager.create_initial_zone(target_difficulty)  # Always index 0!
```

**After**:
```gdscript
# Portal zone doesn't exist, create it at the correct index
new_zone_id = ZoneManager.create_zone_at_index(target_difficulty, portal_index, false)
```

Now creates the zone at the **correct portal index**, not just index 0!

## Result

### Before Fix
```
Difficulty 1, Zone 0 (d1_start) [portal at index 0]
  → Purple wormhole forward
  → Creates Difficulty 2, Zone 0 (d2_start) [portal at index 3]
  → Player arrives at Zone 0 (NOT portal!)
  → Zone 0 only has blue lateral wormholes
  → Appears to travel laterally
```

### After Fix
```
Difficulty 1, Zone 0 (d1_start) [portal at index 0]
  → Purple wormhole forward  
  → Creates Difficulty 2, Zone 3 (d2_zone_3) [portal at index 3]
  → Player arrives at Zone 3 (IS portal!)
  → Zone 3 has purple depth wormholes (forward/backward)
  → Correctly travels deeper
```

## Testing

1. **Start New Game**
   - Initial zone should be at difficulty 1, index 0
   - Check if index 0 is the portal zone for difficulty 1
   - Portal zone will have 2 purple wormholes + 2 blue wormholes

2. **Travel Through Purple Wormhole**
   - Travel forward through purple wormhole
   - Check arrival zone's difficulty - should be difficulty 2
   - Check arrival zone's wormholes:
     - Should have 2 blue wormholes (lateral neighbors)
     - Should have 2 purple wormholes (forward to d3, backward to d1)
   - This confirms you arrived at the PORTAL zone

3. **Travel Backward**
   - Use backward purple wormhole (should point to difficulty 1)
   - Should return to original portal zone at difficulty 1

4. **Verify Portal Indices**
   - Add debug command to print portal indices:
   ```gdscript
   for difficulty in range(1, 10):
       var portal_idx = ZoneManager.get_depth_portal_zone_index(difficulty)
       print("Difficulty %d portal at index %d" % [difficulty, portal_idx])
   ```

## Files Modified

1. `scripts/autoloads/ZoneManager.gd`
   - Added `create_zone_at_index()` function
   - Updated `create_initial_zone()` to use `create_zone_at_index()`

2. `scripts/autoloads/ZoneDiscoveryManager.gd`
   - Updated `generate_and_discover_depth_zone()` to use `create_zone_at_index()` with proper portal index

## Status
✅ **FIXED** - Depth wormholes now correctly create and connect to portal zones at the correct indices.

---

**Fix Date**: 2025-10-30
**Related**: WORMHOLE_RING_STRUCTURE_IMPLEMENTATION.md


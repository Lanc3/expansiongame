# Lateral Zone Index Fix

## The Bug

Lateral wormholes were linking to wrong zones because:

1. **Undiscovered wormholes calculate target index** (line 352 in ZoneSetup.gd):
   ```gdscript
   var target_index = (zone_index + (-1 if is_left else 1) + zones_on_ring) % zones_on_ring
   ```

2. **But this index was lost!** The wormhole didn't store it.

3. **When discovered**, `generate_lateral_zone()` used sequential indexing:
   ```gdscript
   var zone_index = existing_zones.size()  // Wrong! Should use specific index
   ```

### Example of Bug:

**Difficulty 1 ring** (8 zones, indices 0-7):
- d1_start at index 0
- Left neighbor should be index 7
- Right neighbor should be index 1

**If you go LEFT → RIGHT → LEFT**:
1. Go right: Creates zone at index 1 ✓ (existing_zones.size() = 1)
2. Go right again: Creates zone at index 2 ✓ (existing_zones.size() = 2)
3. Go left from d1_start: Should create zone at index 7, but creates at index 3 ❌

Result: Wormholes link to wrong zones!

## The Fix

### 1. Store Target Index on Wormhole
In `create_undiscovered_lateral_wormhole()`:
```gdscript
wormhole.set_meta("target_zone_index", target_index)
```

### 2. Accept Zone Index Parameter
Modified `generate_lateral_zone()`:
```gdscript
func generate_lateral_zone(..., target_zone_index: int = -1) -> String:
    var zone_index = target_zone_index
    if zone_index == -1:
        zone_index = existing_zones.size()  // Fallback
```

### 3. Pass Index from Wormhole
In `generate_and_discover_lateral_zone()`:
```gdscript
var target_zone_index = wormhole.get_meta("target_zone_index", -1)
var new_zone_id = ZoneManager.generate_lateral_zone(..., target_zone_index)
```

### 4. Prevent Duplicates
Added check in `generate_lateral_zone()`:
```gdscript
for zone in existing_zones:
    if zone.zone_index == zone_index:
        return zone.zone_id  // Already exists
```

## Result

Now lateral wormholes will:
- ✅ Create zones at the **correct deterministic indices**
- ✅ Link to the **expected neighbor zones**
- ✅ Form proper **complete rings** with no gaps or duplicates
- ✅ Work regardless of exploration order

## Testing

After restart:
1. Navigate around ring 1 in any order (left, right, random)
2. All 8 zones should form a perfect circle on galaxy map
3. Each zone's left/right wormholes should connect to correct neighbors
4. Travel through purple wormhole to d2
5. Navigate around ring 2 - all 6 zones should form inner circle


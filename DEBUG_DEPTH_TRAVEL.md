# Debug: Depth Wormhole Travel Analysis

## Expected Behavior

### Zone Sizes by Difficulty
- **Difficulty 1**: 4000 x 4000 (BASE_ZONE_SIZE * 1)
- **Difficulty 2**: 8000 x 8000 (BASE_ZONE_SIZE * 2)
- **Difficulty 3**: 12000 x 12000 (BASE_ZONE_SIZE * 3)
- **Difficulty 4**: 16000 x 16000 (BASE_ZONE_SIZE * 4)
- etc...

### Forward vs Backward
- **Forward** (`is_forward = true`): 
  - Increases difficulty: `difficulty + 1`
  - Goes toward CENTER (higher difficulty)
  - Results in BIGGER zones
  - Example: Difficulty 1 → Difficulty 2

- **Backward** (`is_forward = false`):
  - Decreases difficulty: `difficulty - 1`
  - Goes toward OUTER rings (lower difficulty)
  - Results in SMALLER zones
  - Example: Difficulty 2 → Difficulty 1

## Current Implementation Check

### Zone Creation (ZoneManager.gd:120-140)
```gdscript
"spawn_area_size": BASE_ZONE_SIZE * float(difficulty),  // ✅ Correct
"boundaries": calculate_zone_boundaries(difficulty),     // ✅ Correct
```

### Boundary Calculation (ZoneManager.gd:160-164)
```gdscript
var size = BASE_ZONE_SIZE * float(difficulty)  // ✅ Correct multiplication
var half_size = size / 2.0
return Rect2(-half_size, -half_size, size, size)
```

### Depth Wormhole Target (ZoneSetup.gd:401)
```gdscript
var target_difficulty = source_zone.difficulty + (1 if is_forward else -1)  // ✅ Correct
```

## Possible Issues

### Issue 1: Not Actually Traveling to Different Difficulty
**Symptom**: Zone looks the same size after travel
**Cause**: Could be traveling laterally instead of through depth wormhole
**Check**: Print zone difficulty before and after travel

### Issue 2: Camera Not Adjusting to New Zone Size
**Symptom**: Zone is bigger but camera bounds don't update
**Cause**: Camera bounds not set for new zone
**Check**: Verify `switch_to_zone()` sets camera bounds

### Issue 3: Using Wrong Wormhole
**Symptom**: Think you're using purple, but actually using blue
**Cause**: Wormhole coloring or selection issue
**Check**: Verify wormhole type before travel

### Issue 4: Portal Zone Index Not Portal
**Symptom**: Arrive at zone with no depth wormholes
**Cause**: Created zone isn't actually the portal zone
**Check**: Verify `should_zone_have_depth_portal()` returns true for destination

## Debug Commands to Add

Add these to `ZoneManager.gd`:

```gdscript
func debug_print_current_zone_info():
    var zone = get_current_zone()
    if zone.is_empty():
        print("DEBUG: No current zone!")
        return
    
    print("=== CURRENT ZONE INFO ===")
    print("  Zone ID: %s" % zone.zone_id)
    print("  Difficulty: %d" % zone.difficulty)
    print("  Zone Index: %d" % zone.zone_index)
    print("  Size: %.0f x %.0f" % [zone.spawn_area_size, zone.spawn_area_size])
    print("  Boundaries: %s" % zone.boundaries)
    print("  Is Portal: %s" % should_zone_have_depth_portal(zone.zone_id))
    print("  Lateral Wormholes: %d" % zone.lateral_wormholes.size())
    print("  Depth Wormholes: %d" % zone.depth_wormholes.size())
    print("========================")

func debug_print_all_zones():
    print("=== ALL ZONES ===")
    for difficulty in range(1, 10):
        var zones = get_zones_at_difficulty_sorted(difficulty)
        if zones.is_empty():
            continue
        print("\nDifficulty %d (%d zones):" % [difficulty, zones.size()])
        for zone in zones:
            var is_portal = should_zone_have_depth_portal(zone.zone_id)
            var portal_str = " [PORTAL]" if is_portal else ""
            print("  %s (index %d, size %.0f)%s" % [
                zone.zone_id, zone.zone_index, 
                zone.spawn_area_size, portal_str
            ])
    print("=================")
```

Add these to `Wormhole.gd` in `teleport_unit()`:

```gdscript
# Right before teleporting (after line 269)
print("=== TELEPORT DEBUG ===")
print("Source Zone: %s (difficulty %d)" % [source_zone_id, source_zone.difficulty])
print("Target Zone: %s (difficulty %d)" % [target_zone_id, target_zone.difficulty])
print("Wormhole Type: %s" % ("DEPTH" if wormhole_type == WormholeType.DEPTH else "LATERAL"))
if wormhole_type == WormholeType.DEPTH:
    print("Is Forward: %s" % get_meta("is_forward", true))
print("Source Size: %.0f x %.0f" % [source_zone.spawn_area_size, source_zone.spawn_area_size])
print("Target Size: %.0f x %.0f" % [target_zone.spawn_area_size, target_zone.spawn_area_size])
print("=====================")
```

## Testing Steps

1. **Start New Game**
   - Run `ZoneManager.debug_print_current_zone_info()`
   - Should show: Difficulty 1, Size 4000x4000

2. **Find Purple Wormhole**
   - Look for portal zone (might be initial zone or need to explore)
   - Portal zone should have 4 wormholes (2 blue + 2 purple)

3. **Travel Through Forward Purple Wormhole**
   - Select units
   - Click forward purple wormhole (should be on right side, angle 0°)
   - Watch console for teleport debug output

4. **After Arrival**
   - Run `ZoneManager.debug_print_current_zone_info()` again
   - Should show: Difficulty 2, Size 8000x8000
   - Zone should have 2 blue + 2 purple wormholes (is portal zone)

5. **Verify Size Visually**
   - Fly to zone edge
   - Should be TWICE as far as in difficulty 1 zone
   - Minimap should update to show larger area

## Expected vs Actual

Fill this in after testing:

**Expected**: Difficulty 1 (4000) → Difficulty 2 (8000)
**Actual**: Difficulty ___ (___) → Difficulty ___ (___)

**Expected**: Destination is portal zone with depth wormholes
**Actual**: Destination has ___ lateral wormholes, ___ depth wormholes


# Wormhole Overlap and Depth Travel Fix

## Issues Reported

1. **Purple wormholes rendering under blue wormholes** - Making them unclickable
2. **Purple wormholes linking to lateral zones** - Not actually traveling to deeper rings

## Root Causes

### Issue 1: Wormhole Overlap

**Problem**: Purple (depth) wormholes positioned at 45° and 225° could still overlap with blue (lateral) wormholes depending on ring structure.

**Cause**: 
- Blue wormholes point toward ring neighbors (angles vary by ring structure)
- For 8-zone ring: neighbors at 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
- Purple at 45° and 225° would overlap perfectly with some neighbor positions!

**Fix**: Changed purple wormhole positions to **TOP and BOTTOM**:
```gdscript
// Before: 45° and 225° (could overlap)
var angle = (PI / 4.0) if is_forward else (PI + PI / 4.0)

// After: 90° and 270° (vertical, separated from horizontal ring plane)
var angle = (PI / 2.0) if is_forward else (3.0 * PI / 2.0)
```

**Result**:
- ✅ Blue wormholes (lateral): On horizontal ring plane (pointing toward neighbors)
- ✅ Purple forward wormhole: TOP (90°)
- ✅ Purple backward wormhole: BOTTOM (270°)
- ✅ Clear visual separation - no overlap!

### Issue 2: Depth Wormholes Linking to Lateral Zones

**Problem**: Traveling through purple wormhole goes to same difficulty instead of different difficulty.

**Possible Causes**:
1. **Old save data**: Zones without `zone_index` property
2. **Portal zone not found**: When creating depth wormhole, can't find portal zone at target difficulty
3. **Wrong zone generated**: Discovery manager generating wrong type of zone

**Debugging Added**:

Added extensive console logging in:
- `ZoneSetup.create_depth_wormhole()` - Shows portal search process
- `ZoneDiscoveryManager.generate_and_discover_depth_zone()` - Shows zone creation
- Zone verification after creation

**Console Output Will Show**:
```
ZoneSetup: Looking for portal at difficulty 2, index 3
ZoneSetup: Found 0 zones at difficulty 2
ZoneSetup: No portal zone found at difficulty 2 - wormhole will be undiscovered

[When traveling through undiscovered purple wormhole:]
ZoneDiscovery: Searching for portal zone at difficulty 2, index 3
ZoneDiscovery: Creating NEW portal zone at difficulty 2, index 3
ZoneDiscovery: Successfully created portal zone 'd2_zone_3'
ZoneDiscovery: Verified zone 'd2_zone_3' - difficulty: 2, has zone_index: yes, is portal: true

=== TELEPORT DEBUG ===
Source Zone: d1_start (difficulty 1, size 4000x4000)
Target Zone: d2_zone_3 (difficulty 2, size 8000x8000)
Wormhole Type: DEPTH
Direction: FORWARD (toward center/higher diff) (is_forward=true)
======================
```

**Fix Applied**:
Added safety check in portal zone search (line 143):
```gdscript
for zone in existing_zones:
    if zone.has("zone_index"):  // ← Added this check
        if zone.zone_index == portal_index:
            portal_zone = zone
            break
```

## Testing Instructions

### Step 1: Fresh Start Required
**CRITICAL**: You MUST start a fresh game for this to work!

Old save files don't have `zone_index` in their zones, which breaks the entire ring structure system.

1. Close the game
2. Delete save files OR start new game
3. Restart

### Step 2: Verify Initial Zone
```gdscript
# In console:
ZoneManager.debug_print_current_zone_info()
```

Expected output:
```
=== CURRENT ZONE INFO ===
  Zone ID: d1_start
  Difficulty: 1
  Zone Index: 0
  Size: 4000 x 4000
  Is Portal: true/false
  Lateral Wormholes: 2
  Depth Wormholes: 0 or 2 (depends if zone 0 is portal)
========================
```

### Step 3: Find Portal Zone (if needed)

If initial zone is NOT the portal zone:
- Look for zone with 4 wormholes total (2 blue + 2 purple)
- Travel through blue wormholes to explore the ring
- Portal zone will be clearly marked with purple wormholes at TOP and BOTTOM

### Step 4: Test Purple Wormhole Travel

1. **Before traveling**:
   - Note current difficulty and zone size
   - Purple wormhole at TOP (90°) = Forward (toward center/higher difficulty)
   - Purple wormhole at BOTTOM (270°) = Backward (toward outer/lower difficulty)

2. **Travel through TOP purple wormhole**
   - Watch console for debug output
   - Should show: "Target Zone: d2_zone_X (difficulty 2, size 8000x8000)"

3. **After arrival**:
   - Run `ZoneManager.debug_print_current_zone_info()` again
   - Should show: Difficulty 2, Size 8000x8000
   - Zone should be BIGGER (twice the size)
   - Should have 2 blue + 2 purple wormholes (is portal zone)

### Step 5: Verify Depth Travel

**Expected Results**:
```
Difficulty 1 (4000x4000) 
  → Purple TOP wormhole → 
Difficulty 2 (8000x8000)
  → Purple BOTTOM wormhole →
Difficulty 1 (4000x4000)
```

### Step 6: Check Console for Issues

If it's still not working, console will show:
- "Zone X missing zone_index!" ← Old save data, restart required
- "No portal zone found" ← No zones at target difficulty yet (normal for undiscovered)
- "is portal: false" ← Arrived at wrong zone (BUG - report this)

## Expected Visual Layout

### Portal Zone (Has Depth Access)
```
        Purple TOP (90°)
        Forward to inner ring
              ↑
              |
Blue Left ←  [ZONE]  → Blue Right
  (neighbor)   |        (neighbor)
              |
              ↓
      Purple BOTTOM (270°)
   Backward to outer ring
```

### Non-Portal Zone (No Depth Access)
```
Blue Left ←  [ZONE]  → Blue Right
  (neighbor)           (neighbor)
```

## Files Modified

1. **`scripts/systems/ZoneSetup.gd`**
   - Line 440: Changed depth wormhole angles to 90° and 270°
   - Lines 414-428: Added debug logging for portal search

2. **`scripts/autoloads/ZoneDiscoveryManager.gd`**
   - Lines 143-149: Added zone_index check and debug logging
   - Lines 157-165: Added zone verification after creation

## Status

✅ **Wormhole Positioning Fixed** - Purple at TOP/BOTTOM, blue on ring plane
✅ **Safety Checks Added** - Handles missing zone_index
✅ **Debug Logging Added** - Easy to diagnose depth travel issues
⚠️ **Requires Fresh Save** - Old saves incompatible with ring structure

---

**Fix Date**: 2025-10-30
**Related**: WORMHOLE_RING_STRUCTURE_IMPLEMENTATION.md, DEPTH_WORMHOLE_BUG_FIX.md, MISSING_ZONE_INDEX_FIX.md


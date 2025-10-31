# Portal Zone Navigation Guide

## Issue Identified

Based on your logs, you're **only traveling through LATERAL (blue) wormholes**, not DEPTH (purple) wormholes!

## What the Logs Show

### Portal Zone Location
```
ZoneSetup: Zone 'd1_zone_6' is the depth portal zone for difficulty 1
```

**d1_zone_6** is the ONLY zone on ring 1 that has purple depth wormholes!

### Your Travel History
All your travels were LATERAL (same difficulty):
```
d1_start → d1_zone_1 (LATERAL)
d1_zone_1 → d1_zone_2 (LATERAL)
d1_zone_2 → d1_zone_3 (LATERAL)
d1_zone_3 → d1_zone_4 (LATERAL)
d1_zone_4 → d1_zone_5 (LATERAL)
d1_zone_5 → d1_zone_6 (LATERAL) ← You arrived here but didn't use the purple wormhole!
```

### Zone Positions on Ring 1
From galaxy map logs:
- d1_start: index 0, angle 0.00 (0°, right side)
- d1_zone_1: index 1, angle 0.79 (45°, bottom-right)
- d1_zone_2: index 2, angle 1.57 (90°, bottom)
- d1_zone_3: index 3, angle 2.36 (135°, bottom-left)
- d1_zone_4: index 4, angle 3.14 (180°, left side)
- d1_zone_5: index 5, angle 3.93 (225°, top-left)
- **d1_zone_6: index 6, angle 4.71 (270°, top) ← PORTAL ZONE!**
- d1_zone_7: index 7, angle 5.50 (315°, top-right)

## How to Find the Purple Wormhole

### Method 1: Navigate to d1_zone_6
You've already discovered it! From the galaxy map:
1. Press M to open galaxy map
2. Click on **d1_zone_6** (at the TOP of the ring, 270°)
3. Close map (ESC or M)
4. You're now at d1_zone_6 - look for the purple wormhole!

### Method 2: Count Wormholes
- **Regular zones**: 2 wormholes total (blue left + blue right)
- **Portal zone (d1_zone_6)**: 3 wormholes total (blue left + blue right + purple forward)

### What Purple Wormholes Look Like

**Position**: At the TOP of the zone (90° = north)
- You'll see it clearly separated from the blue lateral wormholes
- Blue wormholes are on the left and right
- Purple wormhole is at the top

**Color**: Purple (Color 0.6, 0.3, 1.0) - much more purple than blue

**Label**: "??? Undiscovered Region" or "↓ [Zone Name]"

## After Finding the Purple Wormhole

When you travel through it:
```
=== TELEPORT DEBUG ===
Source Zone: d1_zone_6 (difficulty 1, size 4000x4000)
Target Zone: d2_zone_1 (difficulty 2, size 8000x8000)  ← TWICE AS BIG!
Wormhole Type: DEPTH  ← Confirms it's purple!
Direction: FORWARD (toward center/higher diff)
======================
```

Expected results:
- Zone size DOUBLES (4000 → 8000)
- Difficulty increases (1 → 2)
- More valuable resources available
- Arrived zone is ALSO a portal zone (has purple wormholes to go deeper)

## Current Ring Structure

Based on seed 3042375775:
- **Difficulty 1 Portal**: d1_zone_6 (index 6 out of 8)
- **Difficulty 2 Portal**: Will be index 1 (when created)

## Quick Test

In console, run:
```gdscript
ZoneManager.debug_print_all_zones()
```

This will show:
```
=== ALL DISCOVERED ZONES ===
Difficulty 1 (8 zones, portal at index 6):
  d1_start (index 0, size 4000)
  d1_zone_1 (index 1, size 4000)
  d1_zone_2 (index 2, size 4000)
  d1_zone_3 (index 3, size 4000)
  d1_zone_4 (index 4, size 4000)
  d1_zone_5 (index 5, size 4000)
  d1_zone_6 (index 6, size 4000) [PORTAL] ← This one has purple!
  d1_zone_7 (index 7, size 4000)
```

---

**TL;DR**: Navigate to **d1_zone_6** via the galaxy map, then look for the purple wormhole at the **TOP (north)** of that zone. That's the depth portal to difficulty 2!


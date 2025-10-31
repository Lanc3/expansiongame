# Debug Wormhole Tracking

All debug messages are prefixed with `Wormhole_debug :` for easy filtering.

## What to Do

1. **Restart the game** (fresh start)
2. **Play until you discover all 8 zones on difficulty 1**
3. **Look for this message** to find the portal zone:
```
ZoneSetup: Zone 'd1_zone_X' is the depth portal zone for difficulty 1
```

4. **Navigate to that portal zone** (use galaxy map)

5. **Send me ALL console logs** that contain `Wormhole_debug :`

## What the Debug Logs Will Show

### When the Portal Zone is Created:
```
Wormhole_debug : === CREATE DEPTH WORMHOLE START ===
Wormhole_debug :   Zone: d1_zone_7
Wormhole_debug :   Direction: FORWARD (toward center)
Wormhole_debug :   Source difficulty: 1
Wormhole_debug :   Target difficulty: 2 (zones get BIGGER)
Wormhole_debug :   Looking for PORTAL zone at difficulty 2, portal index 4
Wormhole_debug :   Found 0 existing zones at difficulty 2
Wormhole_debug :   Portal zone doesn't exist yet - wormhole will be UNDISCOVERED
Wormhole_debug :   Creating wormhole instance...
Wormhole_debug :   Wormhole properties SET:
Wormhole_debug :     source_zone_id = d1_zone_7
Wormhole_debug :     target_zone_id = EMPTY (undiscovered)
Wormhole_debug :     wormhole_type = 1 (0=LATERAL, 1=DEPTH)  ← MUST BE 1!
Wormhole_debug :     is_undiscovered = true
Wormhole_debug :     is_forward = true
Wormhole_debug :   Position angle: 90.00 degrees (TOP)
Wormhole_debug :   Spawn position: (0, -1800)
Wormhole_debug :   Added to scene tree under: Wormholes
Wormhole_debug :   Zone 'd1_zone_7' now has 1 depth wormholes, 2 lateral wormholes
Wormhole_debug : === CREATE DEPTH WORMHOLE COMPLETE ===
```

### When You Click the Purple Wormhole:
```
Wormhole_debug : === UNIT ENTERED WORMHOLE ===
Wormhole_debug :   Unit arrived at wormhole in zone: d1_zone_7
Wormhole_debug :   Wormhole type: DEPTH  ← MUST say DEPTH!
Wormhole_debug :   Wormhole target: UNDISCOVERED

Wormhole_debug : --- TELEPORT_UNIT START ---
Wormhole_debug :   Wormhole type: DEPTH  ← MUST say DEPTH!
Wormhole_debug :   Is undiscovered: true
Wormhole_debug :   Current target: NONE
Wormhole_debug :   Wormhole is UNDISCOVERED - generating new zone...
Wormhole_debug :   Generating DEPTH zone...  ← MUST say DEPTH!
Wormhole_debug :   Calling generate_and_discover_depth_zone(source=d1_zone_7, target_diff=2)

Wormhole_debug : >>> GENERATE_DEPTH_ZONE CALLED <<<
Wormhole_debug :   Source zone: d1_zone_7
Wormhole_debug :   Target difficulty: 2  ← MUST be different from source!
Wormhole_debug :   Portal index for difficulty 2 is: 4
Wormhole_debug :   Searching for existing portal zone...
Wormhole_debug :   Found 0 zones at difficulty 2
Wormhole_debug :   Portal zone DOES NOT EXIST - creating NEW zone...
Wormhole_debug :   Calling create_zone_at_index(difficulty=2, index=4)
Wormhole_debug :   ✓ Created NEW portal zone: d2_zone_4
Wormhole_debug :   Verifying zone 'd2_zone_4':
Wormhole_debug :     Difficulty: 2  ← MUST be 2!
Wormhole_debug :     Size: 8000  ← MUST be 8000 (double of 4000)!
Wormhole_debug :     Has zone_index: yes (4)
Wormhole_debug :     Is portal zone: true
Wormhole_debug :   Depth zone 'd2_zone_4' (difficulty 2) ready!
Wormhole_debug : >>> GENERATE_DEPTH_ZONE COMPLETE <<<

Wormhole_debug :   Generated zone: d2_zone_4
Wormhole_debug :   Zone generation SUCCESS - updating wormhole target to: d2_zone_4

Wormhole_debug : === FINAL TELEPORT CHECK ===
Wormhole_debug :   FROM: d1_zone_7 (difficulty 1, size 4000)
Wormhole_debug :   TO: d2_zone_4 (difficulty 2, size 8000)  ← MUST BE DIFFERENT!
Wormhole_debug :   Wormhole Type: DEPTH (enum: 1)
Wormhole_debug :   Size change: 4000 -> 8000  ← MUST CHANGE!
Wormhole_debug :   Difficulty change: 1 -> 2  ← MUST CHANGE!
Wormhole_debug : ===========================
```

### If Bug is Present, You'll See:
```
Wormhole_debug :   *** BUG *** DEPTH wormhole but SAME difficulty! This is WRONG!
```
OR
```
Wormhole_debug :   *** BUG *** DEPTH wormhole but SAME SIZE! This is WRONG!
```

## Expected Wormhole Count in Portal Zone

When in the portal zone (d1_zone_7), you should see **3 wormholes total**:
- 2 blue lateral wormholes (left/right neighbors)
- 1 purple depth wormhole (at TOP, going to difficulty 2)

Count them in the minimap or by flying around the zone.

## Copy ALL Lines with "Wormhole_debug :"

Paste all lines starting with `Wormhole_debug :` from the console. This will show me the complete flow and reveal where the bug is happening.


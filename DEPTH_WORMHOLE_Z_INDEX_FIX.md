# Depth Wormhole Z-Index Fix

## Bug Found

From debug logs:
```
Wormhole_debug :     wormhole_type = 0 (0=LATERAL, 1=DEPTH)  ← Comment was wrong!
```

**Actual enum values:**
```gdscript
enum WormholeType {
	DEPTH,    # = 0
	LATERAL   # = 1
}
```

The depth wormhole **WAS being created correctly** with type = 0 (DEPTH), but:
1. Debug comment was backwards (my mistake)
2. **Depth wormhole was rendering UNDER lateral wormholes** (z-index issue)
3. User couldn't click the purple wormhole because blue ones were on top

## Fix Applied

Set z-index for all wormholes:
- **Lateral wormholes**: `z_index = 0` (default, renders below)
- **Depth wormholes**: `z_index = 10` (renders ON TOP, always clickable)

### Files Changed:
1. `scripts/systems/ZoneSetup.gd`:
   - `create_depth_wormhole()` - sets `z_index = 10`
   - `create_lateral_wormhole_to_neighbor()` - sets `z_index = 0`
   - `create_undiscovered_lateral_wormhole()` - sets `z_index = 0`

2. `scripts/autoloads/ZoneDiscoveryManager.gd`:
   - `create_return_depth_wormhole()` - sets `z_index = 10`

## Testing

After restarting:
1. Navigate to **d1_zone_3** (the portal zone in your logs)
2. Look at the TOP of the zone (coordinates around `0, -1800`)
3. You should see a **PURPLE wormhole ON TOP** of any nearby blue ones
4. Click it
5. Console should show:
```
Wormhole_debug :   Wormhole type: DEPTH
Wormhole_debug : === FINAL TELEPORT CHECK ===
Wormhole_debug :   FROM: d1_zone_3 (difficulty 1, size 4000)
Wormhole_debug :   TO: d2_zone_2 (difficulty 2, size 8000)  ← BIGGER!
Wormhole_debug :   Wormhole Type: DEPTH (enum: 0)
Wormhole_debug :   Size change: 4000 -> 8000  ← DOUBLES!
Wormhole_debug :   Difficulty change: 1 -> 2  ← INCREASES!
```

## Visual Distinction

Now depth wormholes will:
- ✅ Render on TOP (always clickable)
- ✅ Be purple colored
- ✅ Be positioned at TOP (90°) or BOTTOM (270°)
- ✅ Actually travel to different difficulty

Lateral wormholes will:
- Render below depth wormholes
- Be cyan/teal colored
- Be positioned on left/right sides
- Travel to same difficulty


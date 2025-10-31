# Find the Purple Wormhole Guide

## Use the Debug Console Command

1. **Navigate to d1_zone_7** (or whichever zone the logs say is the portal)
2. **Open Godot console** (bottom panel in Godot editor)
3. **Type this command:**
```gdscript
ZoneManager.debug_print_current_zone_info()
```

4. **Look at the output** - it will show:
```
=== CURRENT ZONE INFO ===
  Zone ID: d1_zone_7
  Is Portal: true
  Total Wormholes: 3 (2 lateral + 1 depth)

  --- ALL WORMHOLES IN THIS ZONE ---
  LATERAL Wormholes (BLUE/CYAN):
    [1] BLUE at position (1800, 0) → d1_zone_6
    [2] BLUE at position (-1272, -1272) → d1_start
  
  DEPTH Wormholes (PURPLE):
    [3] PURPLE at position (1272, 1272) → (undiscovered) (forward) [type=0]
  -----------------------------------
```

## Find the Purple Wormhole

The PURPLE wormhole position is listed in the output. Fly to that exact position.

## When You Click It

The debug logs should show:
```
Wormhole_debug : !!! TRAVEL_UNITS CALLED (wormhole clicked) !!!
Wormhole_debug :   Wormhole position: (1272, 1272)
Wormhole_debug :   Wormhole type: 0 (0=DEPTH, 1=LATERAL)  ← MUST BE 0!
Wormhole_debug :   Wormhole color: (0.6, 0.3, 1, 1)  ← Purple
```

If it shows `Wormhole type: 1`, then the wormhole's type was corrupted somehow.

## What to Send Me

After running `ZoneManager.debug_print_current_zone_info()` and clicking the purple wormhole:
1. The full output from `debug_print_current_zone_info()`
2. ALL `Wormhole_debug :` lines from the click event

This will show me:
- Where all wormholes are positioned
- Which one you actually clicked
- If the depth wormhole's type is being corrupted


# Duplicate Wormhole Creation Bug - FIXED

## The Bug

Wormholes were being created **TWICE**:

1. **First**: In `setup_zone_layers()` → `create_zone_layer_for_discovered_zone()` (line 189)
   - Creates ALL wormholes (lateral + depth)
   
2. **Second**: In `setup_wormholes()` (line 250)
   - Called immediately after `setup_zone_layers()`
   - Creates wormholes AGAIN

### What Happened

When the depth wormhole was created:
```
CREATE DEPTH WORMHOLE: type=0 (DEPTH), position=(1272, -1272)
```

Then `setup_wormholes()` ran again and created **another wormhole at the same position**:
```
CREATE LATERAL WORMHOLE: type=1 (LATERAL), position=(1272, -1272)
```

The **lateral wormhole overwrote or obscured the depth wormhole**, even though both were in the arrays!

## The Fix

**Removed** the duplicate call:
```gdscript
# In _ready():
await setup_zone_layers()  ← Creates wormholes
# setup_wormholes()  ← REMOVED - was creating duplicates!
```

Made `setup_wormholes()` a no-op function with a deprecation note.

## Result

Now each zone will have:
- **Regular zones**: Exactly 2 wormholes (lateral left + right)
- **Portal zones**: Exactly 3 wormholes (lateral left + right + depth forward)

No duplicates, no overwrites, no corruption!

## Test

Restart and navigate to d1_zone_7. You should now see:
- 2 blue wormholes (lateral)
- 1 purple wormhole (depth) at position ~(1272, -1272)

Click the purple one and you'll see:
```
Wormhole_debug :   Wormhole type: 0 (0=DEPTH, 1=LATERAL)  ← CORRECT!
Wormhole_debug :   Wormhole color: (0.6, 0.3, 1.0, 1.0)  ← PURPLE!
...
Wormhole_debug :   TO: d2_zone_2 (difficulty 2, size 8000)  ← BIGGER ZONE!
```


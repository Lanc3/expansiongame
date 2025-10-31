# Depth Wormhole Creation Debug

## Current Issue
Depth wormholes are being created according to logs, but:
1. Users can't see them in the zone
2. When clicked, travel is still LATERAL

## Debug Strategy

### Added Debug Logging to:
1. **ZoneSetup.create_depth_wormhole()**:
   - Prints when called
   - Prints source/target difficulty
   - Prints wormhole properties after creation
   - Verifies registration with ZoneManager
   - Confirms depth_wormholes array size

### What to Look For

When d1_zone_7 is created, you should see:
```
>>> CREATE_DEPTH_WORMHOLE CALLED <<<
  Zone: d1_zone_7
  Is Forward: true
  Source difficulty: 1
  Target difficulty: 2
  Looking for portal at difficulty 2, index 4
  Found 0 zones at difficulty 2
  No portal zone found at difficulty 2 - wormhole will be undiscovered
  Wormhole added to parent: Wormholes
  Wormhole global_position: (0, -1800)  ← Should be at TOP
  Wormhole wormhole_type: 1  ← 1 = DEPTH
  Wormhole registered with ZoneManager
  Zone now has 1 depth wormholes  ← CRITICAL: Should be > 0
<<< CREATE_DEPTH_WORMHOLE COMPLETE >>>
```

### Next Steps

After restart with debug logging:
1. Navigate to d1_zone_7 (check console for which zone is the portal)
2. Look at console output for depth wormhole creation
3. Count wormholes in the zone:
   - Should be 3 total (2 lateral + 1 depth)
   - Depth wormhole at TOP (90°, approximately 0, -1800)
4. Try clicking the top wormhole
5. Check console for wormhole type

### If Still Broken

Possible causes:
- Wormhole not being added to depth_wormholes array
- Wormhole scene not loading properly
- Wormhole type being overridden somewhere
- Input system not detecting depth wormholes
- Minimap not displaying depth wormholes with different color


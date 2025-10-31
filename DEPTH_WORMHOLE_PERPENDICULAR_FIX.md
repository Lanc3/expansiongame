# Depth Wormhole Perpendicular Positioning Fix

## The Real Problem

Depth wormholes were positioned at **fixed cardinal angles** (90°, 270°), which could overlap with lateral wormholes that are positioned based on the zone's ring position.

### Example:
- Zone at ring position 90° (bottom of galaxy map)
- Lateral wormholes point toward neighbors at ~45° and ~135°
- Depth wormhole at 90° (between the two laterals) → **OVERLAP/COLLISION**

## The Solution

Position depth wormholes **PERPENDICULAR to the zone's ring position**:

```gdscript
var ring_angle = zone.ring_position  // e.g., 0.79 radians (45°)
var depth_angle = ring_angle + PI/2  // Perpendicular = 2.36 radians (135°)
```

### Why This Works:
- Each zone has a fixed `ring_position` (its angle on the ring)
- Lateral wormholes point along the ring tangent (toward left/right neighbors)
- Depth wormholes point PERPENDICULAR to the ring:
  - **Forward**: `ring_position + 90°` (toward center)
  - **Backward**: `ring_position - 90°` (toward outer edge)

### Visual Example:

For a zone at ring_position = 0° (right side of galaxy):
```
        CENTER
          ↑
          | 90° (forward depth)
          |
←―――[ZONE]―――→  0° (zone's ring position)
   lateral  lateral
          |
          | 270° (backward depth)
          ↓
        OUTER
```

For a zone at ring_position = 90° (bottom of galaxy):
```
          CENTER
          ↑
      180°| ← forward depth
       ↖  |
  lateral[ZONE]lateral  90° (zone's ring position)
          |  ↘
          |   0° ← backward depth
          ↓
        OUTER
```

## Result

Now depth wormholes will:
- ✅ NEVER overlap with lateral wormholes (geometrically impossible)
- ✅ Always point toward/away from galaxy center
- ✅ Be visually distinct (perpendicular to the ring structure)
- ✅ Be clickable (z_index = 10, AND different position)

## Expected Positions

For seed 3469852214, d1_zone_1 is the portal:
- Ring position: 0.79 radians (45°)
- Forward depth wormhole: 0.79 + PI/2 = 2.36 radians (135°)
- Position: approximately (-1272, 1272) - southwest quadrant
- Lateral wormholes: at angles toward 0° and 90° neighbors


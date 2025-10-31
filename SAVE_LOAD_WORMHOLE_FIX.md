# Save/Load System Fix - Wormholes and Zone Discovery

## Problem Summary
When loading a saved game:
1. **Wormholes were not being restored** - they were saved but never loaded
2. **Zone discovery status was being saved** but missing the critical `zone_index` field

## Changes Made

### 1. Enhanced Wormhole Save Function (`_save_wormhole_positions()`)
**File:** `scripts/autoloads/SaveLoadManager.gd` (lines 598-636)

**Added:**
- Save `wormhole_direction` for lateral wormholes
- Save `is_forward` metadata for depth wormholes
- Added debug logging to show how many zones with wormholes were saved

**What gets saved per wormhole:**
- Position (x, y)
- `target_zone_id` - where the wormhole leads
- `source_zone_id` - which zone it's in
- `wormhole_type` - DEPTH (0) or LATERAL (1)
- `is_undiscovered` - whether it leads to an unknown zone
- `wormhole_direction` - angle for lateral wormholes
- `is_forward` - direction for depth wormholes (forward = toward center/higher difficulty)

### 2. Created Wormhole Load Function (`_load_wormhole_positions()`)
**File:** `scripts/autoloads/SaveLoadManager.gd` (lines 638-708)

**This new function:**
1. Loads the Wormhole scene
2. For each zone with saved wormholes:
   - Clears any existing wormholes
   - Instantiates new wormholes with saved properties
   - Sets all wormhole data (position, type, targets, etc.)
   - Restores metadata (direction, forward flag)
   - Registers wormholes with ZoneManager
   - Properly categorizes them as lateral or depth

**Key implementation details:**
- Sets wormhole properties BEFORE adding to scene (to prevent premature initialization)
- Sets position AFTER adding to scene (for proper coordinate system)
- Waits one frame per wormhole to ensure proper initialization
- Provides detailed logging of the loading process

### 3. Integrated Wormhole Loading into Game Load
**File:** `scripts/autoloads/SaveLoadManager.gd` (lines 325-327)

Added call to `_load_wormhole_positions()` in the `_load_game_state()` function:
- Placed after resource nodes are loaded
- Placed before camera positioning
- Uses `await` to ensure wormholes are fully loaded before continuing

### 4. Fixed Zone Network Save/Load - Added `zone_index`
**Files:** `scripts/autoloads/SaveLoadManager.gd`
- **Save** (line 222): Now saves `zone_index` for each zone
- **Load** (line 376): Now restores `zone_index` for each zone

**Why zone_index is critical:**
- Determines the zone's position on its difficulty ring
- Used to calculate neighboring zones (left/right lateral wormholes)
- Required to identify which zone gets the depth portal wormhole
- Essential for the deterministic zone generation system

## Testing Guide

### Basic Save/Load Test
1. Start a new game
2. Explore and discover 2-3 zones (use wormholes to travel)
3. Note which zones you've discovered
4. Note where wormholes are located
5. Save the game (ESC → Save & Quit)
6. Load the game (Start → Load Game)

**Expected Results:**
✅ All discovered zones should still be discovered
✅ All wormholes should be in the same positions
✅ Wormhole colors should match (cyan = lateral, purple = depth forward, blue = depth backward)
✅ Clicking wormholes should work correctly
✅ Undiscovered wormholes should still be undiscovered

### Advanced Test - Depth Wormholes
1. Find and use a purple depth wormhole (leads to harder zone)
2. Verify you're in a harder zone (bigger, more enemies)
3. Save the game
4. Load the game
5. Check that:
   - You're still in the harder zone
   - The return wormhole (blue) still exists and works
   - The wormhole you came through (purple) still exists in the easier zone

### Wormhole Type Verification
After loading, check wormholes:
- **Cyan (Lateral):** Connects zones at same difficulty
- **Purple (Depth Forward):** Leads to harder zone (+1 difficulty)
- **Blue (Depth Backward):** Returns to easier zone (-1 difficulty)
- **Gray with "???":** Undiscovered wormhole (generates new zone when used)

## Technical Details

### Save Data Structure

**Wormhole Data:**
```json
{
  "wormhole_positions": {
    "d1_start": [
      {
        "x": 1200.0,
        "y": 500.0,
        "target_zone_id": "d1_zone_1",
        "source_zone_id": "d1_start",
        "wormhole_type": 1,
        "is_undiscovered": false,
        "wormhole_direction": 1.57
      }
    ]
  }
}
```

**Zone Network Data:**
```json
{
  "zone_network": {
    "zone_network_seed": 12345,
    "zones": [
      {
        "zone_id": "d1_start",
        "difficulty": 1,
        "zone_index": 0,
        "procedural_name": "Azure Nebula",
        "discovered": true,
        "ring_position": 0.0,
        "size_multiplier": 1.0,
        "spawn_area_size": 2000.0,
        "max_resource_tier": 1
      }
    ]
  }
}
```

### Load Order
The loading sequence is carefully ordered:
1. Load zone network (zones and discovery status)
2. Create zone layers
3. Load resources
4. Load units
5. Load buildings
6. **Load wormholes** ← NEW
7. Load camera position
8. Load fog of war

## Known Limitations
- Wormholes in the process of being generated (between zone creation and discovery) may not save perfectly, but this is an edge case that rarely occurs during saves
- Control groups are not re-linked to units after load (existing limitation, not related to this fix)

## Debug Logging
When loading, you'll see console output like:
```
SaveLoadManager: Loading wormholes...
SaveLoadManager: Loaded 2 wormholes for zone 'd1_start'
SaveLoadManager: Loaded 1 wormholes for zone 'd1_zone_1'
SaveLoadManager: Loaded 3 total wormholes across 2 zones
```

## Files Modified
- `scripts/autoloads/SaveLoadManager.gd` - Added wormhole loading, enhanced save, added zone_index

## Summary
The save/load system now properly persists:
✅ **Wormhole positions and properties**
✅ **Wormhole types (depth vs lateral)**
✅ **Wormhole discovery status**
✅ **Zone discovery status**
✅ **Zone ring structure (zone_index)**
✅ **Bidirectional wormhole connections**

The game can now be saved and loaded without losing any wormhole or zone discovery data!


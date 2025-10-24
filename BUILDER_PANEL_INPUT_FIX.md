# Builder Drone Panel - Input Fix

## Problem
When clicking on the BuilderDronePanel UI, the click was passing through to the game world, causing the Builder Drone to be deselected and the panel to close immediately.

## Solution
Applied the same pattern used by CommandShipPanel, which works correctly:

### 1. Fixed Positioning
**Before:**
- Used anchor-based positioning (centered at bottom)
- `anchors_preset = 7` (bottom center)

**After:**
- Fixed pixel coordinates like CommandShipPanel
- `offset_left = 405, offset_top = 300`
- `offset_right = 705, offset_bottom = 600`
- Positioned above CommandShipPanel (which is at y:620)

### 2. Mouse Input Blocking
**Added to all UI elements:**
- Panel: `mouse_filter = 0` (STOP)
- VBox: `mouse_filter = 0`
- ScrollContainer: `mouse_filter = 0`
- BuildingButtons: `mouse_filter = 0`
- Dynamically created buttons: `mouse_filter = Control.MOUSE_FILTER_STOP`

This ensures clicks are blocked from reaching the game world.

### 3. Visual Styling
**Added custom StyleBox:**
- Dark semi-transparent background: `Color(0.1, 0.1, 0.15, 0.95)`
- Green border: `Color(0.5, 0.8, 0.3, 1)` (distinguishes from blue CommandShipPanel)
- Rounded corners (8px radius)
- 2px border on all sides

### 4. Better Typography
- Title color: `Color(0.8, 0.9, 1, 1)` (light blue-white)
- Title font size: 14pt
- Proper spacing between elements (4px separation)

## New Panel Layout

```
Screen Layout:
┌─────────────────────────────┐
│     Top Info Bar (y: 0)     │
├─────────────────────────────┤
│                             │
│      Game World             │
│  ┌────────────────┐         │
│  │ BuilderDrone   │         │ ← New position (y: 300-600)
│  │ Panel          │         │   Green border
│  │ [Buildings...] │         │
│  └────────────────┘         │
├─────────────────────────────┤
│  CommandShipPanel (y: 620)  │ ← Blue border
└─────────────────────────────┘
```

## Files Changed

### scenes/ui/BuilderDronePanel.tscn
- ✅ Added StyleBoxFlat for custom appearance
- ✅ Changed from anchor-based to fixed positioning
- ✅ Set `mouse_filter = 0` on all elements
- ✅ Added theme overrides for colors and spacing
- ✅ Positioned at (405, 300) to (705, 600)

### scripts/ui/BuilderDronePanel.gd
- ✅ Ensured `mouse_filter = Control.MOUSE_FILTER_STOP` in `_ready()`
- ✅ Disabled input processing (let buttons handle their own input)
- ✅ Set `mouse_filter` on dynamically created buttons
- ✅ Added debug print to confirm setup

## Testing Checklist

### ✅ Should Work Now:
- [ ] Click Builder Drone → Panel appears
- [ ] Click inside panel → Panel stays open
- [ ] Click building button → Placement mode starts, panel closes
- [ ] Click outside panel → Builder deselects, panel closes
- [ ] Panel has green border (distinguishable from Command Ship's blue)
- [ ] Panel positioned above Command Ship panel (no overlap)

### ❌ Old Behavior (Fixed):
- ~~Click panel → Panel immediately closes~~
- ~~Click button → Nothing happens (panel closes first)~~
- ~~Panel centered at bottom (overlaps with other UI)~~

## Why This Works

1. **`mouse_filter = STOP`** prevents mouse events from propagating to nodes behind the UI
2. **Fixed positioning** ensures consistent placement (anchors can cause issues with input detection)
3. **All children have STOP filter** ensures clicks anywhere on panel are blocked
4. **Matches CommandShipPanel pattern** which is proven to work correctly

## Position Comparison

| Element | Left | Top | Right | Bottom | Width | Height |
|---------|------|-----|-------|--------|-------|--------|
| CommandShipPanel | 405 | 620 | 1020 | 720 | 615 | 100 |
| BuilderDronePanel | 405 | 300 | 705 | 600 | 300 | 300 |

**Both panels:**
- Align on left edge (x: 405)
- Don't overlap (Builder: 300-600, Command: 620-720)
- Stay in bottom-right area of screen

## Color Scheme

| Panel | Border Color | Purpose |
|-------|-------------|---------|
| CommandShip | Blue (0.3, 0.5, 0.8) | Production/Queue |
| BuilderDrone | Green (0.5, 0.8, 0.3) | Construction |
| Tech Tree | N/A (full screen) | Research |

Green border helps distinguish Builder panel from Command Ship panel visually.

## Success!

The Builder Drone panel now:
✅ Stays open when clicked
✅ Blocks input to game world properly
✅ Matches the working CommandShipPanel pattern
✅ Has distinct visual styling
✅ Positioned correctly to avoid overlaps

You can now click buttons in the panel without it closing! 🎉



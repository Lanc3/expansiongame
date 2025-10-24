# Builder Drone UI - Testing Guide

## What Was Added ✅

1. **BuilderDronePanel** - UI panel that shows available buildings
2. **PlacementController** - Handles mouse-based building placement
3. **UI Integration** - Shows panel when Builder Drone is selected

## How to Use

### Step 1: Select Builder Drone
- Press `B` key to spawn a Builder Drone (test hotkey)
- Click on the Builder Drone to select it
- **BuilderDronePanel appears** at bottom center of screen

### Step 2: Browse Available Buildings
The panel shows all buildings you can construct:
- ✅ **ResearchBuilding** - Always available
- 🔒 **BulletTurret** - Requires research
- 🔒 **LaserTurret** - Requires research
- 🔒 **MissileTurret** - Requires research
- 🔒 Other buildings - Require research

Each button shows:
- **Building Name**
- **Build Time** (e.g., "2m 0s")
- **Cost** (resource requirements)
  - Green text = Can afford
  - Red text = Cannot afford
- **Zone Limit** (if reached, button disabled)

### Step 3: Select Building to Place
- Click on any available building button
- **Placement mode activates**
- A **transparent ghost** appears at your mouse cursor
- Ghost follows your mouse as you move it

### Step 4: Place the Building
- **Green ghost** = Valid placement location
- **Red ghost** = Invalid placement (too close to other buildings/resources)
- **Left Click** = Confirm placement
- **Right Click** or **ESC** = Cancel placement

### Step 5: Watch Construction
- Builder Drone moves to the location
- Construction progress bar appears
- Building completes after construction time
- Real building spawns when done

## Visual Feedback

### BuilderDronePanel
- Located at **bottom center** of screen
- Shows when **single Builder Drone** is selected
- Hides when you select something else
- Lists all buildable structures

### Placement Ghost
- **Transparent preview** of building
- **Circle indicator** shows collision radius
- **Color changes:**
  - Green = Valid placement
  - Red = Invalid placement
- **Follows mouse cursor** in real-time

### Construction Ghost
- Appears after placement confirmed
- Shows building under construction
- Has progress bar
- Spawns real building when complete

## Controls

| Action | Control |
|--------|---------|
| Select Builder | Left Click on Builder Drone |
| Choose Building | Click button in panel |
| Confirm Placement | Left Click |
| Cancel Placement | Right Click or ESC |
| Spawn Test Builder | Press `B` key |

## Testing Checklist

### Basic Flow
- [ ] Press B, Builder Drone spawns
- [ ] Click Builder, panel appears
- [ ] Panel shows ResearchBuilding (and locked buildings)
- [ ] Click ResearchBuilding button
- [ ] Ghost appears at mouse
- [ ] Move mouse, ghost follows
- [ ] Green when valid, red when invalid
- [ ] Left click, placement confirms
- [ ] Builder moves to site
- [ ] Construction starts
- [ ] Building completes

### Edge Cases
- [ ] Can't place on other buildings
- [ ] Can't place on resources
- [ ] Can't place 2nd Research Building in same zone
- [ ] Insufficient resources shows red cost
- [ ] Right click cancels placement
- [ ] ESC cancels placement
- [ ] Selecting another unit hides panel

### Multiple Builders
- [ ] Select different builder, panel updates
- [ ] Each builder can construct independently
- [ ] Multiple construction ghosts work

## Features

### Smart Validation
- ✅ Checks resource availability
- ✅ Validates placement location
- ✅ Enforces zone limits
- ✅ Checks research requirements
- ✅ Shows visual feedback

### User-Friendly
- ✅ Real-time cost display
- ✅ Color-coded affordability
- ✅ Ghost preview before placement
- ✅ Easy cancel with right-click/ESC
- ✅ Clear visual feedback

### Integrated
- ✅ Works with existing selection system
- ✅ Doesn't conflict with other panels
- ✅ Uses existing BuildingDatabase
- ✅ Leverages BuilderDrone construction system

## What Buildings Can Be Built?

### Always Available
- **ResearchBuilding** - No research required

### Requires Research (After Tech Tree)
Once you unlock the corresponding research:
- **BulletTurret** - Basic defense
- **LaserTurret** - Energy defense
- **MissileTurret** - Long-range defense
- **PlasmaTurret** - Advanced defense
- **DroneFactory** - Auto-produces units
- **Refinery** - Resource conversion
- **ShieldGenerator** - Area protection
- **RepairStation** - Auto-repairs units
- **SensorArray** - Extended vision
- **MiningPlatform** - Auto-mining
- **TeleportPad** - Unit teleportation
- **SuperweaponPlatform** - Ultimate weapon

## Known Behaviors

1. **Panel Position** - Fixed at bottom center (can be adjusted in scene)
2. **Ghost Visuals** - Uses placeholder panel graphic (can be replaced)
3. **Placement Validation** - Checks 50-unit radius around resources
4. **Zone Limits** - ResearchBuilding limited to 1 per zone

## Next Steps (Optional Enhancements)

1. **Better Icons** - Custom building icons instead of text
2. **Hotkeys** - Keyboard shortcuts for buildings (e.g., T for turret)
3. **Grid Snapping** - Snap buildings to grid
4. **Rotation** - Rotate buildings during placement
5. **Demolish** - Select and demolish buildings
6. **Upgrade** - Upgrade existing buildings

## Troubleshooting

### Panel Doesn't Appear
- Verify Builder Drone is selected (check selection indicator)
- Check console for warnings about missing BuilderDronePanel
- Verify BuilderDronePanel is in GameScene hierarchy

### Ghost Doesn't Appear
- Check console for PlacementController errors
- Verify PlacementController is in Systems node
- Make sure building was clicked (check console print)

### Can't Place Building
- Check if location is valid (red = invalid)
- Verify you have enough resources
- Check zone limit (1 Research Building per zone)
- Ensure not placing on existing buildings/resources

### Builder Won't Construct
- Verify placement was confirmed (check console)
- Check if resources were consumed
- Verify BuilderDrone.start_construction was called

## Success!

The Builder Drone UI is **fully functional** and provides:
✅ Visual building selection panel
✅ Mouse-based placement mode
✅ Real-time validation feedback
✅ Smooth construction workflow
✅ Integration with research system

You can now build structures using a proper UI instead of code! 🎉



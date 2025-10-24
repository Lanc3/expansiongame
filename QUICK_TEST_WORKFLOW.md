# Quick Test Workflow - Research & Building System

## Starting Resources ✅

You now start with generous resources for testing:

| Resource | Amount | Purpose |
|----------|--------|---------|
| Iron Ore | 1,000 | Main building material |
| Carbon | 800 | Building component |
| Silicon | 600 | Building component |
| Copper | 500 | Building component |
| Zinc | 300 | Research costs |
| Nickel | 200 | Turret construction |
| Silver | 300 | Research costs |
| Lithium | 200 | Research costs |
| Gold | 150 | Advanced research |
| Titanium | 100 | Advanced research |

**This is enough for:**
- ✅ 2+ Research Buildings (300 Iron, 250 Carbon, 200 Silicon, 150 Copper each)
- ✅ Multiple research unlocks
- ✅ Several turrets after research

## Test Workflow: Complete Loop

### Phase 1: Build First Research Building (2 minutes)

1. **Launch game** (GameScene.tscn)
2. **Press `B`** - Spawns Builder Drone
3. **Click Builder Drone** - BuilderDronePanel appears at bottom
4. **Click "Research Facility"** button in panel
5. **Move mouse** - Green ghost follows cursor
6. **Left Click** to place - Builder moves to site
7. **Wait 2 minutes** - Construction completes (120 seconds)

### Phase 2: Use Research System (1 minute)

8. **Click completed Research Building** - Tech Tree opens
9. **Browse categories** - Hull, Shield, Weapon, Ability, Building, Economy
10. **Click available (yellow) nodes** to research:
    - Start with: "Reinforced Hull I" (50 Iron, 30 Carbon)
    - Then: "Basic Deflector" (60 Silicon, 40 Copper, 30 Zinc)
    - Then: "Basic Turret Construction" (100 Iron, 80 Copper, 60 Zinc)
11. **Press ESC** to close tech tree

### Phase 3: Build Turret (30 seconds)

12. **Click Builder Drone** again
13. **Click "Bullet Turret"** (now available after research)
14. **Place turret** with green ghost
15. **Wait 30 seconds** - Turret constructs

### Phase 4: Build Second Research Building (Different Zone)

16. **Travel to Zone 2** (via wormhole or zone switcher)
17. **Press `B`** for new Builder in Zone 2
18. **Build Research Building** in Zone 2 (allowed, 1 per zone)
19. **Try to build 2nd in Zone 2** - Should be blocked! ❌

### Phase 5: Deploy Satellite (If Researched)

20. **Research "Long-Range Sensors"** first
21. **Then research "Reconnaissance Satellite"**
22. **Deploy via code** (no UI yet):
    ```gdscript
    SatelliteManager.deploy_satellite(Vector2(1000, 1000), 1, false)
    ```
23. **Satellite reveals fog** permanently

## Quick Test Shortcuts

### Super Fast Test (1 minute)
1. Press `R` - Instant Research Building spawns
2. Click it - Tech tree opens
3. Research something
4. Press ESC

### Full Builder Test (3 minutes)
1. Press `B` - Builder spawns
2. Click Builder - Panel appears
3. Click Research Facility
4. Place with mouse
5. Wait for construction
6. Click building when done
7. Use tech tree

### Multiple Buildings Test (5 minutes)
1. Build Research Building
2. Research "Basic Turret Construction"
3. Build 3 turrets around base
4. Travel to Zone 2
5. Build another Research Building
6. Try to build 2nd in same zone (blocked!)

## What to Look For

### ✅ Working Correctly
- [ ] Builder panel shows when Builder selected
- [ ] Green/red cost colors match affordability
- [ ] Ghost preview appears and follows mouse
- [ ] Green ghost = valid, red ghost = invalid
- [ ] Left click confirms placement
- [ ] Right click/ESC cancels placement
- [ ] Builder moves to site automatically
- [ ] Construction progress bar visible
- [ ] Building spawns when complete
- [ ] Tech tree opens when clicking Research Building
- [ ] Research consumes resources
- [ ] Unlocked buildings appear in Builder panel
- [ ] Zone limit enforced (1 Research Building per zone)

### ❌ Issues to Check
- [ ] Panel doesn't appear → Check console
- [ ] Ghost doesn't follow mouse → Check PlacementController
- [ ] Building won't place → Check if red (invalid location)
- [ ] Resources not consumed → Check ResourceManager
- [ ] Tech tree blank → Check ResearchDatabase autoload

## Resource Costs Reference

### Buildings
- **Research Building**: 300 Iron, 250 Carbon, 200 Silicon, 150 Copper (120s)
- **Bullet Turret**: 100 Iron, 80 Copper, 60 Nickel (30s) [Requires research]
- **Laser Turret**: 120 Silicon, 100 Lithium, 80 Titanium (45s) [Requires research]
- **Missile Turret**: 130 Carbon, 110 Sulfur, 90 Cobalt (50s) [Requires research]

### Early Research (Available Immediately)
- **Reinforced Hull I**: 50 Iron, 30 Carbon (+15% hull)
- **Basic Deflector**: 60 Silicon, 40 Copper, 30 Zinc (+50 shields)
- **Mass Driver I**: 40 Iron, 30 Copper, 20 Nickel (+20% kinetic damage)
- **Pulse Laser I**: 40 Silicon, 30 Lithium, 20 Beryllium (+20% energy damage)
- **Basic Turret Construction**: 100 Iron, 80 Copper, 60 Zinc (unlocks turrets)

## Success Criteria

The system works if you can:
1. ✅ Select Builder Drone → Panel appears
2. ✅ Click building in panel → Placement mode starts
3. ✅ Place building with mouse → Construction begins
4. ✅ Building completes → Can click and use it
5. ✅ Click Research Building → Tech tree opens
6. ✅ Research tech → Effects apply, buildings unlock
7. ✅ Build unlocked building → Works

## Tips

- **Save resources** - Research is expensive!
- **Start with hull/shield research** - Makes your units stronger
- **Research turrets early** - Unlock defensive buildings
- **Build in different zones** - Test zone limits
- **Watch the progress bar** - Construction takes time
- **Cancel anytime** - Right-click to cancel placement

## Console Commands (Advanced)

If you need to manually test something:

```gdscript
# Give resources
ResourceManager.add_resource(0, 1000)  # Add 1000 Iron

# Unlock research
ResearchManager.unlock_research("building_turret_basic")

# Deploy satellite
SatelliteManager.deploy_satellite(Vector2(1000, 1000), 1, false)

# Spawn building instantly
var building = load("res://scenes/buildings/ResearchBuilding.tscn").instantiate()
building.global_position = Vector2(500, 500)
get_tree().current_scene.add_child(building)
```

## Expected Timeline

- **Startup**: Instant (resources loaded)
- **Select Builder**: 1 second
- **Choose Building**: 2 seconds
- **Place Building**: 3 seconds
- **Construction**: 30-120 seconds (depends on building)
- **Open Tech Tree**: 1 second
- **Research Tech**: 2 seconds
- **Build More**: Repeat

**Total for complete loop: ~3-5 minutes**

Enjoy testing! 🚀



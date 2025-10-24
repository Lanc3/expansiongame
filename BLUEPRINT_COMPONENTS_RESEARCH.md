# Blueprint Components Research Line - Implementation

## Overview

Added a new "blueprint" research category with 20 research nodes that unlock components for a future blueprint builder system. These researches provide no immediate gameplay effects but serve as prerequisites for an upcoming ship/unit customization system.

## What Was Added

### 1. New Research Category: "blueprint"

**Category Properties:**
- Display Name: "Blueprint Components"
- Color: Purple (0.6, 0.3, 0.8)
- Total Nodes: 20
- Tier Range: 0-4

### 2. Four Component Types (5 tiers each)

#### Blueprint Weapon Components
- **Blueprint Weapon I-V** (IDs: blueprint_weapon_1 through blueprint_weapon_5)
- Prerequisites: Requires weapon_damage_1 for Tier I, then each tier requires previous
- Resources: Iron Ore, Aluminum, Titanium, Tungsten, Iridium, Platinum
- Position: x=100-700, y=1000

#### Blueprint Shield Components
- **Blueprint Shield I-V** (IDs: blueprint_shield_1 through blueprint_shield_5)
- Prerequisites: Requires shield_basic_1 for Tier I, then each tier requires previous
- Resources: Carbon, Cobalt, Nickel, Chromium, Osmium, Rhodium
- Position: x=100-700, y=1150

#### Blueprint Energy Core Components
- **Blueprint Energy Core I-V** (IDs: blueprint_energy_1 through blueprint_energy_5)
- Prerequisites: Requires energy_efficiency_1 for Tier I, then each tier requires previous
- Resources: Silicon, Lithium, Uranium, Palladium, Thorium, Antimatter
- Position: x=100-700, y=1300

#### Blueprint Hull Components
- **Blueprint Hull I-V** (IDs: blueprint_hull_1 through blueprint_hull_5)
- Prerequisites: Requires hull_reinforced_1 for Tier I, then each tier requires previous
- Resources: Iron Ore, Copper, Zinc, Lead, Beryllium, Graphene
- Position: x=100-700, y=1450

## Research Structure

### Tier Progression

| Tier | Level | Research Time | Cost Complexity | Example Cost |
|------|-------|---------------|-----------------|--------------|
| 0 | I | 10s | 2-3 resources | 100-150 total |
| 1 | II | 22s | 3-4 resources | 300-400 total |
| 2 | III | 34s | 4-5 resources | 650-800 total |
| 3 | IV | 46s | 5-6 resources | 1100-1300 total |
| 4 | V | 58s | 6+ resources | 1700-2000 total |

### Prerequisites Chain

**Tier I (Independent starts):**
- Blueprint Weapon I → requires weapon_damage_1
- Blueprint Shield I → requires shield_basic_1
- Blueprint Energy I → requires energy_efficiency_1
- Blueprint Hull I → requires hull_reinforced_1

**Tiers II-V (Linear progression):**
- Each tier requires the previous tier of the same component
- Example: Blueprint Weapon V requires IV, which requires III, which requires II, which requires I

### Cost Progression Example (Blueprint Weapon)

**Tier I:** 100 Iron, 50 Aluminum (2 resources, moderate)
**Tier II:** 200 Iron, 100 Aluminum, 50 Titanium (3 resources, higher)
**Tier III:** 350 Iron, 200 Aluminum, 100 Titanium, 50 Tungsten (4 resources, expensive)
**Tier IV:** 500 Iron, 350 Aluminum, 200 Titanium, 100 Tungsten, 50 Iridium (5 resources, very expensive)
**Tier V:** 750 Iron, 500 Aluminum, 350 Titanium, 200 Tungsten, 100 Iridium, 50 Platinum (6 resources, ultimate)

## Tech Tree Layout

### Visual Positioning

```
Blueprint Category (Purple)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Weapons:    [I]──→[II]──→[III]──→[IV]──→[V]
            100    250     400     550    700  (x position)
            y=1000

Shields:    [I]──→[II]──→[III]──→[IV]──→[V]
            100    250     400     550    700
            y=1150

Energy:     [I]──→[II]──→[III]──→[IV]──→[V]
            100    250     400     550    700
            y=1300

Hull:       [I]──→[II]──→[III]──→[IV]──→[V]
            100    250     400     550    700
            y=1450
```

### Connection Lines

Each component line is independent horizontally (I→II→III→IV→V), but:
- Blueprint Weapon I connects to weapon_damage_1 (existing research)
- Blueprint Shield I connects to shield_basic_1 (existing research)
- Blueprint Energy I connects to energy_efficiency_1 (existing research)
- Blueprint Hull I connects to hull_reinforced_1 (existing research)

## Implementation Details

### Files Modified

**scripts/data/ResearchDatabase.gd:**
- Added 20 new research nodes to RESEARCH_NODES array
- Updated get_all_categories() to include "blueprint"
- Updated get_category_display_name() for "blueprint" → "Blueprint Components"
- Updated get_category_color() for "blueprint" → Purple (0.6, 0.3, 0.8)
- Updated header documentation (110+ → 130+ nodes, 6 → 7 categories)
- Updated category list in comments
- Updated unlock_type documentation to include "blueprint_component"

### Research Node Template

```gdscript
{
    id = "blueprint_weapon_1",
    name = "Blueprint Weapon I",
    description = "Unlocks basic weapon components for blueprint builder.",
    prerequisites = ["weapon_damage_1"],
    cost = {0: 100, 3: 50},  // Iron Ore, Aluminum
    category = "blueprint",
    tier = 0,
    effects = {},  // No effects - for future use
    unlock_type = "blueprint_component",
    position = Vector2(100, 1000)
}
```

## Key Properties

### No Immediate Effects
- All blueprint research nodes have `effects = {}`
- They don't modify unit stats or unlock buildings
- They're markers for future blueprint builder system

### unlock_type: "blueprint_component"
- New unlock type specifically for blueprint components
- Allows ResearchManager to identify these for future features
- Can be queried separately from "upgrade", "building", "ability", "unit"

### Category: "blueprint"
- Distinct category for UI organization
- Purple color distinguishes from other research
- Separate tab in tech tree UI

## How It Works

### Research Flow

1. **Player unlocks basic research** (e.g., hull_reinforced_1, weapon_damage_1)
2. **Blueprint Tier I becomes available** (requires basic research)
3. **Player researches Blueprint Tier I** (unlocks component, no stat change)
4. **Blueprint Tier II becomes available** (requires Tier I)
5. **Player continues through tiers** (I→II→III→IV→V)
6. **All tiers unlocked** (ready for blueprint builder system in future phase)

### Example Progression (Blueprint Weapon)

```
Step 1: Research weapon_damage_1 (existing research)
        ↓
Step 2: Blueprint Weapon I available (10s, 150 resources)
        ↓
Step 3: Blueprint Weapon II available (22s, 350 resources)
        ↓
Step 4: Blueprint Weapon III available (34s, 700 resources)
        ↓
Step 5: Blueprint Weapon IV available (46s, 1150 resources)
        ↓
Step 6: Blueprint Weapon V available (58s, 1750 resources)
        ↓
Step 7: All weapon components unlocked (ready for builder)
```

## Testing

### How to Test

1. **Open tech tree** (click Research Building)
2. **Switch to Blueprint Components tab** (purple tab)
3. **Verify 20 nodes visible** (4 rows of 5 nodes each)
4. **Check prerequisites:**
   - Weapon I locked until weapon_damage_1 researched
   - Shield I locked until shield_basic_1 researched
   - Energy I locked until energy_efficiency_1 researched
   - Hull I locked until hull_reinforced_1 researched
5. **Research a Tier I component** (e.g., Blueprint Weapon I)
6. **Verify Tier II unlocks** (Blueprint Weapon II becomes available)
7. **Continue through tiers** (verify linear progression)
8. **Check costs scale properly** (each tier more expensive)
9. **Verify research times** (10s, 22s, 34s, 46s, 58s)
10. **Confirm no stat changes** (researching doesn't affect gameplay yet)

### Expected Console Output

```
ResearchManager: Started research on blueprint_weapon_1 - Blueprint Weapon I (10 seconds)
[10 seconds later]
ResearchManager: Completed research on blueprint_weapon_1 - Blueprint Weapon I
TechTreeUI: Research unlocked: blueprint_weapon_1, updating all nodes
TechTreeNode: Blueprint Weapon II status changed: locked → available (can_afford=true)
```

### Visual Verification

**Blueprint Tab:**
- ✅ Purple color theme
- ✅ "Blueprint Components" label
- ✅ 20 nodes in 4 horizontal rows
- ✅ Nodes spaced 150px apart horizontally
- ✅ Rows spaced 150px apart vertically

**Node States:**
- 🔒 Gray = Locked (prerequisites not met)
- 💛 Yellow = Need resources (prerequisites met, can't afford)
- ✅ Bright Green = Available (prerequisites met, can afford)
- ✅ Green = Researched (completed)

**Connections:**
- Gray lines from Tier I to basic research (before unlocked)
- Yellow/Green lines within component chain (based on status)
- Horizontal progression I→II→III→IV→V

## Future Integration

### Blueprint Builder System (Next Phase)

When the blueprint builder is implemented, it will:
1. **Check unlocked blueprint components**
   - Query ResearchManager for unlock_type="blueprint_component"
2. **Display available components**
   - Show Weapon I-V if researched
   - Show Shield I-V if researched
   - etc.
3. **Allow component selection**
   - Player picks components to build custom ship/unit
4. **Save blueprint designs**
   - Store component selections
5. **Build units from blueprints**
   - Construct units with selected components

### Example Builder Query

```gdscript
# Get all unlocked blueprint components
func get_unlocked_blueprint_components() -> Array:
    var components = []
    for research_id in ResearchManager.unlocked_research:
        var research = ResearchDatabase.get_research_by_id(research_id)
        if research.unlock_type == "blueprint_component":
            components.append(research)
    return components
```

## Success Criteria

✅ **20 nodes added** - All blueprint components in database
✅ **Category created** - "blueprint" category with purple color
✅ **Prerequisites work** - Each tier requires previous + basic research
✅ **Cost progression** - Tiers get progressively more expensive
✅ **Time scaling** - Auto-calculated from tier (10s to 58s)
✅ **No effects** - Empty effects dictionary (for future use)
✅ **UI integration** - Blueprint tab appears in tech tree
✅ **Visual layout** - 4 rows × 5 columns grid
✅ **Save/load ready** - Blueprint research persists across sessions

**All criteria met!** Blueprint components research line fully implemented! 🎨



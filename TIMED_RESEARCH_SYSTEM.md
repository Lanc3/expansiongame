# Timed Research System - Implementation

## Overview

Research is no longer instant! It now takes time based on tier, with visual progress bars showing research status.

## How It Works

### Research Times (By Tier)

| Tier | Time | Example Research |
|------|------|------------------|
| 0 | 10s | Reinforced Hull I, Basic Deflector |
| 1 | 22s | Improved Deflector, Mining Efficiency I |
| 2 | 34s | Composite Armor I, Energy Barrier I |
| 3 | 46s | Composite Armor II, Gold research |
| 4 | 58s | Advanced Alloy, Phase Shield |
| 5 | 70s | Crystalline Hull, Plasma Projector |
| 6 | 82s | Quantum Shield, Particle Beam |
| 7 | 94s | Neutronium Plating, Reality tech |
| 8 | 106s | Exotic Matter, Ultimate weapons |
| 9 | 118s | Dimensional Armor, Transcendent tech |

**Formula:** `research_time = 10 + (tier × 12)` seconds

## Research Flow

### Step-by-Step Process

1. **Click Available Node** (Bright Green)
   - Resources consumed immediately
   - Research starts
   - Progress bar appears on node
   - "RESEARCHING..." label shows

2. **Research In Progress**
   - Progress bar fills: 0% → 100%
   - Updates every frame
   - Node shows blue progress bar
   - Can't start another research (one at a time)

3. **Research Completes**
   - Progress bar disappears
   - "RESEARCHING..." label hides
   - Node turns GREEN (researched)
   - Effects apply to all units
   - Unlock animation plays
   - Can research next tech

## Visual Feedback

### During Research
```
┌─────────────────────┐
│ ████ (Icon)         │
│ Reinforced Hull I   │
│ 50  30             │
├─────────────────────┤
│ RESEARCHING...      │ ← Blue text
│ ████████░░░░ 67%   │ ← Blue progress bar
└─────────────────────┘
```

### After Complete
```
┌─────────────────────┐
│ ████ (Icon)         │ ← Bright green tint
│ ✓ Reinforced Hull I │
│   --Complete--      │
└─────────────────────┘ (Green border)
```

## New Features

### ResearchManager

**New Variables:**
- `current_research_id` - What's being researched
- `research_progress` - Current time elapsed
- `research_time_total` - Total time needed

**New Signals:**
- `research_started(research_id, research_time)` - When research begins
- `research_progress_updated(research_id, progress)` - Every frame (0.0-1.0)
- `research_unlocked(research_id)` - When complete

**New Methods:**
- `start_research(research_id)` - Begins timed research
- `complete_research()` - Completes and applies effects
- `cancel_research()` - Cancels and refunds resources
- `is_researching()` - Check if research active
- `unlock_research()` - Backwards compatible wrapper

**Processing:**
- Runs in `_process(delta)` every frame
- Updates progress
- Auto-completes when time reached

### TechTreeNode

**New UI Elements:**
- `research_progress_bar` - Blue progress bar (140×12)
- `researching_label` - "RESEARCHING..." text

**New Signal Handlers:**
- `_on_research_started()` - Shows progress bar
- `_on_research_progress()` - Updates bar value
- `_on_research_completed()` - Hides bar, updates state

**Visual Changes:**
- Progress bar appears at bottom of node
- Blue bar fills left to right
- Shows percentage (e.g., "67%")
- Label shows "RESEARCHING..."

### ResearchDatabase

**New Helper:**
- `get_research_time(research_id)` - Returns research duration

## Console Output Example

```
User clicks node:
TechTreeNode: Clicked on Reinforced Hull I (status: available)
TechTreeNode: Attempting to start research...
ResearchManager: Started research on hull_reinforced_1 - Reinforced Hull I (10 seconds)
TechTreeNode: Research started!
TechTreeNode: Research started on Reinforced Hull I (10s)

[Every frame for 10 seconds:]
[Progress bar fills silently]

After 10 seconds:
ResearchManager: Completed research on hull_reinforced_1 - Reinforced Hull I
TechTreeNode: Research completed on Reinforced Hull I
```

## Restrictions

### One Research at a Time
- Can only research ONE tech at a time
- Clicking another node shows: "Already researching something else"
- Wait for current research to complete
- Strategic choice required

### Resources Consumed Upfront
- Resources taken when research **starts**
- If you cancel, resources are refunded
- Prevents exploiting the system

### Can't Interrupt
- Must wait for research to complete
- Or cancel and get refund (future feature)

## Strategic Implications

### Early Game (Tier 0-2)
- Fast research (10-34 seconds)
- Quick progression
- Low cost, low commitment

### Mid Game (Tier 3-5)
- Moderate research (46-70 seconds)
- ~1 minute per tech
- Requires planning

### Late Game (Tier 6-9)
- Slow research (82-118 seconds)
- ~1.5-2 minutes per tech
- Major strategic decisions
- High cost investment

## Testing

### How to Test Timed Research

1. **Press `R`** - Spawn Research Building
2. **Click building** - Open tech tree
3. **Click bright green node** (e.g., "Reinforced Hull I")
4. **Watch:**
   - "RESEARCHING..." label appears
   - Blue progress bar shows at bottom
   - Bar fills: 0% → 10% → 20% → ... → 100%
   - Takes 10 seconds for tier 0
5. **At 100%:**
   - Progress bar disappears
   - Node turns green
   - Can research next tech

### Expected Timeline
- Tier 0 research: 10 seconds
- Tier 1 research: 22 seconds  
- Tier 2 research: 34 seconds
- Ultimate tier research: ~2 minutes

## Comparison

### Before (Instant)
```
Click node → Immediately unlocked → Next research
(No waiting, spammy)
```

### After (Timed)
```
Click node → Start research → Wait 10-120s → Complete → Next
(Strategic, meaningful progression)
```

## Future Enhancements (Optional)

1. **Research Queue** - Queue multiple researches
2. **Cancel Button** - Stop research, get refund
3. **Speed Boosts** - Research faster with upgrades
4. **Multiple Buildings** - Research in parallel at different facilities

## Files Modified

- ✅ `scripts/autoloads/ResearchManager.gd` - Added timed research system
- ✅ `scripts/ui/TechTreeNode.gd` - Added progress bar and signals
- ✅ `scripts/data/ResearchDatabase.gd` - Added get_research_time()

## Success Criteria

Timed research works if:
- ✅ Clicking node starts research (not instant)
- ✅ Progress bar appears and fills
- ✅ "RESEARCHING..." label visible
- ✅ Takes 10-120 seconds based on tier
- ✅ Can only research one at a time
- ✅ Node turns green when complete
- ✅ Effects apply after completion

The research system is now **strategic and time-based**! 🕐✨



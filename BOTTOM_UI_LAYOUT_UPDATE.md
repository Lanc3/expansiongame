# Bottom UI Layout Update

## Changes Made

### New Layout Structure

The bottom UI has been reorganized for better space utilization:

**Old Layout (Horizontal):**
```
[SelectedUnits: 400px] [CommandShip/Builder: 410px] [ZoneSwitcher: 195px] [Minimap: 260px]
Total: ~1265px + gaps
```

**New Layout (Hybrid):**
```
[SelectedUnits: 505px] [CommandShip/Builder: 505px] [Right Column: 260px]
                                                      └─ ZoneSwitcher: 60px (stacked)
                                                      └─ Minimap: 200px (stacked)
Total: 1280px (fills screen width perfectly)
```

### Zone Dimensions Updated

#### Left Zone (SelectedUnitsPanel)
- **Old:** 400px width
- **New:** 505px width (+105px)
- **Height:** 100px (unchanged)
- **Benefits:** More space for unit icons and formation buttons

#### Center Zone (CommandShipPanel/BuilderDronePanel)
- **Old:** 410px width
- **New:** 505px width (+95px)
- **Height:** 100px (unchanged)
- **Benefits:** More space for build queue and production buttons

#### Right Zone (Vertical Stack)
- **Width:** 260px (matches minimap)
- **Structure:** VBoxContainer with 2 slots

**ZoneSwitcher Slot:**
- **Dimensions:** 260×60px (60% of minimap height as requested)
- **Old:** 195×100px
- **Benefits:** Wider but more compact, sits perfectly above minimap

**Minimap Slot:**
- **Dimensions:** 260×200px
- **Position:** Below ZoneSwitcher
- **Benefits:** Golden ratio dimensions, no grey space

### Files Modified

1. **scenes/ui/BottomHUD.tscn**
   - Changed RightZone from Control to VBoxContainer
   - Added ZoneSwitcherSlot (260×60)
   - Added MinimapSlot (260×200)
   - Updated LeftZone: 505px
   - Updated CenterZone: 505px
   - Removed RightCenterZone (no longer needed)

2. **scripts/ui/BottomHUD.gd**
   - Updated zone references: `zone_switcher_slot` and `minimap_slot`
   - Updated `setup_panels()` to reparent to new slots

3. **scenes/ui/SelectedUnitsPanel.tscn**
   - Width: 400px → 505px

4. **scenes/ui/CommandShipPanel.tscn**
   - Width: 410px → 505px
   - Position updated for new layout

5. **scenes/ui/BuilderDronePanel.tscn**
   - Width: 410px → 505px
   - Position updated for new layout

6. **scenes/ui/ZoneSwitcher.tscn**
   - Dimensions: 195×100 → 260×60
   - Reduced internal padding (2px separation)
   - Font size: 14pt → 12pt
   - Button minimum size: 32×24px
   - Tighter layout for compact display

7. **scenes/main/GameScene.tscn**
   - Updated SelectedUnitsPanel position
   - Updated ZoneSwitcher position (above minimap)
   - Updated panel offsets to match new zones

### Visual Result

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│                          Game Area (620px height)                        │
│                                                                          │
├────────────────────────────────┬────────────────────────────────┬───────┤
│                                │                                │  Zone │ 60px
│   Selected Units Panel         │  Command/Builder Panel         │ Switch│
│   (505px × 100px)              │  (505px × 100px)               ├───────┤
│   - Cyan border                │  - Blue/Green border           │       │
│   - Unit icons                 │  - Build buttons               │ Mini- │
│   - Formation buttons          │  - Production queue            │  map  │ 200px
│   - Paint mode controls        │  - Unit stats                  │       │
│                                │                                │ 260px │
└────────────────────────────────┴────────────────────────────────┴───────┘
       505px                            505px                       260px
```

### Benefits

1. **Better Space Utilization**
   - Extra 200px distributed across main panels
   - No wasted horizontal space
   - ZoneSwitcher width increased from 195px to 260px

2. **Improved Visual Hierarchy**
   - ZoneSwitcher logically grouped with minimap (both navigation)
   - Cleaner separation of functions
   - Vertical stack on right creates clear navigation column

3. **More Content Space**
   - SelectedUnitsPanel: +26% width (more unit icons visible)
   - CommandShip/Builder: +23% width (more build buttons, longer queue display)
   - ZoneSwitcher: +33% width (easier to read zone name)

4. **Arcade Aesthetic**
   - Compact ZoneSwitcher above minimap looks sleek
   - Fills entire screen width (1280px)
   - Symmetrical layout (505-505-260)

### Zone Switcher Adjustments

The ZoneSwitcher has been optimized for its new compact 260×60px size:
- Reduced internal separation: 5px → 2px
- Reduced font size: 14pt → 12pt
- Set button minimum sizes: 32×24px
- Added 4px padding for tighter fit
- Removed unnecessary spacing

Total internal breakdown (60px):
- Top/bottom padding: 2×4px = 8px
- Zone label: ~18px
- Separator: 2px
- Button row: ~26px
- Separator: 2px
- Unit indicators: ~4px (if shown)
= ~60px total ✓

### Testing Checklist

- [ ] ZoneSwitcher appears above minimap (not beside it)
- [ ] ZoneSwitcher is 260px wide, 60px tall
- [ ] Minimap is 260px wide, 200px tall (with corner brackets)
- [ ] SelectedUnitsPanel is 505px wide
- [ ] CommandShipPanel is 505px wide (when visible)
- [ ] BuilderDronePanel is 505px wide (when visible)
- [ ] No overlapping panels
- [ ] All text is readable in compact ZoneSwitcher
- [ ] Bottom UI fills entire screen width
- [ ] No gaps or alignment issues

### Notes

- Total bottom UI height remains 100px
- ZoneSwitcher and Minimap stack vertically in 260px wide column
- BottomHUD manager automatically reparents panels to correct zones
- All panels maintain their color-coded borders
- Layout is designed for 1280×720 resolution



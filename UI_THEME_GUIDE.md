# UI Theme Guide - Arcade RTS Style

## Overview

This guide documents the arcade-style RTS UI theme system for the Expansion RTS game. The theme emphasizes bright, high-contrast colors, clear borders, and visual depth to create a professional AAA RTS feel with arcade energy.

## Color Palette

### Primary Colors
- **Bright Cyan**: `#00E5FF` (RGB: 0, 0.898, 1) - Primary accent, highlights, hover states
- **Electric Blue**: `#2196F3` (RGB: 0.129, 0.588, 0.953) - Command ship, primary buttons
- **Neon Purple**: `#9C27B0` (RGB: 0.612, 0.153, 0.69) - Wormholes, portals, zone switcher

### Accent Colors
- **Lime Green**: `#76FF03` (RGB: 0.463, 1, 0.012) - Success, builder drone, confirmation
- **Orange**: `#FF9800` (RGB: 1, 0.596, 0) - Warnings, asteroids, resource info
- **Hot Pink**: `#E91E63` (RGB: 0.914, 0.118, 0.388) - Danger, alerts, errors

### Background Colors
- **Dark Panel**: `rgba(10, 15, 30, 0.85-0.95)` (RGB: 0.039, 0.059, 0.118)
- **Darker Overlay**: `rgba(5, 15, 20, 0.95)` (RGB: 0.02, 0.059, 0.078)

### Text Colors
- **White**: `#FFFFFF` (RGB: 1, 1, 1) - Primary text
- **Cyan**: `#00E5FF` - Highlighted text, headers
- **Muted White**: `rgba(255, 255, 255, 0.8)` - Secondary text

## Panel Categories

### 1. HUD Panels
**Used for**: TopInfoBar, ResourceBar
- **Background**: Semi-transparent dark (85% opacity)
- **Border**: 2px bright cyan, bottom border only for top bar
- **Corner Radius**: 8px
- **Shadow**: 4px cyan glow

### 2. Context Panels (Color-Coded by Function)
**Command Ship Panel** (Blue):
- Border: `#2196F3` (Electric Blue)
- Use for: Command ship production, military units

**Builder Drone Panel** (Green):
- Border: `#76FF03` (Lime Green)
- Use for: Construction, building placement

**Selected Units Panel** (Cyan):
- Border: `#00E5FF` (Bright Cyan)
- Use for: Unit selection, formation controls

**Zone Switcher** (Purple):
- Border: `#9C27B0` (Neon Purple)
- Use for: Zone navigation, wormhole control

### 3. Info Panels
**Asteroid Info** (Orange):
- Border: `#FF9800`
- Shadow: 10px dark shadow
- Use for: Resource nodes, mining info

**Wormhole Info** (Purple):
- Border: `#9C27B0`
- Shadow: 10px purple glow
- Use for: Portal destinations, travel info

### 4. Overlay Panels
**Used for**: PauseMenu, TechTreeUI, Settings
- **Background**: Darker, 95% opacity
- **Border**: 3px bright cyan
- **Corner Radius**: 10px
- **Shadow**: 15px dark shadow

### 5. Minimap
- **Size**: 260×200 container, 256×196 drawable area
- **Border**: 2px cyan with decorative corner brackets
- **Background**: Dark panel with 90% opacity

## Typography Hierarchy

### Font Sizes
- **Title**: 24pt - Major headings (Zone titles, menu headers)
- **Header**: 16pt - Section headers, panel titles
- **Body**: 12pt - Standard UI text, labels (default)
- **Small**: 10pt - Secondary info, status text
- **Tiny**: 9pt - Tertiary info, hints

### Font Colors
- Primary text: White
- Headers: Bright Cyan (#00E5FF)
- Context-specific: Match panel border color
- Disabled: `rgba(255, 255, 255, 0.5)`

## Button States

### Normal
- **Background**: Electric blue at 30% opacity
- **Border**: 1px electric blue at 60% opacity
- **Text**: White

### Hover
- **Background**: Electric blue at 50% opacity
- **Border**: 1px bright cyan at 90% opacity
- **Text**: Bright cyan
- **Shadow**: 3px cyan glow
- **Animation**: Smooth transition 0.2s

### Pressed
- **Background**: Bright cyan at 70% opacity
- **Border**: 1px bright cyan solid
- **Text**: White
- **Shadow**: 2px cyan glow (reduced)

### Disabled
- **Background**: Grey at 30% opacity
- **Border**: 1px grey at 40% opacity
- **Text**: Grey at 50% opacity

### Special Variants
**Success Button**:
- Border: Lime green (#76FF03)
- Use for: Confirm, build, create actions

**Danger Button**:
- Border: Hot pink (#E91E63)
- Use for: Delete, cancel, destructive actions

## Component Sizing

### Borders
- Panels: 2px
- Overlay panels: 3px
- Buttons: 1px

### Corner Radius
- Panels: 8px
- Overlay panels: 10px
- Buttons: 5px
- Progress bars: 3px
- Input fields: 4px

### Padding/Margins
- Panels: 8px internal padding
- Buttons: 4px internal padding
- Container separation: 4-5px
- Section separation: 10px

### Icon Sizes
- **Small**: 24×24px - Resource icons, status indicators
- **Medium**: 48×48px - Unit icons, building icons
- **Large**: 64×64px - Major UI elements, production previews

## Progress Bars

### Background
- Color: Dark grey `rgba(51, 51, 64, 0.6)`
- Border: 1px grey at 40% opacity
- Corner radius: 3px

### Fill
- Color: Bright cyan (#00E5FF) at 80% opacity
- Glow: 2px cyan shadow
- Animated: Optional pulsing for active progress

## Shadow & Glow Effects

### Panel Shadows
- HUD panels: 4px cyan glow
- Context panels: 6px colored glow (matching border)
- Info panels: 10px dark shadow
- Overlay panels: 15px dark shadow

### Button Glows
- Hover: 3px cyan glow
- Pressed: 2px cyan glow
- Progress bars: 2px cyan glow on fill

## Minimap Decorations

### Corner Brackets
- Size: 12px
- Thickness: 2px
- Color: Cyan at 60% opacity
- Position: All four corners

### Visual Style
- Scan lines optional for extra arcade feel
- Grid overlay optional for tactical aesthetic

## Best Practices

### Do's
✓ Use the theme resource (`main_theme.tres`) for all standard UI
✓ Match panel border colors to their function
✓ Apply smooth transitions (0.2s) for hover effects
✓ Keep text sizes within the hierarchy
✓ Maintain consistent padding (8px panels, 4px buttons)
✓ Use icon sizes consistently across similar UI elements

### Don'ts
✗ Don't mix inline StyleBoxFlat overrides unless necessary for dynamic colors
✗ Don't use borders narrower than 1px or thicker than 3px
✗ Don't use corner radius larger than 10px
✗ Don't apply glow effects to everything (reserve for active/important elements)
✗ Don't use colors outside the defined palette without good reason

## Implementation Reference

### Theme File Location
`resources/themes/main_theme.tres`

### Panel Type Classes
- `panel_hud` - Generic HUD panels
- `panel_command` - Command ship (blue)
- `panel_builder` - Builder drone (green)
- `panel_selection` - Unit selection (cyan)
- `panel_info` - Information panels (orange/purple)
- `panel_overlay` - Full-screen overlays

### Applying Theme
```gdscript
# In scene file (.tscn):
theme = ExtResource("path/to/main_theme.tres")

# For custom panel styling:
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_custom"]
bg_color = Color(0.039, 0.059, 0.118, 0.9)
border_width_left = 2
border_color = Color(0, 0.898, 1, 1)
# ... etc

theme_override_styles/panel = SubResource("StyleBoxFlat_custom")
```

### Color Overrides
```gdscript
# For labels:
theme_override_colors/font_color = Color(0, 0.898, 1, 1)
theme_override_font_sizes/font_size = 16

# For buttons:
theme_override_colors/font_hover_color = Color(0.463, 1, 0.012, 1)
```

## Examples

### Command Ship Panel
- Background: Dark (90% opacity)
- Border: 2px Electric Blue (#2196F3)
- Shadow: 6px blue glow
- Labels: Cyan text for headers

### Asteroid Info Panel
- Background: Dark (95% opacity)
- Border: 2px Orange (#FF9800)
- Shadow: 10px dark shadow
- Title: Orange, 16pt
- Body: White, 12pt

### Pause Menu
- Background: Darker (95% opacity)
- Border: 3px Bright Cyan (#00E5FF)
- Shadow: 15px dark shadow
- Title: Cyan, 36pt
- Buttons: Standard theme buttons

## Extending the Theme

When creating new UI elements:

1. **Determine category** (HUD, Context, Info, Overlay)
2. **Choose border color** based on function:
   - Blue for command/military
   - Green for building/construction
   - Cyan for selection/navigation
   - Orange for resources/info
   - Purple for portals/zones
   - Pink for danger/alerts
3. **Apply consistent sizing** (8px corners, 2px borders)
4. **Use typography hierarchy** (24/16/12/10pt)
5. **Add appropriate shadow/glow** for depth

## Version History

- **v1.0** (2025-10-28): Initial arcade theme implementation
  - Defined color palette
  - Created panel categories
  - Established sizing standards
  - Documented all UI components


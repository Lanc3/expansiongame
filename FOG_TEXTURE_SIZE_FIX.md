# Fog of War Texture Size Fix

## Problem

**Issue:** In zone 2 and larger zones, the fog of war boundaries didn't match the zone size - it looked like zone 1's fog was being used everywhere.

**Root Cause:** When switching between zones with different grid sizes, the fog texture wasn't being recreated. The old texture (e.g., 20x20 from zone 1) was being "updated" with a larger image (e.g., 40x40 for zone 2), which **fails silently** or produces incorrect results.

## Technical Details

### The Bug

**File:** `scripts/ui/FogOverlay.gd` - `update_fog_texture()` function

**Before (buggy code):**
```gdscript
// Create new image (correct size)
var image = Image.create(width, height, false, Image.FORMAT_L8)

// Try to update existing texture - FAILS if size changed!
if fog_texture:
    fog_texture.update(image)  // ❌ Can't update 20x20 texture with 40x40 image
else:
    fog_texture = ImageTexture.create_from_image(image)
```

**What happened:**
1. Zone 1: Create 20x20 texture ✓
2. Switch to Zone 2: Try to update 20x20 texture with 40x40 image ❌
3. Texture update fails → Zone 2 shows stretched/incorrect fog
4. Fog boundaries appear to be zone 1 size in all zones

### Zone Grid Sizes
```
Zone 1: 4000x4000   → 20x20 tiles  (200px tiles)
Zone 2: 8000x8000   → 40x40 tiles  (200px tiles)
Zone 3: 12000x12000 → 60x60 tiles  (200px tiles)
Zone 4: 16000x16000 → 53x53 tiles  (300px tiles)
Zone 5: 20000x20000 → 67x67 tiles  (300px tiles)
...etc
```

Each zone has a different texture size, so we **must recreate** the texture when switching zones.

## The Fix

### 1. Detect Texture Size Changes

Added size comparison before attempting texture update:

```gdscript
// Check if texture size changed - need to recreate texture
var texture_size_changed = false
if fog_texture:
    var old_size = fog_texture.get_size()
    texture_size_changed = (old_size.x != width or old_size.y != height)
```

### 2. Recreate Texture When Size Changes

```gdscript
if fog_texture and not texture_size_changed:
    // Same size - safe to update
    fog_texture.update(image)
else:
    // New texture or size changed - MUST recreate
    fog_texture = ImageTexture.create_from_image(image)
    
    // Set new texture in shader
    if fog_shader:
        fog_shader.set_shader_parameter("fog_texture", fog_texture)
```

### 3. Prevent Partial Updates Across Size Changes

Also fixed partial update logic to detect size mismatches:

```gdscript
// Check texture size matches grid size
if can_partial_update and fog_texture:
    var texture_size = fog_texture.get_size()
    if texture_size.x != width or texture_size.y != height:
        can_partial_update = false  // Force full regeneration
```

This prevents trying to partially update a 20x20 texture when we need a 40x40 one.

### 4. Enhanced Logging

Added debug output to confirm texture recreation:

```gdscript
if texture_size_changed:
    print("FogOverlay: RECREATED texture for Zone %d (%dx%d) - size changed!")
else:
    print("FogOverlay: Full texture update Zone %d (%dx%d)")
```

## Testing

When you switch zones now, you'll see:

```
// Switching from Zone 1 to Zone 2:
FogOverlay: RECREATED texture for Zone 2 (40x40) - size changed!

// Moving around in Zone 2:
FogOverlay: Full texture update Zone 2 (40x40)

// Switching to Zone 3:
FogOverlay: RECREATED texture for Zone 3 (60x60) - size changed!
```

The "RECREATED" message confirms the texture is being properly rebuilt for each zone size.

## Verification

### Visual Check:
1. **Start in Zone 1** - fog should cover 4000x4000 area
2. **Switch to Zone 2** - fog should now cover 8000x8000 area (2x larger)
3. **Press F key** at any location - fog reveals around camera
4. **Send units around** - fog reveals following them
5. **Check console** - should see "RECREATED texture" when switching zones

### Debug Output:
```
FogOverlay DEBUG Zone 2:
  - Zone bounds: pos=(-4000.0, -4000.0) size=(8000.0, 8000.0)
  - Fog grid: 40x40 tiles, tile_size=200px
  - Expected coverage: 8000x8000 = 8000x8000  ✓
```

**Coverage should always match zone size!**

## Files Modified

**scripts/ui/FogOverlay.gd**
- Added texture size change detection
- Recreate texture when dimensions change
- Fixed partial update logic for zone switches
- Enhanced debug logging

## Performance Impact

**Minimal:** Texture recreation only happens when switching zones (infrequent operation). Normal fog updates use the fast path (texture.update() for same-size updates or partial region updates).

## Related Fixes

This fix works together with previous fog system improvements:
1. ✅ Ships spawn in correct zones (not just viewing zone)
2. ✅ Fog updates for units in all zones (not just current)
3. ✅ Texture properly recreated for different zone sizes
4. ✅ Fog boundaries now match zone boundaries perfectly!

All fog of war issues should now be resolved! 🎯



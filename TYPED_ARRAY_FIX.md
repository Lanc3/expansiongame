# Typed Array Assignment Fix

## Problem
When loading a saved game, an error occurred:
```
Invalid assignment of property or key 'resource_composition' with value of type 'Array' 
on a base object of type 'StaticBody2D (ResourceNode)'.
```

This happened at line 334 when trying to assign the loaded composition data.

## Root Cause

**ResourceNode Definition:**
```gdscript
var resource_composition: Array[Dictionary] = []
```

The `resource_composition` is a **typed array** (`Array[Dictionary]`).

**JSON Limitation:**
When JSON data is saved and loaded, Godot's typed array information is lost. The JSON parser returns a regular `Array`, not `Array[Dictionary]`.

**Direct Assignment Fails:**
```gdscript
# This fails because JSON returns regular Array, not Array[Dictionary]
resource.resource_composition = resource_data["resource_composition"]  # ❌ Type mismatch!
```

## Solution

Convert the regular `Array` from JSON into a properly typed `Array[Dictionary]` before assignment:

```gdscript
if resource_data.has("resource_composition") and "resource_composition" in resource:
    # Convert regular Array to typed Array[Dictionary] to avoid type mismatch
    var composition_array: Array[Dictionary] = []
    for item in resource_data["resource_composition"]:
        if item is Dictionary:
            composition_array.append(item)
    resource.resource_composition = composition_array
```

### How It Works

1. **Create typed array**: `var composition_array: Array[Dictionary] = []`
2. **Iterate through loaded data**: `for item in resource_data["resource_composition"]`
3. **Validate each item**: `if item is Dictionary` (safety check)
4. **Add to typed array**: `composition_array.append(item)`
5. **Assign typed array**: `resource.resource_composition = composition_array` ✓

## Why This Happens

Godot's JSON system doesn't preserve type information:
- **Before Save**: `Array[Dictionary]` (typed)
- **In JSON**: Just `Array` (untyped)
- **After Load**: `Array` (untyped)
- **Need**: `Array[Dictionary]` (typed) for assignment

## File Modified
- `scripts/autoloads/SaveLoadManager.gd` - `_load_resource_nodes()` method

## Testing
- ✓ Load saved game with scanned asteroids
- ✓ No type mismatch errors
- ✓ Composition data loads correctly
- ✓ Asteroids show as scanned with correct resources

## Technical Note

This is a common issue when working with typed arrays and JSON in Godot. The workaround is to always manually reconstruct typed arrays when loading from JSON data.

### Other Typed Arrays to Watch
If you add more typed arrays to save data in the future, remember to use this same conversion pattern:
```gdscript
var typed_array: Array[SomeType] = []
for item in json_array:
    if item is SomeType:  # or appropriate type check
        typed_array.append(item)
target.property = typed_array
```

## No Linter Errors
✓ All changes validated


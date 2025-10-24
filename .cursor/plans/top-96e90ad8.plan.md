<!-- 96e90ad8-a375-4588-9bb7-f5f104aa5d5d 2160ff6a-d7fb-40b2-8f62-ba5ced876f1d -->
# Top Bar Resource Readability and Compact Amounts

## Changes

- Update only the top bar resource slots (`scripts/ui/ResourceSlot.gd`).
- Set label text color (acronym + amount) to contrast with the resource background color:
  - White text on dark backgrounds, black text on light backgrounds (luminance threshold 0.5).
- Replace 999+ cap with compact formatting: 1.2k / 3.4m / 5.6b (one decimal, trim trailing .0).

## Files to Edit

- `scripts/ui/ResourceSlot.gd`

## Key Edits

- In `setup(res_id, res_data)`: after setting `color = res_data.color`, compute contrasting text color and override `acronym_label` and `count_label` font colors.
- Add helper:
```gdscript
func get_contrasting_text_color(bg_color: Color) -> Color:
	var luminance = (0.299 * bg_color.r) + (0.587 * bg_color.g) + (0.114 * bg_color.b)
	return Color.BLACK if luminance > 0.5 else Color.WHITE
```

- Add helper (trim trailing .0):
```gdscript
func format_compact_number(n: int) -> String:
	var value := float(n)
	var suffix := ""
	if n >= 1_000_000_000:
		value = value / 1_000_000_000.0
		suffix = "b"
	elif n >= 1_000_000:
		value = value / 1_000_000.0
		suffix = "m"
	elif n >= 1_000:
		value = value / 1_000.0
		suffix = "k"
	var s := ("%.1f" % value) if suffix != "" else str(n)
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return s + suffix
```

- In `update_count(count)`: replace the 999+ logic with `count_label.text = format_compact_number(count)`.

## Notes

- This change applies only to the top bar (slots instantiated by `TopInfoBar.gd`).
- No changes to inventory or other resource UIs.

### To-dos

- [ ] Add contrast-aware text color in ResourceSlot.setup
- [ ] Add format_compact_number helper in ResourceSlot
- [ ] Use compact formatter in ResourceSlot.update_count
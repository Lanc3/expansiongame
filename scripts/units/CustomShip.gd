extends CharacterBody2D
## Runtime-assembled ship from a blueprint layout

var team_id: int = 0
var placements: Array = []
var cell_px: int = 32

func initialize_from_blueprint(data: Dictionary):
    if data.has("placements"):
        placements = data["placements"]
    _build_visuals()

func _build_visuals():
    # Simple per-piece rectangles as children for MVP
    for p in placements:
        var comp = BlueprintDatabase.get_component_by_id(p.id)
        if comp.is_empty():
            continue
        var node = ColorRect.new()
        var color := Color(0.7, 0.7, 1.0, 0.25)
        match comp.category:
            "hull": color = Color(0.8, 0.8, 0.9, 0.25)
            "engine": color = Color(0.9, 0.6, 0.4, 0.35)
            "core": color = Color(0.6, 0.9, 0.6, 0.35)
            "weapon": color = Color(0.9, 0.4, 0.4, 0.35)
            "shield": color = Color(0.6, 0.6, 0.9, 0.35)
        node.color = color
        node.size = Vector2(comp.size.x * cell_px, comp.size.y * cell_px)
        node.position = Vector2(p.x * cell_px, p.y * cell_px)
        add_child(node)




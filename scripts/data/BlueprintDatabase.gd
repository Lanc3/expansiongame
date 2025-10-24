extends Node
## Defines blueprint components available in the builder

# Component schema (Dictionary):
# {
#   id: String,                    # unique id
#   name: String,                  # display name
#   category: String,              # hull | engine | core | weapon | shield | utility
#   tier: int,                     # 0..4
#   size: Vector2i,                # footprint in grid cells
#   anchors: Array[Vector2i],      # relative cells that must contact hull (non-hull components)
#   cost: Dictionary,              # resource_id -> amount
#   research_ids: Array[String],   # research ids that unlock this component
# }

var COMPONENTS: Array = [
    # Hull plates (place anywhere, used for adjacency/structure)
    {
        id = "hull_t1",
        name = "Hull Plate I",
        category = "hull",
        tier = 0,
        size = Vector2i(2, 2),
        anchors = [],
        cost = {0: 20, 9: 10},
        research_ids = ["blueprint_hull_1"],
    },
    {
        id = "hull_t2",
        name = "Hull Plate II",
        category = "hull",
        tier = 1,
        size = Vector2i(2, 2),
        anchors = [],
        cost = {0: 30, 9: 15, 13: 10},
        research_ids = ["blueprint_hull_2"],
    },

    # Engine (exactly one required)
    {
        id = "engine_t1",
        name = "Engine I",
        category = "engine",
        tier = 0,
        size = Vector2i(2, 2),
        anchors = [Vector2i(0, 0)],
        cost = {2: 25, 7: 10},
        research_ids = ["blueprint_energy_1"],
    },
    {
        id = "engine_t2",
        name = "Engine II",
        category = "engine",
        tier = 1,
        size = Vector2i(2, 2),
        anchors = [Vector2i(0, 0)],
        cost = {2: 40, 7: 20, 8: 10},
        research_ids = ["blueprint_energy_2"],
    },

    # Power core (exactly one required)
    {
        id = "core_t1",
        name = "Power Core I",
        category = "core",
        tier = 0,
        size = Vector2i(2, 2),
        anchors = [Vector2i(0, 0)],
        cost = {2: 30, 7: 15},
        research_ids = ["blueprint_energy_1"],
    },
    {
        id = "core_t2",
        name = "Power Core II",
        category = "core",
        tier = 1,
        size = Vector2i(2, 2),
        anchors = [Vector2i(0, 0)],
        cost = {2: 50, 7: 25, 8: 10},
        research_ids = ["blueprint_energy_2"],
    },

    # Weapon hardpoint
    {
        id = "weapon_t1",
        name = "Weapon Mount I",
        category = "weapon",
        tier = 0,
        size = Vector2i(1, 1),
        anchors = [Vector2i(0, 0)],
        cost = {0: 10, 3: 10},
        research_ids = ["blueprint_weapon_1"],
    },
    {
        id = "weapon_t2",
        name = "Weapon Mount II",
        category = "weapon",
        tier = 1,
        size = Vector2i(1, 1),
        anchors = [Vector2i(0, 0)],
        cost = {0: 15, 3: 15, 4: 10},
        research_ids = ["blueprint_weapon_2"],
    },

    # Shield emitter
    {
        id = "shield_t1",
        name = "Shield Emitter I",
        category = "shield",
        tier = 0,
        size = Vector2i(1, 1),
        anchors = [Vector2i(0, 0)],
        cost = {1: 10, 5: 10},
        research_ids = ["blueprint_shield_1"],
    },
    {
        id = "shield_t2",
        name = "Shield Emitter II",
        category = "shield",
        tier = 1,
        size = Vector2i(1, 1),
        anchors = [Vector2i(0, 0)],
        cost = {1: 15, 5: 15, 6: 10},
        research_ids = ["blueprint_shield_2"],
    },
]

func get_all_components() -> Array:
    return COMPONENTS

func get_component_by_id(component_id: String) -> Dictionary:
    for c in COMPONENTS:
        if c.id == component_id:
            return c
    return {}




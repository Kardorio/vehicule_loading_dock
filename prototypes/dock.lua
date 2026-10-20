local C = require("scripts.constants")
local name = C.name
local graphics = "__vehicle-loading-dock__/graphics/"

local function animation(direction)
  local cells = {north = {0, 0}, east = {627, 0}, south = {0, 627}, west = {627, 627}}
  return {
    filename = graphics .. "dock-sheet.png",
    width = 627, height = 627,
    x = cells[direction][1], y = cells[direction][2],
    scale = 256 / 552,
    priority = "high",
  }
end

data:extend({
  {type = "collision-layer", name = "vld-dock"},
  {type = "recipe-category", name = "vld-unused"},
  {
    type = "item-with-tags",
    name = name,
    icon = graphics .. "icon.png",
    icon_size = 1254,
    subgroup = "transport",
    order = "b[personal-transport]-b[vehicle-loading-dock]",
    place_result = name,
    stack_size = 10,
  },
  {
    type = "recipe",
    name = name,
    enabled = false,
    energy_required = 5,
    ingredients = {
      {type = "item", name = "iron-plate", amount = 20},
      {type = "item", name = mods.pypetroleumhandling and "small-parts-01" or "iron-gear-wheel", amount = 20},
      {type = "item", name = mods.pypetroleumhandling and "engine-unit" or "electronic-circuit",
        amount = mods.pypetroleumhandling and 5 or 10},
      {type = "item", name = "iron-chest", amount = 2},
    },
    results = {{type = "item", name = name, amount = 1}},
  },
  {
    type = "assembling-machine",
    name = name,
    icon = graphics .. "icon.png",
    icon_size = 1254,
    flags = {"placeable-neutral", "placeable-player", "player-creation",
      "no-automated-item-insertion", "no-automated-item-removal"},
    minable = {mining_time = 0.5, result = name},
    max_health = 600,
    corpse = "big-remnants",
    dying_explosion = "medium-explosion",
    collision_box = {{-4, -4}, {4, 4}},
    collision_mask = {layers = {["vld-dock"] = true}},
    tile_buildability_rules = {{
      area = {{-4, -4}, {4, 4}},
      required_tiles = {layers = {ground_tile = true}},
      colliding_tiles = {layers = {water_tile = true}},
    }},
    selection_box = {{-4, -4}, {4, 4}},
    selection_priority = 40,
    tile_width = 8,
    tile_height = 8,
    drawing_box_vertical_extension = 0,
    map_color = {r = 0.78, g = 0.57, b = 0.14},
    graphics_set = {
      animation = {filename = "__core__/graphics/empty.png", size = 1},
      working_visualisations = {{
        always_draw = true,
        render_layer = "lower-object",
        north_animation = animation("north"),
        east_animation = animation("east"),
        south_animation = animation("south"),
        west_animation = animation("west"),
      }},
    },
    circuit_wire_max_distance = 9,
    circuit_connector = circuit_connector_definitions.create_vector(universal_connector_template, {
      {variation = 26, main_offset = {-1.5, -3.5}, shadow_offset = {-1.5, -3.5}, show_shadow = true},
      {variation = 26, main_offset = {3.5, -1.5}, shadow_offset = {3.5, -1.5}, show_shadow = true},
      {variation = 26, main_offset = {1.5, 3.5}, shadow_offset = {1.5, 3.5}, show_shadow = true},
      {variation = 26, main_offset = {-3.5, 1.5}, shadow_offset = {-3.5, 1.5}, show_shadow = true},
    }),
    crafting_categories = {"vld-unused"},
    crafting_speed = 1,
    ingredient_count = 0,
    module_slots = 0,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      buffer_capacity = "60kJ",
      input_flow_limit = "60kW",
      drain = C.power_usage_watts .. "W",
    },
    energy_usage = C.power_usage_watts .. "W",
    -- A square crafting machine needs a fluid box to support native rotation.
    fluid_boxes = {{production_type = "input", volume = 1, pipe_connections = {}}},
    fluid_boxes_off_when_no_fluid_recipe = false,
    allow_copy_paste = false,
    show_recipe_icon = false,
    show_recipe_icon_on_map = false,
    allowed_effects = {},
    effect_receiver = {
      uses_module_effects = false,
      uses_beacon_effects = false,
      uses_surface_effects = false,
    },
    open_sound = {filename = "__base__/sound/metallic-chest-open.ogg", volume = 0.5},
    close_sound = {filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.5},
    impact_category = "metal",
  },
  {
    type = "container",
    name = "vld-inventory",
    icon = graphics .. "icon.png",
    icon_size = 1254,
    flags = {
      "placeable-off-grid",
      "not-on-map",
      "not-blueprintable",
      "not-deconstructable",
      "not-rotatable",
      "not-flammable",
      "hide-alt-info",
    },
    max_health = 600,
    collision_box = {{-3.9, -0.4}, {3.9, 0.4}},
    collision_mask = {layers = {object = true, player = true, water_tile = true, is_object = true, is_lower_object = true}},
    selection_box = {{-4, -0.5}, {4, 0.5}},
    selection_priority = 60,
    inventory_size = C.inventory_size,
    quality_affects_inventory_size = false,
    direction_count = 4,
    inventory_type = "with_bar",
    picture = {filename = "__core__/graphics/empty.png", size = 1},
    open_sound = {filename = "__base__/sound/metallic-chest-open.ogg", volume = 0.5},
    close_sound = {filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.5},
    circuit_wire_max_distance = 0,
    draw_circuit_wires = false,
    draw_copper_wires = false,
    allow_copy_paste = false,
    impact_category = "metal",
  },
})

table.insert(data.raw.technology.automobilism.effects, {type = "unlock-recipe", recipe = name})

local output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
output.name = C.circuit_name
output.flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable", "hide-alt-info"}
output.hidden = true
output.selectable_in_game = false
output.minable = nil
output.collision_box = {{0, 0}, {0, 0}}
output.collision_mask = {layers = {}}
output.selection_box = {{0, 0}, {0, 0}}
output.sprites = {filename = "__core__/graphics/empty.png", size = 1}
output.activity_led_sprites = nil
output.activity_led_light = nil
output.draw_circuit_wires = false
output.draw_copper_wires = false
output.allow_copy_paste = false
output.fast_replaceable_group = nil
output.water_reflection = nil
output.corpse = nil
output.dying_explosion = nil

data:extend({output, {
  type = "virtual-signal",
  name = C.parked_signal,
  icon = "__base__/graphics/icons/car.png",
  icon_size = 64,
  subgroup = "virtual-signal-special",
  order = "z[vehicle-loading-dock]",
}})

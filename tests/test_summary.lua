local additions = 0
local function element(spec, parent)
  local e = {valid = true, style = {}, children = {}}
  for k, v in pairs(spec or {}) do if k ~= 'style' then e[k] = v end end
  e.add = function(s)
    additions = additions + 1
    local child = element(s, e)
    e.children[#e.children + 1] = child
    if child.name then e[child.name] = child end
    return child
  end
  e.destroy = function()
    e.valid = false
    if parent and e.name then parent[e.name] = nil end
  end
  return e
end

local reads = 0
local function inventory(size, contents, slots)
  local inv = {valid = true}
  for i = 1, size do inv[i] = {valid_for_read = i <= slots} end
  inv.get_contents = function() reads = reads + 1; return contents end
  return inv
end
defines = {controllers = {character = 1, remote = 2, editor = 3},
  direction = {north = 0, east = 4, south = 8, west = 12},
  inventory = {car_trunk = 1, spider_trunk = 2, chest = 3}}
local force, other_force = {}, {}
local dock_entity
local surface = {find_entities_filtered = function(filter)
  assert(filter.name == 'vehicle-loading-dock' and filter.area and filter.force == force)
  return {dock_entity}
end}
local vehicle_contents = {{name = 'iron-plate', quality = 'rare', count = 3},
  {name = 'coal', quality = 'normal', count = 7},
  {name = 'iron-plate', quality = 'normal', count = 100},
  {name = 'iron-plate', quality = 'rare', count = 5}}
local trunk = inventory(80, vehicle_contents, 5)
local buffer = inventory(100, {}, 0)
local vehicle = {valid = true, type = 'car', force = force, surface = surface, speed = 0,
  bounding_box = {left_top = {x = -2, y = -2}, right_bottom = {x = 1, y = 1}},
  get_inventory = function() return trunk end}
dock_entity = {valid = true, unit_number = 7, position = {x = 0, y = 0},
  direction = defines.direction.east, force = force, surface = surface}
local chest = {valid = true, force = force, surface = surface,
  get_inventory = function() return buffer end}
local dock = {entity = dock_entity, inventory_entity = chest}
local function make_player(index)
  return {index = index, valid = true, connected = true, controller_type = defines.controllers.character,
    vehicle = vehicle, force = force, surface = surface, display_resolution = {width = 1920, height = 1080},
    display_scale = 1, gui = {left = element()}, opened = 'unchanged'}
end
local player, second = make_player(1), make_player(2)
local players = {player, second}
storage = {docks = {[7] = dock}}
game = {connected_players = players, get_player = function(index) return players[index] end}
local Summary = require('scripts.summary')
local function frame(p) return p.gui.left.vld_vehicle_summary end

-- 003-AC1/003-AC2/003-AC3: automatic, independent, read-only inventory summaries.
Summary.initialize()
assert(frame(player) and frame(second) and player.opened == 'unchanged')
local initial = frame(player)
local grid = initial.vehicle.contents.stock_grid
assert(#grid.children == 3 and grid.item_1.sprite == 'item/coal' and grid.item_1.number == 7)
assert(grid.item_2.quality == 'normal' and grid.item_2.number == 100)
assert(grid.item_3.quality == 'rare' and grid.item_3.number == 8)
assert(grid.item_3.elem_tooltip.quality == 'rare')
assert(initial.vehicle.children[2].caption[2] == 5 and initial.vehicle.children[2].caption[3] == 80)
assert(initial.dock.empty.caption[1] == 'vld.summary-empty')
local count = additions
Summary.refresh_all()
assert(frame(player) == initial and additions == count)
vehicle_contents[1].count = 9
Summary.refresh_all()
assert(frame(player) ~= initial and frame(player).vehicle.contents.stock_grid.item_3.number == 14)
local before = reads
vehicle.speed = 0.1
Summary.on_tick()
assert(frame(player) and reads == before)
-- 003-AC4/003-AC5: leaving control immediately closes only this player's panel.
player.vehicle = nil
Summary.on_player_changed {player_index = 1}
assert(not frame(player) and frame(second) and not storage.vehicle_summaries[1])
player.vehicle = vehicle
Summary.on_player_changed {player_index = 1}
assert(frame(player))
player.controller_type = defines.controllers.remote
player.physical_vehicle = vehicle
player.vehicle = nil
player.spidertron_remote_selection = {vehicle}
Summary.on_player_changed {player_index = 1}
assert(not frame(player))
player.vehicle = vehicle
Summary.on_player_changed {player_index = 1}
assert(frame(player))
local remote_vehicle = {valid = true, type = 'spider-vehicle', force = force, surface = surface,
  speed = 0, bounding_box = {left_top = {x = -1, y = -1}, right_bottom = {x = 0, y = 0}},
  get_inventory = function() return inventory(80, {{name = 'coal', quality = 'rare', count = 23}}, 1) end}
player.vehicle = remote_vehicle
Summary.on_player_changed {player_index = 1}
assert(storage.vehicle_summaries[1].vehicle == remote_vehicle)
assert(frame(player).vehicle.contents.stock_grid.item_1.number == 23)
player.vehicle = nil
Summary.on_tick()
assert(not frame(player) and frame(second))
player.vehicle = vehicle
Summary.on_player_changed {player_index = 1}
vehicle.bounding_box.right_bottom.x = 3.1
before = reads
Summary.on_tick()
assert(not frame(player) and not frame(second) and reads == before)
vehicle.bounding_box.right_bottom.x = 1
Summary.refresh_all()
assert(frame(player) and frame(second))
player.force = other_force
Summary.on_tick()
assert(not frame(player) and frame(second))
player.force = force
Summary.refresh_all()
player.controller_type = defines.controllers.editor
Summary.on_tick()
assert(not frame(player) and frame(second))
player.controller_type = defines.controllers.remote
Summary.refresh_all()
player.surface = {}
Summary.on_tick()
assert(not frame(player) and frame(second))
player.surface = surface
Summary.refresh_all()
chest.force = other_force
Summary.on_tick()
assert(not frame(player) and not frame(second))
chest.force = force
Summary.refresh_all()
player.gui.left.vld_vehicle_summary.destroy()
Summary.refresh_all()
assert(frame(player) and frame(player).valid)
second.connected = false
Summary.on_tick()
assert(not frame(second) and frame(player))
vehicle.valid = false
Summary.on_tick()
assert(not frame(player))
vehicle.valid = true
Summary.refresh_all()
Summary.close_for_dock(7)
assert(not frame(player) and not next(storage.vehicle_summaries))
Summary.refresh_all()
dock_entity.valid = false
Summary.on_tick()
assert(not frame(player))
print('PASS 003 résumé : stocks, qualités, conduite distante, fermeture et isolation des joueurs')

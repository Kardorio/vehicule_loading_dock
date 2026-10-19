local C = require("scripts.constants")
local Geometry = require("scripts.geometry")
local Detection = require("scripts.detection")
local Summary = {}
local frame_name = "vld_vehicle_summary"
local layout_version = 2

local function active_vehicle(player)
  if not player or not player.valid or not player.connected then return nil end
  if player.controller_type ~= defines.controllers.character
    and player.controller_type ~= defines.controllers.remote then return nil end
  local vehicle = player.vehicle
  if not vehicle or not vehicle.valid or vehicle.force ~= player.force
    or vehicle.surface ~= player.surface or not Detection.is_supported_vehicle(vehicle) then return nil end
  return vehicle
end

local function eligible_dock(player, vehicle, dock)
  return dock and dock.entity.valid and dock.inventory_entity.valid
    and dock.entity.force == player.force and dock.entity.surface == vehicle.surface
    and dock.inventory_entity.force == player.force and dock.inventory_entity.surface == vehicle.surface
    and Detection.is_fully_inside_area(vehicle, Geometry.get_vehicle_area(dock.entity))
end

local function find_dock(player, vehicle)
  local selected
  for _, entity in pairs(vehicle.surface.find_entities_filtered {
    name = C.name, area = vehicle.bounding_box, force = player.force,
  }) do
    local dock = storage.docks and storage.docks[entity.unit_number]
    if eligible_dock(player, vehicle, dock) and (not selected or entity.unit_number < selected) then
      selected = entity.unit_number
    end
  end
  return selected
end

local function snapshot(inventory)
  local occupied, grouped = 0, {}
  for i = 1, #inventory do
    if inventory[i].valid_for_read then occupied = occupied + 1 end
  end
  for _, stack in pairs(inventory.get_contents()) do
    local quality = stack.quality or "normal"
    local key = stack.name .. "/" .. quality
    if not grouped[key] then grouped[key] = {name = stack.name, quality = quality, count = 0} end
    grouped[key].count = grouped[key].count + stack.count
  end
  local items = {}
  for _, item in pairs(grouped) do items[#items + 1] = item end
  table.sort(items, function(a, b)
    if a.name == b.name then return a.quality < b.quality end
    return a.name < b.name
  end)
  local signature = {tostring(occupied), tostring(#inventory)}
  for _, item in ipairs(items) do
    signature[#signature + 1] = item.name .. "/" .. item.quality .. ":" .. item.count
  end
  return {items = items, occupied = occupied, size = #inventory}, table.concat(signature, "|")
end

function Summary.close(player)
  if player and player.valid then
    local frame = player.gui.left[frame_name]
    if frame then frame.destroy() end
  end
  if player and storage.vehicle_summaries then storage.vehicle_summaries[player.index] = nil end
end

local function add_inventory(frame, name, stock, maximum_height)
  local section = frame.add {type = "flow", name = name, direction = "vertical"}
  section.style.vertical_spacing = 6
  section.add {type = "label", caption = {"vld.summary-" .. name}, style = "heading_2_label"}
  section.add {type = "label", caption = {"vld.summary-slots", stock.occupied, stock.size}}
  if #stock.items == 0 then
    section.add {type = "label", name = "empty", caption = {"vld.summary-empty"}}
    return
  end
  local scroll = section.add {type = "scroll-pane", name = "contents",
    horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
  scroll.style.maximal_height = maximum_height
  scroll.style.minimal_width = 258
  local grid = scroll.add {type = "table", name = "stock_grid", column_count = 6}
  grid.style.horizontal_spacing = 2
  grid.style.vertical_spacing = 2
  for i, item in ipairs(stock.items) do
    local button = grid.add {type = "sprite-button", name = "item_" .. i,
      style = "slot_button", sprite = "item/" .. item.name, number = item.count}
    button.quality = item.quality
    button.elem_tooltip = {type = "item", name = item.name, quality = item.quality}
  end
end

local function refresh(player)
  local vehicle = active_vehicle(player)
  local id = vehicle and find_dock(player, vehicle)
  if not id then Summary.close(player); return end
  local dock = storage.docks[id]
  local vehicle_stock, vehicle_signature = snapshot(Detection.get_inventory(vehicle))
  local dock_stock, dock_signature = snapshot(dock.inventory_entity.get_inventory(defines.inventory.chest))
  local resolution = player.display_resolution
  local height = math.max(40, math.min(450, math.floor((resolution.height / player.display_scale - 300) / 2)))
  local signature = layout_version .. "||" .. vehicle_signature .. "||" .. dock_signature .. "||" .. height
  local previous = storage.vehicle_summaries[player.index]
  if previous and previous.vehicle == vehicle and previous.dock_id == id
    and previous.signature == signature and player.gui.left[frame_name] then return end
  Summary.close(player)
  local frame = player.gui.left.add {type = "frame", name = frame_name,
    direction = "vertical", caption = {"vld.summary-title"}}
  frame.style.width = 300
  frame.style.padding = 12
  add_inventory(frame, "vehicle", vehicle_stock, height)
  frame.add {type = "line"}
  add_inventory(frame, "dock", dock_stock, height)
  storage.vehicle_summaries[player.index] = {vehicle = vehicle, dock_id = id, signature = signature}
end

function Summary.refresh_all()
  storage.vehicle_summaries = storage.vehicle_summaries or {}
  for _, player in pairs(game.connected_players) do refresh(player) end
end

function Summary.on_tick()
  for index, state in pairs(storage.vehicle_summaries or {}) do
    local player = game.get_player(index)
    local vehicle = active_vehicle(player)
    if not vehicle or vehicle ~= state.vehicle
      or not eligible_dock(player, vehicle, storage.docks and storage.docks[state.dock_id]) then
      if player then Summary.close(player) else storage.vehicle_summaries[index] = nil end
    end
  end
end

function Summary.on_player_changed(event)
  storage.vehicle_summaries = storage.vehicle_summaries or {}
  local player = game.get_player(event.player_index)
  if player then refresh(player) end
end

function Summary.close_for_dock(id)
  for index, state in pairs(storage.vehicle_summaries or {}) do
    if state.dock_id == id then
      local player = game.get_player(index)
      if player then Summary.close(player) else storage.vehicle_summaries[index] = nil end
    end
  end
end

function Summary.initialize()
  storage.vehicle_summaries = storage.vehicle_summaries or {}
  Summary.on_tick()
  Summary.refresh_all()
end

return Summary

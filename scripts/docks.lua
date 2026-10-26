local C = require("scripts.constants")
local Geometry = require("scripts.geometry")
local Detection = require("scripts.detection")
local Transfer = require("scripts.transfer")
local Configuration = require("scripts.configuration")
local Gui = require("scripts.gui")
local Power = require("scripts.power")
local Inventory = require("scripts.inventory")
local Indicator = require("scripts.indicator")
local Summary = require("scripts.summary")
local Circuit = require("scripts.circuit")
local Docks = {}

local function initialize_storage()
  storage.docks = storage.docks or {}
  storage.inventory_owners = storage.inventory_owners or {}
  storage.destroy_registrations = storage.destroy_registrations or {}
  storage.open_docks = storage.open_docks or {}
end

local function spill(surface, position, stack)
  surface.spill_item_stack {position = position, stack = stack,
    enable_looted = true, allow_belts = false, use_start_position_on_failure = true}
end

local function empty_inventory(entity, buffer)
  local inventory = entity.get_inventory(defines.inventory.chest)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read then
      if buffer then
        local inserted = buffer.insert(stack)
        stack.count = stack.count - inserted
      end
      if stack.valid_for_read then
        spill(entity.surface, entity.position, stack)
        stack.clear()
      end
    end
  end
end

local function create_inventory(entity)
  local position = Geometry.get_dock_position(entity)
  if not entity.surface.can_place_entity {name = C.inventory_name, position = position,
    direction = entity.direction, force = entity.force} then return nil end
  local child = entity.surface.create_entity {name = C.inventory_name, position = position,
    direction = entity.direction, force = entity.force, quality = entity.quality,
    create_build_effect_smoke = false}
  if child then
    child.destructible = false
    child.minable_flag = false
    child.rotatable = false
  end
  return child
end

local function remember(dock)
  dock.position = {x = dock.entity.position.x, y = dock.entity.position.y}
  dock.direction = dock.entity.direction
  storage.inventory_owners[dock.inventory_entity.unit_number] = dock.entity.unit_number
end

local function tags_from_event(event)
  return event.tags and event.tags.vld
end

local function refund(entity, event)
  local temporary = game.create_inventory(1)
  temporary[1].set_stack {name = C.name, count = 1, quality = entity.quality.name}
  local destination
  if event.player_index then destination = game.get_player(event.player_index).get_main_inventory()
  elseif event.robot and event.robot.valid then destination = event.robot.get_inventory(defines.inventory.robot_cargo) end
  local inserted = destination and destination.insert(temporary[1]) or 0
  temporary[1].count = temporary[1].count - inserted
  if temporary[1].valid_for_read then spill(entity.surface, entity.position, temporary[1]) end
  temporary.destroy()
end

function Docks.register(entity, configuration, event, existing_inventory)
  if not entity or not entity.valid or entity.name ~= C.name then return nil end
  initialize_storage()
  if storage.docks[entity.unit_number] then return storage.docks[entity.unit_number] end
  configuration = Configuration.normalize(configuration)
  local child = existing_inventory or create_inventory(entity)
  if child then
    child.destructible = false
    child.minable_flag = false
    child.rotatable = false
  end
  if not child then
    if event then refund(entity, event) end
    if event and event.player_index then game.get_player(event.player_index).create_local_flying_text {
      text = {"vld.blocked"}, position = entity.position} end
    entity.destroy()
    return nil
  end
  local dock = {entity = entity, inventory_entity = child, configuration = configuration,
    inventory_size = #child.get_inventory(defines.inventory.chest),
    status = Power.is_powered(entity) and "waiting" or "no-power"}
  storage.docks[entity.unit_number] = dock
  dock.registration = script.register_on_object_destroyed(entity)
  storage.destroy_registrations[dock.registration] = entity.unit_number
  remember(dock)
  Inventory.ensure_capacity(dock)
  Indicator.update(dock)
  Circuit.update(dock, Detection.find_candidate_vehicle(entity))
  return dock
end

function Docks.on_built(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == C.name then
    local tags = tags_from_event(event)
    local dock = Docks.register(entity, tags, event)
    if dock and type(tags) == 'table' then
      Inventory.apply(dock.inventory_entity.get_inventory(defines.inventory.chest), tags.inventory)
    end
  end
end

function Docks.remove(id, buffer)
  local dock = storage.docks[id]
  if not dock then return end
  Summary.close_for_dock(id)
  for player_index, opened_id in pairs(storage.open_docks) do
    if opened_id == id then
      local player = game.get_player(player_index)
      if player then Gui.close(player) end
    end
  end
  Circuit.destroy(dock)
  Indicator.destroy(dock)
  local child = dock.inventory_entity
  if child and child.valid then
    empty_inventory(child, buffer)
    storage.inventory_owners[child.unit_number] = nil
    child.destroy()
  end
  storage.destroy_registrations[dock.registration] = nil
  storage.docks[id] = nil
end

function Docks.on_mined(event)
  local entity = event.entity
  if entity.name ~= C.name then return end
  local dock = storage.docks[entity.unit_number]
  if not dock then return end
  Docks.remove(entity.unit_number, event.buffer)
end

function Docks.on_removed(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == C.name then Docks.remove(entity.unit_number) end
end

function Docks.on_destroyed(event)
  local id = storage.destroy_registrations[event.registration_number]
  if id then Docks.remove(id) end
end

function Docks.sync(dock)
  Inventory.ensure_capacity(dock)
  local entity, old = dock.entity, dock.inventory_entity
  if old and old.valid and entity.position.x == dock.position.x
    and entity.position.y == dock.position.y and entity.direction == dock.direction then
    old.force = entity.force
    return true
  end
  local inventory, temporary, settings
  if old and old.valid then
    inventory = old.get_inventory(defines.inventory.chest)
    temporary = game.create_inventory(#inventory)
    settings = Inventory.serialize(inventory)
    for i = 1, #inventory do temporary[i].swap_stack(inventory[i]) end
    storage.inventory_owners[old.unit_number] = nil
    old.destroy()
  end
  local child = create_inventory(entity)
  local accepted = child ~= nil
  if not accepted then
    entity.direction = dock.direction
    entity.teleport(dock.position)
    child = create_inventory(entity)
  end
  if not child then
    if temporary then
      entity.surface.spill_inventory {position = dock.position, inventory = temporary,
        enable_looted = true, allow_belts = false, use_start_position_on_failure = true}
      temporary.destroy()
    end
    Docks.remove(entity.unit_number)
    entity.destroy()
    return false
  end
  dock.inventory_entity = child
  if temporary then
    inventory = child.get_inventory(defines.inventory.chest)
    for i = 1, #temporary do inventory[i].swap_stack(temporary[i]) end
    Inventory.apply(inventory, settings)
    temporary.destroy()
  end
  remember(dock)
  dock.current_vehicle = nil
  dock.status = Power.is_powered(entity) and "waiting" or "no-power"
  Indicator.update(dock)
  Circuit.update(dock, Detection.find_candidate_vehicle(entity))
  local viewers = {}
  for player_index, id in pairs(storage.open_docks) do
    if id == entity.unit_number then viewers[#viewers + 1] = player_index end
  end
  for _, player_index in ipairs(viewers) do Gui.open(game.get_player(player_index), dock) end
  return accepted
end

function Docks.on_rotated(event)
  local entity = event.entity
  local dock = entity.valid and entity.name == C.name and storage.docks[entity.unit_number]
  if dock and not Docks.sync(dock) and event.player_index then
    game.get_player(event.player_index).create_local_flying_text {text = {"vld.blocked"}, position = entity.position}
  end
end

function Docks.tick()
  for id, dock in pairs(storage.docks) do
    if not dock.entity.valid then
      Docks.remove(id)
    elseif Docks.sync(dock) and dock.inventory_entity.valid then
      local vehicle, status = Detection.find_candidate_vehicle(dock.entity)
      local powered = Power.is_powered(dock.entity)
      dock.current_vehicle = powered and vehicle or nil
      dock.status = powered and status or "no-power"
      if powered and vehicle then
        Transfer.run(dock.inventory_entity.get_inventory(defines.inventory.chest),
          Detection.get_inventory(vehicle), dock.configuration)
      end
      Circuit.update(dock, vehicle)
      Indicator.update(dock)
      Gui.refresh(dock)
    end
  end
end

function Docks.on_blueprint(event)
  local blueprint = event.record or event.stack
  if not blueprint then return end
  for index, entity in pairs(event.mapping.get()) do
    if entity.valid and entity.name == C.name then
      local dock = storage.docks[entity.unit_number]
      if dock then
        local settings = Configuration.serialize(dock.configuration)
        settings.inventory = Inventory.serialize(dock.inventory_entity.get_inventory(defines.inventory.chest))
        blueprint.set_blueprint_entity_tags(index, {vld = settings})
      end
    end
  end
end

local function matching_inventory(entity)
  for _, child in pairs(entity.surface.find_entities_filtered {
    name = C.inventory_name, position = Geometry.get_dock_position(entity), radius = 0.01,
    force = entity.force,
  }) do
    if not storage.inventory_owners[child.unit_number] and child.direction == entity.direction then return child end
  end
end

function Docks.on_cloned(event)
  local source, target = event.source, event.destination
  if not source.valid or not target.valid then return end
  if target.name == C.circuit_name then
    target.destroy()
  elseif source.name == C.inventory_name then
    if storage.inventory_owners[target.unit_number] then return end
    local source_id = storage.inventory_owners[source.unit_number]
    local source_dock = source_id and storage.docks[source_id]
    for _, main in pairs(target.surface.find_entities_filtered {name = C.name,
      area = {{target.position.x - 4, target.position.y - 4},
        {target.position.x + 4, target.position.y + 4}}, force = target.force}) do
      local position = Geometry.get_dock_position(main)
      if not storage.docks[main.unit_number] and position.x == target.position.x and position.y == target.position.y
        and main.direction == target.direction then
        if source_dock then
          Inventory.ensure_capacity(source_dock)
          Inventory.apply(target.get_inventory(defines.inventory.chest),
            Inventory.serialize(source_dock.inventory_entity.get_inventory(defines.inventory.chest)))
        end
        Docks.register(main, source_dock and source_dock.configuration, nil, target)
        return
      end
    end
    target.destroy()
  elseif target.name == C.name then
    local original = storage.docks[source.unit_number]
    if original then Inventory.ensure_capacity(original) end
    local adopted = matching_inventory(target)
    local destination = Docks.register(target, original and original.configuration, nil, adopted)
    if original and destination then
      destination.configuration = Configuration.serialize(original.configuration)
      if not adopted and original.inventory_entity.valid then
        local from = original.inventory_entity.get_inventory(defines.inventory.chest)
        local to = destination.inventory_entity.get_inventory(defines.inventory.chest)
        for i = 1, #from do to[i].set_stack(from[i]) end
      end
      if original.inventory_entity.valid then
        Inventory.apply(destination.inventory_entity.get_inventory(defines.inventory.chest),
          Inventory.serialize(original.inventory_entity.get_inventory(defines.inventory.chest)))
      end
    end
  end
end

function Docks.initialize()
  initialize_storage()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered {name = C.name}) do
      if not storage.docks[entity.unit_number] then Docks.register(entity) end
    end
  end
  for _, dock in pairs(storage.docks) do
    if dock.entity.valid then
      dock.configuration = Configuration.normalize(dock.configuration)
      Docks.sync(dock)
      dock.status = Power.is_powered(dock.entity) and "waiting" or "no-power"
      dock.current_vehicle = nil
      Indicator.update(dock)
      Circuit.update(dock, Detection.find_candidate_vehicle(dock.entity))
      Gui.refresh(dock, true)
    end
  end
end

return Docks

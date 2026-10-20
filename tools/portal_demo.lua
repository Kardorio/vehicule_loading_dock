local demo_detection = require('scripts.detection')
local demo_geometry = require('scripts.geometry')
local demo = {phase = 'prepare', frame = 0}
local left = {x = -9, y = -3}
local right = {x = 9, y = -3}

local function replace_coal(surface)
  for _, entity in pairs(surface.find_entities_filtered {type = {
    'infinity-container', 'container', 'logistic-container', 'inserter',
    'transport-belt', 'underground-belt', 'splitter', 'loader', 'loader-1x1',
  }}) do
    if entity.type == 'infinity-container' then
      for _, filter in pairs(entity.infinity_container_filters) do
        if filter.name == 'coal' then
          filter.name = 'uranium-ore'
          entity.set_infinity_container_filter(filter.index, filter)
        end
      end
    end
    local inventory = entity.get_inventory(defines.inventory.chest)
    if inventory then
      for i = 1, #inventory do
        if inventory[i].valid_for_read and inventory[i].name == 'coal' then
          inventory[i].set_stack {name = 'uranium-ore', count = inventory[i].count}
        end
      end
    end
    if entity.type == 'inserter' then
      if entity.held_stack.valid_for_read and entity.held_stack.name == 'coal' then
        entity.held_stack.set_stack {name = 'uranium-ore', count = entity.held_stack.count}
      end
      for i = 1, entity.filter_slot_count do
        local filter = entity.get_filter(i)
        if type(filter) == 'table' and filter.name == 'coal' then
          filter.name = 'uranium-ore'
          entity.set_filter(i, filter)
        elseif filter == 'coal' then entity.set_filter(i, 'uranium-ore') end
      end
    end
    if entity.type == 'transport-belt' or entity.type == 'underground-belt' or entity.type == 'splitter' then
      for index = 1, entity.get_max_transport_line_index() do
        local line = entity.get_transport_line(index)
        local items = {}
        for _, item in pairs(line.get_detailed_contents()) do
          if item.stack.name == 'coal' then
            items[#items + 1] = {position = item.position, count = item.stack.count}
          end
        end
        if #items > 0 then
          line.remove_item {name = 'coal', count = 1000000}
          for _, item in ipairs(items) do
            assert(line.insert_at(item.position, {name = 'uranium-ore', count = item.count}))
          end
        end
      end
    end
  end
end

local function station(dock, area)
  local result = {dock = dock, unload = dock.configuration.unload_filters[1], belts = {}, inserters = {}}
  for _, entity in pairs(demo.surface.find_entities_filtered {area = area}) do
    if entity.type == 'inserter' then result.inserters[#result.inserters + 1] = entity end
    if entity.type == 'transport-belt' or entity.type == 'underground-belt'
      or entity.type == 'splitter' or entity.type == 'loader' or entity.type == 'loader-1x1' then
      for index = 1, entity.get_max_transport_line_index() do
        result.belts[#result.belts + 1] = entity.get_transport_line(index)
      end
    end
  end
  return result
end

local function remaining(station_state)
  local count = station_state.dock.inventory_entity.get_inventory(defines.inventory.chest).get_item_count(station_state.unload)
  for _, line in ipairs(station_state.belts) do
    for _, item in pairs(line.get_contents()) do
      if item.name == station_state.unload then count = count + item.count end
    end
  end
  for _, inserter in ipairs(station_state.inserters) do
    if inserter.held_stack.valid_for_read and inserter.held_stack.name == station_state.unload then
      count = count + inserter.held_stack.count
    end
  end
  if demo_detection.is_fully_inside_area(demo.car, demo_geometry.get_vehicle_area(station_state.dock.entity)) then
    count = count + demo.car.get_inventory(defines.inventory.car_trunk).get_item_count(station_state.unload)
  end
  return count
end

local function hold(phase, tick)
  demo.phase = phase
  demo.arrival = tick
  demo.empty_since = nil
end

local function drained(station_state, tick)
  assert(tick - demo.arrival < 3600, 'Unloading did not drain within sixty seconds')
  local count = remaining(station_state)
  if count > 0 then demo.empty_since = nil
  elseif not demo.empty_since then
    demo.empty_since = tick
    log('VLD DEMO ' .. demo.phase .. ' output empty at ' .. tick)
  end
  return demo.empty_since and tick - demo.empty_since >= 90
end

local function prepare(player, tick)
  Docks.initialize()
  local original = player.surface
  local surface = game.create_surface('vld-portal-demo', {peaceful_mode = true})
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities()) do entity.destroy() end
  local tiles = {}
  for x = -24, 24 do for y = -85, 85 do
    tiles[#tiles + 1] = {name = 'refined-concrete', position = {x, y}}
  end end
  surface.set_tiles(tiles)
  original.clone_area {source_area = {{-31, -80}, {-17, 80}}, destination_area = {{-16, -80}, {-2, 80}},
    destination_surface = surface, clone_entities = true, clone_tiles = false, clone_decoratives = false}
  original.clone_area {source_area = {{27, -80}, {42, 80}}, destination_area = {{2, -80}, {17, 80}},
    destination_surface = surface, clone_entities = true, clone_tiles = false, clone_decoratives = false}
  player.driving = false
  player.teleport(left, surface)
  for _, pole in pairs(surface.find_entities_filtered {type = 'electric-pole'}) do
    local generator = surface.create_entity {name = 'electric-energy-interface',
      position = {pole.position.x + .5, pole.position.y + .5}, force = 'player'}
    generator.electric_buffer_size = 100000000
    generator.power_production = 1000000
    generator.energy = 100000000
  end
  demo.surface = surface
  demo.car = assert(surface.find_entities_filtered {name = 'car'}[1])
  demo.car.speed = 0
  demo.car.teleport(left)
  demo.car.orientation = .25
  for _, entity in pairs(surface.find_entities_filtered {type = 'character'}) do
    if entity ~= player.character then entity.destroy() end
  end
  demo.car.set_driver(player)
  demo.car.get_fuel_inventory().insert {name = 'rocket-fuel', count = 20}
  local trunk = demo.car.get_inventory(defines.inventory.car_trunk)
  trunk.clear()
  for i = 1, #trunk do trunk.set_filter(i, 'wood') end
  trunk.set_filter(1, 'iron-plate')
  trunk.set_filter(2, 'uranium-ore')
  surface.daytime = 0
  surface.freeze_daytime = true
  surface.destroy_decoratives {}
  rendering.draw_sprite {sprite = 'utility/white_square', surface = surface, target = {0, -3},
    x_scale = 1000, y_scale = 1000, tint = {r = 1, g = 0, b = 1, a = 1}, render_layer = 'ground-layer-1'}
  replace_coal(surface)
  for _, dock in pairs(storage.docks) do
    if dock.entity.surface == surface then
      for _, filters in pairs {dock.configuration.load_filters, dock.configuration.unload_filters} do
        for i, name in pairs(filters) do if name == 'coal' then filters[i] = 'uranium-ore' end end
      end
      local inventory = dock.inventory_entity.get_inventory(defines.inventory.chest)
      inventory.clear()
      inventory.insert {name = dock.configuration.load_filters[1], count = 100}
      if dock.entity.position.x < 0 then demo.left = station(dock, {{-16, -80}, {-2, 80}})
      else demo.right = station(dock, {{2, -80}, {17, 80}}) end
    end
  end
  assert(demo.left and demo.right)
  for _, stop in ipairs {demo.left, demo.right} do
    for _, line in ipairs(stop.belts) do line.remove_item {name = stop.unload, count = 1000000} end
    for _, inserter in ipairs(stop.inserters) do
      if inserter.held_stack.valid_for_read and inserter.held_stack.name == stop.unload then inserter.held_stack.clear() end
    end
  end
  demo.start = tick + 60
  demo.phase = 'warmup'
end

script.on_event(defines.events.on_tick, function(event)
  if demo.phase == 'finished' then return end
  local player = game.get_player(1)
  if not player or not player.connected then return end
  local tick = event.tick
  if demo.phase == 'prepare' then prepare(player, tick); return end
  if tick < demo.start then return end
  if demo.phase == 'warmup' then
    local trunk = demo.car.get_inventory(defines.inventory.car_trunk)
    trunk.clear()
    trunk.insert {name = 'uranium-ore', count = 50}
    hold('left', tick)
  elseif demo.phase == 'left' and drained(demo.left, tick) then
    assert(remaining(demo.left) == 0)
    log('VLD DEMO departure left: output empty')
    demo.car.orientation = .25
    demo.phase = 'east'
  elseif demo.phase == 'east' then
    demo.car.orientation = .25
    demo.car.speed = .20
    if demo.car.position.x >= right.x then
      demo.car.speed = 0
      demo.car.teleport(right)
      hold('right', tick)
    end
  elseif demo.phase == 'right' and drained(demo.right, tick) then
    assert(remaining(demo.right) == 0)
    log('VLD DEMO departure right: output empty')
    demo.car.orientation = .75
    demo.phase = 'west'
  elseif demo.phase == 'west' then
    demo.car.orientation = .75
    demo.car.speed = .20
    if demo.car.position.x <= left.x then
      demo.car.speed = 0
      demo.car.teleport(left)
      hold('return', tick)
    end
  elseif demo.phase == 'return' and drained(demo.left, tick) then
    assert(remaining(demo.left) == 0)
    demo.phase = 'finished'
    helpers.write_file('demo-complete.json', helpers.table_to_json {frames = demo.frame,
      ticks = tick - demo.start, left_remaining = remaining(demo.left), right_remaining = remaining(demo.right)}, false)
    log('VLD DEMO finished: both unloading belts empty')
    return
  end
  if (tick - demo.start) % 6 == 0 then
    game.take_screenshot {player = player, surface = demo.surface, position = {0, -3},
      resolution = {1200, 960}, zoom = 1, path = string.format('frames/frame-%04d.png', demo.frame),
      show_gui = false, show_entity_info = false, force_render = true, hide_clouds = true, hide_fog = true, daytime = 0}
    demo.frame = demo.frame + 1
  end
end)

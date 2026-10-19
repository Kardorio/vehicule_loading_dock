local production_tick = script.get_event_handler(defines.events.on_tick)

local function summary_check(condition, message)
  assert(condition, 'VLD SUMMARY: ' .. message)
  log('VLD SUMMARY PASS ' .. message)
end

local function summary_frame(player)
  return player.gui.left.vld_vehicle_summary
end

script.on_init(function()
  Docks.initialize()
  Summary.initialize()
  if remote.interfaces.freeplay then
    remote.call('freeplay', 'set_skip_intro', true)
    remote.call('freeplay', 'set_disable_crashsite', true)
  end
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0, 0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area = {{-32, -32}, {32, 32}}}) do
    if entity.type ~= 'character' then entity.destroy() end
  end
  local tiles = {}
  for x = -32, 32 do for y = -32, 32 do
    tiles[#tiles + 1] = {name = 'refined-concrete', position = {x, y}}
  end end
  surface.set_tiles(tiles)
  surface.daytime = 0
  surface.freeze_daytime = true
end)

script.on_event(defines.events.on_tick, function(event)
  production_tick(event)
  if storage.summary_finished or event.tick < 30 then return end
  local player = game.get_player(1)
  if not player or not player.connected then return end
  if player.controller_type == defines.controllers.cutscene then player.exit_cutscene() end
  local surface = game.surfaces.nauvis
  local state = storage.summary_stage or 0
  if state == 0 then
    player.teleport({0, 7}, surface)
    surface.create_entity{name='substation',position={8,0},force='player'}
    surface.create_entity{name='substation',position={24,0},force='player'}
    local generator = surface.create_entity{name='electric-energy-interface',position={24,4},force='player'}
    generator.electric_buffer_size = 100000000
    generator.power_production = 1000000
    generator.energy = 100000000
    local entity = surface.create_entity{name='vehicle-loading-dock',position={0,0},
      direction=defines.direction.east,force='player',raise_built=true}
    storage.summary_dock = entity
    storage.summary_car = surface.create_entity{name='car',position={-1,0},force='player'}
    local chest = storage.docks[entity.unit_number].inventory_entity.get_inventory(defines.inventory.chest)
    chest.insert{name='iron-plate',count=175,quality='normal'}
    chest.insert{name='steel-plate',count=32,quality='normal'}
    storage.summary_car.get_inventory(defines.inventory.car_trunk).insert{name='copper-plate',count=125,quality='normal'}
    storage.summary_car.set_driver(player)
    summary_check(player.vehicle == storage.summary_car, 'actual character driver occupies the parked car')
    summary_check(summary_frame(player), 'sidebar opens for the actual driver')
    local frame = summary_frame(player)
    summary_check(frame.vehicle.contents.stock_grid.item_1.number == 125,
      'vehicle quantities are grouped across native stacks')
    summary_check(frame.dock.contents.stock_grid.item_1.number == 175
      and frame.dock.contents.stock_grid.item_2.number == 32, 'dock quantities are shown separately')
    log('VLD SUMMARY slots ' .. serpent.line(frame.vehicle.children[2].caption) .. ' / '
      .. serpent.line(frame.dock.children[2].caption))
    summary_check(tonumber(frame.vehicle.children[2].caption[2]) == 2 and tonumber(frame.vehicle.children[2].caption[3]) == 80
      and tonumber(frame.dock.children[2].caption[2]) == 3 and tonumber(frame.dock.children[2].caption[3]) == 100,
      'native occupied and total slots are displayed for both inventories')
    local button = frame.vehicle.contents.stock_grid.item_1
    local tooltip_quality = button.elem_tooltip.quality
    summary_check(button.quality.name == 'normal' and (tooltip_quality == nil or tooltip_quality == 'normal'
      or tooltip_quality and tooltip_quality.name == 'normal'),
      'native item tooltip preserves quality')
    summary_check(player.opened == nil, 'sidebar leaves the native chest closed')
    storage.summary_stage = 1
    storage.summary_next = event.tick + 15
  elseif event.tick < storage.summary_next then
    return
  elseif state == 1 then
    summary_check(summary_frame(player), 'sidebar remains visible across ticks')
    game.take_screenshot{player=player,position={0,0},resolution={1280,900},zoom=1,
      path='vld-summary.png',show_gui=true,show_entity_info=true,force_render=true}
    storage.summary_car.get_inventory(defines.inventory.car_trunk).insert{name='copper-plate',count=25}
    storage.summary_stage = 4
    storage.summary_next = event.tick + 10
  elseif state == 4 then
    summary_check(summary_frame(player).vehicle.contents.stock_grid.item_1.number == 150,
      'native inventory changes appear within ten ticks')
    storage.summary_car.set_driver(nil)
    summary_check(not summary_frame(player), 'leaving the car closes immediately while the car remains parked')
    storage.summary_car.set_driver(player)
    summary_check(summary_frame(player), 'entering again reopens the sidebar')
    storage.summary_car.teleport({-12,0})
    storage.summary_stage = 2
    storage.summary_next = event.tick + 1
  elseif state == 2 then
    summary_check(not summary_frame(player), 'driving outside the dock closes by the next tick')
    storage.summary_car.set_driver(nil)
    storage.summary_car.teleport({-20,0})
    storage.summary_car.set_driver(player)
    local tank = surface.create_entity{name='tank',position={-0.5,0},force='player'}
    storage.summary_tank = tank
    player.set_controller{type=defines.controllers.remote,position={0,0},surface=surface}
    tank.set_driver(player)
    log('VLD SUMMARY REMOTE controller=' .. player.controller_type .. ' vehicle=' .. tostring(player.vehicle and player.vehicle.name)
      .. ' physical=' .. tostring(player.physical_vehicle and player.physical_vehicle.name))
    summary_check(player.controller_type == defines.controllers.remote and player.vehicle == tank,
      'real remote controller drives the parked tank')
    summary_check(player.physical_vehicle == storage.summary_car,
      'physical character remains in a different car during remote driving')
    summary_check(summary_frame(player), 'remote driving opens the sidebar')
    storage.summary_stage = 3
    storage.summary_next = event.tick + 10
  elseif state == 3 then
    summary_check(summary_frame(player), 'remote driving keeps the sidebar visible')
    storage.summary_tank.set_driver(nil)
    summary_check(not summary_frame(player), 'releasing remote driving closes immediately with the tank still parked')
    summary_check(storage.summary_tank.position.x == -0.5, 'remote release leaves tank on the dock')
    summary_check(player.physical_vehicle == storage.summary_car and player.vehicle == nil,
      'remote release has no active vehicle despite physical occupancy elsewhere')
    helpers.write_file('vld-summary-result.txt', 'VLD SUMMARY OK\n', false)
    storage.summary_finished = true
  end
end)

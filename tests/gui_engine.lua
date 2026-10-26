local function visual_check(condition, message)
  assert(condition, 'VLD VISUAL: ' .. message)
  log('VLD VISUAL PASS ' .. message)
end

script.on_init(function()
  Docks.initialize()
  if remote.interfaces.freeplay then
    remote.call("freeplay", "set_skip_intro", true)
    remote.call("freeplay", "set_disable_crashsite", true)
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
  if storage.visual_finished or event.tick < 30 then return end
  if storage.visual_capture_tick then
    if event.tick < storage.visual_capture_tick then return end
    local player = game.get_player(1)
    local dock = storage.docks[storage.visual_dock.unit_number]
    visual_check(player.opened == dock.inventory_entity, "native chest remains open across ticks")
    visual_check(player.gui.relative.vld_configuration ~= nil, "relative GUI remains open across ticks")
    game.take_screenshot{player = player, position = {0, 0}, resolution = {1280, 900}, zoom = 1,
      path = "vld-preview.png", show_gui = true, show_entity_info = true, force_render = true}
    game.take_screenshot{player = player, position = {0, 0}, resolution = {1280, 900}, zoom = 1.5,
      path = "vld-building.png", show_gui = false, force_render = true}
    helpers.write_file("vld-visual-result.txt", "VLD VISUAL OK\n", false)
    storage.visual_finished = true
    return
  end
  local player = game.get_player(1)
  if not player or not player.connected then return end
  local surface = game.surfaces.nauvis
  if not storage.visual_dock then
    surface.create_entity{name='substation',position={8,0},force='player'}
    surface.create_entity{name='substation',position={24,0},force='player'}
    local generator = surface.create_entity{name='electric-energy-interface',position={24,4},force='player'}
    generator.electric_buffer_size = 100000000
    generator.power_production = 1000000
    generator.energy = 100000000
    storage.visual_dock = surface.create_entity{name = 'vehicle-loading-dock', position = {0, 0},
      direction = defines.direction.east, force = 'player', raise_built = true}
    storage.visual_ready_tick = event.tick + 30
    return
  end
  if event.tick < storage.visual_ready_tick then return end
  if not storage.visual_car then
    if player.controller_type == defines.controllers.cutscene then player.exit_cutscene() end
    player.teleport({0, 7}, surface)
    Docks.tick()
    local waiting = storage.docks[storage.visual_dock.unit_number]
    visual_check(waiting.status == 'waiting', 'powered dock waits for a vehicle')
    visual_check(waiting.indicator.bulb.color.r > waiting.indicator.bulb.color.g,
      'waiting indicator is orange on physical dock')
    if not storage.visual_car_tick then
      game.take_screenshot{player = player, position = {0, 0}, resolution = {1280, 900}, zoom = 1.5,
        path = "vld-indicator-orange.png", show_gui = false, force_render = true}
      storage.visual_car_tick = event.tick + 2
      return
    end
    if event.tick < storage.visual_car_tick then return end
    storage.visual_car = surface.create_entity{name = 'car', position = {-1, 0}, force = 'player'}
  end
  if player.controller_type == defines.controllers.cutscene then player.exit_cutscene() end
  player.teleport({0, 7}, game.surfaces.nauvis)
  player.zoom = 1.1
  local entity = storage.visual_dock
  local dock = storage.docks[entity.unit_number]
  visual_check(dock and dock.inventory_entity.valid, 'real dock and physical inventory exist')
  player.opened = entity
  Gui.on_opened{entity = entity, player_index = player.index}
  visual_check(player.opened == dock.inventory_entity, 'opening dock exposes native chest')
  local frame = player.gui.relative.vld_configuration
  visual_check(frame and frame.valid, 'relative configuration frame exists')
  visual_check(#frame.load.children == 10 and #frame.unload.children == 10, 'two actual grids contain twenty item buttons')
  for _, mode in ipairs{'load', 'unload'} do
    visual_check(frame[mode].column_count == 5, mode .. ' grid has five columns')
    for index = 1, 10 do
      local button = frame[mode]['filter_' .. index]
      visual_check(button.type == 'choose-elem-button' and button.elem_type == 'item', mode .. ' item chooser ' .. index)
    end
  end
  frame.load.filter_1.elem_value = 'iron-plate'
  Gui.on_changed{element = frame.load.filter_1, player_index = player.index}
  frame.unload.filter_10.elem_value = 'copper-plate'
  Gui.on_changed{element = frame.unload.filter_10, player_index = player.index}
  visual_check(dock.configuration.load_filters[1] == 'iron-plate' and dock.configuration.unload_filters[10] == 'copper-plate', 'real GUI changes persist in dock configuration')
  local chest = dock.inventory_entity.get_inventory(defines.inventory.chest)
  visual_check(#chest == 100, 'native inventory exposes one hundred slots')
  chest.insert{name = 'iron-plate', count = 75}
  storage.visual_car.get_inventory(defines.inventory.car_trunk).insert{name = 'copper-plate', count = 25}
  Docks.tick()
  visual_check(dock.indicator.bulb.color.g > dock.indicator.bulb.color.r and dock.indicator.glow.visible,
    'valid stationary vehicle turns indicator green')
  visual_check(storage.visual_car.get_inventory(defines.inventory.car_trunk).get_item_count('iron-plate') == 75, 'GUI filter loads actual car')
  visual_check(chest.get_item_count('copper-plate') == 25, 'GUI filter unloads actual car')
  chest.insert{name = 'steel-plate', count = 32}
  chest.set_filter(1, 'copper-plate')
  chest.set_filter(3, 'iron-plate')
  chest.set_filter(10, 'coal')
  chest.set_bar(21)
  visual_check(chest.supports_filters() and chest.get_filter(3).name=='iron-plate' and chest.get_bar()==21,
    '006-AC1 native GUI inventory has blue filters and red limiter')
  player.opened = nil
  Gui.on_closed{entity = dock.inventory_entity, player_index = player.index}
  visual_check(not player.gui.relative.vld_configuration, 'real relative frame closes')
  Gui.on_opened{entity = entity, player_index = player.index}
  visual_check(player.gui.relative.vld_configuration.load.filter_1.elem_value == 'iron-plate', 'configuration survives reopening')
  storage.visual_capture_tick = event.tick + 10
end)

local Inventory = require('__vehicle-loading-dock__/scripts/inventory')
local Indicator = require('__vehicle-loading-dock__/scripts/indicator')
local Geometry = require('__vehicle-loading-dock__/scripts/geometry')
local Detection = require('__vehicle-loading-dock__/scripts/detection')
local Transfer = require('__vehicle-loading-dock__/scripts/transfer')
local Configuration = require('__vehicle-loading-dock__/scripts/configuration')
local function check(condition, message)
  assert(condition, 'VLD SMOKE: ' .. message)
  log('VLD PASS ' .. message)
end
local function child(entity)
  return entity.surface.find_entities_filtered {name = 'vld-inventory', position = Geometry.get_dock_position(entity), radius = 0.1}[1]
end
local function dock(position, direction, config)
  local e = game.surfaces.nauvis.create_entity {name = 'vehicle-loading-dock', position = position,
    direction = direction, force = 'player'}
  Docks.on_built {entity=e, tags=config and {vld=config}}
  check(e and e.valid and child(e), 'dock built with child')
  return e
end
local function powered_grid(surface)
  local pole = surface.find_entities_filtered {name='substation',position={8,0},radius=0.1}[1]
    or surface.create_entity {name='substation',position={8,0},force='player'}
  local generator = surface.create_entity {name='electric-energy-interface',position={12,0},force='player'}
  generator.electric_buffer_size = 100000000
  generator.power_production = 1000000
  generator.energy = 100000000
  return pole, generator
end
local function check_indicator(dock, state)
  local lamp = dock.indicator
  check(lamp and lamp.bulb.valid and lamp.glow.valid, '002-AC3 indicator render objects exist')
  local color = lamp.bulb.color
  if state == 'ready' then
    check(color.g > color.r and lamp.glow.visible, '002-AC3 stopped vehicle indicator is green')
  elseif state == 'no-power' then
    check(not lamp.glow.visible, '002-AC3 power cut extinguishes indicator glow')
  else
    check(color.r > color.g and color.g > color.b and lamp.glow.visible, '002-AC3 waiting indicator is orange')
  end
end
local function setup()
  local recipe = game.forces.player.recipes['vehicle-loading-dock']
  local ingredients = {}
  for _, ingredient in pairs(recipe.ingredients) do ingredients[ingredient.name] = ingredient.amount end
  check(ingredients['iron-plate']==20 and ingredients['iron-gear-wheel']==20 and
    ingredients['electronic-circuit']==10 and ingredients['iron-chest']==2 and not ingredients['steel-plate'],
    'base recipe uses iron plates and gears')
  check(not prototypes.entity['vehicle-loading-dock'].allow_copy_paste, 'direct settings paste disabled')
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 5)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered {area = {{-80,-80},{80,80}}}) do
    if e.type ~= 'character' then e.destroy() end
  end
  local tiles = {}
  for x = -80, 80 do for y = -80, 80 do tiles[#tiles+1] = {name = 'refined-concrete', position = {x,y}} end end
  surface.set_tiles(tiles)
  storage.surface = surface

  -- 001-AC1/AC4/AC7: native rotation and the real child collision box.
  for i, direction in ipairs {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west} do
    local e = dock({i*16-48,-40}, direction)
    local c = child(e)
    check(#c.get_inventory(defines.inventory.chest) == 100, '002-AC2 exactly one hundred slots')
    local box = c.bounding_box
    local horizontal = direction == defines.direction.north or direction == defines.direction.south
    check(math.abs((box.right_bottom.x-box.left_top.x) - (horizontal and 7.8 or 0.8)) < 0.01,
      '001-AC1 child collision rotates')
    check(surface.can_place_entity {name = 'car',position = e.position,force = 'player'}, '001-AC1 parking remains drivable')
    local inv = c.get_inventory(defines.inventory.chest)
    inv.insert {name = 'iron-plate',count = 37}
    inv.set_bar(17)
    check(inv.supports_filters() and inv.supports_bar(), '006-AC1 native stock supports filters and bar')
    inv.set_filter(1, 'iron-plate')
    inv.set_filter(100, {name='copper-plate',quality='normal',comparator='≥'})
    inv.set_filter(99, {quality='normal',comparator='≥'})
    local previous = e.direction
    check(e.rotate(), '001-AC7 native square rotation supported')
    Docks.on_rotated {entity=e, previous_direction=previous}
    c = child(e)
    check(c and c.get_inventory(defines.inventory.chest).get_item_count('iron-plate') == 37,
      '001-AC7 rotation conserves stock')
    check(c.get_inventory(defines.inventory.chest).get_bar() == 17, '001-AC7 rotation conserves bar')
    local rotated = c.get_inventory(defines.inventory.chest)
    check(rotated.get_filter(1).name=='iron-plate' and rotated.get_filter(100).name=='copper-plate'
      and rotated.get_filter(100).comparator=='≥', '006-AC4 rotation preserves sparse filters and quality comparator')
    check(rotated.get_filter(99) and not rotated.get_filter(99).name
      and rotated.get_filter(99).comparator=='≥', '006-AC4 rotation preserves quality-only filters')
    Docks.on_removed {entity=e};e.destroy()
    check(not c.valid, '001-AC7 main removal destroys child')
  end

  -- 001-AC2/AC3/AC6: real periodic transfer, then motion, exit and ambiguity.
  local e = dock({0,0}, defines.direction.east,
    {load_filters = {'iron-plate'}, unload_filters = {'copper-plate'}})
  local car = surface.create_entity {name='car',position={-1,0},force='player'}
  child(e).get_inventory(defines.inventory.chest).insert {name='iron-plate',count=73}
  car.get_inventory(defines.inventory.car_trunk).insert {name='copper-plate',count=29}
  storage.dock, storage.car = e, car
  storage.pole, storage.generator = powered_grid(surface)
  check(Detection.find_candidate_vehicle(e) == car, '001-AC2 real bounding box accepted away from strip')

  -- 001-AC6: quality, tags, partial stacks and the native limiter.
  local transfer_dock = dock({32,0}, defines.direction.north)
  local from, to = game.create_inventory(4), child(transfer_dock).get_inventory(defines.inventory.chest)
  from[1].set_stack {name='iron-plate',count=100}
  to[1].set_stack {name='iron-plate',count=80}
  to.set_bar(2)
  check(Transfer.transfer_item(from,to,'iron-plate') == 20 and from[1].count == 80,
    '001-AC6 real partial transfer respects bar')
  from.clear();to.clear();to.set_bar()
  from[1].set_stack {name='vehicle-loading-dock',count=1}
  from[1].tags = {vld={load_filters={'coal'}}}
  Transfer.transfer_item(from,to,'vehicle-loading-dock')
  check(to[1].tags.vld.load_filters[1]=='coal', '001-AC6 item tags preserved')
  if prototypes.quality.legendary then
    from[1].set_stack {name='iron-plate',count=7,quality='legendary'}
    Transfer.transfer_item(from,to,'iron-plate')
    check(to.get_item_count {name='iron-plate',quality='legendary'}==7, '001-AC6 legendary quality preserved')
  end
  from.clear();to.clear();to.set_bar(3)
  to.set_filter(1, 'copper-plate');to.set_filter(2, 'iron-plate')
  to.set_filter(3, 'iron-plate')
  from[1].set_stack {name='iron-plate',count=100}
  from[2].set_stack {name='iron-plate',count=50}
  check(Transfer.transfer_item(from,to,'iron-plate')==100 and from[2].count==50
    and not to[1].valid_for_read and not to[3].valid_for_read,
    '006-AC2 vehicle unloading respects blue filters and red bar together')
  check(Transfer.transfer_item(from,to,'iron-plate')==0 and from[2].count==50,
    '006-AC2 saturated filtered stock stops without loss')
  to[3].set_stack {name='iron-plate',count=17}
  check(to[3].count==17 and to.get_bar()==3, '006-AC3 manual placement beyond bar preserves contents')
  from.clear()
  check(Transfer.transfer_item(to,from,'iron-plate')==117 and to.is_empty(),
    '006-AC3 extraction includes stock beyond red bar')
  to.set_filter(2, nil)
  check(not to.get_filter(2), '006-AC1 native filter can be cleared')
  from.destroy();Docks.on_removed {entity=transfer_dock};transfer_dock.destroy()

  -- 001-AC7: mining returns stock, while rebuilding starts with empty filters.
  local mined = dock({-32,0}, defines.direction.north,
    {load_filters={[10]='steel-plate'},unload_filters={'coal'}})
  child(mined).get_inventory(defines.inventory.chest).insert {name='coal',count=123}
  local buffer=game.create_inventory(100)
  buffer[1].set_stack {name='vehicle-loading-dock',count=1}
  Docks.on_mined {entity=mined,buffer=buffer,player_index=1}
  mined.destroy()
  check(buffer.get_item_count('coal')==123, '001-AC7 mining returns inventory')
  local tags
  for i=1,#buffer do
    if buffer[i].valid_for_read and buffer[i].name=='vehicle-loading-dock' then tags=buffer[i].tags end
  end
  check(not tags or not tags.vld, 'mining does not store filters in the item')
  local replacement = surface.create_entity {name='vehicle-loading-dock',position={-32,0},force='player'}
  Docks.on_built {entity=replacement,tags=tags}
  check(not next(storage.docks[replacement.unit_number].configuration.load_filters) and
    not next(storage.docks[replacement.unit_number].configuration.unload_filters), 'rebuilding clears both filter lists')
  local second_buffer=game.create_inventory(100)
  second_buffer[1].set_stack {name='vehicle-loading-dock',count=1}
  Docks.on_mined {entity=replacement,buffer=second_buffer}
  replacement.destroy()
  check(not second_buffer[1].tags or not second_buffer[1].tags.vld, 'repeated mining does not store filters')
  buffer.destroy();second_buffer.destroy()
  -- 001-AC4: regular fueled inserters access the strip from its exterior.
  local inserter_dock=dock({32,24},defines.direction.north)
  local feed=surface.create_entity {name='iron-chest',position={32.5,18.5},force='player'}
  feed.insert {name='iron-plate',count=5}
  local loader=surface.create_entity {name='burner-inserter',position={32.5,19.5},force='player'}
  if loader.drop_position.y<19.5 then loader.direction=defines.direction.south end
  loader.get_fuel_inventory().insert {name='coal',count=5}
  local output=surface.create_entity {name='iron-chest',position={30.5,18.5},force='player'}
  local unloader=surface.create_entity {name='burner-inserter',position={30.5,19.5},force='player'}
  if unloader.drop_position.y>19.5 then unloader.direction=defines.direction.south end
  unloader.get_fuel_inventory().insert {name='coal',count=5}
  child(inserter_dock).insert {name='copper-plate',count=3}
  storage.feed,storage.output,storage.unloader=feed,output,unloader
  local restricted = dock({-16,24},defines.direction.north)
  local restricted_stock = child(restricted).get_inventory(defines.inventory.chest)
  restricted_stock.set_filter(1, 'copper-plate')
  restricted_stock.set_bar(2)
  local blocked_feed=surface.create_entity {name='iron-chest',position={-15.5,18.5},force='player'}
  blocked_feed.insert {name='iron-plate',count=5}
  local blocked_loader=surface.create_entity {name='burner-inserter',position={-15.5,19.5},force='player'}
  if blocked_loader.drop_position.y<19.5 then blocked_loader.direction=defines.direction.south end
  blocked_loader.get_fuel_inventory().insert {name='coal',count=5}
  storage.restricted,storage.blocked_feed,storage.blocked_loader=restricted,blocked_feed,blocked_loader
  -- 001-AC2: spider vehicles expose their trunk through the same contract.
  local spider_dock=dock({-32,32},defines.direction.north)
  local spider=surface.create_entity {name='spidertron',position={-32,33},force='player'}
  check(Detection.find_candidate_vehicle(spider_dock)==spider,'001-AC2 real spider vehicle supported')
  Docks.on_removed {entity=spider_dock};spider_dock.destroy();spider.destroy()
  -- 001-AC7: failed rotation restores stock, limiter and the previous orientation.
  local blocked=dock({48,-16},defines.direction.north)
  local original=child(blocked).get_inventory(defines.inventory.chest)
  original.insert {name='coal',count=13};original.set_bar(9)
  original.set_filter(100, 'steel-plate')
  original.set_filter(99, {quality='normal',comparator='≥'})
  local wall=surface.create_entity {name='stone-wall',position={51.5,-15.5},force='player'}
  blocked.direction=defines.direction.east
  check(not Docks.sync(storage.docks[blocked.unit_number]),'001-AC7 obstructed rotation rejected')
  check(blocked.direction==defines.direction.north and child(blocked).get_inventory(defines.inventory.chest).get_item_count('coal')==13,
    '001-AC7 rejected rotation restores orientation and stock')
  check(child(blocked).get_inventory(defines.inventory.chest).get_bar()==9,'001-AC7 rejected rotation restores limiter')
  check(child(blocked).get_inventory(defines.inventory.chest).get_filter(100).name=='steel-plate',
    '006-AC4 rejected rotation preserves filters')
  check(child(blocked).get_inventory(defines.inventory.chest).get_filter(99).comparator=='≥',
    '006-AC4 rejected rotation preserves quality-only filters')
  Docks.on_removed {entity=blocked};blocked.destroy();wall.destroy()
  -- 001-AC7: blueprint tags preserve a filter in the tenth slot.
  local clone_source=dock({32,-16},defines.direction.east,{load_filters={[10]='coal'},unload_filters={[9]='copper-plate'}})
  child(clone_source).get_inventory(defines.inventory.chest).insert {name='coal',count=77}
  child(clone_source).get_inventory(defines.inventory.chest).set_bar(51)
  child(clone_source).get_inventory(defines.inventory.chest).set_filter(1, 'coal')
  child(clone_source).get_inventory(defines.inventory.chest).set_filter(100, 'steel-plate')
  child(clone_source).get_inventory(defines.inventory.chest).set_filter(99, {quality='normal',comparator='≥'})
  storage.clone_source=clone_source
  local blueprint=game.create_inventory(1)
  blueprint[1].set_stack {name='blueprint',count=1}
  blueprint[1].create_blueprint {surface=surface,force='player',area={{27,-21},{37,-11}}}
  local mapping={}
  for _,item in pairs(blueprint[1].get_blueprint_entities()) do
    if item.name=='vehicle-loading-dock' then mapping[item.entity_number]=clone_source end
  end
  Docks.on_blueprint {stack=blueprint[1],mapping={get=function()return mapping end}}
  local exported = blueprint[1].export_stack()
  check(blueprint[1].import_stack(exported)==0, '006-AC5 blueprint settings survive native string export and import')
  for _,item in pairs(blueprint[1].get_blueprint_entities()) do
    if item.name=='vehicle-loading-dock' then
      check(Configuration.normalize(item.tags.vld).load_filters[10]=='coal','001-AC7 blueprint retains sparse filters')
      local rebuilt = surface.create_entity {name='vehicle-loading-dock',position={64,32},force='player'}
      Docks.on_built {entity=rebuilt,tags=item.tags}
      local settings = storage.docks[rebuilt.unit_number].configuration
      check(settings.load_filters[10]=='coal' and settings.unload_filters[9]=='copper-plate',
        'blueprint construction restores both sparse filter lists')
      local stock=child(rebuilt).get_inventory(defines.inventory.chest)
      check(stock.get_bar()==51 and stock.get_filter(1).name=='coal'
        and stock.get_filter(100).name=='steel-plate' and stock.is_empty(),
        '006-AC5 blueprint and copy construction restore stock settings without cargo')
      Docks.on_removed {entity=rebuilt};rebuilt.destroy()
    end
  end
  storage.stock_blueprint = exported
  blueprint.destroy()
  -- 001-AC7: robot construction reads settings carried by the construction item.
  local tagged=game.create_inventory(1)
  tagged[1].set_stack {name='vehicle-loading-dock',count=1}
  tagged[1].tags={vld={load_filters={[10]='coal'}}}
  local robot_built=surface.create_entity {name='vehicle-loading-dock',position={48,16},force='player'}
  Docks.on_built {entity=robot_built,stack=tagged[1]}
  check(storage.docks[robot_built.unit_number].configuration.load_filters[10]==nil,
    'robot construction ignores legacy item settings')
  Docks.on_removed {entity=robot_built};robot_built.destroy()
  local player_built=surface.create_entity {name='vehicle-loading-dock',position={48,16},force='player'}
  Docks.on_built {entity=player_built,consumed_items=tagged}
  check(storage.docks[player_built.unit_number].configuration.load_filters[10]==nil,
    'player construction ignores legacy consumed item settings')
  Docks.on_removed {entity=player_built};player_built.destroy();tagged.destroy()
  local migration = storage.docks[clone_source.unit_number]
  local migration_inventory = migration.inventory_entity.get_inventory(defines.inventory.chest)
  migration.inventory_size = nil
  migration_inventory.set_bar(51)
  Inventory.ensure_capacity(migration)
  check(migration_inventory.get_bar()==101 and migration.inventory_size==100,
    '002-AC2 legacy unlimited inventory expands to one hundred slots')
  check(migration_inventory.get_item_count('coal')==77 and migration.configuration.load_filters[10]=='coal',
    '002-AC2 migration preserves stock and filters')
  migration.inventory_size = 50
  migration_inventory.set_bar(25)
  Inventory.ensure_capacity(migration)
  check(migration_inventory.get_bar()==25, '002-AC2 migration preserves explicit manual limiter')
  migration_inventory.set_bar(51)
  Indicator.destroy(migration)
  check(not migration.indicator, '002-AC4 legacy dock has no stored indicator')
  storage.phase = 1
end
script.on_init(function() Docks.initialize(); setup() end)
script.on_event(defines.events.on_tick,function(event)
  if storage.phase == 1 and event.tick >= 20 then
    check(storage.docks[storage.clone_source.unit_number].indicator.bulb.valid,
      '002-AC4 periodic update repairs legacy indicator after reload')
    local blueprint=game.create_inventory(1)
    blueprint[1].import_stack(storage.stock_blueprint)
    local ghosts = blueprint[1].build_blueprint {surface=storage.surface,force='player',position={64,32}}
    local revived
    for _, ghost in pairs(ghosts) do
      if ghost.ghost_name=='vehicle-loading-dock' then
        local success
        success, revived = ghost.revive {raise_revive=true}
        check(success and revived and storage.docks[revived.unit_number],
          '006-AC5 native blueprint revival registers dock through event')
      end
    end
    check(revived ~= nil, '006-AC5 native blueprint creates dock ghost')
    local pasted = child(revived).get_inventory(defines.inventory.chest)
    check(pasted.get_bar()==51 and pasted.get_filter(100).name=='steel-plate' and pasted.is_empty(),
      '006-AC5 native paste restores stock filters and limiter without cargo')
    check(pasted.get_filter(99) and not pasted.get_filter(99).name and pasted.get_filter(99).comparator=='≥',
      '006-AC5 native blueprint paste preserves quality-only filters')
    Docks.on_removed {entity=revived};revived.destroy()
    blueprint.destroy()
    local saved = child(storage.clone_source).get_inventory(defines.inventory.chest)
    check(saved.get_bar()==51 and saved.get_filter(1).name=='coal' and saved.get_filter(100).name=='steel-plate',
      '006-AC4 save and reload preserve native stock settings')
    -- 001-AC7: native cloning creates all entities before raising clone events.
    storage.surface.clone_area {source_area={{27,-21},{37,-11}},destination_area={{59,-21},{69,-11}},
      clone_entities=true,clone_tiles=false}
    local clones=storage.surface.find_entities_filtered {name='vehicle-loading-dock',area={{59,-21},{69,-11}}}
    check(#clones==1 and child(clones[1]),'001-AC7 area clone retains its dock')
    check(storage.docks[clones[1].unit_number].indicator.bulb.valid,
      '002-AC4 area clone gets independent indicator')
    local children=storage.surface.find_entities_filtered {name='vld-inventory',area={{59,-21},{69,-11}}}
    check(#children==1 and children[1].get_inventory(defines.inventory.chest).get_item_count('coal')==77,
      '001-AC7 area clone has exactly one stocked child')
    check(children[1].get_inventory(defines.inventory.chest).get_bar()==51,
      '002-AC2 area clone preserves intentional fifty-slot limiter')
    local cloned=storage.clone_source.clone {position={-32,-16},surface=storage.surface}
    check(cloned and cloned.valid and child(cloned).get_inventory(defines.inventory.chest).get_item_count('coal')==77,
      '001-AC7 single entity clone copies stock')
    check(child(cloned).get_inventory(defines.inventory.chest).get_bar()==51,
      '002-AC2 single clone preserves intentional fifty-slot limiter')
    check(child(cloned).get_inventory(defines.inventory.chest).get_filter(100).name=='steel-plate'
      and children[1].get_inventory(defines.inventory.chest).get_filter(100).name=='steel-plate',
      '006-AC5 single and area clones preserve sparse filters')
    check(child(cloned).get_inventory(defines.inventory.chest).get_filter(99).comparator=='≥'
      and children[1].get_inventory(defines.inventory.chest).get_filter(99).comparator=='≥',
      '006-AC5 single and area clones preserve quality-only filters')
    local e,car = storage.dock,storage.car
    check(e.is_connected_to_electric_network(), '002-AC1 dock connects to native electrical network')
    check_indicator(storage.docks[e.unit_number], 'ready')
    check(car.get_inventory(defines.inventory.car_trunk).get_item_count('iron-plate')==73,
      '001-AC6 periodic loading after save and reload')
    check(child(e).get_inventory(defines.inventory.chest).get_item_count('copper-plate')==29,
      '001-AC6 periodic unloading after save and reload')
    car.teleport({-1,-1.8})
    storage.second=storage.surface.create_entity {name='car',position={-1,1.8},force='player'}
    child(e).get_inventory(defines.inventory.chest).insert {name='iron-plate',count=11}
    local candidate,status=Detection.find_candidate_vehicle(e)
    check(not candidate and status=='multiple','001-AC3 two real cars stop transfers')
    storage.phase=2
  elseif storage.phase == 2 and event.tick >= 40 then
    check_indicator(storage.docks[storage.dock.unit_number], 'waiting')
    check(child(storage.dock).get_inventory(defines.inventory.chest).get_item_count('iron-plate')==11,
      '001-AC3 periodic ambiguity preserves dock stock')
    storage.second.destroy()
    storage.car.teleport({-3.8,0})
    local candidate=Detection.find_candidate_vehicle(storage.dock)
    check(not candidate,'001-AC2 centre inside but bounding box outside rejected')
    storage.car.teleport({-1,0})
    storage.car.speed=0.01
    local vehicle,status=Detection.find_candidate_vehicle(storage.dock)
    check(not vehicle and status=='moving','001-AC2 moving vehicle rejected')
    storage.car.speed=0
    storage.phase=3
  elseif storage.phase == 3 and event.tick >= 60 then
    check(child(storage.dock).get_inventory(defines.inventory.chest).get_item_count('iron-plate')==0,
      '001-AC6 transfer resumes after single stopped vehicle')
    storage.generator.destroy()
    storage.dock.energy=0
    child(storage.dock).get_inventory(defines.inventory.chest).insert {name='iron-plate',count=11}
    storage.phase=7
  elseif storage.phase == 7 and event.tick >= 80 then
    local dock_state=storage.docks[storage.dock.unit_number]
    check(child(storage.dock).get_inventory(defines.inventory.chest).get_item_count('iron-plate')==11,
      '002-AC1 power cut prevents periodic transfer')
    check(dock_state.status=='no-power' and not dock_state.current_vehicle,
      '002-AC1 power cut clears current vehicle and reports no power')
    check_indicator(dock_state, 'no-power')
    local _, generator = powered_grid(storage.surface)
    storage.generator=generator
    storage.phase=8
  elseif storage.phase == 8 and event.tick >= 100 then
    check(child(storage.dock).get_inventory(defines.inventory.chest).get_item_count('iron-plate')==0,
      '002-AC1 periodic transfer resumes when electricity returns')
    check_indicator(storage.docks[storage.dock.unit_number], 'ready')
    local e=storage.dock
    storage.removed_indicator=storage.docks[e.unit_number].indicator
    local old_child=child(e)
    old_child.get_inventory(defines.inventory.chest).insert {name='coal',count=19}
    e.destroy()
    storage.phase=4
    storage.removed_child=old_child
  elseif storage.phase == 4 and event.tick >= 120 then
    check(not storage.removed_child.valid,'001-AC7 silent script destruction cleans child')
    check(not storage.removed_indicator.bulb.valid and not storage.removed_indicator.glow.valid,
      '002-AC4 silent destruction cleans indicator render objects')
    storage.phase=5
  elseif storage.phase==5 and event.tick>=900 then
    check(storage.feed.get_item_count('iron-plate')==0,'001-AC4 regular inserter feeds strip')
    check(storage.output.get_item_count('copper-plate')==3,'001-AC4 regular inserter empties strip')
    local restricted_stock = child(storage.restricted).get_inventory(defines.inventory.chest)
    check(restricted_stock.is_empty(), '006-AC2 native inserter respects stock filter and red bar')
    check(storage.blocked_feed.get_item_count('iron-plate') + storage.blocked_loader.held_stack.count == 5,
      '006-AC2 blocked inserter preserves all input items')
    helpers.write_file('vld-smoke-result.txt','VLD SMOKE OK\n',false)
    log('VLD SMOKE OK')
    storage.phase=6
  end
end)

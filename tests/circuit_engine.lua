local C = require('__vehicle-loading-dock__/scripts/constants')
local function check(ok, message)
  assert(ok, 'VLD CIRCUIT: ' .. message)
  log('VLD PASS ' .. message)
end
local function inventory(dock)
  return dock.inventory_entity.get_inventory(defines.inventory.chest)
end
local red, green = defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green
local function signal(pole, color, name, quality, kind)
  local network = pole.get_circuit_network(color)
  return network and network.get_signal {type = kind or 'item', name = name, quality = quality or 'normal'} or 0
end
local function presence(expected)
  for _, color in ipairs {red, green} do
    check(signal(storage.reader, color, C.parked_signal, nil, 'virtual') == expected,
      '005-AC3 présence sur les deux couleurs : ' .. expected)
  end
end
local function setup()
  Docks.initialize()
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 4)
  surface.force_generate_chunk_requests()
  for _, e in pairs(surface.find_entities_filtered {area = {{-64,-64},{96,64}}}) do e.destroy() end
  local tiles = {}
  for x = -64, 96 do for y = -64, 64 do tiles[#tiles+1] = {name='refined-concrete',position={x,y}} end end
  surface.set_tiles(tiles)
  storage.circuit_docks = {}
  storage.readers = {}
  for i, direction in ipairs {defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west} do
    local x = (i-1)*20
    local entity = surface.create_entity {name=C.name,position={x,0},direction=direction,force='player'}
    local dock = Docks.register(entity, {load_filters={'iron-plate'}})
    local pole = surface.create_entity {name='small-electric-pole',position={x,-6},force='player'}
    for _, color in ipairs {red,green} do
      check(entity.get_wire_connector(color,true).connect_to(pole.get_wire_connector(color,true)),
        '005-AC1 branchement natif orientation ' .. direction)
    end
    inventory(dock).insert {name='iron-plate',count=23}
    inventory(dock).insert {name='iron-plate',count=7,quality='legendary'}
    storage.circuit_docks[i] = dock
    storage.readers[i] = pole
  end
  storage.dock = storage.circuit_docks[1]
  storage.reader = storage.readers[1]
  storage.car = surface.create_entity {name='car',position={0,0},force='player'}
  local input = surface.create_entity {name='constant-combinator',position={-2,-6},force='player'}
  input.get_or_create_control_behavior().add_section().filters = {
    {value={type='virtual',name='signal-A',quality='normal'},min=42}}
  input.get_wire_connector(red,true).connect_to(storage.reader.get_wire_connector(red,true))
  storage.input = input
  -- 005-AC5 : une sauvegarde d’un ancien quai ne contient pas d’émetteur.
  storage.dock.circuit_output.destroy()
  storage.dock.circuit_output = nil
  storage.phase = 0
end
script.on_init(setup)
script.on_event(defines.events.on_tick, function(event)
  if event.tick % 10 ~= 5 then return end
  local phase = storage.phase
  if phase == 0 then
    if event.tick < 15 then return end
    for i, dock in ipairs(storage.circuit_docks) do
      for _, color in ipairs {red,green} do
        check(signal(storage.readers[i], color, 'iron-plate') == 23,
          '005-AC2 stock normal après rechargement')
        check(signal(storage.readers[i], color, 'iron-plate', 'legendary') == 7,
          '005-AC2 qualité distincte')
      end
      check(dock.circuit_output and dock.circuit_output.valid, '005-AC5 émetteur créé ou réparé')
    end
    check(signal(storage.reader,red,'signal-A',nil,'virtual')==42 and
      signal(storage.reader,green,'signal-A',nil,'virtual')==0,'005-AC1 réseaux indépendants')
    presence(1)
    check(storage.dock.status=='no-power' and inventory(storage.dock).get_item_count('iron-plate')==23 and
      storage.car.get_inventory(defines.inventory.car_trunk).is_empty(),
      '005-AC4 lecture sans courant et aucun transfert')
    check(storage.dock.entity.rotate(), '005-AC5 rotation native connectée')
    Docks.on_rotated {entity=storage.dock.entity}
    inventory(storage.dock).remove {name='iron-plate',count=3}
  elseif phase == 1 then
    for _, color in ipairs {red,green} do
      check(signal(storage.reader,color,'iron-plate')==20,'005-AC2/005-AC5 stock modifié et câbles conservés après rotation')
    end
    presence(1)
    storage.car.speed=0.02
  elseif phase == 2 then
    presence(0)
    storage.car.speed=0
    storage.car.teleport({-3.8,0})
  elseif phase == 3 then
    presence(0)
    storage.car.teleport({0,-1.8})
    storage.second=storage.car.surface.create_entity {name='car',position={0,1.8},force='player'}
  elseif phase == 4 then
    presence(0)
    storage.second.destroy()
    storage.car.teleport({0,12})
    inventory(storage.dock).clear()
  elseif phase == 5 then
    presence(0)
    for _, color in ipairs {red,green} do
      check(signal(storage.reader,color,'iron-plate')==0 and
        signal(storage.reader,color,'iron-plate','legendary')==0,'005-AC2 stock vide efface les signaux')
    end
    inventory(storage.dock).insert {name='copper-plate',count=13}
    storage.dock.entity.surface.clone_area {source_area={{-5,-8},{5,5}},destination_area={{-5,24},{5,37}},
      clone_entities=true,clone_tiles=false}
    local clones=storage.dock.entity.surface.find_entities_filtered {name=C.name,area={{-5,24},{5,37}}}
    check(#clones==1,'005-AC5 un seul quai cloné')
    storage.cloned = storage.docks[clones[1].unit_number]
    storage.dock.configuration.load_filters = {'copper-plate'}
    storage.car.teleport({0,0})
    local surface = storage.dock.entity.surface
    surface.create_entity {name='substation',position={6,0},force='player'}
    local generator = surface.create_entity {name='electric-energy-interface',position={10,0},force='player'}
    generator.electric_buffer_size=100000000
    generator.power_production=1000000
    generator.energy=100000000
  elseif phase == 6 then
    if event.tick < 95 then return end
    check(storage.cloned.circuit_output ~= storage.dock.circuit_output and
      inventory(storage.cloned).get_item_count('copper-plate')==13,'005-AC5 clone indépendant avec stock')
    check(storage.cloned.entity.surface.count_entities_filtered {name=C.circuit_name,area={{-5,24},{5,37}}}==1,
      '005-AC5 aucun émetteur de clone orphelin')
    for _, color in ipairs {red,green} do
      check(signal(storage.reader,color,'copper-plate')==0,'005-AC2 lecture après transfert alimenté')
    end
    check(storage.car.get_inventory(defines.inventory.car_trunk).get_item_count('copper-plate')==13,
      '005-AC2 transfert réel vers le véhicule')
    inventory(storage.dock).insert {name='copper-plate',count=13}
    storage.removed_output=storage.cloned.circuit_output
    storage.cloned.entity.destroy()
    local buffer=game.create_inventory(100)
    storage.mined_output=storage.dock.circuit_output
    Docks.on_mined {entity=storage.dock.entity,buffer=buffer}
    check(buffer.get_item_count('copper-plate')==13,'005-AC5 minage conserve le contenu')
    storage.dock.entity.destroy()
    buffer.destroy()
  elseif phase == 7 then
    check(not storage.removed_output.valid and not storage.mined_output.valid,
      '005-AC5 destruction et minage nettoient les émetteurs')
    for _, color in ipairs {red,green} do
      check(signal(storage.reader,color,'copper-plate')==0,'005-AC5 destruction efface les signaux')
    end
    helpers.write_file('vld-circuit-result.txt','VLD CIRCUIT OK\n',false)
    log('VLD CIRCUIT OK')
  end
  storage.phase = phase + 1
end)

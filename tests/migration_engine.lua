local Configuration = require('__vehicle-loading-dock__/scripts/configuration')
local Indicator = require('__vehicle-loading-dock__/scripts/indicator')
local function migration_check(condition, message)
  assert(condition, 'VLD MIGRATION: ' .. message)
  log('VLD MIGRATION PASS ' .. message)
end

script.on_configuration_changed(function(event)
  storage.migration_mod_changes = next(event.mod_changes) ~= nil
  storage.migration_configuration_events = (storage.migration_configuration_events or 0) + 1
end)
script.on_init(function()
  Docks.initialize()
  local surface = game.surfaces.nauvis
  surface.request_to_generate_chunks({0,0}, 2)
  surface.force_generate_chunk_requests()
  for _, entity in pairs(surface.find_entities_filtered{area={{-16,-16},{32,16}}}) do
    if entity.type ~= 'character' then entity.destroy() end
  end
  local tiles = {}
  for x=-16,32 do for y=-16,16 do
    tiles[#tiles+1]={name='refined-concrete',position={x,y}}
  end end
  surface.set_tiles(tiles)
  storage.migration_ids = {}
  for index=1,2 do
    local entity=surface.create_entity{name='vehicle-loading-dock',position={(index-1)*16,0},force='player',
      quality=index==2 and prototypes.quality.legendary and 'legendary' or 'normal'}
    Docks.on_built{entity=entity,tags={vld={load_filters={[10]='coal'},unload_filters={[10]='iron-plate'}}}}
    local dock=storage.docks[entity.unit_number]
    local inventory=dock.inventory_entity.get_inventory(defines.inventory.chest)
    migration_check(#inventory==50, 'legacy native inventory has fifty slots')
    inventory[1].set_stack{name='coal',count=37,quality=entity.quality.name}
    inventory[50].set_stack{name='vehicle-loading-dock',count=1,quality='normal'}
    inventory[50].tags={vld={load_filters={[10]='steel-plate'}}}
    if index==2 then inventory.set_bar(25) end
    migration_check(inventory.get_bar()==(index==1 and 51 or 25), 'legacy native limiter saved')
    Indicator.destroy(dock)
    dock.inventory_size=nil
    storage.migration_ids[index]=entity.unit_number
  end
  storage.migration_version=script.active_mods['vehicle-loading-dock']
end)
script.on_event(defines.events.on_tick,function(event)
  if event.tick<20 or storage.migration_done then return end
  migration_check(script.active_mods['vehicle-loading-dock']==storage.migration_version, 'version unchanged across prototype upgrade')
  Docks.tick()
  for index,id in ipairs(storage.migration_ids) do
    local dock=storage.docks[id]
    local inventory=dock.inventory_entity.get_inventory(defines.inventory.chest)
    migration_check(#inventory==100 and dock.inventory_size==100, 'legacy save upgraded to one hundred slots')
    migration_check(inventory.get_bar()==(index==1 and 101 or 25), 'unlimited expands and explicit limiter survives')
    migration_check(inventory[1].name=='coal' and inventory[1].count==37 and inventory[1].quality.name==dock.entity.quality.name,
      'native stock and quality survive prototype migration')
    migration_check(inventory[50].valid_for_read and Configuration.normalize(inventory[50].tags.vld).load_filters[10]=='steel-plate', 'last legacy slot and item tags survive')
    migration_check(dock.configuration.load_filters[10]=='coal' and dock.configuration.unload_filters[10]=='iron-plate',
      'both sparse filter lists survive')
    migration_check(dock.indicator and dock.indicator.bulb.valid and not dock.indicator.glow.visible,
      'legacy save receives valid unpowered indicator')
  end
  storage.migration_done=true
  migration_check(not storage.migration_mod_changes, 'no mod version or mod list change')
  log('VLD MIGRATION CONFIG EVENTS '..(storage.migration_configuration_events or 0))
  helpers.write_file('vld-migration-result.txt','VLD MIGRATION OK\n',false)
end)

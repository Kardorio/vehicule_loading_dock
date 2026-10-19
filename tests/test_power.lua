package.path = './?.lua;' .. package.path

defines = {inventory = {chest = 1}}
local C = require('scripts.constants')
local Power = require('scripts.power')
local Inventory = require('scripts.inventory')
local function check(condition, name)
  assert(condition, name)
  print('PASS 002 ' .. name)
end
local connected = true
local entity = {valid = true, energy = C.energy_per_check,
  is_connected_to_electric_network = function() return connected end}
check(Power.is_powered(entity), 'alimentation suffisante au seuil exact')
entity.energy = C.energy_per_check - 1
check(not Power.is_powered(entity), 'énergie insuffisante bloque le transfert')
entity.energy = 60000
connected = false
check(not Power.is_powered(entity), 'déconnexion bloque malgré le tampon chargé')
connected = true
entity.energy = 0
check(not Power.is_powered(entity), 'réseau sans énergie bloque le transfert')
entity.valid = false
check(not Power.is_powered(entity), 'entité invalide ignorée')

local function migrated(bar, previous_size)
  local inv = {}
  for i = 1, 100 do inv[i] = {name = i == 1 and 'coal' or nil, count = i == 1 and 77 or 0} end
  inv.get_bar = function() return bar end
  inv.set_bar = function(value) bar = value or 101 end
  local dock = {inventory_size = previous_size, configuration = {load_filters = {[10] = 'coal'}},
    inventory_entity = {valid = true, get_inventory = function(index)
      assert(index == defines.inventory.chest)
      return inv
    end}}
  Inventory.ensure_capacity(dock)
  check(dock.inventory_size == 100, 'capacité connue migrée vers cent')
  check(inv[1].count == 77 and dock.configuration.load_filters[10] == 'coal', 'migration conserve stock et filtres')
  return dock, inv.get_bar()
end
local legacy, bar = migrated(51)
check(bar == 101, 'ancienne limite illimitée étendue à cent')
local _, restricted = migrated(25, 50)
check(restricted == 25, 'limite manuelle conservée')
local _, intentional = migrated(51, 100)
check(intentional == 51, 'limite manuelle cinquante conservée après migration')
Inventory.ensure_capacity(legacy)
check(legacy.inventory_size == 100, 'migration répétée sans effet secondaire')

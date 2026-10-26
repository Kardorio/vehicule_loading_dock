local C = require("scripts.constants")
local Inventory = {}

function Inventory.serialize(inventory)
  local settings = {bar = inventory.get_bar(), filters = {}}
  if inventory.supports_filters() then
    for index = 1, #inventory do
      settings.filters[index] = inventory.get_filter(index)
    end
  end
  return settings
end

local comparators = {['='] = true, ['≠'] = true, ['<'] = true, ['>'] = true, ['≤'] = true, ['≥'] = true}

local function normalize_filter(filter)
  if type(filter) == 'string' then filter = {name = filter} end
  if type(filter) ~= 'table' then return nil end
  if filter.name ~= nil and (type(filter.name) ~= 'string'
    or not prototypes.item[filter.name]) then return nil end
  local quality = filter.quality or 'normal'
  local comparator = filter.comparator or '='
  if type(quality) ~= 'string' or not prototypes.quality[quality]
    or not comparators[comparator] then return nil end
  return {name = filter.name, quality = quality, comparator = comparator}
end

function Inventory.apply(inventory, settings)
  if type(settings) ~= 'table' then return end
  if type(settings.filters) == 'table' and inventory.supports_filters() then
    for index = 1, #inventory do
      local filter = normalize_filter(settings.filters[index] or settings.filters[tostring(index)])
      inventory.set_filter(index, filter)
    end
  end
  local bar = settings.bar
  if type(bar) == 'number' and bar == math.floor(bar) and bar >= 1 and bar <= #inventory + 1 then
    inventory.set_bar(bar)
  end
end

function Inventory.ensure_capacity(dock)
  local entity = dock.inventory_entity
  if not entity or not entity.valid then return end
  local inventory = entity.get_inventory(defines.inventory.chest)
  local size = #inventory
  local previous_size = dock.inventory_size or C.legacy_inventory_size
  if previous_size < size and inventory.get_bar() == previous_size + 1 then
    inventory.set_bar()
  end
  dock.inventory_size = size
end

return Inventory

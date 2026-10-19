local C = require("scripts.constants")
local Inventory = {}

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

local Constants = require('scripts.constants')
local Transfer = {}

local function quality_level(quality)
  if type(quality) == 'string' then return prototypes.quality[quality].level end
  return quality.level
end

local function accepts_filter(filter, stack)
  if not filter then return true end
  if type(filter) == 'string' then filter = {name = filter} end
  if filter.name and filter.name ~= stack.name then return false end
  local actual = quality_level(stack.quality)
  local expected = quality_level(filter.quality or 'normal')
  local comparator = filter.comparator or '='
  if comparator == '=' or comparator == '==' then return actual == expected end
  if comparator == '≠' or comparator == '!=' then return actual ~= expected end
  if comparator == '<' then return actual < expected end
  if comparator == '>' then return actual > expected end
  if comparator == '≤' or comparator == '<=' then return actual <= expected end
  if comparator == '≥' or comparator == '>=' then return actual >= expected end
  return false
end

function Transfer.transfer_item(source_inventory, destination_inventory, item_name)
  local transferred = 0
  local last_slot = #destination_inventory
  if destination_inventory.supports_bar() then
    last_slot = math.min(last_slot, destination_inventory.get_bar() - 1)
  end
  local supports_filters = destination_inventory.supports_filters()
  for source_index = 1, #source_inventory do
    local source = source_inventory[source_index]
    if source.valid_for_read and source.name == item_name then
      for pass = 1, 2 do
        for destination_index = 1, last_slot do
          if not source.valid_for_read then break end
          local destination = destination_inventory[destination_index]
          if (pass == 1) == destination.valid_for_read then
            local filter = supports_filters and destination_inventory.get_filter(destination_index) or nil
            if accepts_filter(filter, source) and destination.can_set_stack{name = source.name, quality = source.quality, count = 1} then
              local before = source.count
              destination.transfer_stack(source)
              transferred = transferred + before - (source.valid_for_read and source.count or 0)
            end
          end
        end
      end
    end
  end
  return transferred
end

local function transfer_filters(source, destination, filters)
  local count, seen = 0, {}
  for index = 1, Constants.filter_count do
    local item_name = filters[index]
    if item_name and not seen[item_name] then
      seen[item_name] = true
      count = count + Transfer.transfer_item(source, destination, item_name)
    end
  end
  return count
end

function Transfer.transfer_from_vehicle(dock_inventory, vehicle_inventory, filters)
  return transfer_filters(vehicle_inventory, dock_inventory, filters)
end

function Transfer.transfer_to_vehicle(dock_inventory, vehicle_inventory, filters)
  return transfer_filters(dock_inventory, vehicle_inventory, filters)
end

function Transfer.run(dock_inventory, vehicle_inventory, configuration)
  local count = Transfer.transfer_from_vehicle(dock_inventory, vehicle_inventory, configuration.unload_filters)
  return count + Transfer.transfer_to_vehicle(dock_inventory, vehicle_inventory, configuration.load_filters)
end

return Transfer

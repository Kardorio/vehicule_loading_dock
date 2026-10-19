local Geometry = require('scripts.geometry')
local Constants = require('scripts.constants')
local Detection = {STOP_SPEED_EPSILON = Constants.stop_speed_epsilon}

function Detection.get_inventory(vehicle)
  if not vehicle or not vehicle.valid then return nil end
  local inventory_id
  if vehicle.type == 'car' then
    inventory_id = defines.inventory.car_trunk
  elseif vehicle.type == 'spider-vehicle' then
    inventory_id = defines.inventory.spider_trunk
  else
    return nil
  end
  local inventory = vehicle.get_inventory(inventory_id)
  if inventory and inventory.valid then return inventory end
  return nil
end

function Detection.is_supported_vehicle(vehicle)
  return Detection.get_inventory(vehicle) ~= nil
end

function Detection.is_fully_inside_area(vehicle, area)
  local box = vehicle.bounding_box
  return box.left_top.x >= area.left_top.x and box.left_top.y >= area.left_top.y and
      box.right_bottom.x <= area.right_bottom.x and box.right_bottom.y <= area.right_bottom.y
end

function Detection.is_vehicle_stopped(vehicle)
  return math.abs(vehicle.speed) < Detection.STOP_SPEED_EPSILON
end

function Detection.find_candidate_vehicle(entity)
  local area = Geometry.get_vehicle_area(entity)
  local vehicles = entity.surface.find_entities_filtered{
    area = area, type = {'car', 'spider-vehicle'}, force = entity.force
  }
  local candidate
  for _, vehicle in pairs(vehicles) do
    if Detection.is_supported_vehicle(vehicle) and Detection.is_fully_inside_area(vehicle, area) then
      if candidate then return nil, 'multiple' end
      candidate = vehicle
    end
  end
  if not candidate then return nil, 'waiting' end
  if not Detection.is_vehicle_stopped(candidate) then return nil, 'moving' end
  return candidate, 'ready'
end

return Detection

local Geometry = {}

function Geometry.get_footprint(entity)
  local p = entity.position
  return {left_top = {x = p.x - 4, y = p.y - 4}, right_bottom = {x = p.x + 4, y = p.y + 4}}
end

function Geometry.get_vehicle_area(entity)
  local area = Geometry.get_footprint(entity)
  local direction = entity.direction
  if direction == defines.direction.north then
    area.left_top.y = area.left_top.y + 1
  elseif direction == defines.direction.east then
    area.right_bottom.x = area.right_bottom.x - 1
  elseif direction == defines.direction.south then
    area.right_bottom.y = area.right_bottom.y - 1
  elseif direction == defines.direction.west then
    area.left_top.x = area.left_top.x + 1
  else
    error('Unsupported dock direction: ' .. tostring(direction))
  end
  return area
end

function Geometry.get_dock_area(entity)
  local area = Geometry.get_footprint(entity)
  local direction = entity.direction
  if direction == defines.direction.north then
    area.right_bottom.y = area.left_top.y + 1
  elseif direction == defines.direction.east then
    area.left_top.x = area.right_bottom.x - 1
  elseif direction == defines.direction.south then
    area.left_top.y = area.right_bottom.y - 1
  elseif direction == defines.direction.west then
    area.right_bottom.x = area.left_top.x + 1
  else
    error('Unsupported dock direction: ' .. tostring(direction))
  end
  return area
end

function Geometry.get_dock_position(entity)
  local area = Geometry.get_dock_area(entity)
  return {x = (area.left_top.x + area.right_bottom.x) / 2,
          y = (area.left_top.y + area.right_bottom.y) / 2}
end

function Geometry.get_status_light_offset(entity)
  local position = Geometry.get_dock_position(entity)
  return {x = position.x - entity.position.x, y = position.y - entity.position.y}
end

return Geometry

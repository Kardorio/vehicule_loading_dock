package.path = './?.lua;' .. package.path

defines = {direction = {north = 0, east = 4, south = 8, west = 12}}
local Indicator = require('scripts.indicator')
local Geometry = require('scripts.geometry')
local created = 0
local function object(parameters)
  created = created + 1
  parameters.valid = true
  parameters.destroy = function() parameters.valid = false end
  return parameters
end
rendering = {draw_circle = object, draw_light = object}
local dock = {entity = {valid = true, position = {x = 0, y = 0}, direction = defines.direction.east,
  surface = {}}, status = 'waiting'}
Indicator.update(dock)
assert(created == 3)
assert(dock.indicator.bulb.color.r > dock.indicator.bulb.color.g and dock.indicator.glow.visible)
local original = dock.indicator.bulb
for _, status in ipairs{'ready', 'multiple', 'moving', 'waiting', 'no-power'} do
  dock.status = status
  Indicator.update(dock)
  assert(created == 3 and dock.indicator.bulb == original)
  if status == 'ready' then
    assert(original.color.g > original.color.r and dock.indicator.glow.visible)
  elseif status == 'no-power' then
    assert(not dock.indicator.glow.visible and original.color.r < 0.2 and original.color.g < 0.2)
  else
    assert(original.color.r > original.color.g and dock.indicator.glow.visible)
  end
end
for _, direction in ipairs{0, 4, 8, 12} do
  dock.entity.direction = direction
  Indicator.update(dock)
  local offset = original.target.offset
  local strip = Geometry.get_dock_area(dock.entity)
  assert(offset.x >= strip.left_top.x and offset.x <= strip.right_bottom.x)
  assert(offset.y >= strip.left_top.y and offset.y <= strip.right_bottom.y)
end
original.valid = false
Indicator.update(dock)
assert(created == 4 and dock.indicator.bulb.valid)
local objects = dock.indicator
Indicator.destroy(dock)
assert(dock.indicator == nil)
for _, value in pairs(objects) do assert(not value.valid) end
Indicator.destroy(dock)
print('PASS 002 voyant : états, rotations, réutilisation, réparation et retrait')

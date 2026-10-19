package.path = './?.lua;' .. package.path

defines = {direction = {north = 0, east = 4, south = 8, west = 12}, inventory = {car_trunk = 1, spider_trunk = 2}}
prototypes = {item = {iron = {}, copper = {}, tagged = {}}, quality = {normal = {name = 'normal', level = 0}, rare = {name = 'rare', level = 2}}}

local Geometry = require('scripts.geometry')
local Detection = require('scripts.detection')
local Transfer = require('scripts.transfer')
local Configuration = require('scripts.configuration')
local cases = 0
local function test(name, fn)
  fn()
  cases = cases + 1
  print('PASS ' .. name)
end
local function equal(actual, expected)
  assert(actual == expected, tostring(actual) .. ' != ' .. tostring(expected))
end
local function stack(name, count, quality, metadata)
  local result = {valid_for_read = name ~= nil, name = name, count = count or 0,
    quality = prototypes.quality[quality or 'normal'], metadata = metadata, limit = 100}
  result.can_set_stack = function(candidate)
    return candidate.count <= result.limit
  end
  result.transfer_stack = function(source)
    if result.valid_for_read and (result.name ~= source.name or result.quality ~= source.quality or result.metadata ~= source.metadata) then return false end
    local amount = math.min(source.count, result.limit - result.count)
    if amount > 0 then
      result.name, result.quality, result.metadata = source.name, source.quality, source.metadata
      result.count = result.count + amount
      result.valid_for_read = true
      source.count = source.count - amount
      source.valid_for_read = source.count > 0
    end
    return not source.valid_for_read
  end
  return result
end
local function inventory(slots, bar, filters)
  slots.valid = true
  slots.supports_bar = function() return bar ~= nil end
  slots.get_bar = function() return bar end
  slots.supports_filters = function() return filters ~= nil end
  slots.get_filter = function(index) return filters[index] end
  return slots
end
local function dock(direction)
  return {position = {x = 10, y = -5}, direction = direction or defines.direction.east, force = 'player'}
end
local function vehicle(kind, box, speed)
  local trunk = inventory({stack()})
  return {valid = true, type = kind or 'car', bounding_box = box or {left_top = {x = 9, y = -6}, right_bottom = {x = 11, y = -4}},
    speed = speed or 0, get_inventory = function(index)
      if kind == 'spider-vehicle' then equal(index, defines.inventory.spider_trunk)
      else equal(index, defines.inventory.car_trunk) end
      return trunk
    end}
end

test('001-AC1 quatre orientations et partition exacte', function()
  local expected = {
    [0] = {6, -8, 14, -1, 10, -8.5}, [4] = {6, -9, 13, -1, 13.5, -5},
    [8] = {6, -9, 14, -2, 10, -1.5}, [12] = {7, -9, 14, -1, 6.5, -5}
  }
  for direction, values in pairs(expected) do
    local entity = dock(direction)
    local full = Geometry.get_footprint(entity)
    equal(full.right_bottom.x - full.left_top.x, 8)
    equal(full.right_bottom.y - full.left_top.y, 8)
    local area, physical, position = Geometry.get_vehicle_area(entity), Geometry.get_dock_area(entity), Geometry.get_dock_position(entity)
    equal(area.left_top.x, values[1]); equal(area.left_top.y, values[2])
    equal(area.right_bottom.x, values[3]); equal(area.right_bottom.y, values[4])
    equal(position.x, values[5]); equal(position.y, values[6])
    equal((area.right_bottom.x - area.left_top.x) * (area.right_bottom.y - area.left_top.y), 56)
    equal((physical.right_bottom.x - physical.left_top.x) * (physical.right_bottom.y - physical.left_top.y), 8)
  end
end)

test('001-AC2 bounding box intégrale, bords inclus et vitesse stricte', function()
  local area = Geometry.get_vehicle_area(dock())
  local car = vehicle('car', area)
  assert(Detection.is_fully_inside_area(car, area))
  car.bounding_box = {left_top = {x = area.left_top.x - 0.001, y = area.left_top.y}, right_bottom = area.right_bottom}
  assert(not Detection.is_fully_inside_area(car, area))
  for _, speed in ipairs({0, -0.0009, 0.0009}) do car.speed = speed; assert(Detection.is_vehicle_stopped(car)) end
  for _, speed in ipairs({0.001, -0.001, 0.1}) do car.speed = speed; assert(not Detection.is_vehicle_stopped(car)) end
end)

test('001-AC2 types compatibles, coffres et requête locale de même force', function()
  assert(Detection.is_supported_vehicle(vehicle('car')))
  assert(Detection.is_supported_vehicle(vehicle('spider-vehicle')))
  assert(not Detection.is_supported_vehicle({valid = true, type = 'cargo-wagon'}))
  assert(not Detection.is_supported_vehicle({valid = false}))
  assert(not Detection.is_supported_vehicle({valid = true, type = 'car', get_inventory = function() return nil end}))
  local entity, car = dock(), vehicle('car')
  entity.surface = {find_entities_filtered = function(query)
    equal(query.force, 'player'); equal(query.type[1], 'car'); equal(query.type[2], 'spider-vehicle')
    equal(query.area.right_bottom.x, 13)
    return {car}
  end}
  local found, status = Detection.find_candidate_vehicle(entity)
  equal(found, car); equal(status, 'ready')
end)

test('001-AC3 ambiguïté incluant un véhicule mobile et oubli', function()
  local entity, cars = dock(), {vehicle('car'), vehicle('car', nil, 1)}
  entity.surface = {find_entities_filtered = function() return cars end}
  local candidate, status = Detection.find_candidate_vehicle(entity)
  equal(candidate, nil); equal(status, 'multiple')
  cars = {cars[2]}
  candidate, status = Detection.find_candidate_vehicle(entity)
  equal(candidate, nil); equal(status, 'moving')
  cars[1].bounding_box.left_top.x = -100
  candidate, status = Detection.find_candidate_vehicle(entity)
  equal(candidate, nil); equal(status, 'waiting')
  cars = {}
  candidate, status = Detection.find_candidate_vehicle(entity)
  equal(candidate, nil); equal(status, 'waiting')
end)

test('001-AC5 filtres indépendants, index et validation', function()
  local config = Configuration.normalize({load_filters = {[2] = 'iron', [10] = 'tagged', [11] = 'copper'}, unload_filters = {[2] = 'iron', [3] = 'unknown', [4] = {name = 'iron'}}})
  equal(config.load_filters[1], nil); equal(config.load_filters[2], 'iron')
  equal(config.load_filters[10], 'tagged'); equal(config.load_filters[11], nil)
  equal(config.unload_filters[2], 'iron'); equal(config.unload_filters[3], nil); equal(config.unload_filters[4], nil)
  local copy = Configuration.serialize(config)
  copy.load_filters[2] = 'copper'
  equal(config.load_filters[2], 'iron')
  equal(Configuration.normalize(false).load_filters[1], nil)
end)

test('001-AC6 transfert partiel sans perte ni métadonnée effacée', function()
  local metadata = {label = 'unique', ammo = 7, durability = 0.25}
  local source = inventory({stack('tagged', 170, 'rare', metadata)})
  local target = inventory({stack('tagged', 80, 'rare', metadata)})
  equal(Transfer.transfer_item(source, target, 'tagged'), 20)
  equal(source[1].count, 150); equal(target[1].count, 100)
  equal(source[1].metadata, metadata); equal(target[1].metadata, metadata)
  equal(target[1].quality.name, 'rare')
  target[1] = stack()
  equal(Transfer.transfer_item(source, target, 'tagged'), 100)
  equal(source[1].count, 50); equal(target[1].metadata, metadata)
  target[1] = stack()
  equal(Transfer.transfer_item(source, target, 'tagged'), 50)
  equal(source[1].valid_for_read, false); equal(target[1].metadata, metadata)
end)

test('001-AC6 piles incompatibles, remplissage avant slot vide', function()
  local source = inventory({stack('iron', 40)})
  local target = inventory({stack(), stack('iron', 80), stack('iron', 20, 'rare')})
  equal(Transfer.transfer_item(source, target, 'iron'), 40)
  equal(target[2].count, 100); equal(target[1].count, 20); equal(target[3].count, 20)
  local tagged = inventory({stack('tagged', 1, 'normal', {a = 1})})
  local other = inventory({stack('tagged', 1, 'normal', {a = 2})})
  equal(Transfer.transfer_item(tagged, other, 'tagged'), 0)
  equal(tagged[1].count, 1)
end)

test('001-AC6 barre, filtres de nom et qualité', function()
  local source = inventory({stack('iron', 30, 'rare')})
  local target = inventory({stack(), stack(), stack()}, 3, {[1] = {name = 'copper'}, [2] = {name = 'iron', quality = 'rare', comparator = '='}})
  equal(Transfer.transfer_item(source, target, 'iron'), 30)
  equal(target[1].valid_for_read, false); equal(target[2].count, 30); equal(target[3].valid_for_read, false)
  source = inventory({stack('iron', 30, 'rare')})
  target = inventory({stack()}, 1)
  equal(Transfer.transfer_item(source, target, 'iron'), 0)
  target = inventory({stack()}, nil, {[1] = {name = 'iron', quality = 'normal', comparator = '>'}})
  equal(Transfer.transfer_item(source, target, 'iron'), 30)
  source = inventory({stack('iron', 30, 'rare')})
  target = inventory({stack()}, nil, {[1] = 'iron'})
  equal(Transfer.transfer_item(source, target, 'iron'), 0)
end)

test('001-AC6 déchargement avant chargement et filtres creux', function()
  local dock_inventory = inventory({stack('copper', 100), stack()})
  local vehicle_inventory = inventory({stack('iron', 100)})
  equal(Transfer.run(dock_inventory, vehicle_inventory, {load_filters = {[10] = 'copper'}, unload_filters = {[5] = 'iron'}}), 200)
  equal(vehicle_inventory[1].name, 'copper'); equal(vehicle_inventory[1].count, 100)
  equal(dock_inventory[2].name, 'iron'); equal(dock_inventory[2].count, 100)
end)

test('001-AC6 même filtre dans les deux sens et destination pleine', function()
  local dock_inventory = inventory({stack()})
  local vehicle_inventory = inventory({stack('iron', 10)})
  equal(Transfer.run(dock_inventory, vehicle_inventory, {load_filters = {'iron'}, unload_filters = {'iron'}}), 20)
  equal(vehicle_inventory[1].count, 10); equal(dock_inventory[1].valid_for_read, false)
  local full = inventory({stack('copper', 100)})
  equal(Transfer.transfer_item(vehicle_inventory, full, 'iron'), 0)
  equal(vehicle_inventory[1].count, 10)
end)

print(tostring(cases) .. ' tests core réussis')

-- 001-AC7: Factorio converts sparse numeric tag keys to strings after serialization.
local roundtrip = Configuration.normalize {load_filters = {["10"] = "iron"}}
assert(roundtrip.load_filters[10] == "iron")
print("PASS 001-AC7 filtres creux après sérialisation des tags")

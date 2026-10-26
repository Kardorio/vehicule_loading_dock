package.path = './?.lua;' .. package.path

prototypes = {item = {iron = {}, copper = {}}, quality = {normal = {}, rare = {}}}
local Inventory = require('scripts.inventory')
local filters, bar = {}, 101
local slots = {}
for index = 1, 100 do slots[index] = {} end
slots.supports_filters = function() return true end
slots.get_filter = function(index) return filters[index] end
slots.set_filter = function(index, filter) filters[index] = filter end
slots.get_bar = function() return bar end
slots.set_bar = function(value) bar = value end

Inventory.apply(slots, {bar = 4, filters = {
  ['1'] = {name = 'iron', quality = 'rare', comparator = '≥'}, ['100'] = 'copper',
  ['99'] = {quality = 'rare', comparator = '≥'},
}})
assert(bar == 4 and filters[1].quality == 'rare' and filters[1].comparator == '≥')
assert(filters[100].name == 'copper' and not filters[2])
local snapshot = Inventory.serialize(slots)
assert(snapshot.bar == 4 and snapshot.filters[100].name == 'copper')
assert(snapshot.filters[99].name == nil and snapshot.filters[99].quality == 'rare')
Inventory.apply(slots, {bar = 101, filters = {}})
assert(not filters[1] and not filters[100] and bar == 101)
Inventory.apply(slots, snapshot)
assert(filters[1].name == 'iron' and filters[100].name == 'copper' and bar == 4)
assert(filters[99].name == nil and filters[99].quality == 'rare' and filters[99].comparator == '≥')
print('PASS 006-AC5 sparse stock filters survive serialized blueprint keys')

for _, value in ipairs({false, 'bad', 7}) do Inventory.apply(slots, value) end
Inventory.apply(slots, {bar = 102, filters = {
  [1] = {name = 'removed-mod-item'}, [2] = {name = 'iron', quality = 'removed-quality'},
  [3] = {name = 'iron', comparator = 'invalid'}, [4] = false,
}})
assert(bar == 4 and not next(filters))
Inventory.apply(slots, {bar = 1.5})
assert(bar == 4)
Inventory.apply(slots, {bar = 1})
assert(bar == 1)
print('PASS 006-AC5 invalid or obsolete blueprint stock settings are ignored safely')

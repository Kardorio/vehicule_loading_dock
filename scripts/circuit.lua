local C = require("scripts.constants")
local Circuit = {}

function Circuit.destroy(dock)
  if dock.circuit_output and dock.circuit_output.valid then dock.circuit_output.destroy() end
  dock.circuit_output = nil
end

function Circuit.update(dock, vehicle)
  local entity = dock.entity
  local output = dock.circuit_output
  if output and output.valid and output.surface ~= entity.surface then
    Circuit.destroy(dock)
    output = nil
  end
  if not output or not output.valid then
    output = entity.surface.create_entity {name = C.circuit_name, position = entity.position,
      force = entity.force, create_build_effect_smoke = false}
    output.destructible = false
    output.minable_flag = false
    output.rotatable = false
    dock.circuit_output = output
  end
  if output.position.x ~= entity.position.x or output.position.y ~= entity.position.y then
    output.teleport(entity.position)
  end
  output.force = entity.force
  for _, id in ipairs {defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    output.get_wire_connector(id, true).connect_to(entity.get_wire_connector(id, true),
      false, defines.wire_origin.script)
  end
  local filters = {}
  for _, stack in pairs(dock.inventory_entity.get_inventory(defines.inventory.chest).get_contents()) do
    filters[#filters + 1] = {value = {type = "item", name = stack.name,
      quality = stack.quality or "normal", comparator = "="}, min = stack.count}
  end
  if vehicle then
    filters[#filters + 1] = {value = {type = "virtual", name = C.parked_signal,
      quality = "normal", comparator = "="}, min = 1}
  end
  local behavior = output.get_or_create_control_behavior()
  local section = behavior.get_section(1) or behavior.add_section()
  section.filters = filters
end

return Circuit

local Geometry = require("scripts.geometry")
local Indicator = {}

local OFF = {r = 0.12, g = 0.10, b = 0.06, a = 1}
local WAITING = {r = 1, g = 0.42, b = 0.03, a = 1}
local READY = {r = 0.12, g = 1, b = 0.20, a = 1}

function Indicator.destroy(dock)
  for _, object in pairs(dock.indicator or {}) do
    if object.valid then object.destroy() end
  end
  dock.indicator = nil
end

function Indicator.update(dock)
  local entity = dock.entity
  if not entity or not entity.valid then
    Indicator.destroy(dock)
    return
  end
  local target = {entity = entity, offset = Geometry.get_status_light_offset(entity)}
  local powered = dock.status ~= "no-power"
  local color = powered and (dock.status == "ready" and READY or WAITING) or OFF
  if dock.indicator and (not dock.indicator.housing or not dock.indicator.housing.valid) then
    Indicator.destroy(dock)
  end
  local indicator = dock.indicator or {}
  dock.indicator = indicator
  if not indicator.housing or not indicator.housing.valid then
    indicator.housing = rendering.draw_circle {
      color = {r = 0.055, g = 0.065, b = 0.075, a = 1}, radius = 0.28,
      filled = true, target = target, surface = entity.surface,
    }
  end
  if not indicator.bulb or not indicator.bulb.valid then
    indicator.bulb = rendering.draw_circle {
      color = color, radius = 0.19, filled = true, target = target, surface = entity.surface,
    }
  end
  if not indicator.glow or not indicator.glow.valid then
    indicator.glow = rendering.draw_light {
      sprite = "utility/light_small", scale = 0.7, intensity = 0.65, minimum_darkness = 0.2,
      color = color, visible = powered, target = target, surface = entity.surface,
    }
  end
  indicator.housing.target = target
  indicator.bulb.target = target
  indicator.glow.target = target
  indicator.bulb.color = color
  indicator.glow.color = color
  indicator.glow.visible = powered
end

return Indicator

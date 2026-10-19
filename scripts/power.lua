local C = require("scripts.constants")
local Power = {}

function Power.is_powered(entity)
  return entity.valid and entity.is_connected_to_electric_network()
    and entity.energy >= C.energy_per_check
end

return Power

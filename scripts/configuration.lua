local Constants = require('scripts.constants')
local Configuration = {MAX_FILTERS = Constants.filter_count}

function Configuration.empty()
  return {load_filters = {}, unload_filters = {}}
end

function Configuration.normalize(config)
  local result = Configuration.empty()
  if type(config) ~= 'table' then return result end
  for _, key in ipairs({'load_filters', 'unload_filters'}) do
    local filters = config[key]
    if type(filters) == 'table' then
      for index = 1, Configuration.MAX_FILTERS do
        local name = filters[index] or filters[tostring(index)]
        if type(name) == 'string' and name ~= '' and
            (not prototypes or not prototypes.item or prototypes.item[name]) then
          result[key][index] = name
        end
      end
    end
  end
  return result
end

function Configuration.serialize(config)
  return Configuration.normalize(config)
end

return Configuration

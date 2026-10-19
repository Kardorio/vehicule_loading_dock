local C = require("scripts.constants")
local Configuration = require("scripts.configuration")
local Gui = {}
local frame_name = "vld_configuration"

function Gui.close(player)
  local frame = player.gui.relative[frame_name]
  if frame then frame.destroy() end
  storage.open_docks[player.index] = nil
end

function Gui.open(player, dock)
  Gui.close(player)
  if not dock or not dock.entity.valid or not dock.inventory_entity.valid
    or player.force ~= dock.entity.force then return end
  if player.opened ~= dock.inventory_entity then player.opened = dock.inventory_entity end
  Gui.close(player)
  storage.open_docks[player.index] = dock.entity.unit_number
  local frame = player.gui.relative.add {
    type = "frame", name = frame_name, direction = "vertical",
    caption = {"vld.title"},
    anchor = {gui = defines.relative_gui_type.container_gui,
      position = defines.relative_gui_position.right},
  }
  frame.style.padding = 12
  frame.add {type = "label", name = "status", caption = {"vld.status-" .. (dock.status or "waiting")}}
  for _, mode in ipairs {"load", "unload"} do
    frame.add {type = "label", caption = {"vld." .. mode}, style = "heading_2_label"}
    local grid = frame.add {type = "table", name = mode, column_count = 5}
    for i = 1, C.filter_count do
      grid.add {
        type = "choose-elem-button", name = "filter_" .. i, elem_type = "item",
        item = dock.configuration[mode .. "_filters"][i],
        tags = {vld_mode = mode, vld_index = i},
      }
    end
  end
  local help = frame.add {type = "label", caption = {"vld.help"}}
  help.style.single_line = false
  help.style.maximal_width = 230
end

function Gui.refresh(dock, filters)
  for player_index, id in pairs(storage.open_docks) do
    if id == dock.entity.unit_number then
      local player = game.get_player(player_index)
      if player and player.valid then
        local frame = player.gui.relative[frame_name]
        if player.force ~= dock.entity.force or not frame then
          Gui.close(player)
        else
          frame.status.caption = {"vld.status-" .. (dock.status or "waiting")}
          if filters then
            for _, mode in ipairs {"load", "unload"} do
              for i = 1, C.filter_count do
                frame[mode]["filter_" .. i].elem_value = dock.configuration[mode .. "_filters"][i]
              end
            end
          end
        end
      end
    end
  end
end

function Gui.on_opened(event)
  local entity = event.entity
  if not entity or not entity.valid then return end
  local id = entity.name == C.name and entity.unit_number
    or storage.inventory_owners[entity.unit_number]
  if id and storage.docks[id] then Gui.open(game.get_player(event.player_index), storage.docks[id]) end
end

function Gui.on_closed(event)
  if event.entity and event.entity.valid and event.entity.name == C.inventory_name then
    Gui.close(game.get_player(event.player_index))
  end
end

function Gui.on_changed(event)
  local element = event.element
  if not element or not element.valid then return end
  local tags = element.tags
  if not tags.vld_mode then return end
  local id = storage.open_docks[event.player_index]
  local dock = id and storage.docks[id]
  local player = game.get_player(event.player_index)
  if not dock or not dock.entity.valid or dock.entity.force ~= player.force then
    Gui.close(player)
    return
  end
  if (tags.vld_mode ~= "load" and tags.vld_mode ~= "unload")
    or tags.vld_index < 1 or tags.vld_index > C.filter_count then return end
  dock.configuration[tags.vld_mode .. "_filters"][tags.vld_index] = element.elem_value
  dock.configuration = Configuration.normalize(dock.configuration)
  Gui.refresh(dock, true)
end

return Gui

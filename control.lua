local C = require("scripts.constants")
local Docks = require("scripts.docks")
local Gui = require("scripts.gui")
local Summary = require("scripts.summary")

local function initialize()
  Docks.initialize()
  Summary.initialize()
end

script.on_init(initialize)
script.on_configuration_changed(initialize)
script.on_nth_tick(C.check_interval, function()
  Docks.tick()
  Summary.refresh_all()
end)
script.on_event(defines.events.on_tick, Summary.on_tick)
script.on_event({defines.events.on_player_driving_changed_state,
  defines.events.on_player_controller_changed, defines.events.on_player_joined_game}, Summary.on_player_changed)
script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity,
  defines.events.script_raised_built, defines.events.script_raised_revive}, Docks.on_built)
script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, Docks.on_mined)
script.on_event({defines.events.on_entity_died, defines.events.script_raised_destroy}, Docks.on_removed)
script.on_event(defines.events.on_object_destroyed, Docks.on_destroyed)
script.on_event({defines.events.on_player_rotated_entity, defines.events.on_player_flipped_entity,
  defines.events.script_raised_teleported}, Docks.on_rotated)
script.on_event(defines.events.on_entity_cloned, Docks.on_cloned)
script.on_event(defines.events.on_player_setup_blueprint, Docks.on_blueprint)
script.on_event(defines.events.on_gui_opened, Gui.on_opened)
script.on_event(defines.events.on_gui_closed, Gui.on_closed)
script.on_event(defines.events.on_gui_elem_changed, Gui.on_changed)
script.on_event({defines.events.on_player_left_game, defines.events.on_player_died,
  defines.events.on_player_changed_force, defines.events.on_player_changed_surface}, function(event)
  local player = game.get_player(event.player_index)
  if player then
    Gui.close(player)
    Summary.close(player)
  end
end)

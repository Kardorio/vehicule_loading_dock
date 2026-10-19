local function element(spec,parent)
  local e={valid=true,style={},children={}}
  for k,v in pairs(spec or {}) do if k~='style' then e[k]=v end end
  e.add=function(s)
    local c=element(s,e)
    e.children[#e.children+1]=c
    if c.name then e[c.name]=c end
    c.elem_value=s.item
    return c
  end
  e.destroy=function()
    e.valid=false
    if parent and e.name then parent[e.name]=nil end
  end
  return e
end
local force={name='player'}
local chest={valid=true,name='vld-inventory',unit_number=3}
local player={index=1,force=force,valid=true,gui={relative=element()}}
local dock={entity={valid=true,unit_number=1,force=force},inventory_entity=chest,
  configuration={load_filters={[10]='iron-plate'},unload_filters={'coal'}},status='waiting'}
defines={relative_gui_type={container_gui=1},relative_gui_position={right=2}}
prototypes={item={['iron-plate']={},coal={}}}
storage={open_docks={},docks={[1]=dock},inventory_owners={[3]=1}}
game={get_player=function()return player end}
local Gui=require('scripts.gui')
-- 001-AC5: both independent grids retain sparse settings and synchronize viewers.
Gui.open(player,dock)
local frame=player.gui.relative.vld_configuration
assert(player.opened==chest and #frame.load.children==10 and #frame.unload.children==10)
assert(frame.load.filter_10.elem_value=='iron-plate' and frame.unload.filter_1.elem_value=='coal')
local input=frame.load.filter_1
input.elem_value='coal'
Gui.on_changed {player_index=1,element=input}
assert(dock.configuration.load_filters[1]=='coal' and dock.configuration.unload_filters[1]=='coal')
input.elem_value=nil
Gui.on_changed {player_index=1,element=input}
assert(not dock.configuration.load_filters[1] and dock.configuration.load_filters[10]=='iron-plate')
dock.status='multiple';Gui.refresh(dock)
assert(frame.status.caption[1]=='vld.status-multiple')
-- 001-AC7: closing or losing force access clears stale state.
Gui.on_closed {player_index=1,entity=chest}
assert(not storage.open_docks[1] and not player.gui.relative.vld_configuration)
Gui.open(player,dock)
player.force={name='other'}
Gui.refresh(dock)
assert(not storage.open_docks[1] and not player.gui.relative.vld_configuration)
print('PASS 001-AC5/AC7 interface : 20 filtres, édition, synchronisation et fermeture')

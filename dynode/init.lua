dynode = {}

minetest.register_entity("dynode:appearance", {
    initial_properties = {
        visual = "cube",
        textures = {"unknown_node.png",
                    "unknown_node.png",
                    "unknown_node.png",
                    "unknown_node.png",
                    "unknown_node.png",
                    "unknown_node.png"},
        pointable = false,
    },
    on_activate = function(self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            self.dynode_data = minetest.parse_json(staticdata)
        end
    end,
    get_staticdata = function(self)
        local json = minetest.write_json(self.dynode_data)
        if json then
            return json
        end
        return ""
    end
})

function dynode.setup_entity(pos)
    local meta = minetest.get_meta(pos)
    local entity
    if meta then
        local entity_data = meta:get("dynode:appearance_props")
        if entity_data then
            local datatable = {}
            datatable.attach_pos = pos
            local datajson = minetest.write_json(datatable)
            if datajson then
                entity = minetest.add_entity(pos, "dynode:appearance", datajson)
                if entity then
                    local props = minetest.parse_json(entity_data)
                    if props then
                        if props._pointable_override then
                            props.pointable = props._pointable_override
                            props._pointable_override = nil
                        else
                            props.pointable = false
                        end
                    end
                    local prop_extra = props._extra
                    if prop_extra then props._extra = nil end
                    entity:set_properties(props)
                end
            end
        else
            local datatable = {}
            datatable.attach_pos = pos
            local datajson = minetest.write_json(datatable)
            if datajson then
                entity = minetest.add_entity(pos, "dynode:appearance", datajson)
            end
        end
    end
    return entity
end

function dynode.cleanup_entity(pos)
    local minpos = {x = math.floor(pos.x), y = math.floor(pos.y), z = math.floor(pos.z)}
    local maxpos = vector.add(minpos, {x=0.9999, y=0.9999, z=0.9999})
    for obj in minetest.objects_in_area(minpos, maxpos) do
        local luaent = obj:get_luaentity()
        if luaent and luaent.name == "dynode:appearance" then
            luaent.object:remove()
        end
    end
end

-- You need to call this function every time the graphics for the node need to be updated,
-- otherwise it can't know without constantly ticking and causing lag
function dynode.refresh(pos)
    dynode.cleanup_entity(pos)
    dynode.setup_entity(pos)
end

function dynode.dynamic_node_on_construct(pos)
    dynode.setup_entity(pos)
end

function dynode.dynamic_node_after_place_node(pos, placer, itemstack, pointed_thing)
    local itemmeta = itemstack:get_meta()
    if itemmeta then
        local nodemeta = minetest.get_meta(pos)
        if nodemeta then
            local appearance_props = itemmeta:get("dynode:appearance_props")
            if appearance_props then
                nodemeta:set_string("dynode:appearance_props", appearance_props)
            end
        end
    end
    dynode.refresh(pos)
end

function dynode.dynamic_node_after_destruct(pos, oldnode)
    dynode.cleanup_entity(pos)
end

function dynode.register_dynamic_node(name, table)
    local _on_construct = table.on_construct
    local _after_place_node = table.after_place_node
    local _after_destruct = table.after_destruct

    table.on_construct = function(pos)
        dynode.dynamic_node_on_construct(pos)
        if _on_construct then
            _on_construct(pos)
        end
    end

    table.after_place_node = function(pos, placer, itemstack, pointed_thing)
        dynode.dynamic_node_after_place_node(pos, placer, itemstack, pointed_thing)
        if _after_place_node then
            _after_place_node(pos, placer, itemstack, pointed_thing)
        end
    end

    table.after_destruct = function(pos, oldnode)
        dynode.dynamic_node_after_destruct(pos, oldnode)
        if _after_destruct then
            _after_destruct(pos, oldnode)
        end
    end

    table.tiles = {"[fill:16x16:#00000000"}
    table.drawtype = "glasslike"
    table.inventory_image = "[fill:16x16:#FF0000"
    table.wield_image = "[fill:16x16:#FF0000"

    minetest.register_node(name, table)
end

dynode.register_dynamic_node("dynode:basic_custom", {
    description = "Custom Appearance Node",
    short_description = "Custom Appearance Node",
    groups = {oddly_breakable_by_hand = 1}
})
fruit_tree_framework = {}
fruit_tree_framework.registered_fruits = {}

local function get_fruit_pos(pos)
    local meta = minetest.get_meta(pos)
    if meta then
        local fruit = meta:get("fruit_tree_framework:type")
        -- If nil, return nil, so caller can do what they want
        return fruit
    end
end

local function get_fruit_meta(meta)
    local fruit = meta:get("fruit_tree_framework:type")
    -- If nil, return nil, so caller can do what they want
    return fruit
end

local function get_fruit_table(meta)
    local fruit = meta["fruit_tree_framework:type"]
    -- If nil, return nil, so caller can do what they want
    return fruit
end

function fruit_tree_framework.setup_common_metadata(pos, itemstack)
    local itemmeta = itemstack:get_meta()
    if itemmeta then
        local fruit = get_fruit_meta(itemmeta)
        if fruit then
            local nodemeta = minetest.get_meta(pos)
            if nodemeta then
                nodemeta:set_string("fruit_tree_framework:type", fruit)
                local fruitdef = fruit_tree_framework.registered_fruits[fruit];
                if fruitdef then
                    local fruit_name = fruitdef.name
                    if fruit_name then
                        nodemeta:set_string("infotext", fruit_name)
                    end
                elseif string.sub(fruit, 1, 1) == "~" then
                    -- This is an itemstring sapling
                    local itemstring = string.sub(fruit, 2, -1)
                    local shortdesc = ItemStack(itemstring):get_description()
                    nodemeta:set_string("infotext", shortdesc)
                end
            end
        end
    end
end

function fruit_tree_framework.preserve_common_metadata(oldmeta, drops, itemname)
    local fruit = get_fruit_table(oldmeta);
    local itemmeta
    if fruit then
        for i,drop in ipairs(drops) do
            if drop:get_name() == itemname then
                itemmeta = drop:get_meta()
                if itemmeta then
                    itemmeta:set_string("fruit_tree_framework:type", fruit)
                end
            end
        end
    end
    return itemmeta
end

function fruit_tree_framework.check_valid_spot(pos)
    for i=-2,2 do
        for j=1,5 do
            for k=-2,2 do
                local vec = pos:add({x = i, y = j, z = k})
                if minetest.get_node(pos).name ~= "air" then
                    return false
                end
            end
        end
    end
    return true
end

function fruit_tree_framework.grow_tree(pos, fruit)
    local fruit_color, log_color, name = nil, nil, nil
    local fruitdef = fruit_tree_framework.registered_fruits[fruit]
    if fruitdef then
        fruit_color = fruitdef.fruit_color
        log_color = fruitdef.log_color
        itemstring = fruitdef.itemstring
    end
    if fruit_color == nil then
        fruit_color = 1
    end
    if log_color == nil then
        log_color = 1
    end
    if fruitdef then
        local fruit_name = fruitdef.name
        if fruit_name then
            name = fruit_name
        end
    elseif string.sub(fruit, 1, 1) == "~" then
        -- This is an itemstring sapling
        local itemstring = string.sub(fruit, 2, -1)
        local shortdesc = ItemStack(itemstring):get_description()
        name = shortdesc
    end
    for i=-2,2 do
        for j=2,5 do
            for k=-2,2 do
                local newpos = pos:add({x=i, y=j, z=k})
                minetest.set_node(newpos, {name="fruit_tree_framework:leaves", param1=0, param2=fruit_color})
                local newmeta = minetest.get_meta(newpos)
                if newmeta then
                    newmeta:set_string("fruit_tree_framework:type", fruit)
                    newmeta:set_int("fruit_tree_framework:ready", 0)
                    newmeta:set_string("infotext", name .. " (Not Ready)")
                end
                local timer = minetest.get_node_timer(newpos)
                if timer then
                    timer:start(5)
                end
            end
        end
    end
    for i=0,4 do
        local newpos = pos:add({x=0,y=i,z=0})
        minetest.set_node(newpos, {name="fruit_tree_framework:log", param1=0, param2=log_color})
        local newmeta = minetest.get_meta(newpos)
        if newmeta then
            newmeta:set_string("fruit_tree_framework:type", fruit)
            newmeta:set_string("infotext", name)
        end
    end
end

function fruit_tree_framework.sapling_preserve_metadata(pos, oldnode, oldmeta, drops)
    local itemmeta = fruit_tree_framework.preserve_common_metadata(oldmeta, drops, "fruit_tree_framework:sapling")
    local fruit = get_fruit_table(oldmeta)
    local fruitdef = fruit_tree_framework.registered_fruits[fruit]
    if fruitdef and fruitdef.fruit_color then
        itemmeta:set_int("palette_index", fruitdef.fruit_color)
    end
end

function fruit_tree_framework.sapling_after_place_node(pos, placer, itemstack, pointed_thing)
    fruit_tree_framework.setup_common_metadata(pos, itemstack)
    local timer = minetest.get_node_timer(pos)
    if timer then
        timer:start(5)
    end
end

function fruit_tree_framework.sapling_on_timer(pos, elapsed)
    local fruit = get_fruit_pos(pos)
    if fruit then
        fruit_tree_framework.grow_tree(pos, fruit)
    end
end

minetest.register_node("fruit_tree_framework:sapling", {
    description = "Sapling",
    drawtype = "plantlike",
    visual_scale = 1.0,
    tiles = {{name = "fruit_tree_framework__sapling.png", color = "white"}},
    overlay_tiles = {{name = "fruit_tree_framework__sapling_overlay.png"}},
    palette = "fruit_tree_framework__fruit_palette.png",
    groups = {snappy = 2, dig_immediate = 3, flammable = 2, attached_node = 1, sapling = 1},
    paramtype = "light",
    paramtype2 = "color",
    diggable = true,
    sunlight_propagates = true,
    walkable = true,
    waving = 1,
    floodable = true,
    preserve_metadata = fruit_tree_framework.sapling_preserve_metadata,
    after_place_node = fruit_tree_framework.sapling_after_place_node,
    on_timer = fruit_tree_framework.sapling_on_timer
})

function fruit_tree_framework.log_preserve_metadata(pos, oldnode, oldmeta, drops)
    local itemmeta = fruit_tree_framework.preserve_common_metadata(oldmeta, drops, "fruit_tree_framework:log")
    local fruit = get_fruit_table(oldmeta)
    local fruitdef = fruit_tree_framework.registered_fruits[fruit]
    if fruitdef and fruitdef.log_color then
        itemmeta:set_int("palette_index", fruitdef.log_color)
    end
end

function fruit_tree_framework.log_after_place_node(pos, placer, itemstack, pointed_thing)
    fruit_tree_framework.setup_common_metadata(pos, itemstack)
end

minetest.register_node("fruit_tree_framework:log", {
    description = "Log",
    drawtype = "normal",
    tiles = {"fruit_tree_framework__log_top.png",
             "fruit_tree_framework__log_top.png",
             "fruit_tree_framework__log_side.png",
             "fruit_tree_framework__log_side.png",
             "fruit_tree_framework__log_side.png",
             "fruit_tree_framework__log_side.png"},
    groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
    palette = "fruit_tree_framework__log_palette.png",
    paramtype = "none",
    paramtype2 = "color",
    diggable = true,
    preserve_metadata = fruit_tree_framework.log_preserve_metadata,
    after_place_node = fruit_tree_framework.log_after_place_node
})

function fruit_tree_framework.leaves_preserve_metadata(pos, oldnode, oldmeta, drops)
    local itemmeta = fruit_tree_framework.preserve_common_metadata(oldmeta, drops, "fruit_tree_framework:leaves")
    local fruit = get_fruit_table(oldmeta)
    local fruitdef = fruit_tree_framework.registered_fruits[fruit]
    if fruitdef and fruitdef.fruit_color then
        itemmeta:set_int("palette_index", fruitdef.fruit_color)
    end
end

function fruit_tree_framework.leaves_after_place_node(pos, placer, itemstack, pointed_thing)
    fruit_tree_framework.setup_common_metadata(pos, itemstack)
    local meta = minetest.get_meta(pos)
    if meta then
        meta:set_int("fruit_tree_framework:ready", 0)
        meta:set_string("infotext", meta:get_string("infotext") .. " (Not Ready)")
    end
    local timer = minetest.get_node_timer(pos)
    if timer then
        timer:start(5)
    end
    local node = minetest.get_node(pos)
    node.param2 = 0
end

function fruit_tree_framework.leaves_on_timer(pos, elapsed)
    local meta = minetest.get_meta(pos)
    if meta and meta:get_int("fruit_tree_framework:ready") == 0 then
        meta:set_int("fruit_tree_framework:ready", 1)
        meta:set_string("infotext", string.gsub(meta:get_string("infotext"), "%(Not Ready%)", "") .. "(Ready)")
        local fruit = get_fruit_meta(meta)
        local node = minetest.get_node(pos)
        local fruit_def = fruit_tree_framework.registered_fruits
        if fruit_def and fruit_def.fruit_color then
            node.param2 = fruit_def.fruit_color
        end
    end
end

function fruit_tree_framework.leaves_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
    local meta = minetest.get_meta(pos)
    if meta then
        if meta:get_int("fruit_tree_framework:ready") == 1 then
            local inventory = clicker:get_inventory()
            if inventory then
                local fruit = get_fruit_pos(pos)
                local item = nil
                if fruit then
                    local fruitdef = fruit_tree_framework.registered_fruits[fruit]
                    if fruitdef then
                        item = ItemStack(fruitdef.itemstring)
                    elseif string.sub(fruit, 1, 1) == "~" then
                        -- Custom itemstring leaves
                        item = ItemStack(string.sub(fruit, 2, -1))
                    end
                end
                if item then
                    local leftover = inventory:add_item("main", item)
                    if leftover then
                        minetest.add_item(pos, leftover)
                    end
                end
            end
            meta:set_int("fruit_tree_framework:ready", 0)
            meta:set_string("infotext", string.gsub(meta:get_string("infotext"), "%(Ready%)", "") .. "(Not Ready)")
            local timer = minetest.get_node_timer(pos)
            if timer then
                timer:start(5)
            end
            node.param2 = 0
        end
    end
end

minetest.register_node("fruit_tree_framework:leaves", {
    description = "Leaves",
    drawtype = "normal",
    tiles = {{name = "fruit_tree_framework__leaves.png", color = "white"}},
    overlay_tiles = {{name = "fruit_tree_framework__leaves_overlay.png"}},
    palette = "fruit_tree_framework__fruit_palette.png",
    groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
    paramtype = "none",
    paramtype2 = "color",
    diggable = true,
    preserve_metadata = fruit_tree_framework.leaves_preserve_metadata,
    after_place_node = fruit_tree_framework.leaves_after_place_node,
    on_timer = fruit_tree_framework.leaves_on_timer,
    on_rightclick = fruit_tree_framework.leaves_on_rightclick
})

--[[
Registers a new fruit tree type, with the given name

table should be:
{
    fruit_color = n, -- n should be 0-255, index into the fruit palette table. The color will be rendered on saplings and leaves
    log_color = n, -- n should be 0-255, index into the log palette table. The color will be rendered on logs
    name = s, -- s should be a name for the fruit, which will be shown in tooltips
    itemstring = s -- s should be an itemstring for what can be picked off the leaves with right-click
}

recipegrid is optional. If present, it's a recipe grid for a shaped recipe to make the sapling

The metadata for logs, saplings, and leaves refers to the name given, but if there is no registered entry
with that name and the name starts with "~", the "~" is removed and the rest is used as an itemstring.
The colors will be color 1 in their respective palettes, and the name shown in tooltips will be the description of the item
generated by the itemstring.
]]
function fruit_tree_framework.register_fruit(name, table, recipegrid)
    fruit_tree_framework.registered_fruits[name] = table
    local resultitem = ItemStack("fruit_tree_framework:sapling")
    local meta = resultitem:get_meta()
    if meta then
        meta:set_string("fruit_tree_framework:type", name)
        meta:set_string("palette_index", table.fruit_color)
    end
    local resultstring = resultitem:to_string()
    if recipegrid then
        minetest.register_craft({
            type = "shaped",
            output = resultstring,
            recipe = recipegrid
        })
    end
end
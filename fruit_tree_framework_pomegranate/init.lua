minetest.register_craftitem("fruit_tree_framework_pomegranate:pomegranate", {
    description = "Pomegranate",
    short_description = "Pomegranate",
    groups = {},
    inventory_image = "fruit_tree_framework_pomegranate__pomegranate.png",
    stack_max = 99,
})

fruit_tree_framework.register_fruit(
    "fruit_tree_framework_pomegranate:pomegranate",
    {name="Pomegranate", itemstring="fruit_tree_framework_pomegranate:pomegranate 1", fruit_color=246, log_color=3},
    {{"fruit_tree_framework_pomegranate:pomegranate"}})
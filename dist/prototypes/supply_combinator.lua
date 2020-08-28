local tint = {g = 0.8}

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "TSM-Supply-Combinator"
entity.minable.result = entity.name
entity.icons = {{icon = entity.icon, icon_mipmaps = entity.icon_mipmaps, icon_size = entity.icon_size, tint = tint}}
entity.icon = nil
entity.item_slot_count = 2
entity.sprites.east.layers[1].tint = tint
entity.sprites.east.layers[1].hr_version.tint = tint
entity.sprites.north.layers[1].tint = tint
entity.sprites.north.layers[1].hr_version.tint = tint
entity.sprites.south.layers[1].tint = tint
entity.sprites.south.layers[1].hr_version.tint = tint
entity.sprites.west.layers[1].tint = tint
entity.sprites.west.layers[1].hr_version.tint = tint
data:extend({entity})

local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = "TSM-Supply-Combinator"
item.icons = {{icon = item.icon, icon_mipmaps = item.icon_mipmaps, icon_size = item.icon_size, tint = tint}}
item.icon = nil
item.place_result = item.name
item.subgroup = "transport"
item.order = "a[train-system]-cc[supply-combinator]"
data:extend({item})

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.name = "TSM-Supply-Combinator"
recipe.result = recipe.name
data:extend({recipe})

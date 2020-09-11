local path = "__TSM_Helper__/graphics/train-staion-counter"

local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.name = "train-staion-counter"
entity.minable.result = entity.name
entity.icon = path .. "/icons/train-staion-counter.png"
entity.icon_size = 64
entity.icon_mipmaps = 4
entity.item_slot_count = 2

entity.sprites.north.layers[1].filename = string.format("%s/entity/train-staion-counter.png", path)
entity.sprites.north.layers[1].hr_version.filename = string.format("%s/entity/hr-train-staion-counter.png", path)
entity.sprites.east.layers[1].filename = string.format("%s/entity/train-staion-counter.png", path)
entity.sprites.east.layers[1].hr_version.filename = string.format("%s/entity/hr-train-staion-counter.png", path)
entity.sprites.south.layers[1].filename = string.format("%s/entity/train-staion-counter.png", path)
entity.sprites.south.layers[1].hr_version.filename = string.format("%s/entity/hr-train-staion-counter.png", path)
entity.sprites.west.layers[1].filename = string.format("%s/entity/train-staion-counter.png", path)
entity.sprites.west.layers[1].hr_version.filename = string.format("%s/entity/hr-train-staion-counter.png", path)

data:extend({entity})

local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = "train-staion-counter"
item.icon = entity.icon
item.icon_size = entity.icon_size
item.icon_mipmaps = entity.icon_mipmaps
item.place_result = item.name
item.subgroup = "transport"
item.order = "a[train-system]-cc[supply-combinator]"
data:extend({item})

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.name = "train-staion-counter"
recipe.result = recipe.name
data:extend({recipe})

local technology = data.raw.technology

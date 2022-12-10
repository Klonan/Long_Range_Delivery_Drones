local overlay_size = 24
local stack_size = 16
local variation_count = 8
local make_delivery_particle = function(item)
  local layers = {}

  local base_size = item.icon_size
  for k, icon in pairs (item.icons or {{icon = item.icon, size = base_size}}) do
    local icon_size = icon.icon_size or base_size
    layers[k] =
    {
      filename = icon.icon,
      width = icon_size,
      height = icon_size,
      scale = (icon.scale or 1) * overlay_size / icon_size,
      tint = icon.tint,
      shift = icon.shift or {0, 0},
    }
  end
  local pictures = {}
  local shadows = {}

  for k = 1, (item.stack_size == 1 and 1) or variation_count do
    local result_layers = {}
    local stack_size = math.min(stack_size, item.stack_size)
    for k = 1, stack_size do
      local last = (k == stack_size)
      local shift = (last and {0,0}) or {0.5 * (math.random() - 0.5), 0.5 * math.random()}
      local scale = (last and 1) or 0.4 + 0.6 * math.random()
      for j, layer in pairs (layers) do
        local picture = util.copy(layer)
        picture.shift = {picture.shift[1] + shift[1], picture.shift[2] + shift[2]}
        picture.scale = picture.scale * scale
        table.insert(result_layers, picture)
      end
    end
    local shadow_layers = util.copy(result_layers)
    for k, layer in pairs (shadow_layers) do
      layer.draw_as_shadow = true
      layer.shift = {layer.shift[1] + 0.75, layer.shift[2] + 0.75}
    end
    pictures[k] = {layers = result_layers}
    shadows[k] = {layers = shadow_layers}
  end

  local delivery_particle =
  {
    type = "optimized-particle",
    name = "long-range-delivery-drone-delivery-particle-" .. item.name,
    movement_modifier = 1,
    movement_modifier_when_on_ground = 0,
    vertical_acceleration = 0,
    life_time = 240,
    regular_trigger_effect_frequency = 9999,
    render_layer = "projectile",
    render_layer_when_on_ground = "projectile",
    pictures = pictures,
    shadows = shadows,
  }
  data:extend({delivery_particle})
end

local item_types =
{
  "item",
  "item-with-entity-data",
  "item-with-inventory",
  "item-with-label",
  "item-with-tags",
  "tool",
  "ammo",
  "capsule",
  "gun",
  "repair-tool"
}

for k, item_type in pairs(item_types) do
  for k, item in pairs(data.raw[item_type] or {}) do
    make_delivery_particle(item)
  end
end

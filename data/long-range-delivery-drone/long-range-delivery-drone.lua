local depot =
{
  type = "logistic-container",
  name = "long-range-delivery-drone-depot",
  localised_name = {"long-range-delivery-drone-depot"},
  icon = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/depot-icon.png",
  icon_size = 64,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 1, result = "long-range-delivery-drone-depot"},
  max_health = 350,
  collision_box = {{-2.85, -2.85}, {2.85, 2.85}},
  selection_box = {{-3, -3}, {3, 3}},
  render_not_in_network_icon = false,
  landing_location_offset = {0, 2.5},
  scale_info_icons = true,
  use_exact_mode = true,
  inventory_type = "with_filters_and_bar",
  resistances =
  {
    {
      type = "fire",
      percent = 90
    },
    {
      type = "impact",
      percent = 60
    }
  },
  fast_replaceable_group = "container",
  inventory_size = 19,
  logistic_mode = "requester",
  scale_info_icons = false,
  open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
  close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
  opened_duration = 10,
  animation =
  {
    layers =
    {
      {
        filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/depot.png",
        width = 224,
        height = 224,
        frame_count = 1,
        shift = util.by_pixel(0, -2),
        scale = 1
      },
      {
        filename = "__base__/graphics/entity/artillery-turret/hr-artillery-turret-base-shadow.png",
        priority = "high",
        line_length = 1,
        width = 277,
        height = 149,
        frame_count = 1,
        direction_count = 1,
        shift = util.by_pixel(36, 12),
        draw_as_shadow = true,
        scale = 1
      }
    }
  },
  circuit_wire_connection_point =circuit_connector_definitions.create
  (
    universal_connector_template,
    {
      { variation = 26, main_offset = util.by_pixel(3, 64 + 5.5), shadow_offset = util.by_pixel(7.5, 64 + 7.5), show_shadow = true }
    }
  ).points,
  circuit_connector_sprites = circuit_connector_definitions.create
  (
    universal_connector_template,
    {
      { variation = 26, main_offset = util.by_pixel(3, 64 + 5.5), shadow_offset = util.by_pixel(7.5, 64 + 7.5), show_shadow = true }
    }
  ).sprites,
  circuit_wire_max_distance = 10,
  created_effect =
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      source_effects =
      {
        type = "script",
        effect_id = "long-range-delivery-drone-depot-created"
      }
    }
  }
}

local depot_item =
{
  type = "item",
  name = "long-range-delivery-drone-depot",
  icon = depot.icon,
  icon_size = depot.icon_size, icon_mipmaps = depot.icon_mipmaps,
  flags = {},
  subgroup = "logistic-network",
  order = "k[long-range-delivery-drone-depot]-a",
  place_result = "long-range-delivery-drone-depot",
  stack_size = 10
}

local depot_recipe =
{
  type = "recipe",
  name = "long-range-delivery-drone-depot",
  enabled = false,
  ingredients =
  {
    {"steel-chest", 20},
    {"electronic-circuit", 15},
    {"iron-gear-wheel", 10}
  },
  energy_required = 5,
  result = "long-range-delivery-drone-depot"
}

local request_depot =
{
  type = "logistic-container",
  name = "long-range-delivery-drone-request-depot",
  localised_name = {"long-range-delivery-drone-request-depot"},
  icon = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/request-depot-icon.png",
  icon_size = 64,
  flags = {"placeable-player", "player-creation"},
  minable = {mining_time = 1, result = "long-range-delivery-drone-request-depot"},
  max_health = 350,
  corpse = "requester-chest-remnants",
  dying_explosion = "requester-chest-explosion",
  collision_box = {{-0.85, -0.85}, {0.85, 0.85}},
  selection_box = {{-1, -1}, {1, 1}},
  render_not_in_network_icon = false,
  inventory_type = "with_filters_and_bar",
  resistances =
  {
    {
      type = "fire",
      percent = 90
    },
    {
      type = "impact",
      percent = 60
    }
  },
  fast_replaceable_group = "container",
  inventory_size = 69,
  logistic_mode = "buffer",
  open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.43 },
  close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.43 },
  opened_duration = 10,
  animation =
  {
    layers =
    {
      {
        filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/request-depot.png",
        priority = "extra-high",
        width = 128,
        height = 196,
        frame_count = 1,
        shift = util.by_pixel(0, -20),
        scale = 0.5
      },
      {
        filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/request-depot-shadow.png",
        priority = "extra-high",
        width = 173,
        height = 76,
        repeat_count = 1,
        shift = util.by_pixel(14, 12),
        draw_as_shadow = true,
        scale = 0.5,
      }
    }
  },
  circuit_wire_connection_point =circuit_connector_definitions.create
  (
    universal_connector_template,
    {
      { variation = 26, main_offset = util.by_pixel(3, 16 + 5.5), shadow_offset = util.by_pixel(7.5, 16 + 7.5), show_shadow = true }
    }
  ).points,
  circuit_connector_sprites = circuit_connector_definitions.create
  (
    universal_connector_template,
    {
      { variation = 26, main_offset = util.by_pixel(3, 16 + 5.5), shadow_offset = util.by_pixel(7.5, 16 + 7.5), show_shadow = true }
    }
  ).sprites,
  circuit_wire_max_distance = 10,
  created_effect =
  {
    type = "direct",
    action_delivery =
    {
      type = "instant",
      source_effects =
      {
        type = "script",
        effect_id = "long-range-delivery-drone-request-depot-created"
      }
    }
  }
}

local request_depot_item =
{
  type = "item",
  name = "long-range-delivery-drone-request-depot",
  icon = request_depot.icon,
  icon_size = request_depot.icon_size, icon_mipmaps = request_depot.icon_mipmaps,
  flags = {},
  subgroup = "logistic-network",
  order = "k[long-range-delivery-drone-request-depot]-b",
  place_result = "long-range-delivery-drone-request-depot",
  stack_size = 10
}

local request_depot_recipe =
{
  type = "recipe",
  name = "long-range-delivery-drone-request-depot",
  enabled = false,
  ingredients =
  {
    {"steel-chest", 1},
    {"electronic-circuit", 5}
  },
  result = "long-range-delivery-drone-request-depot"
}

local delivery_drone =
{
  type = "car",
  name = "long-range-delivery-drone",
  localised_name = {"long-range-delivery-drone"},
  icon = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/drone-item-icon.png",
  icon_size = 64,
  flags = {"placeable-neutral", "player-creation", "placeable-off-grid", "not-flammable"},
  --minable = {mining_time = 0.4, result = "car"},
  mined_sound = {filename = "__core__/sound/deconstruct-medium.ogg", volume = 0.8},
  max_health = 500,
  --corpse = "car-remnants",
  dying_explosion = "car-explosion",
  alert_icon_shift = util.by_pixel(0, -13),
  energy_per_hit_point = 1000000,
  collision_box = {{0, 0}, {0, 0}},
  collision_mask = {"colliding-with-tiles-only"},
  selection_box = {{-0.7, -1}, {0.7, 1}},
  effectivity = 1,
  braking_power = "200kW",
  energy_source =
  {
    type = "void"
  },
  consumption = "150kW",
  friction = 0.000000001,
  poop_light =
  {
    {
      type = "oriented",
      minimum_darkness = 0.3,
      picture =
      {
        filename = "__core__/graphics/light-cone.png",
        priority = "extra-high",
        flags = { "light" },
        scale = 2,
        width = 200,
        height = 200
      },
      shift = {-0.6, -14},
      size = 2,
      intensity = 0.6,
      color = {r = 0.92, g = 0.77, b = 0.3}
    },
    {
      type = "oriented",
      minimum_darkness = 0.3,
      picture =
      {
        filename = "__core__/graphics/light-cone.png",
        priority = "extra-high",
        flags = { "light" },
        scale = 2,
        width = 200,
        height = 200
      },
      shift = {0.6, -14},
      size = 2,
      intensity = 0.6,
      color = {r = 0.92, g = 0.77, b = 0.3}
    }
  },
  render_layer = "air-object",
  poop_light_animation =
  {
    filename = "__base__/graphics/entity/car/car-light.png",
    priority = "low",
    blend_mode = "additive",
    draw_as_glow = true,
    width = 102,
    height = 84,
    line_length = 8,
    direction_count = 64,
    shift = util.by_pixel(0 + 2, -8 + 3),
    repeat_count = 2
  },
  poop_animation =
  {
    layers =
    {
      {
        priority = "low",
        width = 102,
        height = 86,
        frame_count = 2,
        direction_count = 64,
        shift = {0, -0.1875},
        animation_speed = 8,
        max_advance = 0.2,
        stripes =
        {
          {
            filename = "__base__/graphics/entity/car/car-1.png",
            width_in_frames = 2,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-2.png",
            width_in_frames = 2,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-3.png",
            width_in_frames = 2,
            height_in_frames = 20
          }
        }
      },
      {
        priority = "low",
        width = 100,
        height = 75,
        frame_count = 2,
        apply_runtime_tint = true,
        direction_count = 64,
        max_advance = 0.2,
        line_length = 2,
        shift = {0, -0.171875},
        stripes = util.multiplystripes(2,
        {
          {
            filename = "__base__/graphics/entity/car/car-mask-1.png",
            width_in_frames = 1,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-mask-2.png",
            width_in_frames = 1,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-mask-3.png",
            width_in_frames = 1,
            height_in_frames = 20
          }
        })
      },
      {
        priority = "low",
        width = 114,
        height = 76,
        frame_count = 2,
        draw_as_shadow = true,
        direction_count = 64,
        shift = {0.28125, 0.25},
        max_advance = 0.2,
        stripes = util.multiplystripes(2,
        {
          {
            filename = "__base__/graphics/entity/car/car-shadow-1.png",
            width_in_frames = 1,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-shadow-2.png",
            width_in_frames = 1,
            height_in_frames = 22
          },
          {
            filename = "__base__/graphics/entity/car/car-shadow-3.png",
            width_in_frames = 1,
            height_in_frames = 20
          }
        })
      }
    }
  },
  animation =
  {
    layers =
    {
      {
        size = 512,
        frame_count = 4,
        direction_count = 64,
        animation_speed = 1,
        scale = 0.5,
        stripes =
        {
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-a.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-b.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-c.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-d.png",
            width_in_frames = 8,
            height_in_frames = 8
          }
        }
      },
      {
        size = 512,
        frame_count = 4,
        direction_count = 64,
        animation_speed = 1,
        scale = 0.5,
        apply_runtime_tint = true,
        stripes =
        {
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-msk-a.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-msk-b.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-msk-c.png",
            width_in_frames = 8,
            height_in_frames = 8
          },
          {
            filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-msk-d.png",
            width_in_frames = 8,
            height_in_frames = 8
          }
        }
      }
    }
  },
  poop_turret_animation =
  {
    layers =
    {
      {
        filename = "__base__/graphics/entity/car/car-turret.png",
        priority = "low",
        line_length = 8,
        width = 36,
        height = 29,
        frame_count = 1,
        direction_count = 64,
        shift = {0.03125, -0.890625},
        animation_speed = 8,
      },
      {
        filename = "__base__/graphics/entity/car/car-turret-shadow.png",
        priority = "low",
        line_length = 8,
        width = 46,
        height = 31,
        frame_count = 1,
        draw_as_shadow = true,
        direction_count = 64,
        shift = {0.875, 0.359375}
      }
    }
  },
  turret_rotation_speed = 0.35 / 60,
  sound_no_fuel =
  {
    {
      filename = "__base__/sound/fight/car-no-fuel-1.ogg",
      volume = 0.6
    }
  },
  stop_trigger_speed = 0.15,
  stop_trigger =
  {
    {
      type = "play-sound",
      sound =
      {
        {
          filename = "__base__/sound/car-breaks.ogg",
          volume = 0.2
        }
      }
    }
  },
  sound_minimum_speed = 0.1,
  sound_scaling_ratio = 0.1,
  working_sound =
  {
    sound =
    {
      filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/engine.ogg",
      volume = 0.4
    },
    poop_activate_sound =
    {
      filename = "__base__/sound/car-engine-start.ogg",
      volume = 0.67
    },
    poop_deactivate_sound =
    {
      filename = "__base__/sound/car-engine-stop.ogg",
      volume = 0.67
    },
    --match_speed_to_activity = true,
    match_volume_to_activity = true
  },
  open_sound = { filename = "__base__/sound/car-door-open.ogg", volume=0.5 },
  close_sound = { filename = "__base__/sound/car-door-close.ogg", volume = 0.4 },
  rotation_speed = 0.015,
  weight = 100,
  guns = {},
  inventory_size = 5,
  has_belt_immunity = true,
  allow_passengers = false,
  terrain_friction_modifier = 0,
  minimap_representation =
  {
    filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/long-range-delivery-drone-map.png",
    flags = {"icon"},
    size = {128, 128},
    scale = 0.5
  }
}

local delivery_drone_item =
{
  type = "item",
  name = "long-range-delivery-drone",
  localised_name = delivery_drone.localised_name,
  icon = delivery_drone.icon,
  icon_size = delivery_drone.icon_size,
  flags = {},
  stack_size = 1,
  subgroup = "logistic-network",
  order = "k[long-range-delivery-drone]-c"
}

local delivery_drone_recipe =
{
  type = "recipe",
  name = "long-range-delivery-drone",
  enabled = false,
  ingredients =
  {
    {"engine-unit", 1},
    {"iron-gear-wheel", 10},
    {"steel-plate", 5},
    {"solid-fuel", 1}
  },
  energy_required = 10,
  result = "long-range-delivery-drone"
}

local drone_shadow_animation =
{
  type = "animation",
  name = "long-range-delivery-drone-shadow-animation",
  size = 512,
  frame_count = 4,
  direction_count = 64,
  animation_speed = 1,
  scale = 0.5,
  --draw_as_shadow = true,
  tint = {1, 1, 1, 0.5},
  --shift = {5, 5},
  stripes =
  {
    {
      filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-a.png",
      width_in_frames = 8,
      height_in_frames = 8
    },
    {
      filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-b.png",
      width_in_frames = 8,
      height_in_frames = 8
    },
    {
      filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-c.png",
      width_in_frames = 8,
      height_in_frames = 8
    },
    {
      filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-d.png",
      width_in_frames = 8,
      height_in_frames = 8
    }
  }

}

local animation =
{
  layers =
  {
    {
      size = 512,
      frame_count = 255,
      direction_count = 1,
      animation_speed = 4,
      scale = 0.5,
      stripes =
      {
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-a.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-b.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-c.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-d.png",
          width_in_frames = 8,
          height_in_frames = 8
        }
      }
    },
  }
}

local shadow_animation =
{
  layers =
  {
    {
      size = 512,
      frame_count = 255,
      direction_count = 1,
      animation_speed = 4,
      scale = 0.5,
      draw_as_shadow = true,
      stripes =
      {
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-a.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-b.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-c.png",
          width_in_frames = 8,
          height_in_frames = 8
        },
        {
          filename = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/hr-drone-sh-d.png",
          width_in_frames = 8,
          height_in_frames = 8
        }
      }
    }
  }
}

local reversed = function(animation)
  local animation = util.copy(animation)
  local layers = animation.layers or {animation}

  for k, layer in pairs (layers) do
    layer.run_mode = "backward"
  end

  return animation
end

local drone_dying_particle =
{
  type = "optimized-particle",
  name = "long-range-delivery-drone-dying-particle",
  pictures = {animation, reversed(animation)},
  shadows = {shadow_animation, reversed(shadow_animation)},
  movement_modifier = 0.95,
  movement_modifier_when_on_ground = 0.90,
  life_time = 1000,
  render_layer = "air-object",
  render_layer_when_on_ground = "object",
  regular_trigger_effect_frequency = 2,
  regular_trigger_effect =
  {
    {
      type = "create-trivial-smoke",
      smoke_name = "smoke-fast",
      starting_frame_deviation = 5,
      probability = 0.5
    },
    {
      type = "create-particle",
      particle_name = "spark-particle",
      tail_length = 10,
      tail_length_deviation = 5,
      tail_width = 5,
      probability = 0.2,
      initial_height = 0.2,
      initial_vertical_speed = 0.15,
      initial_vertical_speed_deviation = 0.05,
      speed_from_center = 0.1,
      speed_from_center_deviation = 0.05,
      offset_deviation = {{-0.25, -0.25},{0.25, 0.25}}
    }
  },
  ended_on_ground_trigger_effect =
  {
    {
      type = "create-entity",
      entity_name = "big-explosion"
    }
  },
  ended_in_water_trigger_effect =
  {
    {
      type = "create-entity",
      entity_name = "big-explosion"
    }
  }
}

local delivery_particle =
{
  type = "optimized-particle",
  name = "long-range-delivery-drone-delivery-particle",
  movement_modifier = 1,
  movement_modifier_when_on_ground = 0,
  vertical_acceleration = 0,
  life_time = 1000,
  regular_trigger_effect_frequency = 9999,
  render_layer = "projectile",
  pictures =
  {
    {
      filename = "__base__/graphics/entity/poison-capsule/hr-poison-capsule.png",
      draw_as_glow = true,
      frame_count = 16,
      line_length = 8,
      animation_speed = 0.250,
      width = 58,
      height = 59,
      shift = util.by_pixel(1, 0.5),
      scale = 0.5
    }
  },
  shadows =
  {
    {
      filename = "__base__/graphics/entity/poison-capsule/hr-poison-capsule-shadow.png",
      frame_count = 16,
      line_length = 8,
      animation_speed = 0.250,
      width = 54,
      height = 42,
      shift = {0.75, 0.75},
      draw_as_shadow = true,
      scale = 0.5
    }
  }
}

local technology =
{
  type = "technology",
  name = "long-range-delivery-drone",
  localised_name = {"long-range-delivery-drone"},
  localised_description = {"long-range-delivery-drone-description"},
  icon = "__Long_Range_Delivery_Drones__/data/long-range-delivery-drone/tech-icon.png",
  icon_size = 128,
  effects =
  {
    {
      type = "unlock-recipe",
      recipe = "long-range-delivery-drone"
    },
    {
      type = "unlock-recipe",
      recipe = "long-range-delivery-drone-depot"
    },
    {
      type = "unlock-recipe",
      recipe = "long-range-delivery-drone-request-depot"
    }
  },
  prerequisites = {"engine", "automation-2", "oil-processing"},
  unit =
  {
    count = 500,
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1}
    },
    time = 30
  },
  order = "a-d-b"
}

data:extend
{
  depot,
  depot_item,
  depot_recipe,
  request_depot,
  request_depot_item,
  request_depot_recipe,
  delivery_drone,
  delivery_drone_item,
  delivery_drone_recipe,
  drone_dying_particle,
  delivery_particle,
  drone_shadow_animation,
  technology
}
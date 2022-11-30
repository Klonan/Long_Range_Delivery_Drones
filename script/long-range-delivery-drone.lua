local DEPOT_UPDATE_INTERVAL = 101
local DEPOT_UPDATE_BREAK_TIME = 61
local GUI_UPDATE_INTERVAL = 6
local DRONE_MAX_UPDATE_INTERVAL = 300
local DRONE_MIN_SPEED = 0.01
local DRONE_ACCELERATION = 1 / (60 * 8)
local DRONE_MAX_SPEED = 0.5
local DRONE_TURN_SPEED = 1 / (60 * 5)
local DRONE_HEIGHT = 8
local DELIVERY_OFFSET = {0, -DRONE_HEIGHT}
local DELIVERY_DISTANCE = 25
local DRONE_NAME = "long-range-delivery-drone"
local MAX_DELIVERY_STACKS = 5
local MIN_DELIVERY_STACKS = 1
local DEPOT_ORDER_TIMEOUT = 2 * 60 * 60
local DEPOT_ORDER_MINIMAL_TIME = 10 * 60
local script_data =
{
  request_depots = {},
  depots = {},
  depot_map = {},
  depot_update_buckets = {},
  drones = {},
  drone_update_schedule = {},
  gui_updates = {}
}


local ceil = math.ceil
local floor = math.floor
local min = math.min
local max = math.max
local atan2 = math.atan2
local tau = 2 * math.pi
local table_insert = table.insert
local sin = math.sin
local cos = math.cos
local random = math.random

local logistic_curve = function(x)
  local a = (x / (1 - x)) ^ 2
  return 1 - (1 / (1 + a))
end

local distance_squared = function(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return dx * dx + dy * dy
end

local stack_sizes_cache = {}
local get_stack_size = function(item_name)
  local stack_size = stack_sizes_cache[item_name]
  if not stack_size then
    stack_size = game.item_prototypes[item_name].stack_size
    stack_sizes_cache[item_name] = stack_size
  end
  return stack_size
end

local add_to_depots = function(self, list)
  list[self.unit_number] = self
end

local add_to_map = function(self, list)

  local force_name = self.entity.force.name
  local force_depots = list[force_name]
  if not force_depots then
    force_depots = {}
    list[force_name] = force_depots
  end

  local surface_name = self.entity.surface.name
  local surface_depots = force_depots[surface_name]
  if not surface_depots then
    surface_depots = {}
    force_depots[surface_name] = surface_depots
  end
  surface_depots[self.unit_number] = self
end

local add_to_update_schedule = function(self)
  local bucket_index = self.unit_number % DEPOT_UPDATE_INTERVAL
  local bucket = script_data.depot_update_buckets[bucket_index]
  if not bucket then
    bucket = {}
    script_data.depot_update_buckets[bucket_index] = bucket
  end
  bucket[self.unit_number] = self
end

local get_depots_on_map = function(surface, force, list)
  local force_depots = list[force.name]
  return force_depots and force_depots[surface.name]
end

local entity_say = function(entity, text, tint)
  if entity.valid then
    entity.surface.create_entity
    {
      name = "flying-text",
      position = entity.position,
      text = text,
      color = tint
    }
  end
end

local Drone = {}
Drone.metatable = {__index = Drone}
Drone.new = function(entity)
  local self =
  {
    entity = entity,
    unit_number = entity.unit_number,
    scheduled = {},
    inventory = entity.get_inventory(defines.inventory.car_trunk),
  }
  script.register_on_entity_destroyed(entity)
  Drone.load(self)
  script_data.drones[self.unit_number] = self
  self:create_shadow()
  return self
end

Drone.create_shadow = function(self)
  self.shadow = rendering.draw_animation
  {
    animation = "long-range-delivery-drone-shadow-animation",
    orientation = 0,
    x_scale = 1,
    y_scale = 1,
    tint = nil,
    render_layer = "projectile",
    animation_speed = 1,
    animation_offset = nil,
    orientation_target = nil,
    orientation_target_offset = nil,
    oriented_offset = nil,
    target = self.entity,
    target_offset = {0, 0},
    surface = self.entity.surface,
    time_to_live = nil,
    forces = nil,
    players = nil,
    visible = nil,
  }
  self:update_shadow_height()
  self:update_shadow_orientation()
end

Drone.say = function(self, text, tint)
  entity_say(self.entity, text, tint)
end

Drone.load = function(self)
  setmetatable(self, Drone.metatable)
end

Drone.get_minimap_icon = function(self)
  return nil
end

Drone.get_orientation_to_position = function(self, position)
  local origin = self.entity.position
  local dx = position.x - origin.x
  local dy = position.y - origin.y
  local orientation = (atan2(dy, dx) / tau) + 0.25
  if orientation < 0 then
    orientation = orientation + 1
  elseif orientation > 1 then
    orientation = orientation - 1
  end
  return orientation
end

Drone.get_delivery_position = function(self)
  local position = self.delivery_target.position
  return {x = position.x + DELIVERY_OFFSET[1], y = position.y + DELIVERY_OFFSET[2]}
end

Drone.get_distance_to_target = function(self)
  return self:get_distance(self:get_delivery_position())
end

Drone.get_distance = function(self, position)
  local origin = self.entity.position
  local dx = position.x - origin.x
  local dy = position.y - origin.y
  return (dx * dx + dy * dy) ^ 0.5
end

Drone.get_time_to_next_update = function(self)
  if self.needs_fast_update then
    return 1
  end
  local distance = (self:get_distance_to_target() - DELIVERY_DISTANCE)
  local time = distance / self.entity.speed
  local ticks = floor(time * 0.5)
  if ticks < 1 then
    return 1
  end
  return min(ticks, DRONE_MAX_UPDATE_INTERVAL)
end

Drone.schedule_next_update = function(self, time)
  local scheduled = script_data.drone_update_schedule
  local tick = game.tick + time
  local scheduled_drones = scheduled[tick]
  if not scheduled_drones then
    scheduled_drones = {}
    scheduled[tick] = scheduled_drones
  end
  scheduled_drones[self.unit_number] = true
  --self:say(tick - game.tick)
end

local get_rad = function(orientation)
  local adjusted_orientation = orientation - 0.25
  if adjusted_orientation < 0 then
    adjusted_orientation = adjusted_orientation + 1
  end
  return adjusted_orientation * tau
end

Drone.get_movement = function(self, orientation_variation)
  local orientation = self.entity.orientation + ((0.5 - math.random()) * (orientation_variation or 0))
  local speed = self.entity.speed
  local dx = speed * cos(get_rad(orientation))
  local dy = speed * sin(get_rad(orientation))
  return {dx, dy}
end

Drone.suicide = function(self)

  local position = self.entity.position
  local surface = self.entity.surface
  surface.create_entity
  {
    name = "big-explosion",
    position = position,
    movement = self:get_movement(0.1),
    --movement = {, 0},
    height = DRONE_HEIGHT,
    vertical_speed = 0.1,
    frame_speed = 1
  }
  surface.create_particle
  {
    name = "long-range-delivery-drone-dying-particle",
    position = {position.x, position.y + DRONE_HEIGHT},
    movement = self:get_movement(0.1),
    --movement = {, 0},
    height = DRONE_HEIGHT,
    vertical_speed = 0.1,
    frame_speed = 1
  }
  script_data.drones[self.unit_number] = nil
  self.entity.destroy()
end

Drone.schedule_suicide = function(self)
  self.delivery_target:remove_targeting_me(self)
  self.tick_to_suicide = game.tick + random(120, 300)
  self.suicide_orientation = self.entity.orientation + ((0.5 - random()) * 2)
  self:schedule_next_update(random(1, 30))
end

Drone.make_delivery_particle = function(self)
  local distance = self:get_distance_to_target()
  local position = self.entity.position
  local speed = self.entity.speed
  local time = distance / speed
  local delivery_height = DRONE_HEIGHT - 0.75
  local vertical_speed = -delivery_height / time

  self.entity.surface.create_particle
  {
    name = "long-range-delivery-drone-delivery-particle",
    position = {position.x, position.y + delivery_height},
    movement = self:get_movement(),
    height = delivery_height,
    vertical_speed = vertical_speed,
    frame_speed = 1
  }

  return time
end

Drone.deliver_to_target = function(self)
  --self:say("Poopin time")

  local delivery_time
  local source_scheduled = self.scheduled
  local name, count = next(source_scheduled)
  count = min(count, get_stack_size(name))
  if name then
    local target_scheduled = self.delivery_target.scheduled
    local removed = self.inventory.remove({name = name, count = count})
    if removed > 0 then
      self.delivery_target.inventory.insert({name = name, count = removed})
    end

    source_scheduled[name] = source_scheduled[name] - count
    if source_scheduled[name] <= 0 then
      source_scheduled[name] = nil
    end

    if target_scheduled[name] then
      target_scheduled[name] = target_scheduled[name] - count
      if target_scheduled[name] <= 0 then
        target_scheduled[name] = nil
      end
    end

    delivery_time = self:make_delivery_particle()
  end

  if not next(self.scheduled) then
    self:schedule_suicide()
    return
  end

  self:schedule_next_update(ceil(delivery_time * 2) + random(10, 30))
end

Drone.cleanup = function(self)
  if self.delivery_target then
    local source_scheduled = self.scheduled
    local target_scheduled = self.delivery_target.scheduled
    for name, count in pairs(source_scheduled) do
      source_scheduled[name] = nil
      target_scheduled[name] = (target_scheduled[name] or count) - count
      if target_scheduled[name] <= 0 then
        target_scheduled[name] = nil
      end
    end
  end
end

Drone.update_orientation = function(self, target_orientation)

  if self.entity.speed < DRONE_MAX_SPEED then
    return
  end

  local orientation = self.entity.orientation
  if orientation == target_orientation then
    return
  end

  local delta_orientation = target_orientation - orientation
  if delta_orientation < -0.5 then
    delta_orientation = delta_orientation + 1
  elseif delta_orientation > 0.5 then
    delta_orientation = delta_orientation - 1
  end

  if delta_orientation > DRONE_TURN_SPEED then
    self.entity.orientation = orientation + DRONE_TURN_SPEED
    self.needs_fast_update = true
  elseif delta_orientation < -DRONE_TURN_SPEED then
    self.entity.orientation = orientation - DRONE_TURN_SPEED
    self.needs_fast_update = true
  else
    self.entity.orientation = target_orientation
  end
  self:update_shadow_orientation()

end

Drone.update_speed = function(self)

  local speed = self.entity.speed

  if speed < DRONE_MIN_SPEED then
    self.entity.speed = DRONE_MIN_SPEED + DRONE_ACCELERATION
    self:update_shadow_height()
    self.needs_fast_update = true
    return
  end

  if speed < DRONE_MAX_SPEED then
    self.entity.speed = speed + DRONE_ACCELERATION
    self:update_shadow_height()
    self.needs_fast_update = true
  end

end

Drone.update_shadow_height = function(self)
  local shadow = self.shadow
  if not shadow then return end
  local height = (logistic_curve(self.entity.speed / DRONE_MAX_SPEED)) * DRONE_HEIGHT
  rendering.set_target(shadow, self.entity, {height, height})
end

Drone.update_shadow_orientation = function(self)
  local shadow = self.shadow
  if not shadow then return end
  rendering.set_orientation(shadow, self.entity.orientation)
end

Drone.get_state_description = function(self)
  local text = ""
  local distance = ceil(self:get_distance_to_target())
  text = text .. "[color=34, 181,255][" .. distance .. "m][/color]"
  for name, count in pairs(self.scheduled) do
    text = text .. " [item=" .. name .. "]"
  end
  return text
end

Drone.update = function(self)

  if not self.entity.valid then
    self:cleanup()
    return true
  end

  if self.tick_to_suicide then
    self:update_orientation(self.suicide_orientation)
    if game.tick >= self.tick_to_suicide then
      self:suicide()
    else
      self:schedule_next_update(1)
    end
    return
  end

  local target = self.delivery_target
  if not target then
    error("NO target?")
  end
  if not target.entity.valid then
    script_data.drones[self.unit_number] = nil
    self.entity.die()
    return
  end
  --self:say("HI")

  if self.entity.speed >= DRONE_MAX_SPEED and self:get_distance_to_target() <= DELIVERY_DISTANCE then
    self:deliver_to_target()
    return
  end

  self.needs_fast_update = false
  self:update_speed()
  self:update_orientation(self:get_orientation_to_position(self:get_delivery_position()))
  self:schedule_next_update(self:get_time_to_next_update())

end

local Depot = {}
Depot.metatable = {__index = Depot}
Depot.new = function(entity)
  local self =
  {
    entity = entity,
    unit_number = entity.unit_number,
    position = entity.position,
    scheduled = {},
    inventory = entity.get_inventory(defines.inventory.chest)
  }
  script.register_on_entity_destroyed(entity)
  Depot.load(self)
  add_to_depots(self, script_data.depots)
  add_to_map(self, script_data.depot_map)
  add_to_update_schedule(self)
  return self
end

Depot.get_minimap_icon = function(self)
  return "entity/"..self.entity.name
end

Depot.load = function(self)
  setmetatable(self, Depot.metatable)
end

Depot.say = function(self, text)
  entity_say(self.entity, text, {r = 0, g = 1, b = 1})
end

Depot.get_available_capacity = function(self, item_name)
  local stacks = MAX_DELIVERY_STACKS
  for name, count in pairs(self.scheduled) do
    if name ~= item_name then
      stacks = stacks - ceil(count / get_stack_size(name))
    end
  end
  if not item_name then return stacks end
  return floor(stacks * (get_stack_size(item_name)) - (self.scheduled[item_name] or 0))
end

Depot.update_logistic_filters = function(self)
  local slot_index = 1

  if next(self.scheduled) then
    self.entity.set_request_slot({name = DRONE_NAME, count = 1 + (self.scheduled[DRONE_NAME] or 0)}, slot_index)
    slot_index = slot_index + 1
    for name, count in pairs(self.scheduled) do
      if name ~= DRONE_NAME then
        self.entity.set_request_slot({name = name, count = count}, slot_index)
        slot_index = slot_index + 1
      end
    end
  end

  for i = slot_index, self.entity.request_slot_count do
    self.entity.clear_request_slot(i)
  end
end

Depot.delivery_requested = function(self, request_depot, item_name, item_count)
  if (self.delivery_target and self.delivery_target ~= request_depot) then
    error("Trying to schedule a delivery to another target")
  end

  item_count = min(item_count, self:get_available_capacity(item_name))
  if item_count == 0 then
    return 0
  end

  if not self.delivery_target then
    self.delivery_target = request_depot
    self.delivery_target:add_targeting_me(self)
  end


  self.tick_of_recieved_order = game.tick

  local scheduled = self.scheduled
  scheduled[item_name] = (scheduled[item_name] or 0) + item_count
  self:update_logistic_filters()

  return item_count
end

Depot.network_can_satisfy_request = function(self, item_name, count, request_from_buffers)
  local network = self.entity.logistic_network
  return network and network.can_satisfy_request(item_name, count, request_from_buffers)
end


Depot.can_handle_request = function(self, request_depot)
  if self.delivery_target and self.delivery_target ~= request_depot then
    return false
  end

  if (self.entity.logistic_network == request_depot.entity.logistic_network) then
    return false
  end

  local inventory_count = self:get_inventory_count(DRONE_NAME)
  if inventory_count > 0 then
    return true
  end

  if self:network_can_satisfy_request(DRONE_NAME, 1, self.entity.request_from_buffers) then
    return true
  end

  return false
end

Depot.get_inventory_count = function(self, item_name)
  return self.inventory.get_item_count(item_name) - (self.scheduled[item_name] or 0)
end

Depot.transfer_package = function(self, drone)

  local source_inventory = self.inventory
  local source_scheduled = self.scheduled
  local drone_inventory = drone.inventory
  local drone_scheduled = drone.scheduled
  for name, count in pairs(source_scheduled) do
    local removed = source_inventory.remove({name = name, count = count})
    if removed > 0 then
      drone_inventory.insert({name = name, count = removed})
    end
    source_scheduled[name] = nil
    drone_scheduled[name] = count
  end
  self:update_logistic_filters()

end

local empty_color = {r = 0, g = 0, b = 0}
local get_force_color = function(force)
  local index, player = next(force.players)
  if player then
    return player.color
  end
  return empty_color
end

Depot.send_drone = function(self)

  local target = self.delivery_target
  if not target then
    error("No target?")
  end

  local removed = self.inventory.remove({name = DRONE_NAME, count = 1})
  if removed == 0 then
    return
  end

  local force = self.entity.force

  local entity = self.entity.surface.create_entity
  {
    name = DRONE_NAME,
    position = self.position,
    force = force
  }
  entity.color = get_force_color(force)

  force.item_production_statistics.on_flow(DRONE_NAME, -1)


  local drone = Drone.new(entity)
  self:transfer_package(drone)

  drone.delivery_target = target
  target:add_targeting_me(drone)

  self.delivery_target = nil
  self.tick_of_recieved_order = nil
  target:remove_targeting_me(self)

  drone:update()

  return true

end

Depot.cleanup = function(self)

  if self.delivery_target then
    self.delivery_target:remove_targeting_me(self)
    local source_scheduled = self.scheduled
    local target_scheduled = self.delivery_target.scheduled
    for name, count in pairs(source_scheduled) do
      target_scheduled[name] = (target_scheduled[name] or count) - count
      if target_scheduled[name] <= 0 then
        target_scheduled[name] = nil
      end
      source_scheduled[name] = nil
    end
  end
end

Depot.has_all_fulfilled = function(self)
  local scheduled = self.scheduled
  local inventory = self.inventory
  local get_item_count = inventory.get_item_count

  for name, count in pairs(scheduled) do
    local has_count = get_item_count(name)
    if name == DRONE_NAME then has_count = has_count - 1 end
    if has_count < count then
      return
    end
  end
  return true
end

Depot.has_order_timeout = function(self)
  local tick = self.tick_of_recieved_order
  if not tick then return end
  if game.tick >= (tick + DEPOT_ORDER_TIMEOUT) then
    --self:say("Depot order timeout")
    return true
  end
end

Depot.descope_order = function(self)
  local scheduled = self.scheduled
  local inventory = self.inventory
  local get_item_count = inventory.get_item_count
  local target_scheduled = self.delivery_target.scheduled
  for name, count in pairs(scheduled) do
    local has_count = get_item_count(name)
    scheduled[name] = has_count
    if scheduled[name] <= 0 then
      scheduled[name] = nil
    end
    target_scheduled[name] = ((target_scheduled[name] or 0) - count) + has_count
    if target_scheduled[name] <= 0 then
      target_scheduled[name] = nil
    end
  end
end

Depot.check_minimal_order_time = function(self)
  -- If we are processing too quick, then we might miss some orders the player is setting, so if there is still capacity, we wait a little while
  if not self.tick_of_recieved_order then return end
  local capacity = self:get_available_capacity()
  if capacity <= 0 then return end
  local tick = self.tick_of_recieved_order
  if game.tick < (self.tick_of_recieved_order + DEPOT_ORDER_MINIMAL_TIME) then
    return true
  end
end

Depot.check_send_drone = function(self)
  if self:check_minimal_order_time() then
    return
  end

  if self:has_order_timeout() then
    self:descope_order()
    self:send_drone()
    return
  end

  if self:has_all_fulfilled() then
    self:send_drone()
  end
end

Depot.get_state_description = function(self)
  local text = ""
  for name, count in pairs(self.scheduled) do
    text = text .. " [item=" .. name .. "]"
  end
  return text
end

Depot.get_supply_counts = function(self, name)
  local network = self.entity.logistic_network
  return network and network.get_supply_counts(name)
end

Depot.update = function(self)

  if not self.delivery_target then
    return
  end

  if not self.entity.valid then
    self:cleanup()
    return true
  end

  --self:say("Hello")
  if not self.delivery_target.entity.valid then
    self.delivery_target = nil
    local scheduled = self.scheduled
    for name, count in pairs(scheduled) do
      scheduled[name] = nil
    end
    self:update_logistic_filters()
    return
  end

  self:check_send_drone()
  self:update_logistic_filters()
  --self:say("All fulfilled! Send it!")

end

local Request_depot = {}
Request_depot.metatable = {__index = Request_depot}

Request_depot.new = function(entity)
  local self =
  {
    entity = entity,
    unit_number = entity.unit_number,
    position = entity.position,
    scheduled = {},
    inventory = entity.get_inventory(defines.inventory.chest),
    logistic_point = entity.get_logistic_point(),
    targeting_me = {}
  }
  script.register_on_entity_destroyed(entity)
  Request_depot.load(self)
  add_to_depots(self, script_data.request_depots)
  add_to_update_schedule(self)
  return self
end

Request_depot.load = function(self)
  setmetatable(self, Request_depot.metatable)
end

Request_depot.say = function(self, text)
  entity_say(self.entity, text, {r = 1, g = 0.5, b = 0})
end

Request_depot.add_targeting_me = function(self, other)
  self.targeting_me = self.targeting_me or {}
  self.targeting_me[other.unit_number] = other
end

Request_depot.remove_targeting_me = function(self, other)
  self.targeting_me = self.targeting_me or {}
  self.targeting_me[other.unit_number] = nil
end

Request_depot.get_closest = function(self, depots)
  local closest_depot = nil
  local closest_distance = math.huge
  local position = self.position
  for unit_number, depot in pairs(depots) do
    local distance = distance_squared(position, depot.position)
    if distance < closest_distance then
      closest_depot = depot
      closest_distance = distance
    end
  end

  if not closest_depot then return end

  depots[closest_depot.unit_number] = nil
  return closest_depot
end

Request_depot.try_to_schedule_delivery = function(self, item_name, item_count)

  local depots = get_depots_on_map(self.entity.surface, self.entity.force, script_data.depot_map)
  if not depots then return end

  --self:say("Trying to schedule: " .. item_name .. " " .. item_count)

  local stack_size = get_stack_size(item_name)

  local request_count = min(item_count, stack_size * MAX_DELIVERY_STACKS)

  local depots_to_check = {{}, {}, {}, {}}

  local check_depot = function(unit_number, depot)
    if depot:get_available_capacity(item_name) < stack_size * MIN_DELIVERY_STACKS then
      return
    end

    local inventory_count = depot:get_inventory_count(item_name)
    if inventory_count >= request_count then
      depots_to_check[1][unit_number] = depot
      return
    end

    local supply_counts = depot:get_supply_counts(item_name)
    if not supply_counts then return end

    local count = supply_counts["storage"] + supply_counts["passive-provider"] + supply_counts["active-provider"]
    if count >= request_count then
      depots_to_check[2][unit_number] = depot
      return
    end

    if self.entity.request_from_buffers then
      count = count + supply_counts["buffer"]
      if count >= request_count then
        depots_to_check[3][unit_number] = depot
        return
      end
    end

    if count >= stack_size * MIN_DELIVERY_STACKS then
      depots_to_check[4][unit_number] = depot
      return
    end
  end

  for unit_number, depot in pairs (depots) do
    if not depot.entity.valid then
      depots[unit_number] = nil
    elseif depot:can_handle_request(self) then
      check_depot(unit_number, depot)
    end
  end

  local scheduled = self.scheduled

  local closest
  for k, list in pairs(depots_to_check) do
    if next(list) then
      closest = self:get_closest(list)
      if closest then
        break
      end
    end
  end
  if not closest then return end

  local scheduled_count = closest:delivery_requested(self, item_name, item_count)
  if scheduled_count == 0 then return end

  scheduled[item_name] = (scheduled[item_name] or 0) + scheduled_count
  closest:update()

end

local add_or_update_scheduled = function(scheduled, table)
  for name, count in pairs(scheduled) do
    local button = table[name] or table.add
    {
      type = "sprite-button",
      name = name,
      sprite = "item/" .. name,
      style = "transparent_slot"
    }
    button.number = count
  end
  for k, child in pairs(table.children) do
    local name = child.name
    if name and not scheduled[name]  then
      child.destroy()
    end
  end
end

local add_or_update_targeting_panel = function(targeting_me, gui)

  local frame = gui[tostring(targeting_me.unit_number)]
  if not frame then

    frame = gui.add
    {
      type = "frame",
      direction = "vertical",
      style = "train_with_minimap_frame",
      name = tostring(targeting_me.unit_number)
    }
    --frame.style.width = 215
    --frame.style.height = 215 + 12 + 28
    local button = frame.add
    {
      type = "button",
      style = "locomotive_minimap_button",
      name = "click_to_open_on_map",
      tags = {unit_number = targeting_me.unit_number},
    }
    button.style.width = 176
    button.style.height = 176
    --button.style.horizontally_stretchable = true
    --button.style.vertically_stretchable = true
    local camera = button.add
    {
      type = "minimap",
      position = targeting_me.position or {0,0},
      zoom = 1
    }
    camera.entity = targeting_me.entity
    local size = 884
    camera.style.minimal_width = 176
    camera.style.minimal_height = 176
    camera.style.horizontally_stretchable = true
    camera.style.vertically_stretchable = true
    camera.ignored_by_interaction = true
    local sprite = targeting_me:get_minimap_icon()
    if sprite then
      local icon = camera.add{type = "sprite", sprite = sprite}
      icon.style.padding = {(191 - 32)/2, (191 - 32)/2}
    end
    if targeting_me.get_distance_to_target then
      local label = camera.add
      {
        type = "label",
        name = "distance_to_target"
      }
      label.style.left_padding = 4
      label.style.font = "count-font"
      label.style.horizontal_align = "center"
      label.style.width = 172
      label.style.vertical_align = "bottom"
      label.style.height = 172
    end
    frame.add{type = "table", column_count = 5}
  end
  local label = frame.children[1].children[1].distance_to_target
  if label then
    label.caption = "[" .. ceil(targeting_me:get_distance_to_target()).."m]"
  end
  local table = frame.children[2]
  --local deep = frame.add{type = "frame", style = "deep_frame_in_shallow_frame"}
  add_or_update_scheduled(targeting_me.scheduled, table)
end

local get_or_make_relative_gui = function(player)

  local gui = player.gui.relative
  local relative_gui = player.gui.relative.request_depot_gui
  if relative_gui then return relative_gui end

  relative_gui = player.gui.relative.add
  {
    type = "frame",
    name = "request_depot_gui",
    caption = "Deliveries",
    direction = "vertical",
    anchor =
    {
      gui = defines.relative_gui_type.container_gui,
      name = "long-range-delivery-drone-request-depot",
      --position = defines.relative_gui_position.bottom
      position = defines.relative_gui_position.right
      --position = defines.relative_gui_position.left
    }
  }
  relative_gui.style.vertically_stretchable = false
  relative_gui.style.horizontally_stretchable = false

  local inner = relative_gui.add
  {
    type = "frame",
    direction = "vertical",
    style = "inside_deep_frame"
  }
  inner.style.vertically_stretchable = false

  local scroll = inner.add{type = "scroll-pane", style = "naked_scroll_pane", horizontal_scroll_policy = "never"}

  local table = scroll.add
  {
    type = "table",
    column_count = 2,
    style = "trains_table"
  }

  return relative_gui

end

local get_panel_table = function(gui)
  return gui.children[1].children[1].children[1]
end

Request_depot.update_gui = function(self, player)
  local relative_gui = get_or_make_relative_gui(player)
  local table = get_panel_table(relative_gui)
  local targeting_me = self.targeting_me or {}
  relative_gui.visible = next(targeting_me)
  for unit_number, other in pairs(targeting_me) do
    add_or_update_targeting_panel(other, table)
  end
  for k, child in pairs(table.children) do
    local name = child.name
    if name and not targeting_me[tonumber(name)]  then
      child.destroy()
    end
  end
end

Request_depot.update = function(self)
  if not self.entity.valid then
    return true
  end
  local contents = self.inventory.get_contents()
  local scheduled = self.scheduled
  local on_the_way = self.logistic_point.targeted_items_deliver or {}
  local get_request_slot = self.entity.get_request_slot

  for slot_index = 1, self.entity.request_slot_count do
    local request = get_request_slot(slot_index)
    if request then
      local name = request.name
      local scheduled_count = scheduled[name] or 0
      local container_count = contents[name] or 0
      local on_the_way_count = on_the_way[name] or 0
      local stack_size = get_stack_size(name)
      local needed = request.count - (container_count + scheduled_count + on_the_way_count)

      if needed >= stack_size * MAX_DELIVERY_STACKS then
        self:try_to_schedule_delivery(name, stack_size * MAX_DELIVERY_STACKS)
      elseif container_count >= stack_size * MAX_DELIVERY_STACKS then
        -- We have loads already
      elseif needed >= (stack_size * MIN_DELIVERY_STACKS) then
        self:try_to_schedule_delivery(name, needed)
      end
    end
  end

end

local depot_created = function(event)
  local entity = event.source_entity
  if not (entity and entity.valid) then
    return
  end
  local depot = Depot.new(entity)
  game.print(depot.inventory.set_filter(1, DRONE_NAME))
end

local request_depot_created = function(event)
  local entity = event.source_entity
  if not (entity and entity.valid) then
    return
  end
  local depot = Request_depot.new(entity)
end

local triggers =
{
  ["long-range-delivery-drone-depot-created"] = depot_created,
  ["long-range-delivery-drone-request-depot-created"] = request_depot_created,
}

local on_script_trigger_effect = function(event)
  local effect_id = event.effect_id
  local trigger = triggers[effect_id]
  if trigger then
    trigger(event)
  end
end

local update_request_depots = function(tick)
  local index = script_data.next_request_depot_update_index
  if not index and tick % DEPOT_UPDATE_BREAK_TIME ~= 0 then
    return
  end
  local unit_number, depot = next(script_data.request_depots, index)
  if not unit_number then
    script_data.next_request_depot_update_index = nil
    return
  end
  if depot:update() then
    script_data.request_depots[unit_number] = nil
    script_data.next_request_depot_update_index = nil
  else
    --depot:say(unit_number)
    script_data.next_request_depot_update_index = unit_number
  end
end

local update_depots = function(tick)
  local index = script_data.next_depot_update_index
  if not index and tick % DEPOT_UPDATE_BREAK_TIME ~= 0 then
    return
  end
  local unit_number, depot = next(script_data.depots, index)
  if not unit_number then
    script_data.next_depot_update_index = nil
    return
  end
  if depot:update() then
    script_data.depots[unit_number] = nil
    script_data.next_depot_update_index = nil
  else
    --depot:say(unit_number)
    script_data.next_depot_update_index = unit_number
  end
end

local old_update_depots = function(tick)
  local bucket_index = tick % DEPOT_UPDATE_INTERVAL
  local bucket = script_data.depot_update_buckets[bucket_index]
  if not bucket then return end

  for unit_number, depot in pairs(bucket) do
    if depot:update() then
      bucket[unit_number] = nil
    end
  end

  if not next(bucket) then
    script_data.depots[bucket_index] = nil
  end

end

local update_drones = function(tick)

  local drones_to_update = script_data.drone_update_schedule[tick]
  if not drones_to_update then return end
  local drones = script_data.drones
  for unit_number, bool in pairs (drones_to_update) do
    local drone = drones[unit_number]
    if drone then
      if drone:update() then
        drones[unit_number] = nil
      end
    end
  end
  script_data.drone_update_schedule[tick] = nil
end

local update_player_opened = function(player)

  if player.opened_gui_type ~= defines.gui_type.entity then
    return true
  end

  local opened = player.opened
  if not (opened and opened.valid) then return true end

  local unit_number = opened.unit_number
  if not unit_number then return true end


  local request_depot = script_data.request_depots[unit_number]
  if not request_depot then return true end

  request_depot:update_gui(player)

end

local update_guis = function(tick)
  if not (script_data.gui_updates and next(script_data.gui_updates)) then return end
  local players = game.players
  for player_index, player in pairs(script_data.gui_updates) do
    if (player_index + tick) % GUI_UPDATE_INTERVAL == 0 then
      if update_player_opened(player) then
        script_data.gui_updates[player_index] = nil
      end
    end
  end
end

local on_tick = function(event)
  local tick = event.tick
  update_request_depots(tick)
  update_depots(tick)
  update_drones(tick)
  update_guis(tick)
end

local on_gui_opened = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local request_depot = script_data.request_depots[entity.unit_number]
  if not request_depot then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  script_data.gui_updates = script_data.gui_updates or {}

  script_data.gui_updates[player.index] = player
  request_depot:update_gui(player)

end

local open_on_map = function(player, entity)
  if not (entity and entity.valid) then return end
  player.opened = nil
  player.open_map(entity.position, 1/8)
end

local on_gui_click = function(event)
  local gui = event.element
  if not (gui and gui.valid) then return end
  local name = gui.name
  if not (name and name == "click_to_open_on_map") then return end
  local unit_number = gui.tags.unit_number
  if not unit_number then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  local depot = script_data.depots[unit_number]
  if depot then
    open_on_map(player, depot.entity)
  end

  local drone = script_data.drones[unit_number]
  if drone then
    open_on_map(player, drone.entity)
  end
end

local lib = {}

lib.events =
{
  [defines.events.on_script_trigger_effect] = on_script_trigger_effect,
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_tick] = on_tick
}

lib.on_init = function()
  global.long_range_delivery_drone = global.long_range_delivery_drone or script_data
end

lib.on_load = function()
  script_data = global.long_range_delivery_drone or script_data

  for unit_number, depot in pairs(script_data.depots) do
    Depot.load(depot)
  end

  for unit_number, request_depot in pairs(script_data.request_depots) do
    Request_depot.load(request_depot)
  end

  for unit_number, drone in pairs(script_data.drones) do
    Drone.load(drone)
  end

end

return lib

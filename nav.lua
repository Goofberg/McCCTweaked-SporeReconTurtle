local Utils = require("./utils")
local nav = {}

-- External context (injected)
nav.ctx = nil

-- Direction vectors
local dirs = {
  [0] = { x = 0,  z = -1 }, -- North
  [1] = { x = 1,  z = 0  }, -- East
  [2] = { x = 0,  z = 1  }, -- South
  [3] = { x = -1, z = 0  }  -- West
}

-- ======================
-- PICKAXE CHECK / EQUIP
-- ======================
function nav.checkPickaxe()
  local function isPickaxe()
    local equipped = turtle.getEquippedLeft()
    return equipped and equipped.name == "minecraft:diamond_pickaxe"
  end

  -- already equipped
  if isPickaxe() then
    return true
  end

  -- find in inventory
  local pickaxeSlotId = Utils.findItem("minecraft:diamond_pickaxe")
  if pickaxeSlotId then
    turtle.select(pickaxeSlotId)
    turtle.equipLeft()

    if isPickaxe() then
      return true
    else
      warn("Failed to equip diamond pickaxe to left")
      return false
    end
  end

  warn("No diamond pickaxe found in inventory or equipped")
  return false
end

-- ======================
-- GPS POSITION UPDATE
-- ======================
function nav.updatePos()
  local function isModem()
    local equipped = turtle.getEquippedLeft()
    return equipped and equipped.name == "computercraft:wireless_modem_advanced"
  end

  if not isModem() then
    local modemSlotId = Utils.findItem("computercraft:wireless_modem_advanced")
    if modemSlotId then
      turtle.select(modemSlotId)
      turtle.equipLeft()

      if isModem() then
        return true
      else
        warn("Failed to equip wireless modem to left")
        return false
      end
    end
  end

  local x, y, z = gps.locate(10)
  if not x then return false end

  nav.ctx.pos.x = math.floor(x)
  nav.ctx.pos.y = math.floor(y)
  nav.ctx.pos.z = math.floor(z)
  print(textutils.serializeJSON(nav.ctx.pos))
  return true
end

-- ======================
-- DETECT DIRECTION
-- ======================
function nav.detectDirection()
  nav.updatePos()
  local x1 = nav.ctx.pos.x
  local z1 = nav.ctx.pos.z

  if not turtle.forward() then
    error("Cannot move forward to detect direction")
  end

  nav.updatePos()
  local dx = nav.ctx.pos.x - x1
  local dz = nav.ctx.pos.z - z1

  print(dx, dz)

  if dx == 1 then nav.ctx.dir = 1
  elseif dx == -1 then nav.ctx.dir = 3
  elseif dz == 1 then nav.ctx.dir = 2
  elseif dz == -1 then nav.ctx.dir = 0
  else error("Failed to detect direction") end

  turtle.back()
  nav.updatePos()
end

-- ======================
-- TURNING
-- ======================
function nav.turnLeft()
  turtle.turnLeft()
  nav.ctx.dir = (nav.ctx.dir + 3) % 4
end

function nav.turnRight()
  turtle.turnRight()
  nav.ctx.dir = (nav.ctx.dir + 1) % 4
end

function nav.face(targetDir)
  while nav.ctx.dir ~= targetDir do
    nav.turnRight()
  end
end

-- ======================
-- MOVEMENT
-- ======================
function nav.forward()
  while not turtle.forward() do
    nav.checkPickaxe()
    turtle.dig()
    sleep(0.2)
  end

  local d = dirs[nav.ctx.dir]
  nav.ctx.pos.x = nav.ctx.pos.x + d.x
  nav.ctx.pos.z = nav.ctx.pos.z + d.z
end

function nav.up()
  while not turtle.up() do
    nav.checkPickaxe()
    turtle.digUp()
    sleep(0.2)
  end
  nav.ctx.pos.y = nav.ctx.pos.y + 1
end

function nav.down()
  while not turtle.down() do
    nav.checkPickaxe()
    turtle.digDown()
    sleep(0.2)
  end
  nav.ctx.pos.y = nav.ctx.pos.y - 1
end

-- ======================
-- GO TO POSITION
-- ======================
function nav.moveTo(tx, ty, tz)  
  -- Y axis first
  while nav.ctx.pos.y < ty do nav.up() end
  while nav.ctx.pos.y > ty do nav.down() end

  -- X axis
  if nav.ctx.pos.x < tx then nav.face(1) end
  if nav.ctx.pos.x > tx then nav.face(3) end
  while nav.ctx.pos.x ~= tx do nav.forward() end

  -- Z axis
  if nav.ctx.pos.z < tz then nav.face(2) end
  if nav.ctx.pos.z > tz then nav.face(0) end
  while nav.ctx.pos.z ~= tz do nav.forward() end
end

function nav.distance(pos1, pos2)
  return math.abs(pos1.x - pos2.x)
       + math.abs(pos1.y - pos2.y)
       + math.abs(pos1.z - pos2.z)
end

-- ======================
-- INIT WITH CONTEXT
-- ======================
function nav.init(context)
  if not context then
    error("nav.init requires a context table")
  end

  if not context.pos then
    error("context.pos is required")
  end

  if context.dir == nil then
    error("context.dir is required")
  end

  nav.ctx = context

  if not nav.updatePos() then
    error("GPS not available")
  end
  print("Initial position:", nav.ctx.pos.x, nav.ctx.pos.y, nav.ctx.pos.z)

  nav.detectDirection()

  print("Initialized at:", nav.ctx.pos.x, nav.ctx.pos.y, nav.ctx.pos.z)
  print("Facing:", nav.ctx.dir)
end

return nav
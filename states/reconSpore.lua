local Utils = require("../utils")

local reconSpore = {}

local function saveEntities(entities)
  for _, e in pairs(entities) do
    if e.name == "Flesh Mound"
    or e.name == "Proto Hivemind"
    or e.name == "Womb" then

      local worldX = ctx.pos.x + e.x
      local worldY = ctx.pos.y + e.y
      local worldZ = ctx.pos.z + e.z

      table.insert(_G.FOUND_SPORES, {
        name = e.name,
        x = worldX,
        y = worldY,
        z = worldZ
      })
    end
  end
end

function CheckEnvPerip()
  local function isEnvPerip()
    local equipped = turtle.getEquippedLeft()
    return equipped and equipped.name == "advancedperipherals:environment_detector"
  end

  if isEnvPerip() then
    return true
  end

  local envDetectorSlotId = Utils.findItem("advancedperipherals:environment_detector")
  if envDetectorSlotId then
    turtle.select(envDetectorSlotId)
    turtle.equipLeft()

    if isEnvPerip() then
      return true
    else
      warn("Failed to equip environmental detector to left")
      return false
    end
  end

  warn("No environmental detector found in inventory or equipped")
  return false
end

local function scan(ctx)
  if not CheckEnvPerip() then
    warn("Cannot scan for entities without Environmental Peripheral equipped")
    return
  end
  local EnvPerip = peripheral.wrap("left")
  local entities = EnvPerip.scanEntities(16)
  if entities then
    saveEntities(entities)
  end

  Utils:sendWebhookUpdate(ctx, {
    ["username"] = "Turtle Bot, #"..os.computerID(),
    ["embeds"]= {
      {
        ["title"]= "Turtle Recon, Scanning",
        ["description"]= "Scanning Area",
        ["color"]= 5763719,

        ["fields"]= {
          {
            ["name"]= "Fuel",
            ["value"]= Utils.getFuelLevelPercentage() .. "%",
            ["inline"]= false
          },
          {
            ["name"]= "Position",
            ["value"]= "X: " .. ctx.pos.x .. " Y: " .. ctx.pos.y .. " Z: " .. ctx.pos.z,
            ["inline"]= false
          }
        }
      }
    }
  })
end

local function buildWaypointFile()
  local lines = {}

  for i, spore in ipairs(_G.FOUND_SPORES) do
    local line = string.format(
      "waypoint:%s-%d:S:%d:%d:%d:1:false:3:gui.xaero_default:false:0:0:true",
      spore.name,
      i,
      math.floor(spore.x),
      math.floor(spore.y),
      math.floor(spore.z)
    )

    table.insert(lines, line)
  end

  return table.concat(lines, "\n")
end

local function sendWaypointFile(ctx)
  if not ctx.webhook then
    print("No webhook URL")
    return
  end

  local fileContent = buildWaypointFile()

  local boundary = "----CCBOUNDARY" .. os.clock()

  local body =
    "--" .. boundary .. "\r\n" ..
    'Content-Disposition: form-data; name="payload_json"\r\n\r\n' ..
    textutils.serializeJSON({
      username = "Turtle Bot, #" .. os.computerID(),
      content = "Spore scan complete. Waypoints attached. Found " .. #_G.FOUND_SPORES .. " spores."
    }) .. "\r\n" ..

    "--" .. boundary .. "\r\n" ..
    'Content-Disposition: form-data; name="file"; filename="spores.txt"\r\n' ..
    "Content-Type: text/plain\r\n\r\n" ..
    fileContent .. "\r\n" ..

    "--" .. boundary .. "--\r\n"

  local res, err = http.post(
    ctx.webhook,
    body,
    {
      ["Content-Type"] = "multipart/form-data; boundary=" .. boundary
    }
  )

  if res then
    res.close()
  else
    print("Webhook file upload failed:", err)
  end
end

local function checkFuel()
  return Utils.getFuelLevelPercentage() <= 0.1
end

function reconSpore.run(ctx)
  print("Recon Spore scanning started/resumed")

  if not CheckEnvPerip() then
    warn("Cannot scan for entities without Environmental Peripheral equipped")
    return
  end

  _G.FOUND_SPORES = _G.FOUND_SPORES or {}

  local SCAN_CONFIG = {
    RANGE_X = 1,
    RANGE_Z = 1,
    RANGE_Y = 1, -- 5 layer if at Y-level 72
    STEP = 24
  }

  local STEP = SCAN_CONFIG.STEP
  local RX = SCAN_CONFIG.RANGE_X
  local RZ = SCAN_CONFIG.RANGE_Z
  local RY = SCAN_CONFIG.RANGE_Y

  if ctx.origin == nil then
    ctx.origin = {
      x = ctx.pos.x,
      y = ctx.pos.y,
      z = ctx.pos.z
    }
  end

  ctx.recon = ctx.recon or {
    x = -RX,
    z = -RZ,
    y = 0
  }

  while ctx.recon.y <= RY do
    while ctx.recon.z <= RZ do

      local goingPositiveX = (ctx.recon.z % 2 == 0)

      if goingPositiveX then
        ctx.recon.x = ctx.recon.x or -RX
        while ctx.recon.x <= RX do
          if checkFuel() then return "REFUEL" end

          local target = {
            x = ctx.origin.x + (ctx.recon.x * STEP),
            y = ctx.origin.y - (ctx.recon.y * STEP),
            z = ctx.origin.z + (ctx.recon.z * STEP)
          }

          while ctx.pos.y < target.y do
            if checkFuel() then return "REFUEL" end
            ctx.nav.up()
          end

          while ctx.pos.y > target.y do
            if checkFuel() then return "REFUEL" end
            ctx.nav.down()
          end

          if ctx.pos.x < target.x then ctx.nav.face(1) end
          if ctx.pos.x > target.x then ctx.nav.face(3) end

          while ctx.pos.x ~= target.x do
            if checkFuel() then return "REFUEL" end
            ctx.nav.forward()
          end

          if ctx.pos.z < target.z then ctx.nav.face(2) end
          if ctx.pos.z > target.z then ctx.nav.face(0) end

          while ctx.pos.z ~= target.z do
            if checkFuel() then return "REFUEL" end
            ctx.nav.forward()
          end

          scan(ctx)

          ctx.recon.x = ctx.recon.x + 1
        end
      else
        ctx.recon.x = ctx.recon.x or RX
        while ctx.recon.x >= -RX do
          if checkFuel() then return "REFUEL" end

          local target = {
            x = ctx.origin.x + (ctx.recon.x * STEP),
            y = ctx.origin.y - (ctx.recon.y * STEP),
            z = ctx.origin.z + (ctx.recon.z * STEP)
          }

          while ctx.pos.y < target.y do
            if checkFuel() then return "REFUEL" end
            ctx.nav.up()
          end

          while ctx.pos.y > target.y do
            if checkFuel() then return "REFUEL" end
            ctx.nav.down()
          end

          if ctx.pos.x < target.x then ctx.nav.face(1) end
          if ctx.pos.x > target.x then ctx.nav.face(3) end

          while ctx.pos.x ~= target.x do
            if checkFuel() then return "REFUEL" end
            ctx.nav.forward()
          end

          if ctx.pos.z < target.z then ctx.nav.face(2) end
          if ctx.pos.z > target.z then ctx.nav.face(0) end

          while ctx.pos.z ~= target.z do
            if checkFuel() then return "REFUEL" end
            ctx.nav.forward()
          end

          scan(ctx)

          ctx.recon.x = ctx.recon.x - 1
        end
      end

      ctx.recon.z = ctx.recon.z + 1
      ctx.recon.x = nil
    end

    ctx.recon.y = ctx.recon.y + 1
    ctx.recon.z = -RZ
    ctx.recon.x = nil

    Utils:sendWebhookUpdate(ctx, {
      ["username"]= "Turtle Bot, #"..os.computerID(),
      ["content"]= "Moving to next Y layer: " .. ctx.recon.y
    })
  end

  sendWaypointFile(ctx)

  ctx.nav.moveTo(ctx.origin.x, ctx.origin.y, ctx.origin.z)

  ctx.recon = nil
  return "DONE"
end

return reconSpore
local Utils = require("../utils")

local mining = {}

function mining.run(ctx)
  print("Mining started")

  if ctx.pos.y <= -50 or ctx.pos.y >= 40 then
    math.randomseed(os.time())
    local newY = math.random(-50, 40)
    ctx.nav.moveTo(ctx.pos.x, newY, ctx.pos.z)
  end

  while true do
    turtle.dig()
    turtle.forward()

    if Utils.getFuelLevelPercentage() <= 0.5 then
      return "REFUEL"
    end

    if Utils.isInventoryFull() then
      return "RETURN_HOME"
    end

    sleep(0.1)
  end
end

return mining
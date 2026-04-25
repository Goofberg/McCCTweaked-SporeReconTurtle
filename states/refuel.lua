local Utils = require("../utils")
local refuel = {}

function refuel.run(ctx)
  local SendRetrievalMSG = false
  while true do
    if Utils.getFuelLevelPercentage() >= 5.12 then break end

    for i = 1, 16 do
      turtle.select(i)
      turtle.refuel()
    end
    sleep(1)
    if Utils.getFuelLevelPercentage() >= 5.12 then break end

    if SendRetrievalMSG == false then
      SendRetrievalMSG = true
      Utils:sendWebhookUpdate(ctx, {
        ["username"]= "Turtle Bot, #"..os.computerID(),
        ["embeds"]= {
          {
            ["title"]= "Turtle Recon Report:",
            ["description"]= "Report of recon",
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
              },
              {
                ["name"]= "Status",
                ["value"]= "Finding Spores nest, Failed. Ran out of fuel. Waiting retrieval.",
                ["inline"]= false
              }
            }
          }
        },
      })
    end
    sleep(2)
  end

  return "RECON_SPORE"
end

return refuel
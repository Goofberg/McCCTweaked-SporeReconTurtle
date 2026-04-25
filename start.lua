local Utils = require("./utils")
local nav = require("nav")
local FSM = require("fsm")
-- local mining = require("states/mining")
local refuel = require("states/refuel")
local reconSpore = require("states/reconSpore")


local context = {
  dir = 0,
  pos = { x = 0, y = 0, z = 0 },
  webhook = "https://discord.com/api/webhooks/1497460475737407639/csNn8tSMZuMsihXTGDCLQHQzBvxlUlDKT1NkNobMROqTLKWgn7oBBnGcBnX5rF_qtrVA"
}


nav.init(context)
context.nav = nav
context.pos_origin = { x = context.pos.x, y = context.pos.y, z = context.pos.z }
local fsm = FSM.new("REFUEL", context)

-- fsm:addState("MINING", mining)
fsm:addState("REFUEL", refuel)
fsm:addState("RECON_SPORE", reconSpore)
Utils:sendWebhookUpdate(context, {
  ["username"] = "Turtle Bot, #"..os.computerID(),
  ["embeds"]= {
    {
      ["title"]= "Turtle, FSM starting up",
      ["description"]= "Running Startup.lua",
      ["color"]= 5763719,

      ["fields"]= {
        {
          ["name"]= "Fuel",
          ["value"]= Utils.getFuelLevelPercentage() .. "%",
          ["inline"]= false
        },
        {
          ["name"]= "Position",
          ["value"]= "X: " .. context.pos.x .. " Y: " .. context.pos.y .. " Z: " .. context.pos.z,
          ["inline"]= false
        }
      }
    }
  }
})
fsm:run()
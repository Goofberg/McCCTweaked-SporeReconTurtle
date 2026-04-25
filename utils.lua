local utils = {}

function utils.isInventoryFull()
  for i = 1, 16 do
    for j = i + 1, 16 do
      local a = turtle.getItemDetail(i)
      local b = turtle.getItemDetail(j)

      if a and b and a.name == b.name then
        turtle.select(j)
        turtle.transferTo(i)
      end
    end
  end

  for i = 1, 16 do
    local item = turtle.getItemDetail(i)

    if item == nil or #item == 0 then return false end
    if item.count < item.maxCount then return false end
  end
  return true
end

function utils.findItem(itemID)
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and item.name == itemID then
      return i
    end
  end
  return nil
end

function utils.getFuelLevelPercentage()
  return (turtle.getFuelLevel() / turtle.getFuelLimit()) * 100
end

function utils:sendWebhookUpdate(ctx, message)
  if ctx.webhook == nil then
    print("No webhook URL provided.")
    return
  end

  local payload

  if type(message) == "table" then
    payload = textutils.serializeJSON(message)
  else
    payload = textutils.serializeJSON({
      content = tostring(message)
    })
  end

  local res, err = http.post(
    ctx.webhook,
    payload,
    { ["Content-Type"] = "application/json" }
  )

  if res then
    res.close()
  else
    print("Error:", err)
  end
end

return utils
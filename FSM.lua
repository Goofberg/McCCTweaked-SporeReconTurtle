local FSM = {}
FSM.__index = FSM

function FSM.new(initial, context)
  context = context or {}
  context.current = initial
  return setmetatable({
    states = {},
    context = context
  }, FSM)
end

function FSM:addState(name, state)
  self.states[name] = state
end

function FSM:run()
  while true do
    local state = self.states[self.context.current]

    if not state then
      error("Missing state: " .. self.context.current)
    end

    print("Running state:", self.context.current)

    local nextState = state.run(self.context)

    if nextState == "DONE" then
      print("FSM completed successfully.")
      break
    elseif nextState then
      print("Switching to:", nextState)
      self.context.current = nextState
    else
      error("State did not return next state")
    end
  end
end

return FSM
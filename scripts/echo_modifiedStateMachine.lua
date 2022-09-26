--- dirty edit because hooking wouldn't make allow me to pull local variables, at least I don't think that'll work.
--- i'll test that later
--- functionally identical to the standard stateMachine except I added a function to simply return cooldownTimers, because that table seems funky.
--- also added functionality to update *only* cooldown parameters

--- damn psuedo-private variables :(

stateMachine = {}

function stateMachine.create(availableStates, stateTables)
  local self = {}

  local stateName = nil
  local stateData = nil
  local stateNames = availableStates
  local cooldownTimers = {}
  
  function self.stateCooldownTimers() --new function
	return cooldownTimers
  end

  local getStateTable = function(stateName)
    if stateTables ~= nil then
      local state = stateTables[stateName]
      if state ~= nil then
        return state
      end
    end

    return _ENV[stateName]
  end

  local updateCurrentState = function(dt)
    if stateName ~= nil then
      local originalStateName = stateName
      local state = getStateTable(stateName)

      local stateDone, cooldownTime = state.update(dt, stateData)
      if stateDone and stateName == originalStateName then
        self.endState(cooldownTime)
      end

      return true
    else
      return false
    end
  end
  

  self.autoPickState = true
  self.enteringState = nil
  self.leavingState = nil

  function self.hasState()
    if stateName ~= nil then
      return true
    else
      return false
    end
  end

  function self.shuffleStates()
    math.randomseed(math.floor((os.time() + (os.clock() % 1)) * 1000))
    local iterations = #stateNames
    local j
    for i = iterations, 2, -1 do
      j = math.random(i)
      stateNames[i], stateNames[j] = stateNames[j], stateNames[i]
    end
  end

  function self.moveStateToEnd(stateToMove)
    for i, stateName in ipairs(stateNames) do
      if stateName == stateToMove then
        table.insert(stateNames, table.remove(stateNames, i))
        return
      end
    end
  end

  function self.pickState(params)
    if stateName ~= nil then
      local state = getStateTable(stateName)
      if state.preventStateChange ~= nil and state.preventStateChange(stateData) then
        return false
      end
    end

    local enterFunctionName = "enter"
    if params ~= nil then enterFunctionName = "enterWith" end

    for i, newStateName in ipairs(stateNames) do
      if cooldownTimers[newStateName] == nil then
        local newState = getStateTable(newStateName)
        local enterFunction = newState[enterFunctionName]
        if enterFunction ~= nil then
          local newStateData, cooldown = enterFunction(params)
          if newStateData ~= nil then
            self.endState()

            if self.enteringState ~= nil then
              self.enteringState(newStateName)
            end

            if newState.enteringState ~= nil then
              newState.enteringState(newStateData)
            end

            stateName = newStateName
            stateData = newStateData
            return true
          elseif cooldown ~= nil then
            cooldownTimers[newStateName] = cooldownTime
          end
        end
      end
    end

    return false
  end

  function self.endState(cooldownTime)
    if stateName == nil then return end

    local stateNameWas = stateName
    local stateDataWas = stateData

    cooldownTimers[stateName] = cooldownTime

    -- Clear state now, in case leavingState calls pickState
    stateName = nil
    stateData = nil

    local state = getStateTable(stateNameWas)
    if state.leavingState ~= nil then
      state.leavingState(stateDataWas)
    end

    if self.leavingState ~= nil then
      self.leavingState(stateNameWas)
    end
  end

  function self.stateDesc()
    if stateName ~= nil then
      local state = getStateTable(stateName)
      if state.description ~= nil then
        return state.description()
      else
        return stateName
      end
    end

    return ""
  end

  function self.stateCooldown(stateName, newCooldown)
    if stateName ~= nil and type(newCooldown) == "number" then
      cooldownTimers[stateName] = newCooldown
    elseif stateName ~= nil and cooldownTimers[stateName] and cooldownTimers[stateName] > 0 then
      return cooldownTimers[stateName]
    else
      return 0
    end
  end

  -- Returns true if a state was updated during this call
  function self.update(dt)
    -- Update current state
    local updatedState = updateCurrentState(dt)

    -- Try and find a new state
    if stateName == nil and self.autoPickState then
      self.pickState()

      if not updatedState then
        updatedState = updateCurrentState(dt)
      end
    end

    -- Tick per-state cooldown timers
    for cooldownState, cooldownTimer in pairs(cooldownTimers) do
      cooldownTimer = cooldownTimer - dt
      if cooldownTimer < 0.0 then
        cooldownTimer = nil
      end
      cooldownTimers[cooldownState] = cooldownTimer
    end

    if not updatedState and stateName == nil then
      return false
    else
      return true
    end
  end
  
  function self.updateCooldownTimers(dt) --new function
	for cooldownState, cooldownTimer in pairs(cooldownTimers) do
      cooldownTimer = cooldownTimer - dt
      if cooldownTimer < 0.0 then
        cooldownTimer = nil
      end
      cooldownTimers[cooldownState] = cooldownTimer
    end
  end

  return self
end

--- Scans the given lua script paths for the given pattern, which should capture
--- a state name from the name of the script
-- Example: stateMachine.scanScripts(config.getParameter("scripts"), "(%a+)State%.lua")
function stateMachine.scanScripts(scripts, pattern)
  local stateNames = {}

  if scripts ~= nil then
    for i, subScript in ipairs(scripts) do
      local stateName = string.match(subScript, pattern)
      if stateName ~= nil then
        local state = _ENV[stateName]
        if state ~= nil and type(state) == "table" and (state["enter"] ~= nil or state["enterWith"] ~= nil) and state["update"] ~= nil then
          table.insert(stateNames, stateName)
        end
      end
    end
  end

  return stateNames
end

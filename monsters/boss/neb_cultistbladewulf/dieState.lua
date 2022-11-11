--------------------------------------------------------------------------------
dieState = {}

function dieState.enterWith(params)
  if not params.die then return nil end
  
  rangedAttack.setConfig(config.getParameter("projectiles.deathexplosion.type"), config.getParameter("projectiles.deathexplosion.config"), 0.2)

  return {
    timer = 3,
    rotateInterval = 0.1,
    rotateAngle = 0.05,
    deathSound = true
  }
end

function dieState.enteringState(stateData)
  --Open generator door
  world.objectQuery(mcontroller.position(), 80, { name = "cultistdoor", callScript = "openDoor" })

  --animator.setAnimationState("crystalhum", "off")
  
  --animator.setAnimationState("shell", "stage"..currentPhase())
  --animator.setAnimationState("eye", "hurt")
  
  animator.playSound("shatter")
  animator.playSound("death")
end

function dieState.update(dt, stateData)
  stateData.timer = stateData.timer - dt

  --local angle = dieState.angleFactorFromTime(stateData.timer, stateData.rotateInterval) * stateData.rotateAngle - stateData.rotateAngle / 2
  --animator.rotateGroup("all", angle, true)

  stateData.timer = stateData.timer - dt

  if stateData.timer < 0.2 and stateData.deathSound then
    animator.playSound("shatter")
    stateData.deathSound = false
  end

  if stateData.timer < 0 then
    self.dead = true
  end
  return false
end

--basic triangle wave
function dieState.angleFactorFromTime(timer, interval)
  local modTime = interval - (timer % interval)
  if modTime < interval / 2 then
    return modTime / (interval / 2)
  else
    return (interval - modTime) / (interval / 2) 
  end
end

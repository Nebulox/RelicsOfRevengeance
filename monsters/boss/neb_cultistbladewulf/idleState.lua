idleState = {}

function idleState.enter()
  if hasTarget() then return nil end

  return {
    timer = 0,
    bobInterval = 0.5,
    bobHeight = 0.1
  }
end

function idleState.enteringState(stateData)
end

function idleState.update(dt, stateData)
  stateData.timer = stateData.timer + dt
  if stateData.timer > stateData.bobInterval then
    stateData.timer = stateData.timer - stateData.bobInterval
  end
  
  --animator.setGlobalTag("fullbrightImage", "/monsters/boss/neb_cultistbladewulf/nobright.png")

  --local bobOffset = math.sin((stateData.timer / stateData.bobInterval) * math.pi * 2) * stateData.bobHeight
  --local targetPosition = {self.spawnPosition[1], self.spawnPosition[2] + bobOffset}
  --local toTarget = world.distance(targetPosition, mcontroller.position())

  --mcontroller.controlApproachVelocity(vec2.mul(toTarget, 1/dt), 30)
end

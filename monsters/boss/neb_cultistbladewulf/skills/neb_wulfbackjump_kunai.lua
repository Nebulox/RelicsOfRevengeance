neb_wulfbackjump_kunai = {}

function neb_wulfbackjump_kunai.enter()
  neb_wulfbackjump_kunai.cooldownCategory = config.getParameter("neb_wulfbackjump_kunai.cooldownCategory")
  
  if animator.animationState("body") == "outOfStagger" then return nil end
  if animator.animationState("body") == "holdStagger" then
	animator.setAnimationState("body","outOfStagger")
	return nil
  end
  
  if not (self.state.stateCooldown(neb_wulfbackjump_kunai.cooldownCategory) == 0) then
	return nil 
  end
  
  if not (hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfbackjump_kunai.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  local minDistance = config.getParameter("neb_wulfbackjump_kunai.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfbackjump_kunai.maxDistance", 20)
  
  local distance = math.abs(vec2.mag(neb_wulfbackjump_kunai.toTarget))
  
  if not (distance > minDistance and distance < maxDistance ) then --distance check
	return nil
  end
  
  
  neb_wulfbackjump_kunai.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfbackjump_kunai.toTarget[1])
  local xDir = 0
  
  if neb_wulfbackjump_kunai.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end
  
  --check if mob can reasonable jump behind to mitigate some awkward stuckness that can occur
  local boundingBox = mcontroller.boundBox()
  -- updates bounding box to be in world coordinates
  boundingBox = {boundingBox[1]+mcontroller.position()[1],boundingBox[2]+mcontroller.position()[2],boundingBox[3]+mcontroller.position()[1],boundingBox[4]+mcontroller.position()[2]}
  local endBox = {boundingBox[1]-(xDir * 3),boundingBox[2]+3,boundingBox[3]-(xDir * 3),boundingBox[4]+3}
  local invalidPosition = world.rectTileCollision(endBox, {"Null", "Block", "Dynamic", "Slippery"})
  if invalidPosition then return nil end

  return {
    windupTimer = config.getParameter("neb_wulfbackjump_kunai.windupTime", 1.0),
    timer = config.getParameter("neb_wulfbackjump_kunai.skillTime", 0.3),
	bufferTime = config.getParameter("neb_wulfbackjump_kunai.bufferTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfbackjump_kunai.winddownTime", 1.0),
	degreesTurned = 0,
	finishedTurn = false
  }
end

function neb_wulfbackjump_kunai.enteringState(stateData)
  animator.setAnimationState("body", "jumpWindup")
  self.rotationMult = -1 --backwards flip
  
  stateData.targetPosition = self.targetPosition
end

function neb_wulfbackjump_kunai.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfbackjump_kunai.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfbackjump_kunai.toTarget[1])
  local xDir = 0
  
  if neb_wulfbackjump_kunai.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt

    if stateData.timer <= 0 then
	  animator.setAnimationState("body", "inAirBack")
	  mcontroller.controlFace(targetDir)
	  local vel = config.getParameter("neb_wulfbackjump_kunai.jumpVelocity")
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
    end

    return false
  end
  
  if stateData.bufferTime > 0 then
    stateData.bufferTime = stateData.bufferTime - dt

    if stateData.bufferTime <= 0 then
	  local aimVector = world.distance(stateData.targetPosition, mcontroller.position())
	  local aimDir = math.atan(aimVector[2],aimVector[1])
	  
	  animator.setAnimationState("body", "flip")
	  
	  mcontroller.controlFace(targetDir)
	  
	  local params = {}
	  params.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * 4 --4 damage at base, technically 8 because of the kunai explosion
	  params.speed = 60
	  params.timeToLive = 1.0
	  
	  world.spawnProjectile("energyshard", mcontroller.position(), entity.id(), {math.cos(aimDir),math.sin(aimDir)}, false, params)
	  
	  aimDir = math.atan(aimVector[2], aimVector[1]) + math.pi/180 * 10
	  world.spawnProjectile("energyshard", mcontroller.position(), entity.id(), {math.cos(aimDir),math.sin(aimDir)}, false, params)
	  
	  aimDir = math.atan(aimVector[2], aimVector[1]) - math.pi/180 * 10
	  world.spawnProjectile("energyshard", mcontroller.position(), entity.id(), {math.cos(aimDir),math.sin(aimDir)}, false, params)
	  
	  local vel = config.getParameter("neb_wulfbackjump_kunai.hopVelocity")
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
      animator.playSound("fire")
    end

    return false
  end
  
  if not stateData.finishedTurn then
	--stateData.degreesTurned = stateData.degreesTurned + (35 / 180 * math.pi * dt)
	--animator.rotateTransformationGroup("all", 35/180*math.pi)
  end

  if stateData.winddownTimer > 0 then
	if not mcontroller.onGround() then return false end
	
	if not stateData.finishedTurn then 
		--animator.rotateTransformationGroup("all", -stateData.degreesTurned)
		stateData.finishedTurn = true
		--animator.setAnimationState("body", "intoStagger")
		animator.setAnimationState("body", "idle")
	end
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  self.state.stateCooldown(neb_wulfbackjump_kunai.cooldownCategory, config.getParameter("neb_wulfbackjump_kunai.cooldownTime"))
  return true
end

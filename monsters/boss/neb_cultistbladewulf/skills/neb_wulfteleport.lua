neb_wulfteleport = {}

function neb_wulfteleport.enter()
  neb_wulfteleport.cooldownCategory = config.getParameter("neb_wulfteleport.cooldownCategory")
  
  if animator.animationState("body") == "outOfStagger" then return nil end
  if animator.animationState("body") == "holdStagger" then
	animator.setAnimationState("body","outOfStagger")
	return nil
  end
  
  if not (self.state.stateCooldown(neb_wulfteleport.cooldownCategory) == 0) then
	return nil 
  end
  
  if not (hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfteleport.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  local minDistance = config.getParameter("neb_wulfteleport.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfteleport.maxDistance", 20)
  
  local distance = math.abs(vec2.mag(neb_wulfteleport.toTarget))
  
  if not (distance > minDistance and distance < maxDistance ) then --distance check
	return nil
  end
  
  -- desired position calculations
  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])
  local xDir = 0
  if neb_wulfteleport.toTarget[1] > 0 then xDir = 1 else xDir = -1 end
  
  local desiredPosition = {self.targetPosition[1] - (xDir * 3),self.targetPosition[2]}
  
  local boundingBox = mcontroller.boundBox()
  local endBox = {boundingBox[1]+desiredPosition[1],boundingBox[2]+desiredPosition[2],boundingBox[3]+desiredPosition[1],boundingBox[4]+desiredPosition[2]}
  local invalidPosition = world.rectTileCollision(endBox, {"Null", "Block", "Dynamic", "Slippery"})
  if invalidPosition then return nil end

  return {
    windupTimer = config.getParameter("neb_wulfteleport.windupTime", 1.0),
    timer = config.getParameter("neb_wulfteleport.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfteleport.winddownTime", 1.0),
	slashTimer = 0.3,
	desiredPos = desiredPosition
  }
end

function neb_wulfteleport.enteringState(stateData)
  --animator.setAnimationState("body", "flipWindup")
  animator.setAnimationState("body", "teleportOut")
  --animator.playSound("spawnCharge")
end

function neb_wulfteleport.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfteleport.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfteleport.toTarget[1])
  local xDir = 0
  
  if neb_wulfteleport.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end
  
  if animator.animationState("body") == "teleportOut" then return false end
  if animator.animationState("body") == "hidden" then animator.setAnimationState("body","teleportInNeutral"); mcontroller.setPosition(stateData.desiredPos); return false end
  if animator.animationState("body") == "teleportInNeutral" then return false end
  
  if animator.animationState("body") == "idle" and not stateData.triggered then animator.setAnimationState("body","flipWindup"); stateData.triggered = true; return false end
  

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if stateData.windupTimer <= 0 then
		animator.setAnimationState("body", "slash")
		
		if self.phase == 2 then
			animator.playSound("phase2attack")
		else 
			animator.playSound("slash")
		end
	end
    return false
  end
  
  if stateData.slashTimer > 0 then
	stateData.slashTimer = stateData.slashTimer - dt
	
	if stateData.slashTimer <= 0 then
		mcontroller.controlFace(targetDir)
	end
	return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt
	

    if stateData.timer <= 0 then
	  animator.setAnimationState("body", "inAirBack")
	  local vel = config.getParameter("neb_wulfteleport.jumpVelocity")
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
      --animator.playSound("spawnAdd")
    end

    return false
  end

  if stateData.winddownTimer > 0 then
	if not mcontroller.onGround() then return false end
	animator.setAnimationState("body", "idle")
	
	--if animator.animationState("body") == "inAirBack" then animator.setAnimationState("body", "intoStagger") end
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
    stateData.winddownTimer = stateData.winddownTimer - dt
	
    return false
  end
  
  animator.setAnimationState("body", "idle")
  
  self.state.stateCooldown(neb_wulfteleport.cooldownCategory,config.getParameter("neb_wulfteleport.cooldownTime"))
  return true
end
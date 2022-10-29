neb_wulfbackjump = {}

function neb_wulfbackjump.enter()
  neb_wulfbackjump.cooldownCategory = config.getParameter("neb_wulfbackjump.cooldownCategory")
  
  if not (self.state.stateCooldown(neb_wulfbackjump.cooldownCategory) == 0) then
	return nil 
  end
  
  if (not hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfbackjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  local minDistance = config.getParameter("neb_wulfbackjump.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfbackjump.maxDistance", 20)
  
  local distance = math.abs(vec2.mag(neb_wulfbackjump.toTarget))
  
  if not (distance > minDistance and distance < maxDistance ) then --distance check
	return nil
  end

  --if not self.moontants then self.moontants = 6 end

  --if self.moontants <= 1 then return nil end
  
  local triggerSlash = false
  if distance < config.getParameter("neb_wulfbackjump.slashTriggerDistance") then
	triggerSlash = true
  end

  return {
    windupTimer = config.getParameter("neb_wulfbackjump.windupTime", 1.0),
    timer = config.getParameter("neb_wulfbackjump.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfbackjump.winddownTime", 1.0),
	triggerSlash = triggerSlash,
	slashTimer = 0.3
  }
end

function neb_wulfbackjump.enteringState(stateData)
  if not stateData.triggerSlash then
	animator.setAnimationState("body", "jumpWindup")
  else
	animator.setAnimationState("body", "flipWindup")
  end
  animator.playSound("spawnCharge")
end

function neb_wulfbackjump.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfbackjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfbackjump.toTarget[1])
  local xDir = 0
  
  if neb_wulfbackjump.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if stateData.windupTimer <= 0 and stateData.triggerSlash then
		animator.setAnimationState("body", "slash")
		animator.playSound("spawnAdd")
	end
    return false
  end
  
  if stateData.triggerSlash and stateData.slashTimer > 0 then
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
	  local vel = config.getParameter("neb_wulfbackjump.jumpVelocity")
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
      animator.playSound("spawnAdd")
    end

    return false
  end

  if stateData.winddownTimer > 0 then
	if not mcontroller.onGround() then return false end
	
	if animator.animationState("body") == "inAirBack" then animator.setAnimationState("body", "intoStagger") end
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  self.state.stateCooldown(neb_wulfbackjump.cooldownCategory,config.getParameter("neb_wulfbackjump.cooldownTime"))
  return true
end

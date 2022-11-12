neb_wulfspinattack = {}

function neb_wulfspinattack.enter()
  neb_wulfspinattack.cooldownCategory = config.getParameter("neb_wulfspinattack.cooldownCategory")
  
  if animator.animationState("body") == "outOfStagger" then return nil end
  if animator.animationState("body") == "holdStagger" then
	animator.setAnimationState("body","outOfStagger")
	return nil
  end
  
  if not (self.state.stateCooldown(neb_wulfspinattack.cooldownCategory) == 0) then
	return nil 
  end
  
  if not (hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfspinattack.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  local minDistance = config.getParameter("neb_wulfspinattack.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfspinattack.maxDistance", 20)
  
  local distance = math.abs(vec2.mag(neb_wulfspinattack.toTarget))
  
  if not (distance > minDistance and distance < maxDistance ) then --distance check
	return nil
  end
  
  local minVerticalDistance = config.getParameter("neb_wulfspinattack.minVerticalDistance", 5)
  local maxVerticalDistance = config.getParameter("neb_wulfspinattack.maxVerticalDistance", 20)
  local verticalDistance = math.abs(neb_wulfspinattack.toTarget[2])
  
  if not (verticalDistance > minVerticalDistance and verticalDistance < maxVerticalDistance ) then --vertical distance check
	return nil
  end
  

  return {
    windupTimer = config.getParameter("neb_wulfspinattack.windupTime", 1.0),
    timer = config.getParameter("neb_wulfspinattack.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfspinattack.winddownTime", 1.0),
	timesSpun = 0,
  }
end

function neb_wulfspinattack.enteringState(stateData)
  animator.setAnimationState("body", "flipWindup")
  animator.setAnimationState("flash", "on")
  
  --animator.playSound("spawnCharge")
end

function neb_wulfspinattack.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfspinattack.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfspinattack.toTarget[1])
  local xDir = 0
  
  if neb_wulfspinattack.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if stateData.windupTimer <= 0 then
		animator.setAnimationState("body", "flip")
		--animator.playSound("spawnAdd")
		
		local targetPosition = self.targetPosition
		targetPosition[2] = targetPosition[2] + 5 --aim a little bit above the player
		
		local aimVector = world.distance(targetPosition, mcontroller.position())
		local aimDir = math.atan(aimVector[2],aimVector[1])
		
		  
		mcontroller.setVelocity({math.cos(aimDir) * 70, math.max(math.sin(aimDir) * 70,45)}) -- aims directly at target, jumps towards them.
		-- may look to calculate an actual formula to have better intercepts (i.e. considering gravity; target entity will be assumed to be stationary because I can't be bother to do *that* much math :) )
		  
		--animator.playSound("spawnAdd")
	end
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt
	
		if stateData.timer <= 0 then
		  
		  
		end

    return false
  end

  if stateData.winddownTimer > 0 then
	if not mcontroller.onGround() then
		--animator.rotateTransformationGroup("all", 35 / 180 * math.pi * dt)
		return false 
	end
	
	if not stateData.touchedGround then
		animator.setAnimationState("body", "idle")
		
		if stateData.timesSpun == 2 then animator.setAnimationState("body", "intoStagger") end
		
		stateData.touchedGround = true
	end
	
    stateData.winddownTimer = stateData.winddownTimer - dt
	
	if stateData.winddownTimer <= 0 then
		stateData.timesSpun = stateData.timesSpun + 1
		if stateData.timesSpun < 3 then
			stateData.windupTimer = config.getParameter("neb_wulfspinattack.windupTime", 1.0) * 0.5
			stateData.timer = config.getParameter("neb_wulfspinattack.skillTime", 0.3)
			stateData.winddownTimer = config.getParameter("neb_wulfspinattack.winddownTime", 1.0)
			stateData.touchedGround = false
			
			animator.setAnimationState("body", "flipWindup")
			
			if stateData.timesSpun == 2 then
				stateData.winddownTimer = 0.5
			end
			--animator.setAnimationState("flash", "on")
			
			return false
		end
	end
    return false
  end
  
  animator.setAnimationState("body", "idle")
  
  self.state.stateCooldown(neb_wulfspinattack.cooldownCategory,config.getParameter("neb_wulfspinattack.cooldownTime"))
  return true
end
neb_wulfjump_combo = {}

function neb_wulfjump_combo.checkDistance()
  if animator.animationState("body") == "outOfStagger" then return nil end
  if animator.animationState("body") == "holdStagger" then
	animator.setAnimationState("body","outOfStagger")
	return nil
  end

  local minDistance = config.getParameter("neb_wulfjump_combo.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfjump_combo.maxDistance", 20)
  
  neb_wulfjump_combo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = math.abs(vec2.mag(neb_wulfjump_combo.toTarget))
  
  if (distance > minDistance and distance < maxDistance ) then --distance check
	return true
  end
  
  return false
end

function neb_wulfjump_combo.checkOverDistance()
  local maxDistance = config.getParameter("neb_wulfjump_combo.maxDistance", 20)
  
  neb_wulfjump_combo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = math.abs(vec2.mag(neb_wulfjump_combo.toTarget))
  
  if (distance > maxDistance ) then --distance check
	return true
  end
  
  return false
end

function neb_wulfjump_combo.enter()
  neb_wulfjump_combo.cooldownCategory = config.getParameter("neb_wulfjump_combo.cooldownCategory")
  
  if not (self.state.stateCooldown(neb_wulfjump_combo.cooldownCategory) == 0) then
	return nil 
  end
  
  if not (hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfjump_combo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  if not neb_wulfjump_combo.checkDistance() then
	return nil
  end
  
  
  return {
	comboCount = 2,
	
	chargeVel = config.getParameter("neb_wulfjump_combo.chargeVelocity"),
	
    windupTimer = config.getParameter("neb_wulfjump_combo.windupTime", 1.0),
    timer = config.getParameter("neb_wulfjump_combo.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfjump_combo.winddownTime", 1.0)
  }
end

function neb_wulfjump_combo.enteringState(stateData)
  --animator.setAnimationState("eye", "windup")
  animator.setAnimationState("body", "jumpWindup")
  animator.playSound("spawnCharge")
end

function neb_wulfjump_combo.update(dt, stateData)
  if not hasTarget() then return true end
  
  stateData.phase = self.phase
  --sb.logInfo("phase :" ..stateData.phase)
  
  neb_wulfjump_combo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfjump_combo.toTarget[1])
  local xDir = 0
  
  if neb_wulfjump_combo.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
	if not mcontroller.onGround() then return false end
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if stateData.windupTimer <= 0 and stateData.comboCount == 0 then
		animator.setAnimationState("body", "run")
		stateData.chargeDir = xDir
	end
	
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt
	
	if stateData.comboCount > 0 then
		if stateData.timer <= 0 then
		  animator.setAnimationState("body", "jump")
		  
		  local aimVector = world.distance(self.targetPosition, mcontroller.position())
		  local aimDir = math.atan(aimVector[2],aimVector[1])
		  
		  
		  local vel = config.getParameter("neb_wulfjump_combo.jumpVelocity")
		  if stateData.phase == 2 then
			mcontroller.setVelocity({vel[1] * xDir * 1.25,vel[2] * 1.25}) -- increased jump height if doing the spinny
		  else
			mcontroller.setVelocity({vel[1] * xDir,vel[2]})
		  end
		  
		  animator.playSound("spawnAdd")
		  
		  -- stateData.countered = false
		  -- stateData.counterTriggered = false
		  
		  -- --ex {"hitType":"ShieldHit","damageSourceKind":"shield","sourceEntityId":629,"healthLost":0,"damageDealt":0,"targetMaterialKind":"organic","targetEntityId":-65536,"position":[334.153,1117.5]}
		  -- stateData.damageListener = damageListener("inflictedHits", function(notifications)
			-- for _, notification in pairs(notifications) do
				-- --sb.logInfo(sb.printJson(notification))
				-- if notification.hitType == "ShieldHit" then
					-- --animator.playSound("hiltSmashHit")
					-- --sb.logInfo("counter plz")
					-- stateData.countered = true
				-- return
				-- end
			-- end
		  -- end)
		end
	
	else
		mcontroller.setXVelocity(stateData.chargeVel*stateData.chargeDir)
		local wallBlock = checkWalls(stateData.chargeDir)
		
		if wallBlock then --if hit wall, then poise break
			animator.setAnimationState("body", "intoStagger",true)
			stateData.counterTriggered = true
			stateData.timer = 0
			stateData.winddownTimer = 0.0
			status.setResource("poise",0)
			
			--animator.playSound("shatter")
		end
	end

    return false
  end
  
  --monster.setDamageParts({})

  if stateData.comboCount > 0 and stateData.winddownTimer > 0 then
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
	
	if stateData.phase == 2 and not mcontroller.onGround() then
		animator.setAnimationState("body", "flip")
		
		animator.rotateTransformationGroup("all", 35/180*math.pi)
	end
	
	if not mcontroller.onGround() then return false end
	if stateData.phase == 2 then animator.resetTransformationGroup("all") end
	
	if animator.animationState("body") == "flip" then animator.setAnimationState("body", "idle") end
	
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  if stateData.comboCount > 0 then
	
	if stateData.phase == 2 then animator.resetTransformationGroup("all") end
	
	stateData.comboCount = stateData.comboCount - 1
	stateData.windupTimer = config.getParameter("neb_wulfjump_combo.comboWindupTime", 1.0)
    stateData.timer = config.getParameter("neb_wulfjump_combo.skillTime", 0.3)
    stateData.winddownTimer = config.getParameter("neb_wulfjump_combo.comboWinddownTime", 1.0)
	
	animator.setAnimationState("body", "jumpWindup")
	animator.playSound("spawnCharge")
	mcontroller.controlFace(targetDir)
	
	if stateData.comboCount == 0 or (not stateData.phase == 2 and neb_wulfjump_combo.checkOverDistance()) then --transition to a dash attack
		--monster.setDamageOnTouch(false)
		animator.setAnimationState("body", "jumpWindup",true)
		animator.setAnimationState("flash", "on")
		
		stateData.windupTimer = 0.75--config.getParameter("neb_wulfjump_combo.windupTimer", 1.0)
		stateData.timer = config.getParameter("neb_wulfjump_combo.chargeTime", 0.3)
		
		stateData.comboCount = 0
		stateData.winddownTimer = 0.75
	end
	return false
  end
  
  if stateData.comboCount == 0 and stateData.winddownTimer > 0 then
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  --monster.setDamageOnTouch(false)
  animator.setAnimationState("body", "idle")
  self.damageListener = nil
  self.state.stateCooldown(neb_wulfjump_combo.cooldownCategory,config.getParameter("neb_wulfjump_combo.cooldownTime"))
  return true
end

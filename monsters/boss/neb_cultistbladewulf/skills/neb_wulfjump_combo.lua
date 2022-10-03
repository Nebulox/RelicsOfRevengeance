neb_wulfjump_combo = {}

function neb_wulfjump_combo.checkDistance()
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
  
  if (not hasTarget() and mcontroller.onGround()) then return nil end
  
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
  animator.playSound("spawnCharge")
end

function neb_wulfjump_combo.update(dt, stateData)
  if not hasTarget() then return true end
  
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
		animator.setAnimationState("body", "charge")
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
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
      animator.playSound("spawnAdd")
	  
	  stateData.countered = false
	  stateData.counterTriggered = false
	  
	  --ex {"hitType":"ShieldHit","damageSourceKind":"shield","sourceEntityId":629,"healthLost":0,"damageDealt":0,"targetMaterialKind":"organic","targetEntityId":-65536,"position":[334.153,1117.5]}
	  stateData.damageListener = damageListener("inflictedHits", function(notifications)
		for _, notification in pairs(notifications) do
			--sb.logInfo(sb.printJson(notification))
			if notification.hitType == "ShieldHit" then
				--animator.playSound("hiltSmashHit")
				--sb.logInfo("counter plz")
				stateData.countered = true
			return
			end
		end
	  end)
    end
	
	else
		mcontroller.setXVelocity(stateData.chargeVel*stateData.chargeDir)
		local wallBlock = checkWalls(stateData.chargeDir)
		
		if wallBlock then --if hit wall, then stun
			animator.setAnimationState("body", "idle")
			stateData.timer = 0
			stateData.winddownTimer = config.getParameter("neb_wulfjump_combo.winddownTime", 1.0) * 3
			animator.playSound("shatter")
		end
	end

    return false
  end
  
  --monster.setDamageParts({})

  if stateData.winddownTimer > 0 then
	if not mcontroller.onGround() then return false end
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
	
	if stateData.countered then --mimics behavior from the actual source game - that being if Blade Wolf is parried, he'll bounce backwards from his jump attack.
		if not stateData.counterTriggered then
			local vel = config.getParameter("neb_wulfjump_combo.jumpVelocity")
			mcontroller.setVelocity({vel[1] * -xDir * 0.5,vel[2] * 0.5})
			stateData.counterTriggered = true
			stateData.damageListener = nil
			animator.playSound("shatter")
			
			monster.setDamageOnTouch(false)
			
			stateData.winddownTimer = config.getParameter("neb_wulfjump_combo.winddownTime", 1.0) * 1.5
		end
	else
		sb.logInfo("ticking damage listener")
		stateData.damageListener:update()
	end
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  if stateData.comboCount > 0 then 
	stateData.comboCount = stateData.comboCount - 1
	stateData.windupTimer = config.getParameter("neb_wulfjump_combo.comboWindupTime", 1.0)
    stateData.timer = config.getParameter("neb_wulfjump_combo.skillTime", 0.3)
    stateData.winddownTimer = config.getParameter("neb_wulfjump_combo.comboWinddownTime", 1.0)
	
	animator.playSound("spawnCharge")
	
	if stateData.comboCount == 0 or neb_wulfjump_combo.checkOverDistance() then --transition to a dash attack
		--monster.setDamageOnTouch(false)
		stateData.windupTimer = config.getParameter("neb_wulfjump_combo.windupTimer", 1.0)/2
		stateData.timer = config.getParameter("neb_wulfjump_combo.chargeTime", 0.3)
		
		stateData.comboCount = 0
		stateData.winddownTimer = config.getParameter("neb_wulfjump_combo.winddownTime", 1.0)
	end
	return false
  end
  
  --monster.setDamageOnTouch(false)
  animator.setAnimationState("body", "idle")
  self.damageListener = nil
  self.state.stateCooldown(neb_wulfjump_combo.cooldownCategory,config.getParameter("neb_wulfjump_combo.cooldownTime"))
  return true
end

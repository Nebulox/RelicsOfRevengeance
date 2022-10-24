neb_wulfjump = {}

function neb_wulfjump.checkDistance()
  local minDistance = config.getParameter("neb_wulfjump.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfjump.maxDistance", 20)
  
  neb_wulfjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = math.abs(vec2.mag(neb_wulfjump.toTarget))
  
  if (distance > minDistance and distance < maxDistance ) then --distance check
	return true
  end
  
  return false
end

function neb_wulfjump.checkShortDistance()
  local minDistance = config.getParameter("neb_wulfjump.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfjump.maxDistance", 20)
  
  neb_wulfjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = math.abs(vec2.mag(neb_wulfjump.toTarget))
  
  if (distance > minDistance) then --distance check
	return true
  end
  
  return false
end

function neb_wulfjump.enter()
  neb_wulfjump.cooldownCategory = config.getParameter("neb_wulfjump.cooldownCategory")
  
  if not (self.state.stateCooldown(neb_wulfjump.cooldownCategory) == 0) then
	return nil 
  end
  
  if (not hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  if not neb_wulfjump.checkDistance() then
	return nil
  end
  
  
  return {
    windupTimer = config.getParameter("neb_wulfjump.windupTime", 1.0),
    timer = config.getParameter("neb_wulfjump.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfjump.winddownTime", 1.0)
  }
end

function neb_wulfjump.enteringState(stateData)
  animator.setAnimationState("body", "generalWindup")
  animator.playSound("spawnCharge")
end

function neb_wulfjump.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfjump.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfjump.toTarget[1])
  local xDir = 0
  
  if neb_wulfjump.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if (not neb_wulfjump.checkShortDistance() == true) and (self.state.stateCooldown("neb_wulfbackjump") == 0) then --transitions to backjump if too close
	
		--sb.logInfo("switch to different state!!")
		-- note: debatable if this even works....
		neb_wulfbackjump.enter()
		return true
	end
	
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt

    if stateData.timer <= 0 then
	  animator.setAnimationState("body", "pounce")
	  
	  --monster.setDamageParts({"jumpbite"})
	  local aimVector = world.distance(self.targetPosition, mcontroller.position())
	  local aimDir = math.atan(aimVector[2],aimVector[1])
	  
	  
	  local vel = config.getParameter("neb_wulfjump.jumpVelocity")
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

    return false
  end
  
  --monster.setDamageParts({})

  if stateData.winddownTimer > 0 then
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
	
	if stateData.winddownTimer <= 0.3 and stateData.counterTriggered then
		animator.setAnimationState("body", "outOfStagger",true)
		stateData.cancelListener = true
		stateData.counterTriggered = false
		stateData.countered = false
	end
	
	if stateData.countered then --mimics behavior from the actual source game - that being if Blade Wolf is parried, he'll bounce backwards from his jump attack.
		if not stateData.counterTriggered then
			local vel = config.getParameter("neb_wulfjump.jumpVelocity")
			mcontroller.setVelocity({vel[1] * -xDir * 0.5,vel[2] * 0.5})
			stateData.counterTriggered = true
			stateData.damageListener = nil
			animator.playSound("shatter")
			
			animator.setAnimationState("body", "intoStagger",true)
			--monster.setDamageOnTouch(false)
			
			stateData.winddownTimer = 2.0
		end
	else
		--sb.logInfo("ticking damage listener")
		if not stateData.cancelListener then
			stateData.damageListener:update()
		end
	end
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  animator.setAnimationState("body", "idle")
  
  --monster.setDamageOnTouch(false)
  self.damageListener = nil
  self.state.stateCooldown(neb_wulfjump.cooldownCategory,config.getParameter("neb_wulfjump.cooldownTime"))
  return true
end

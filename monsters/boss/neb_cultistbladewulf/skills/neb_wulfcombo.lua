neb_wulfcombo = {}

function neb_wulfcombo.checkDistance()
  local minDistance = config.getParameter("neb_wulfcombo.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfcombo.maxDistance", 20)
  
  neb_wulfcombo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = math.abs(vec2.mag(neb_wulfcombo.toTarget))
  
  if (distance > minDistance and distance < maxDistance ) then --distance check
	return true
  end
  
  return false
end

function neb_wulfcombo.enter()
  neb_wulfcombo.cooldownCategory = config.getParameter("neb_wulfcombo.cooldownCategory")
  
  if not (self.state.stateCooldown(neb_wulfcombo.cooldownCategory) == 0) then
	return nil 
  end
  
  if (not hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfcombo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  if not neb_wulfcombo.checkDistance() then
	return nil
  end
  
  return {
	comboCount = 2,
    windupTimer = config.getParameter("neb_wulfcombo.windupTime", 1.0),
    timer = config.getParameter("neb_wulfcombo.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfcombo.comboWinddownTime", 1.0)
  }
end

function neb_wulfcombo.enteringState(stateData)
  animator.setAnimationState("body", "generalWindup")
  
  animator.setAnimationState("flash", "on")
  
  animator.playSound("spawnCharge")
end

function neb_wulfcombo.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfcombo.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfcombo.toTarget[1])
  local xDir = 0
  
  if neb_wulfcombo.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	--if (not neb_wulfcombo.checkDistance() == true) and (self.state.stateCooldown("neb_wulfbackjump") == 0) then --transitions to backjump if too close
	
		--sb.logInfo("switch to different state!!")
		--neb_wulfbackjump.enter()
		--return true
	--end
	
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt

    if stateData.timer <= 0 then
	  if stateData.comboCount == 2 or stateData.comboCount == 0 then
		animator.setAnimationState("body", "bite",true)
	  else
		animator.setAnimationState("body", "pounce",true)
	  end
	  
	  local vel = config.getParameter("neb_wulfcombo.jumpVelocity")
	  mcontroller.setVelocity({vel[1] * xDir,vel[2]})
      animator.playSound("spawnAdd")
	  
	  stateData.countered = false
	  stateData.counterTriggered = false
	  stateData.cancelListener = false
	  
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
    stateData.winddownTimer = stateData.winddownTimer - dt
	
	if stateData.winddownTimer <= 0.3 and stateData.counterTriggered then
		animator.setAnimationState("body", "outOfStagger",true)
		stateData.cancelListener = true
		stateData.counterTriggered = false
		stateData.countered = false
	end
	
	--if stateData.comboCount == 0 then
		if stateData.countered then --mimics behavior from the actual source game
			if not stateData.counterTriggered then
				local vel = config.getParameter("neb_wulfcombo.jumpVelocity")
				mcontroller.setVelocity({vel[1] * -xDir * 0.5,vel[2] * 0.5})
				stateData.counterTriggered = true
				stateData.damageListener = nil
				--animator.playSound("shatter")
				
				stateData.comboCount = 0
				
				animator.setAnimationState("body", "intoStagger",true)
				--monster.setDamageOnTouch(false)
			
				stateData.winddownTimer = 0.75
				
				status.modifyResource("poise", -20)
			end
		else
			--sb.logInfo("ticking damage listener")
			if not stateData.cancelListener then
				stateData.damageListener:update()
			end
		end
	--end
    return false
  end
  
  if stateData.comboCount > 0 then 
	stateData.comboCount = stateData.comboCount - 1
	stateData.windupTimer = config.getParameter("neb_wulfcombo.comboWindupTime", 1.0)/2
    stateData.timer = config.getParameter("neb_wulfcombo.skillTime", 0.3)
    stateData.winddownTimer = config.getParameter("neb_wulfcombo.comboWinddownTime", 1.0)
	
	animator.playSound("spawnCharge")
	animator.setAnimationState("body", "generalWindup")
	
	if stateData.comboCount == 0 then
		--monster.setDamageOnTouch(false)
		stateData.winddownTimer = config.getParameter("neb_wulfcombo.winddownTime", 1.0)
	end
	
	return false
  end
  
  animator.setAnimationState("body", "idle")
  
  stateData.damageListener = nil
  self.state.stateCooldown(neb_wulfcombo.cooldownCategory,config.getParameter("neb_wulfcombo.cooldownTime"))
  return true
end

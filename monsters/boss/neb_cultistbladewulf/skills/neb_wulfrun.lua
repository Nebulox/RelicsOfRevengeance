neb_wulfrun = {}

function neb_wulfrun.checkDistance()
  local minDistance = config.getParameter("neb_wulfrun.minDistance", 5)
  local maxDistance = config.getParameter("neb_wulfrun.maxDistance", 20)
  
  local distance = math.abs(vec2.mag(neb_wulfrun.toTarget))
  
  if (distance > minDistance and distance < maxDistance ) then --distance check
	return true
  end
  
  return false
end

function neb_wulfrun.enter()
  neb_wulfrun.cooldownCategory = config.getParameter("neb_wulfrun.cooldownCategory")
  
  if not (self.state.stateCooldown(neb_wulfrun.cooldownCategory) == 0) then
	return nil 
  end
  
  if (not hasTarget() and mcontroller.onGround()) then return nil end
  
  neb_wulfrun.toTarget = world.distance(self.targetPosition, mcontroller.position())
  
  if not neb_wulfrun.checkDistance() then
	return nil
  end
  

  --if not self.moontants then self.moontants = 6 end

  --if self.moontants <= 1 then return nil end

  return {
    windupTimer = config.getParameter("neb_wulfrun.windupTime", 1.0),
    timer = config.getParameter("neb_wulfrun.skillTime", 0.3),
    winddownTimer = config.getParameter("neb_wulfrun.winddownTime", 1.0),
	runSpeed = config.getParameter("neb_wulfrun.runSpeed",40.0),
	jumpWindupTimer = 0,
	jumpWinddownTimer = 0,
	jumpTriggered = false
  }
end

function neb_wulfrun.enteringState(stateData)
  animator.setAnimationState("body", "jumpWindup")
  animator.playSound("spawnCharge")
end

function neb_wulfrun.update(dt, stateData)
  if not hasTarget() then return true end
  
  neb_wulfrun.toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(neb_wulfrun.toTarget[1])
  local xDir = 0
  
  if neb_wulfrun.toTarget[1] > 0 then
	xDir = 1
  else
	xDir = -1
  end

  if stateData.windupTimer > 0 then
    mcontroller.controlFace(targetDir)
    stateData.windupTimer = stateData.windupTimer - dt
	
	if stateData.windupTimer <= 0 then
		animator.setAnimationState("body", "run")
	end
    return false
  end
  
  if not stateData.jumpTriggered then
	mcontroller.controlFace(targetDir)
	mcontroller.setXVelocity(stateData.runSpeed * xDir)
	
	--sb.logInfo(sb.printJson(neb_wulfrun.checkDistance()))

	if not neb_wulfrun.checkDistance() then
		stateData.jumpWindupTimer = 0.01
		stateData.jumpWinddownTimer = 0.5
		--sb.logInfo("run into jump!")
		
		stateData.jumpTriggered = true
		--self.state.endState()
		--neb_wulfforcejump.enterWith({enteringJump = true})
		--neb_wulfspawnads.enterWith({enteringPhase = true})
	end
	
	return false
  end
  
  if stateData.jumpWindupTimer > 0 then
    --mcontroller.controlFace(targetDir)
    stateData.jumpWindupTimer = stateData.jumpWindupTimer - dt
	
	if stateData.jumpWindupTimer <= 0 then
		animator.setAnimationState("body", "pounce")
		local aimVector = world.distance(self.targetPosition, mcontroller.position())
		local aimDir = math.atan(aimVector[2],aimVector[1])
	  
		--local params = {}
		--params.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * 50
		--params.knockback = 50
		--local projectile = "meleebite"
	  
		--if stateData.comboCount == 1 then projectile = "meleeslash" end
	  
		--world.spawnProjectile(projectile, vec2.add(mcontroller.position(),{2.5*math.cos(aimDir),2.5*math.sin(aimDir)-1.0}), entity.id(), aimVector, true, params)
		--monster.setDamageOnTouch(true)
		
		local vel = config.getParameter("neb_wulfrun.jumpVelocity")
		mcontroller.setVelocity({vel[1] * xDir,vel[2]})
		animator.playSound("spawnAdd")
	  
		stateData.countered = false
		stateData.counterTriggered = false
	  
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
  
  if stateData.jumpWinddownTimer > 0 then
    --mcontroller.controlFace(targetDir)
	
	if stateData.jumpWinddownTimer <= 0.3 and stateData.counterTriggered then
		animator.setAnimationState("body", "outOfStagger",true)
		stateData.cancelListener = true
		stateData.counterTriggered = false
		stateData.countered = false
	end
	
	if stateData.countered then --mimics behavior from the actual source game - that being if Blade Wolf is parried, he'll bounce backwards from his jump attack.
		if not stateData.counterTriggered then
			local vel = config.getParameter("neb_wulfrun.jumpVelocity")
			mcontroller.setVelocity({vel[1] * -xDir * 0.5,vel[2] * 0.5})
			stateData.counterTriggered = true
			stateData.damageListener = nil
			animator.playSound("shatter")
			
			animator.setAnimationState("body", "intoStagger",true)
			--monster.setDamageOnTouch(false)
			
			stateData.jumpWinddownTimer = 0.75
		end
	else
		--sb.logInfo("ticking damage listener")
		if not stateData.cancelListener then
			stateData.damageListener:update()
		end
	end
	
    stateData.jumpWinddownTimer = stateData.jumpWinddownTimer - dt
    return false
  end
  
  animator.setAnimationState("body", "idle")
  
  --monster.setDamageOnTouch(false)
  stateData.damageListener = nil
  self.state.stateCooldown(neb_wulfrun.cooldownCategory,config.getParameter("neb_wulfrun.cooldownTime"))
  return true
end

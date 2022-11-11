--Not really an attack, just some idle time between attacks
neb_wulfspawnads = {
  --stateNames = {"one", "two", "three", "four", "five", "six"}
}

-- function neb_wulfspawnads.enter()
  -- if not hasTarget() then return nil end

  -- --if not self.moontants then self.moontants = 6 end

  -- --if self.moontants <= 1 then return nil end

  -- return {
    -- windupTimer = 1.0,
    -- timer = config.getParameter("neb_wulfspawnads.skillTime", 0.3),
    -- winddownTimer = 1.0,
    -- spawnAngle = config.getParameter("neb_wulfspawnads.spawnAngle", 0.2),
    -- direction = util.randomDirection(),
    -- rotateInterval = config.getParameter("neb_wulfspawnads.rotateInterval", 0.1),
    -- rotateAngle = config.getParameter("neb_wulfspawnads.rotateAngle", 0.02)
  -- }
-- end

function neb_wulfspawnads.enterWith(args) --this way, skills that function by triggering on phase change ONLY trigger on phase change!!
  if not args or not args.enteringPhase then return nil end --also necessary for this function
  
  if not hasTarget() then return nil end

  --if not self.moontants then self.moontants = 6 end

  --if self.moontants <= 1 then return nil end

  return {
    windupTimer = 0.3,
    timer = config.getParameter("neb_wulfspawnads.skillTime", 0.3),
    winddownTimer = 0.5,
    spawnAngle = config.getParameter("neb_wulfspawnads.spawnAngle", 0.2),
    direction = util.randomDirection(),
    rotateInterval = config.getParameter("neb_wulfspawnads.rotateInterval", 0.1),
    rotateAngle = config.getParameter("neb_wulfspawnads.rotateAngle", 0.02)
  }
end

function neb_wulfspawnads.enteringState(stateData)
end

function neb_wulfspawnads.update(dt, stateData)
  --mcontroller.controlFly({0,0})

  if stateData.windupTimer > 0 then
    stateData.windupTimer = stateData.windupTimer - dt
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt

    if stateData.timer < 0 then
	   animator.setGlobalTag("fullbrightImage", "/monsters/boss/neb_cultistbladewulf/neb_cultistbladewulffullbright.png")
	  animator.setAnimationState("body", "enterPhase")
	
	  --update this later, spawn actual NPCs or mobs for release. placeholder right now.
      world.spawnProjectile("moontantspawn", mcontroller.position(), entity.id(), {0,-1}, false, {power = 0, level = monster.level()} )


      --animator.playSound("spawnAdd")
    end

    return false
  end

  if stateData.winddownTimer > 0 then
	
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end
  
  animator.setAnimationState("body", "idle")

  return true
end

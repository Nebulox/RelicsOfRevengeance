--Not really an attack, just some idle time between attacks
neb_wulfspawnads = {
  stateNames = {"one", "two", "three", "four", "five", "six"}
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
    windupTimer = 0.5,
    timer = config.getParameter("neb_wulfspawnads.skillTime", 0.3),
    winddownTimer = 0.5,
    spawnAngle = config.getParameter("neb_wulfspawnads.spawnAngle", 0.2),
    direction = util.randomDirection(),
    rotateInterval = config.getParameter("neb_wulfspawnads.rotateInterval", 0.1),
    rotateAngle = config.getParameter("neb_wulfspawnads.rotateAngle", 0.02)
  }
end

function neb_wulfspawnads.enteringState(stateData)
  --animator.setAnimationState("eye", "windup")
  animator.playSound("spawnCharge")
end

function neb_wulfspawnads.update(dt, stateData)
  --mcontroller.controlFly({0,0})

  if stateData.windupTimer > 0 then
    stateData.windupTimer = stateData.windupTimer - dt
    return false
  end

  if stateData.timer > 0 then
    stateData.timer = stateData.timer - dt

    --local duration = config.getParameter("crystalShatterAttack.skillTime", 1) - stateData.timer
    --local angle = crystalShatterAttack.angleFactorFromTime(stateData.timer, stateData.rotateInterval) * stateData.rotateAngle - stateData.rotateAngle/2
    --animator.rotateGroup("all", angle, true)

    if stateData.timer < 0 then
      --local downAngle = -0.5 * math.pi
      --local spawnAngle = downAngle + stateData.direction * stateData.spawnAngle
      --local aimVector = {math.cos(spawnAngle), math.sin(spawnAngle)}
      world.spawnProjectile("moontantspawn", mcontroller.position(), entity.id(), {0,-1}, false, {power = 0, level = monster.level()} )

      --self.moontants = self.moontants - 1
      --animator.setAnimationState("organs", neb_wulfspawnads.stateNames[self.moontants])

      animator.playSound("spawnAdd")
    end

    return false
  end

  if stateData.winddownTimer > 0 then
    --animator.rotateGroup("all", 0, true)
    --animator.setAnimationState("eye", "winddown")
    stateData.winddownTimer = stateData.winddownTimer - dt
    return false
  end

  return true
end

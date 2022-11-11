--------------------------------------------------------------------------------
dieState = {}

function dieState.enterWith(params)
  if not params.die then return nil end
  
  rangedAttack.setConfig(config.getParameter("projectiles.deathexplosion.type"), config.getParameter("projectiles.deathexplosion.config"), 0.2)

  return {
    timer = 1,
    deathSound = true
  }
end

function dieState.enteringState(stateData)
  --Open generator door
  world.objectQuery(mcontroller.position(), 80, { name = "cultistdoor", callScript = "openDoor" })

  --Chance to drop sword
  if math.random() < config.getParameter("swordDropChance", 0.05) then
    local aimVec = {math.random() * 2 - 1, math.random() * 3 + 2}
    world.spawnProjectile("neb-murasamadropprojectile", mcontroller.position(), entity.id(), aimVec)
    animator.playSound("rareDrop")
  end
  
  animator.playSound("hurt")
end

function dieState.update(dt, stateData)
  stateData.timer = stateData.timer - dt

  if stateData.timer < 0.2 and stateData.deathSound then
    animator.playSound("death")
    stateData.deathSound = false
  end

  if stateData.timer < 0 then
    self.dead = true
  end
  return false
end

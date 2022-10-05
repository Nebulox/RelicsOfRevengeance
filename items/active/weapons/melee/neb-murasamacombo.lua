-- Melee primary ability
NebMurasamaCombo = WeaponAbility:new()

function NebMurasamaCombo:init()
  self.comboStep = 1

  self.energyUsage = self.energyUsage or 0

  self:computeDamageAndCooldowns()

  self.weapon:setStance(self.stances.idle)

  self.edgeTriggerTimer = 0
  self.flashTimer = 0
  self.cooldownTimer = self.cooldowns[1]

  self.animKeyPrefix = self.animKeyPrefix or ""

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

-- Ticks on every update regardless if this is the active ability
function NebMurasamaCombo:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
    if self.cooldownTimer == 0 then
      self:readyFlash()
    end
  end
  world.debugText(self.cooldownTimer, vec2.add(mcontroller.position(), {0, 1}), "red")

  if self.flashTimer > 0 then
    self.flashTimer = math.max(0, self.flashTimer - self.dt)
    if self.flashTimer == 0 then
      animator.setGlobalTag("bladeDirectives", "")
    end
  end

  --self.activatingFireMode = fireMode ~= "none" and fireMode or self.activatingFireMode

  self.edgeTriggerTimer = math.max(0, self.edgeTriggerTimer - dt)
  --if self.lastFireMode ~= (self.activatingFireMode or self.abilitySlot) and fireMode == (self.activatingFireMode or self.abilitySlot) then
  if self.lastFireMode == "none" and fireMode ~= "none" then
    self.edgeTriggerTimer = self.edgeTriggerGrace
  end
  self.lastFireMode = fireMode
  if not self.weapon.currentAbility and self:shouldActivate() then
    self:setState(self.windup, self.activatingFireMode == "alt" and "Unsheath" or nil)
  end
end

-- State: windup
function NebMurasamaCombo:windup(overWrite)
  local stanceSuffix = (overWrite or self.comboStep)
  local stance = self.stances["windup" .. stanceSuffix]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)

  if stance.bladeStorm then
    local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
    animator.setAnimationState("swoosh", animStateKey)
    animator.playSound(animStateKey)
	
    animator.setAnimationState("sheathState", "halfSheathed")

    local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
    animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  end
  
  self.edgeTriggerTimer = 0
  
  local timer = 0
  local charged = "regular"
  if stance.holdTime then
    --while timer < stance.holdTime and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
	local ringFactor = 0
	local ringRotation = math.random() * math.pi * 2
	
	animator.playSound("chargeSheath", -1)
	local targetGrav = world.gravity(mcontroller.position()) * -0.005
    while timer < stance.holdTime and self.fireMode ~= "none" do
	  timer = timer + self.dt
	  
	  animator.setSoundPitch("chargeSheath", ringFactor > 0 and 0.1 + ringFactor or 0.01)
	  if timer > stance.duration then		
	    ringFactor = timer / (stance.holdTime - stance.duration)
	    mcontroller.controlApproachVelocity({0, targetGrav}, 1000 * ringFactor)
		
	    ringRotation = ringRotation + (self.dt * self.chargeRingConfig.rotationRate)
	    local ring = {
		  fullbright = self.chargeRingConfig.fullbright,
		  image = self.chargeRingConfig.image,
	      color = {255, 255, 255, math.min(255, 255 * ringFactor)},
	      scale = (ringFactor * (self.chargeRingConfig.startEndScale[2] - self.chargeRingConfig.startEndScale[1]) + self.chargeRingConfig.startEndScale[1]),
	      centered = true,
		  rotation = ringRotation,
          position = vec2.add(mcontroller.position(), activeItem.handPosition()),
		
		  renderLayer = mcontroller.facingDirection() > 0 and "Player-1" or "Player+1"
        }
        activeItem.setScriptedAnimationParameter("ringProperties", ring)
	  end

      coroutine.yield()
    end
	animator.stopAllSounds("chargeSheath")
    if timer >= stance.holdTime then
      charged = "charged"
    elseif timer < stance.duration then
	  util.wait(stance.duration - timer)
	end
  else
    util.wait(stance.duration)
  end
  activeItem.setScriptedAnimationParameter("ringProperties", nil)
  animator.setGlobalTag("stanceDirectives", "")

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end
  
  if stance.bladeStorm then
    self:setState(self.bladeStorm)
  elseif self.stances["preslash" .. stanceSuffix] then
    self:setState(self.preslash, overWrite)
  else
    self:setState(self.fire, overWrite, charged)
  end
end

-- State: wait
-- waiting for next combo input
function NebMurasamaCombo:bladeStorm()
  local stance = self.stances["fire" .. self.comboStep]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local oldPosition = mcontroller.position()
  local targetPosition = vec2.add(oldPosition, vec2.rotate({mcontroller.facingDirection() * stance.target[1], stance.target[2]}, self.weapon.aimAngle * mcontroller.facingDirection()))

  local groundCollision = world.lineTileCollisionPoint(mcontroller.position(), targetPosition)
  if groundCollision then
    local groundPos, normal = groundCollision[1], groundCollision[2]
    targetPosition = groundPos
  end
	
  local targets = world.entityQuery(mcontroller.position(), stance.forgivenessRange, {
    withoutEntityId = activeItem.ownerEntityId(),
    includedTypes = {"creature"},
    order = "nearest"
  })
  if targets[1] and entity.entityInSight(targets[1]) and world.entityCanDamage(activeItem.ownerEntityId(), targets[1]) then
	targetPosition = world.entityPosition(targets[1])
  end
  world.resolvePolyCollision(mcontroller.collisionPoly(), vec2.add(targetPosition, stance.targetOffset), stance.targetTolerance)
  
  if stance.projectileType and targetPosition then
	local angleToTarget = vec2.angle({targetPosition[2] - mcontroller.position()[2], targetPosition[1] - mcontroller.position()[1]})
	local aimVector = vec2.rotate({0, 1}, -angleToTarget)
	--aimVector[1] = aimVector[1] * mcontroller.facingDirection()
	
	local params = stance.projectileParameters or {}
	params.power = stance.projectileDamage * config.getParameter("damageLevelMultiplier")
	params.powerMultiplier = activeItem.ownerPowerMultiplier()
	params.speed = util.randomInRange(params.speed)
		
    world.spawnProjectile(
	  stance.projectileType,
	  targetPosition,
	  activeItem.ownerEntityId(),
	  aimVector,
	  false,
	  params
	)
  end
  
  util.wait(stance.duration, function()
  end)
  animator.setGlobalTag("stanceDirectives", "")
  animator.setAnimationState("sheathState", "unsheathed")

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1
  end
end

function NebMurasamaCombo:wait(overWrite)
  local stanceSuffix = (overWrite or (self.comboStep - 1))
  local stance = self.stances["wait" .. stanceSuffix]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if self:shouldActivate() then
      self:setState(self.windup, overWrite and nil or (self.activatingFireMode == "alt" and "Unsheath"))
      return
    end
  end)
  animator.setGlobalTag("stanceDirectives", "")

  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  self.comboStep = 1
end

-- State: preslash
-- brief frame in between windup and fire
function NebMurasamaCombo:preslash(overWrite, charged)
  local stanceSuffix = (overWrite or self.comboStep)
  local stance = self.stances["preslash" .. stanceSuffix]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  util.wait(stance.duration)
  animator.setGlobalTag("stanceDirectives", "")

  self:setState(self.fire, overWrite, charged)
end

-- State: fire
function NebMurasamaCombo:fire(overWrite, charged)
  local stanceSuffix = (overWrite or self.comboStep)
  local stance = self.stances["fire" .. stanceSuffix]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)
  self.weapon:updateAim()

  local isCharged = (charged == "charged")
  local animStateKey = self.animKeyPrefix .. "fire" .. (overWrite or (self.comboStep > 1 and self.comboStep or "")) .. (isCharged and "Charged" or "")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)
  
  if isCharged then
    status.overConsumeResource("energy", status.resourceMax("energy"))
  end

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)
  
  local damageConfig = overWrite and self.unsheathDamageConfig[charged] or self.stepDamageConfig[self.comboStep]
  local damageArea = partDamageArea("swoosh")
  util.wait(stance.duration, function()
    self.weapon:setDamage(damageConfig, damageArea)
  end)
  animator.setGlobalTag("stanceDirectives", "")
  
  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait, isCharged and nil or overWrite)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
    self.comboStep = 1
  end
end

function NebMurasamaCombo:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
    if self.comboStep > 1 then
	  self.activatingFireMode = self.fireMode
      return self.edgeTriggerTimer > 0
    else
      --return self.fireMode == (self.activatingFireMode or self.abilitySlot)
	  self.activatingFireMode = self.fireMode
      return self.fireMode ~= "none"
    end
  end
end

function NebMurasamaCombo:readyFlash()
  animator.setGlobalTag("bladeDirectives", self.flashDirectives)
  self.flashTimer = self.flashTime
end

function NebMurasamaCombo:computeDamageAndCooldowns()
  local attackTimes = {}
  for i = 1, self.comboSteps do
    local attackTime = self.stances["windup"..i].duration + self.stances["fire"..i].duration
    if self.stances["preslash"..i] then
      attackTime = attackTime + self.stances["preslash"..i].duration
    end
    table.insert(attackTimes, attackTime)
  end

  self.cooldowns = {}
  local totalAttackTime = 0
  local totalDamageFactor = 0
  for i, attackTime in ipairs(attackTimes) do
    self.stepDamageConfig[i] = util.mergeTable(copy(self.damageConfig), self.stepDamageConfig[i])
    self.stepDamageConfig[i].timeoutGroup = "primary"..i

    local damageFactor = self.stepDamageConfig[i].baseDamageFactor
    self.stepDamageConfig[i].baseDamage = damageFactor * self.baseDps * self.fireTime

    totalAttackTime = totalAttackTime + attackTime
    totalDamageFactor = totalDamageFactor + damageFactor

    local targetTime = totalDamageFactor * self.fireTime
    local speedFactor = 1.0 * (self.comboSpeedFactor ^ i)
    table.insert(self.cooldowns, math.max(0.75, (targetTime - totalAttackTime) * speedFactor))
  end
end

function NebMurasamaCombo:uninit()
  self.weapon:setDamage()
end

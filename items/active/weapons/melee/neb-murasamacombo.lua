require "/scripts/status.lua"

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
    if self.wasAlt and (fireMode == "primary") then
      self.edgeTriggerTimer = self.edgeTriggerGrace
	elseif not self.wasAlt then
      self.edgeTriggerTimer = self.edgeTriggerGrace
	end
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
  
  self.wasAlt = overWrite
  self.edgeTriggerTimer = 0
  
  local timer = 0
  local charged = "regular"
  if stance.holdTime then
    --while timer < stance.holdTime and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
	local ringFactor = 0
	local ringRotation = math.random() * math.pi * 2
	
	animator.playSound("chargeSheath", -1)
	local targetGrav = world.gravity(mcontroller.position()) * -0.005
	
	local bufferTimer = 1.0 --can hold for this long after being fully charged
    while timer < stance.holdTime + bufferTimer and self.fireMode ~= "none" do
	  --Count down timer
	  timer = timer + self.dt
	  
	  --Prevent energy regen while charging
	  status.setResourcePercentage("energyRegenBlock", 0.6)
	  
	  --Enable walk while charging
	  if stance.walkWhileHolding == true then
        mcontroller.controlModifiers({runningSuppressed=true})
	  end
	  
	  --Charge sound
	  animator.setSoundPitch("chargeSheath", ringFactor > 0 and 0.1 + ringFactor or 0.01)
	  --If the charge has made a enough progress to be considered a charge attack, trigger the visual effects
	  if timer > stance.duration then
	    --The factor (0-1) of the charge, 1 being full
	    ringFactor = math.min((timer / (stance.holdTime - stance.duration)),1.125) -- find mathmatical reason for this constant value?
		
	    --Fake time slow effect, where the player slows down while charging
	    mcontroller.controlApproachVelocity({0, targetGrav}, 350 * ringFactor)
		
		--Ring local animator VFX
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
	  
	  if timer > stance.holdTime then animator.stopAllSounds("chargeSheath") end

      coroutine.yield()
    end
	--Finish our charging
	animator.stopAllSounds("chargeSheath")
    if timer >= stance.holdTime then
      charged = "charged"
	  
	  --Charge finish effects
	  animator.setGlobalTag("bladeDirectives", stance.chargeDirectives or "")
	  animator.playSound("chargePing")
	end
  end
  
  --Clear effects
  animator.setGlobalTag("bladeDirectives", self.chargeDirectives or "")
  activeItem.setScriptedAnimationParameter("ringProperties", nil)
  
  util.wait(stance.duration)

  if self.energyUsage then
    status.overConsumeResource("energy", self.energyUsage)
  end
  
  animator.setGlobalTag("stanceDirectives", "")
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

function NebMurasamaCombo:wait(overWrite, wasCharged, shortenDuration)
  local stanceSuffix = (overWrite or (self.comboStep - 1))
  local stance = self.stances["wait" .. stanceSuffix]

  animator.setGlobalTag("stanceDirectives", stance.directives or "")
  self.weapon:setStance(stance)

  util.wait(stance.duration, function()
    if wasCharged then
      return
    elseif self:shouldActivate() then
      self:setState(self.windup, self.activatingFireMode == "alt" and "Unsheath" or nil)
      return
	end
  end)

  self.wasAlt = nil
  
  self.cooldownTimer = math.max(0, self.cooldowns[self.comboStep - 1] - stance.duration)
  if shortenDuration then self.cooldownTimer = self.cooldownTimer * 0.25 end
  
  animator.setGlobalTag("stanceDirectives", "")
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
  
  local shieldDamageListener = nil
  
  local damageConfig = {}
  for x, y in pairs(self.stepDamageConfig[self.comboStep]) do
    damageConfig[x] = y
  end
  
  if overWrite then
    --Dynamically multiply damage based on current step
    damageConfig.knockback = damageConfig.knockback * 1.35
    damageConfig.baseDamage = damageConfig.baseDamage * 1.35
    if isCharged then
	  local chargeTime = self.stances["windup" .. stanceSuffix].holdTime or 1
      damageConfig.knockback = damageConfig.knockback * 1.35 * chargeTime
      damageConfig.baseDamage = damageConfig.baseDamage * 1.35 * chargeTime
	  
	  --Consume energy if charged
      status.overConsumeResource("energy", status.resourceMax("energy"))
    end
  
    --Seting up the damage listener for actions on shield hit
	self.hasBlocked = false --Yes, I could've retooled the "hit" var for this purpose, but I thought it would be better to use a seperate variable regardless - Echo
    shieldDamageListener = damageListener("damageTaken", function(notifications)
	  --Optionally spawn a parry projectile when the shield is hit
	  for _, notification in pairs(notifications) do
	    if notification.hitType == "ShieldHit" then
		  if not self.hasBlocked then
			self.hasBlocked = true
		  end
		  
		  --Fire a projectile when the shield is hit
		  if #self.reflectedProjectiles > 0 and not hit then
		    animator.playSound("parry")
	        hit = true
		    status.overConsumeResource("energy", status.resourceMax("energy"))
		  end
		
		  --Projectile parameters
		  for _, projectileConfig in ipairs(self.reflectedProjectiles) do
		    local params = copy(projectileConfig)
		    --params.power = params.power * config.getParameter("damageLevelMultiplier")
		    params.power = self.baseDps * config.getParameter("damageLevelMultiplier") / #self.reflectedProjectiles
		    params.speed = params.speed * 1.25
		  
		    --Projectile spawn code
		    if not world.pointTileCollision(mcontroller.position()) then
		      for i = 1, self.projectileCount or 1 do
			    local aimAngle = math.atan(params.position[2] - activeItem.ownerAimPosition()[2], params.position[1] - activeItem.ownerAimPosition()[1])
			    local aimVec = vec2.rotate({1,0}, -aimAngle)
		  	    aimVec[1] = aimVec[1] * -1
		    	world.spawnProjectile(projectileConfig.projectileName, params.position, activeItem.ownerEntityId(), aimVec, false, params)
		      end
		    end
		  end
		
		  return
	    end
	  end
    end)
  end

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)
  
  self.reflectedProjectiles = {}
  local populatedProjectiles = false
  local damageArea = partDamageArea("swoosh")
  util.wait(stance.duration, function()
	if shieldDamageListener then 
	  shieldDamageListener:update() 
	
	  local shieldPoly = animator.partPoly("swoosh", "damageArea")
      activeItem.setItemShieldPolys({shieldPoly})
	  
	  if isCharged then
		foundProjectiles = world.entityQuery(mcontroller.position(), 7, 
		  {
			withoutEntityId = entity.id(),
			includedTypes = {"projectile"},
			order = "nearest"
		  }
		)
		if #foundProjectiles > 0 and not populatedProjectiles then
		  populatedProjectiles = true
		  for _, projectile in ipairs(foundProjectiles) do
			local projectileName = world.entityName(projectile)
			local projectileConfig = root.projectileConfig(projectileName)
			projectileConfig.position = world.entityPosition(projectile)
			if not projectileConfig.piercing then
			  table.insert(self.reflectedProjectiles, projectileConfig)
			end
		  end
		end
	  end
	end
	
    self.weapon:setDamage(damageConfig, damageArea)
  end)
  activeItem.setItemShieldPolys({})
  
  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait, overWrite, isCharged, self.hasBlocked)
  else
    self.cooldownTimer = self.cooldowns[self.comboStep]
	if shortenDuration then self.cooldownTimer = self.cooldownTimer * 0.25 end
	
    animator.setGlobalTag("stanceDirectives", "")
    self.comboStep = 1
  end
end

function NebMurasamaCombo:shouldActivate()
  if self.cooldownTimer == 0 and (self.energyUsage == 0 or not status.resourceLocked("energy")) then
	self.activatingFireMode = self.fireMode
    if self.comboStep > 1 then
      return self.edgeTriggerTimer > 0
    else
      --return self.fireMode == (self.activatingFireMode or self.abilitySlot)
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

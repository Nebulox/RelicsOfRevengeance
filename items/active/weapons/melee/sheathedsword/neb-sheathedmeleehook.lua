neb_originalMeleeInit = init
function init(...)
  neb_originalMeleeInit(...)
  
  self.animConfig = config.getParameter("scriptedAnimationParameters", {})
  
  animator.setAnimationState("sheathState", "hidden")
  self.initCooldownTimer = config.getParameter("primaryAbility").fireTime --cooldown timer to prevent initial premature unsheathing of sword
end

neb_originalMeleeUpdate = update
function update(dt, fireMode, shiftHeld, ...)
  neb_originalMeleeUpdate(dt, fireMode, shiftHeld, ...)
  
  self.sheathed = math.max(0, (self.sheathed or 0) - dt)
  self.initCooldownTimer = math.max(0, self.initCooldownTimer  - dt)
  
  if fireMode ~= "none" and self.initCooldownTimer == 0 then
    self.sheathed = config.getParameter("sheathTimer", 2)
  end
  
  --activeItem.setHoldingItem(self.sheathed > 0)
  if self.sheathed == 0 and animator.animationState("sheathState") == "unsheathed" then
    animator.setAnimationState("sheathState", "hidden")
	  animator.playSound("unsheathSword")
  elseif self.sheathed > 0 and animator.animationState("sheathState") == "hidden" then
    animator.setAnimationState("sheathState", "unsheathed")
  end
  
  local state = self.sheathed == 0 and "sheathed" or "unsheathed"
  if animator.animationState("sheathState") == "sheathed" or animator.animationState("sheathState") == "halfSheathed" then
    state = "hidden"
  end
  updateSheath(state)
end

function getBobYOffset()
  local shoulderOffset = {-3 / 8, (-1 + 0.5) / 8} --from humanoid.config, could perhaps derive based on species to see if it needs to? root.assetJson based on species name shouldnt be too hard but maybe not worth it, probs do in init

  local target = {mcontroller.position()[1] + 50, mcontroller.position()[2]} --cant be too close otherwise its weird as fuckl
  local angle = activeItem.aimAngle(0, target)

  local shoulderX = mcontroller.position()[1] + shoulderOffset[1]
  local shoulderBaseY = mcontroller.position()[2] + shoulderOffset[2]

  local dx = target[1] - shoulderX
  local actualShoulderY = target[2] - math.tan(angle) * dx

  return actualShoulderY - shoulderBaseY
end

function updateSheath(state)
  local weaponRot = (((math.log(math.abs(mcontroller.xVelocity()) + 0.35, 3) + 1) * (mcontroller.xVelocity() > 0 and 1 or -1)) * mcontroller.facingDirection() + ((math.log(math.abs(mcontroller.yVelocity()) + 0.35, 2) + 1) * (mcontroller.yVelocity() > 0 and -1 or 1)))
  local sheathLayer = self.animConfig.alwaysBehind and -1 or (mcontroller.facingDirection() * (self.animConfig.zLevelFlipped and 1 or -1))
  
  local sheathProperties = {}
  
  local bobOffset = {0, getBobYOffset()}

  local sheathRotation = ((self.animConfig.sheathRotation or 90) + weaponRot) * (math.pi/180) + (mcontroller.rotation() * -mcontroller.facingDirection())
  local base = {
    image = self.animConfig.sheathSprites[state] or "/assetmissing.png",
    rotation = sheathRotation,
    mirrored = mcontroller.facingDirection() > 0,
    offset = vec2.add(vec2.mul(self.animConfig.sheathOffset or {0, -1.25}, {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0}),
    renderLayer = sheathLayer > 0 and "Player+1" or "Player-2",
    bobOffset = bobOffset
  }
  local fullbright = {
    image = self.animConfig.sheathSpritesFullbright[state] or "/assetmissing.png",
    rotation = sheathRotation,
    mirrored = mcontroller.facingDirection() > 0,
    fullbright = true,
    offset = vec2.add(vec2.mul(self.animConfig.sheathOffset or {0, -1.25}, {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0}),
    renderLayer = sheathLayer > 0 and "Player+2" or "Player-1",
    bobOffset = bobOffset
  }
  table.insert(sheathProperties, base)
  table.insert(sheathProperties, fullbright)
  
  activeItem.setScriptedAnimationParameter("neb-sheathProperties", sheathProperties)
  --player.setProperty("neb-sheathProperties", sheathProperties)
end

neb_originalMeleeUninit = uninit
function uninit(...)
  neb_originalMeleeUninit(...)
  player.setProperty("neb-sheathSprite", nil)
end
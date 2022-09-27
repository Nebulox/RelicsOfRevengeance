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
  
  activeItem.setHoldingItem(self.sheathed > 0)
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

function updateSheath(state)
  local weaponRot = ((math.log(math.abs(mcontroller.xVelocity()) + 0.35, 3) + 1) * (mcontroller.xVelocity() > 0 and 1 or -1)) * mcontroller.facingDirection() + ((math.log(math.abs(mcontroller.yVelocity()) + 0.35, 2) + 1) * (mcontroller.yVelocity() > 0 and -1 or 1))
  local sheathLayer = mcontroller.facingDirection() * (config.getParameter("zLevelFlipped", false) and -1 or 1)
  
  local sheathProperties = {}
  
  --world.debugText(weaponRot, vec2.add(mcontroller.position(), {0, 2}), "yellow")
  
  local base = {
    image = self.animConfig.sheathSprites[state] or "/assetmissing.png",
	rotation = ((self.animConfig.sheathRotation or 90) + weaponRot) * (math.pi/180),
	mirrored = mcontroller.facingDirection() > 0,
	position = vec2.add(mcontroller.position(), vec2.add(vec2.mul(self.animConfig.sheathOffset or {0, -1.25}, {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0})),
	renderLayer = sheathLayer > 0 and "Player+1" or "Player-2"
  }
  local fullbright = {
    image = self.animConfig.sheathSpritesFullbright[state] or "/assetmissing.png",
	rotation = ((self.animConfig.sheathRotation or 90) + weaponRot) * (math.pi/180),
	mirrored = mcontroller.facingDirection() > 0,
	fullbright = true,
	position = vec2.add(mcontroller.position(), vec2.add(vec2.mul(self.animConfig.sheathOffset or {0, -1.25}, {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0})),
	renderLayer = sheathLayer > 0 and "Player+2" or "Player-1"
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
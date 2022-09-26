neb_originalMeleeUpdate = update
function update(dt, fireMode, shiftHeld, ...)
  neb_originalMeleeUpdate(dt, fireMode, shiftHeld, ...)
  
  self.sheathed = math.max(0, (self.sheathed or 0) - dt)
  if fireMode ~= "none" then
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
  local sheathProperties = {
    image = config.getParameter("sheathSprites", {sheathed = "/assetmissing.png", unsheathed = "/assetmissing.png"})[state],
	rotation = (config.getParameter("sheathRotation", 90) + weaponRot) * (math.pi/180),
	mirrored = mcontroller.facingDirection() > 0,
	position = vec2.add(mcontroller.position(), vec2.add(vec2.mul(config.getParameter("sheathOffset", {0, -1.125}), {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0})),
	renderLayer = sheathLayer > 0 and "Player+1" or "Player-2"
  }
  activeItem.setScriptedAnimationParameter("neb-sheathProperties", sheathProperties)
  
  local sheathFullbrightProperties = {
    image = config.getParameter("sheathSpritesFullbright", {sheathed = "/assetmissing.png", unsheathed = "/assetmissing.png"})[state],
	rotation = (config.getParameter("sheathRotation", 90) + weaponRot) * (math.pi/180),
	mirrored = mcontroller.facingDirection() > 0,
	fullbright = true,
	position = vec2.add(mcontroller.position(), vec2.add(vec2.mul(config.getParameter("sheathOffset", {0, -1.125}), {mcontroller.facingDirection(), 1}), mcontroller.crouching() and {0, -0.5} or {0, 0})),
	renderLayer = sheathLayer > 0 and "Player+2" or "Player-1"
  }
  activeItem.setScriptedAnimationParameter("neb-sheathFullbrightProperties", sheathFullbrightProperties)
  --player.setProperty("neb-sheathProperties", sheathProperties)
end

neb_originalMeleeUninit = uninit
function uninit(...)
  neb_originalMeleeUninit(...)
  player.setProperty("neb-sheathSprite", nil)
end
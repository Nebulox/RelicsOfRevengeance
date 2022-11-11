require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.spinDirection = config.getParameter("spinDirection", -1)
  self.spinRate = config.getParameter("spinRate", 0.5)
  self.minSpinSpeed = config.getParameter("minSpinSpeed", 25)
end

function update(dt)
  --Spinning
  local direction = util.toDirection(mcontroller.velocity()[1]) * self.spinDirection
  local speed = math.max(self.minSpinSpeed, vec2.mag(mcontroller.velocity()))
  mcontroller.setRotation(mcontroller.rotation() + (speed * self.spinRate) * (dt * direction))
end

function destroy()
   world.spawnItem(config.getParameter("itemToDrop", "neb-hfmurasama"), mcontroller.position(), 1, {level = world.threatLevel()}, {0, 5})
end

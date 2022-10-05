require "/scripts/vec2.lua"

function init()
  mcontroller.setPosition(vec2.add(config.getParameter("startPosition", mcontroller.position()), {math.random() * config.getParameter("offset", 3) - config.getParameter("offset", 3) / 2, math.random() * config.getParameter("offset", 5) - config.getParameter("offset", 5)/2}))
  for _, action in ipairs(config.getParameter("soundActions", {})) do
    projectile.processAction(action)
  end
end

function destroy()
  if config.getParameter("loops", 0) > 0 then
    local action = {
      action = "projectile",
      type = world.entityName(entity.id()),
      config = {
	    damageRepeatTimeout = 0.15,
	    periodicActions = jarray(),
		
		startPosition = mcontroller.position(),
		loops = config.getParameter("loops", 0) - 1
	  },
      rotate = true,
      inheritDamageFactor = 1,
      fuzzAngle = 360
	}
	
	projectile.processAction(action)
  end
end
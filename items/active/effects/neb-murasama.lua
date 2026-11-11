require "/scripts/vec2.lua"

function update(dt)
  localAnimator.clearDrawables()
  
  --Sheath
  local sheathProperties = animationConfig.animationParameter("neb-sheathProperties")
  for _, sheath in ipairs(sheathProperties) do
    if sheath and sheath.image ~= "" and sheath.image ~= "/assetmissing.png" then
      sheath.centered = true
      sheath.position = vec2.add(vec2.add(activeItemAnimation.ownerPosition(), sheath.offset), sheath.bobOffset)
      localAnimator.addDrawable(sheath, sheath.renderLayer)
    end
  end

  --Charge Rings
  local ringProperties = animationConfig.animationParameter("ringProperties")
  
  if ringProperties then
	  localAnimator.addDrawable(ringProperties, ringProperties.renderLayer)
  end
end
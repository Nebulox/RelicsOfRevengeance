function update(dt)  localAnimator.clearDrawables()  local sheathProperties = animationConfig.animationParameter("neb-sheathProperties")  for _, sheath in ipairs(sheathProperties) do    if sheath and sheath.image ~= "" and sheath.image ~= "/assetmissing.png" then      sheath.centered = true	  sb.logInfo("%s" sheath)      localAnimator.addDrawable(sheath, sheath.renderLayer)    end  endend
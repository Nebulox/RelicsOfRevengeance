neb_skinoriginalMeleeInit = init
function init(...)
  neb_skinoriginalMeleeInit(...)
  
  if config.getParameter("skinConfigPath") then
    self.skinList = root.assetJson(config.getParameter("skinConfigPath"))
    self.skin = player.getProperty("neb-murasamaCurrentSkin", "traditional")
	
	updateWeaponSkin()
  end
end

neb_skinoriginalMeleeUpdate = update
function update(dt, fireMode, shiftHeld, ...)
  neb_skinoriginalMeleeUpdate(dt, fireMode, shiftHeld, ...)
  
  if self.skinList then
    self.skin = player.getProperty("neb-murasamaCurrentSkin", "traditional")
    if self.skin ~= self.lastSkin then
      updateWeaponSkin()
    end
    self.lastSkin = self.skin
  end
end

function updateWeaponSkin()
  local skinConfig = self.skinList.skins[self.skin]
  
  local currentItem = root.itemConfig(config.getParameter("itemName"))
  local newDescriptor = sb.mergeJson(currentItem, skinConfig)
  sb.logInfo("%s", newDescriptor)
  --root.createItem(ItemDescriptor descriptor, [float level], [unsigned seed])
end
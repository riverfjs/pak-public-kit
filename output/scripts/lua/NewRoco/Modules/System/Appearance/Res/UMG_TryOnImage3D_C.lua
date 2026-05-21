local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_TryOnImage3D_C = _G.NRCViewBase:Extend("UMG_TryOnImage3D_C")

function UMG_TryOnImage3D_C:OnConstruct()
  self.AvatarPlayer = nil
  self.FakeAvatar = nil
  self.camera = nil
  self.captureComponent = nil
  self.bIsWearingWand = false
  self.curWandId = nil
  self._SalonOverrides = {}
  self._GlassesOverrideId = {}
  self.curPendanta = nil
  self.curPendantaFromUpgrade = false
  self.curHelmetId = nil
  Log.Dump(self, 4, "UMG_TryOnImage3D_C:InitInfo")
end

function UMG_TryOnImage3D_C:SetModule(module)
  if not self.module then
    self.module = module
  end
end

function UMG_TryOnImage3D_C:OnActive()
  Log.Error("UMG_TryOnImage3D_C:OnActive")
end

function UMG_TryOnImage3D_C:OnDeactive()
end

function UMG_TryOnImage3D_C:OnAddEventListener()
end

function UMG_TryOnImage3D_C:OnDestruct()
  self.module:ClearRotAvatarPlayer("TryOn")
end

function UMG_TryOnImage3D_C:SetFirstSuit(firstFashions, firstSalons, firstSuitId)
  self:CreateAvatarPlayer(firstFashions, firstSalons, firstSuitId)
end

function UMG_TryOnImage3D_C:CreateAvatarPlayer(firstFashions, firstSalons, firstSuitId)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local res = self.module:GetRes(self.module:GetAvatarResPath(player.gender), "AppearanceTryOn")
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 1.6500000000000001)
  local zeroTransform = UE4.FTransform(quat, UE4.FVector(-986231.6875, 937638.8125, 688))
  self.AvatarPlayer = self.TryOnWorldView:SpawnActor(res, zeroTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.AvatarPlayer:SetActorHiddenInGame(true)
  local count = 0
  local bAvatarShown = false
  local bNeedFallback = true
  self:DelayFrames(10, function()
    if bNeedFallback and self.AvatarPlayer and not bAvatarShown then
      self.AvatarPlayer:SetActorHiddenInGame(false)
      bAvatarShown = true
    end
  end)
  self.AvatarPlayer.OnLoadAvatarActorComplete:Bind(self.AvatarPlayer, function()
    if 1 == count then
      self.AvatarPlayer:SetActorHiddenInGame(false)
      bNeedFallback = false
    end
    count = count + 1
  end)
  self.Yaw = self.AvatarPlayer:K2_GetActorRotation().Yaw
  self.module:InitAvatarRotationData(self.AvatarPlayer, self.Yaw, self.Yaw, "TryOn")
  self.SalonIds = self:GetCurrentSalonIds()
  self.FakeAvatar = self.TryOnWorldView:SpawnActor(res, zeroTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  self.FakeAvatar:SetActorHiddenInGame(true)
  self.FakeAvatar:SetActorEnableCollision(false)
end

function UMG_TryOnImage3D_C:GetCurrentSalonIds()
  local wardrobeIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().current_wardrobe_index
  local currentWardrobe = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().wardrobe_data[wardrobeIndex + 1]
  local result
  if currentWardrobe then
    local salonIds = currentWardrobe.salon_item_wear_id
    if salonIds then
      result = {}
      for k, v in pairs(salonIds) do
        local salonId = v
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(salonId, true)
        if salonItemConf then
          result[salonItemConf.type] = salonId
        end
      end
    end
  end
  self:_ReplenishSalon(result)
  return result
end

function UMG_TryOnImage3D_C:SetAvatarAppearance(fashionIds, salonIds, suitId)
  local showFashionIds = {}
  local suitFashionIds = {}
  if suitId then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    suitFashionIds = suitConf and suitConf.item_id or {}
    if #suitFashionIds > 0 then
      for k, v in ipairs(suitFashionIds) do
        table.insert(showFashionIds, v)
      end
    end
    if self.bIsWearingWand and self.curWandId then
      table.insert(showFashionIds, self.curWandId)
    end
    if self.curPendanta and not self.curPendantaFromUpgrade then
      table.insert(showFashionIds, self.curPendanta)
    end
    if self.curPendantaFromUpgrade then
      self.curPendanta = nil
      self.curPendantaFromUpgrade = false
    end
    self.curHelmetId = nil
    local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
    local hairConflicts = AppearanceUtils.GetConflictBodyTypes(UE4.EAvatarBodyType.Hair)
    if hairConflicts then
      for _, fashionId in ipairs(suitFashionIds) do
        local avatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(fashionId)
        if avatarEnum then
          for _, conflictType in ipairs(hairConflicts) do
            if avatarEnum == conflictType then
              self.curHelmetId = fashionId
              break
            end
          end
        end
        if self.curHelmetId then
          break
        end
      end
    end
    self.module:PlayReloadingSkill(self.AvatarPlayer)
    UIUtils.SetAvatarSuit(self.AvatarPlayer, showFashionIds, salonIds)
    self.module:SetPlayerAngle(0, self.AvatarPlayer, "TryOn")
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, true, nil, self.AvatarPlayer)
  else
    if fashionIds and #fashionIds > 0 then
      for k, v in ipairs(fashionIds) do
        UIUtils.SetAvatarFashion(self.AvatarPlayer, v, true)
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
          self.bIsWearingWand = true
          self.curWandId = v
        elseif fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
          self.curPendanta = v
          self.curPendantaFromUpgrade = false
        else
          local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
          local avatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(v)
          local hairConflicts = AppearanceUtils.GetConflictBodyTypes(UE4.EAvatarBodyType.Hair)
          if avatarEnum and hairConflicts then
            for _, conflictType in ipairs(hairConflicts) do
              if avatarEnum == conflictType then
                self.curHelmetId = v
                break
              end
            end
          end
        end
        self.module:SetPlayerAngle(fashionItemConf.type, self.AvatarPlayer, "TryOn")
        if fashionItemConf.type ~= _G.Enum.FashionLabelType.FLT_GLASSES then
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, false, v, self.AvatarPlayer)
        end
      end
    end
    if salonIds and #salonIds > 0 then
      for k, v in ipairs(salonIds) do
        local salonItemConf = _G.DataConfigManager:GetSalonItemConf(v)
        if salonItemConf and salonItemConf.type == _G.Enum.SalonLabelType.SLT_HAIR then
          self:AutoRemoveHelmetForHair()
        end
        UIUtils.SetAvatarSalon(self.AvatarPlayer, v)
        if salonItemConf then
          self._SalonOverrides[salonItemConf.type] = v
        end
        self.module:SetPlayerAngle(salonItemConf.type, self.AvatarPlayer, "TryOn")
      end
    end
  end
end

function UMG_TryOnImage3D_C:SetPendantaFromUpgrade(bFromUpgrade)
  self.curPendantaFromUpgrade = bFromUpgrade
end

function UMG_TryOnImage3D_C:DemountFashionById(fashionId)
  UIUtils.SetAvatarFashion(self.AvatarPlayer, fashionId, false)
  local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
  if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
    self.bIsWearingWand = false
    self.curWandId = nil
  end
  if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
    self.curPendanta = nil
    self.curPendantaFromUpgrade = false
  end
  if fashionId == self.curHelmetId then
    self.curHelmetId = nil
  end
  if fashionItemConf and fashionItemConf.type ~= _G.Enum.FashionLabelType.FLT_GLASSES then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, false, fashionId, self.AvatarPlayer, false)
  end
end

function UMG_TryOnImage3D_C:DemountSalonById(SalonId)
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(SalonId, true)
  if salonItemConf and self.AvatarPlayer and self.SalonIds then
    local salonData = self.SalonIds[salonItemConf.type]
    if salonData and type(salonData) == "table" and salonData[1] then
      UIUtils.SetAvatarSalon(self.AvatarPlayer, salonData[1])
    elseif salonData then
      UIUtils.SetAvatarSalon(self.AvatarPlayer, salonData)
    end
    self._SalonOverrides[salonItemConf.type] = nil
    if salonItemConf.type == _G.Enum.SalonLabelType.SLT_HAIR then
      self:RestoreHelmetAfterHairRemoval()
    end
  end
end

function UMG_TryOnImage3D_C:AutoRemoveHelmetForHair()
  if not self.curHelmetId then
    return
  end
  UIUtils.SetAvatarFashion(self.AvatarPlayer, self.curHelmetId, false)
  Log.Info("UMG_TryOnImage3D_C:AutoRemoveHelmetForHair - removed helmet", self.curHelmetId)
end

function UMG_TryOnImage3D_C:RestoreHelmetAfterHairRemoval()
  if not self.curHelmetId then
    return
  end
  UIUtils.SetAvatarFashion(self.AvatarPlayer, self.curHelmetId, true)
  Log.Info("UMG_TryOnImage3D_C:RestoreHelmetAfterHairRemoval - restored helmet", self.curHelmetId)
end

function UMG_TryOnImage3D_C:RecoverToOriginalSalons()
  if self.SalonIds then
    for k, v in ipairs(self.SalonIds) do
      if v and type(v) == "table" and v[1] then
        UIUtils.SetAvatarSalon(self.AvatarPlayer, v[1])
      elseif v then
        UIUtils.SetAvatarSalon(self.AvatarPlayer, v)
      end
    end
    self._SalonOverrides = {}
  end
end

function UMG_TryOnImage3D_C:SetAvatarRotation(delta)
  if not self.AvatarPlayer then
    return
  end
  local avatarRotation = self.AvatarPlayer:K2_GetActorRotation()
  self.AvatarPlayer:K2_SetActorRotation(avatarRotation - UE4.FVector(0, delta, 0), false)
end

function UMG_TryOnImage3D_C:_ReplenishSalon(salonIds)
  if not self.defaultSalonIds then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if nil == localPlayer then
      Log.Error("player is nil")
      return
    end
    if 1 == localPlayer.gender then
      self.defaultSalonIds = {}
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_HAIR] = 1
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYEBORWS] = 33
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYELASH] = 58
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYES] = 157
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_MAKEUP] = 64
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_SKIN] = 153
    elseif 2 == localPlayer.gender then
      self.defaultSalonIds = {}
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_HAIR] = 77
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYEBORWS] = 109
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYELASH] = 134
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_EYES] = 157
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_MAKEUP] = 140
      self.defaultSalonIds[_G.Enum.SalonLabelType.SLT_SKIN] = 153
    end
  end
  local typeMap = {}
  typeMap[_G.Enum.SalonLabelType.SLT_HAIR] = 0
  typeMap[_G.Enum.SalonLabelType.SLT_EYEBORWS] = 0
  typeMap[_G.Enum.SalonLabelType.SLT_EYELASH] = 0
  typeMap[_G.Enum.SalonLabelType.SLT_EYES] = 0
  typeMap[_G.Enum.SalonLabelType.SLT_MAKEUP] = 0
  typeMap[_G.Enum.SalonLabelType.SLT_SKIN] = 0
  if salonIds then
    for k, v in pairs(salonIds) do
      local itemConf = _G.DataConfigManager:GetSalonItemConf(v, true)
      if itemConf then
        typeMap[itemConf.type] = 1
      end
    end
    for k, v in pairs(typeMap) do
      if 0 == v then
        salonIds[k] = self.defaultSalonIds[k]
      end
    end
  end
end

function UMG_TryOnImage3D_C:UpdateSalonIds(initSuit, initSalonIds)
  if not initSalonIds or not self.AvatarPlayer then
    return
  end
  
  local function each_salon(tbl, fn)
    for k, v in pairs(tbl) do
      if type(v) == "number" then
        local conf = _G.DataConfigManager:GetSalonItemConf(v, true)
        if conf then
          fn(conf.type, v)
        end
      end
    end
  end
  
  local function each_fashion(tbl, fn)
    for k, v in pairs(tbl) do
      if v and v.wearing_item_id and type(v.wearing_item_id) == "number" then
        local conf = _G.DataConfigManager:GetFashionItemConf(v, true)
        if conf then
          fn(conf.type, v)
        end
      elseif type(v) == "table" then
        local conf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id, true)
        if conf then
          fn(conf.type, v.wearing_item_id, v.wearing_glass)
        end
      end
    end
  end
  
  local updatedTypes = {}
  each_salon(initSalonIds, function(sType, salonId, glassInfo)
    self.SalonIds[sType] = salonId
    updatedTypes[sType] = salonId
  end)
  local bFoundGlass = false
  each_fashion(initSuit, function(fType, fashionId, glassInfo)
    if fType == _G.Enum.FashionLabelType.FLT_GLASSES then
      bFoundGlass = true
      self._GlassesOverrideId = fashionId
      self._GlassesOverrideGlassInfo = glassInfo
    end
  end)
  for sType, salonId in pairs(updatedTypes) do
    if not self._SalonOverrides or not self._SalonOverrides[sType] then
      UIUtils.SetAvatarSalon(self.AvatarPlayer, salonId)
    end
  end
  if bFoundGlass then
    UIUtils.SetAvatarFashion(self.AvatarPlayer, self._GlassesOverrideId, true, self._GlassesOverrideGlassInfo)
  else
    UIUtils.SetAvatarFashion(self.AvatarPlayer, self._GlassesOverrideId, false, self._GlassesOverrideGlassInfo)
  end
  if not self.SalonIds then
    self.SalonIds = self:GetCurrentSalonIds()
  end
  self:_ReplenishSalon(self.SalonIds)
end

function UMG_TryOnImage3D_C:GetCurrentTryingPendanta()
  return self.curPendanta
end

return UMG_TryOnImage3D_C

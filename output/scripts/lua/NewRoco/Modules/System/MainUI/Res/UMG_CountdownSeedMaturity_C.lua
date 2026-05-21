local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_CountdownSeedMaturity_C = _G.NRCPanelBase:Extend("UMG_CountdownSeedMaturity_C")

function UMG_CountdownSeedMaturity_C:OnConstruct()
end

function UMG_CountdownSeedMaturity_C:OnDestruct()
end

function UMG_CountdownSeedMaturity_C:OnActive()
  self.option = nil
  self:PCKeySetting()
  self:OnAddEventListener()
  self.EradicateBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PCKey:SetKeyVisibility(false)
  self.PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_CountdownSeedMaturity_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_CountdownSeedMaturity_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_CountdownSeedMaturity_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_CountdownSeedMaturity_C:OnClicked()
  if self.option and self.option.config and self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_GET then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_CountdownSeedMaturity_C:OnClicked")
  self:ExecuteOption()
end

function UMG_CountdownSeedMaturity_C:PCKeySetting()
  if SystemSettingModuleCmd and self.PCKey then
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_Shovel_MainUIDefault")
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(false)
    self.PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CountdownSeedMaturity_C:OnTick()
  if not self.option or not self.option.owner then
    return
  end
  if not self.IconInit then
    self:UpdateIcon()
  end
  if not self.NameInit then
    self:UpdateNameText()
  end
  self:UpdateContent()
  self:UpdateCircleFill()
  self:UpdateProgressBar()
end

function UMG_CountdownSeedMaturity_C:UpdateNameText()
  if not self.NameText then
    return
  end
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      Log.Error("UMG_CountdownSeedMaturity_C:UpdateNameText: farmLandInfo is nil", self.option.owner)
      self.NameText:SetText("")
      self.NameInit = false
      return
    end
    local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(farmLandInfo.plant_seed_id)
    if not plantGrowConf then
      Log.Error("UMG_CountdownSeedMaturity_C:UpdateNameText: plantGrowConf is nil", farmLandInfo.plant_seed_id)
      self.NameText:SetText("")
      self.NameInit = false
      return
    end
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(plantGrowConf.plant_harvest)
    if not bagItemConf then
      Log.Error("UMG_CountdownSeedMaturity_C:UpdateNameText: bagItemConf is nil", plantGrowConf.plant_harvest)
      self.NameText:SetText("")
      self.NameInit = false
      return
    end
    self.NameText:SetText(bagItemConf.name)
    self.NameInit = true
  else
    self.NameText:SetText("")
    self.NameInit = false
  end
end

function UMG_CountdownSeedMaturity_C:UpdateContent()
  if self.option and self.option.owner then
    local text = ""
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      self.ContentText:SetText("Nil Land Info Error!!!!")
      return
    end
    if self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_GET then
      self.Hourglass:SetVisibility(UE4.ESlateVisibility.Collapsed)
      text = string.format("%s/%s", tostring(farmLandInfo.plant_harvest_num - farmLandInfo.plant_steal_account), tostring(farmLandInfo.plant_harvest_num))
      self.ContentText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#D56C1FFF"))
    elseif self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_SEED then
      self.Hourglass:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local maxTime = farmLandInfo.plant_rip_time
      local currentTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
      local remainTime = math.max(maxTime - currentTime, 0)
      local day = math.floor(remainTime / 86400)
      local hour = math.floor((remainTime - day * 86400) / 3600)
      local min = math.floor((remainTime - day * 86400 - hour * 3600) / 60)
      local sec = math.floor(remainTime % 60)
      if 0 == day and 0 == hour and 0 == min and 0 == sec then
        sec = 1
      end
      local context_d = _G.LuaText.clear_plant_confirm_text_d
      local context_h = _G.LuaText.clear_plant_confirm_text_h
      local context_m = _G.LuaText.clear_plant_confirm_text_m
      local context_s = _G.LuaText.clear_plant_confirm_text_s
      context_d = day > 0 and string.format(context_d, tostring(day)) or ""
      context_h = hour > 0 and string.format(context_h, tostring(hour)) or ""
      context_m = min > 0 and string.format(context_m, tostring(min)) or ""
      context_s = sec > 0 and string.format(context_s, tostring(sec)) or ""
      if day > 0 then
        text = string.format("%s%s", context_d, context_h)
      elseif hour > 0 then
        text = string.format("%s%s", context_h, context_m)
      elseif min > 0 then
        text = string.format("%s%s", context_m, context_s)
      else
        text = string.format("%s", context_s)
      end
      text = string.format(_G.LuaText.plant_ripe_time_text, text)
      self.ContentText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    end
    self.ContentText:SetText(text)
  end
end

function UMG_CountdownSeedMaturity_C:UpdateCircleFill()
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      self.CircleFillImage_77:SetFillAmount(0)
      return
    end
    local maxTime = farmLandInfo.plant_rip_time
    local maxTimeCfg = farmLandInfo.plant_rip_cfg_time
    local startTime = farmLandInfo.plant_time
    local currentTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
    local progress = 0 == maxTime and 1 or math.clamp(1 - (maxTime - currentTime) / (maxTimeCfg - startTime), 0, 1)
    self.CircleFillImage_77:SetFillAmount(progress)
  end
end

function UMG_CountdownSeedMaturity_C:UpdateProgressBar()
  if not self.ProgressBar then
    return
  end
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      self.ProgressBar:SetPercent(0)
      return
    end
    if self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_GET then
      self.ProgressBar:SetPercent(0)
    elseif self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_SEED then
      local WateringContinueMaxTime = FarmUtils.GetWateringContinueMaxTime(farmLandInfo.plant_id)
      if not WateringContinueMaxTime then
        self.ProgressBar:SetPercent(0)
        return
      end
      local progress = math.clamp(1 - (_G.ZoneServer:GetServerTime() / 1000 - farmLandInfo.plant_water_time) / WateringContinueMaxTime, 0, 1)
      self.ProgressBar:SetPercent(progress)
    end
  else
    self.ProgressBar:SetPercent(0)
  end
end

function UMG_CountdownSeedMaturity_C:UpdateIcon()
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.IconInit = false
      return
    end
    local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(farmLandInfo.plant_seed_id)
    if not plantGrowConf then
      Log.Error("UMG_CountdownSeedMaturity_C:UpdateIcon: plantGrowConf is nil", farmLandInfo.plant_seed_id)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.IconInit = false
      return
    end
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(plantGrowConf.plant_harvest)
    if not bagItemConf then
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.IconInit = false
      return
    end
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Icon:SetPath(bagItemConf.icon)
    self.IconInit = true
  else
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IconInit = false
  end
end

function UMG_CountdownSeedMaturity_C:UpdateHarvestIcon()
  local iconPath
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      if self.HarvestIconPath ~= iconPath then
        self.HarvestIconPath = iconPath
        self.Harvest:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      return
    end
    if FarmUtils.IsLandWateringAvailable(farmLandInfo.plant_id) then
      iconPath = _G.DataConfigManager:GetHomeGlobalConfig("plant_water_path").str
      if self.HarvestIconPath ~= iconPath then
        self.HarvestIconPath = iconPath
        self.Harvest:SetPath(iconPath)
        self.Harvest:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    elseif FarmUtils.IsLandFertilizingAvailable(farmLandInfo.plant_id) then
      iconPath = _G.DataConfigManager:GetHomeGlobalConfig("plant_manure_path").str
      if self.HarvestIconPath ~= iconPath then
        self.HarvestIconPath = iconPath
        self.Harvest:SetPath(iconPath)
        self.Harvest:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    elseif FarmUtils.IsLandHarvest(farmLandInfo.plant_id) then
      iconPath = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_HomePlanting_Harvest_png.img_HomePlanting_Harvest_png'"
      if self.HarvestIconPath ~= iconPath then
        self.HarvestIconPath = iconPath
        self.Harvest:SetPath(iconPath)
        self.Harvest:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    elseif self.HarvestIconPath ~= iconPath or not self.HarvestIconPath and not iconPath then
      self.HarvestIconPath = iconPath
      self.Harvest:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.HarvestIconPath ~= iconPath or not self.HarvestIconPath and not iconPath then
    self.HarvestIconPath = iconPath
    self.Harvest:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CountdownSeedMaturity_C:UpdateRemovalBtn()
  if self.option and self.option.owner then
    local farmLandInfo = self.option:GetOwnerFarmlandInfo()
    if not farmLandInfo then
      self.EradicateBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
    if self.option.config.npc_interact_type == Enum.InteractType.IT_PLANT_SEED and FarmUtils.IsCurrentHomeOwner() then
      self.EradicateBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
  end
  self.EradicateBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_CountdownSeedMaturity_C:OnAnimationFinished(anim)
end

function UMG_CountdownSeedMaturity_C:SetOption(option)
  self:UpdateHarvestIcon()
  if self.option == option then
    return
  end
  self.option = option
  if not self.option or not self.option.owner then
    return
  end
  self.IconInit = false
  self.NameInit = false
  self:StopAllAnimations()
  self:PlayAnimation(self.Open)
  self:UpdateNameText()
  self:UpdateIcon()
  self:UpdateContent()
  self:UpdateCircleFill()
  self:UpdateProgressBar()
end

function UMG_CountdownSeedMaturity_C:ClearOption()
  self.option = nil
end

function UMG_CountdownSeedMaturity_C:ExecuteOption()
  if self.option and self.option.owner then
    self.option:OnOptionAction()
    self.option = nil
  end
end

return UMG_CountdownSeedMaturity_C

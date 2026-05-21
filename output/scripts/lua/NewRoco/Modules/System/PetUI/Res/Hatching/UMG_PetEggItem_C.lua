local UMG_PetEggItem_C = _G.NRCPanelBase:Extend("UMG_PetEggItem_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local NORMAL_GLASS_MATERIAL_INS_PATH = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_PetDazzle.MI_UI_PetDazzle'"

function UMG_PetEggItem_C:OnActive()
end

function UMG_PetEggItem_C:OnDeactive()
end

function UMG_PetEggItem_C:OnAddEventListener()
end

function UMG_PetEggItem_C:SetEggIcon(eggInfo, icon_path, panel)
  self.eggInfo = eggInfo
  self.iconPath = icon_path
  self.panel = panel
  self.randomEggConf = nil
  if self.eggInfo and self.eggInfo.random_egg_conf then
    self.randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(self.eggInfo.random_egg_conf)
  end
  self:ReleaseResLoadRequest()
  self:SetItemIcon()
end

function UMG_PetEggItem_C:SetItemIcon()
  self.EggIcon:SetRenderOpacity(0)
  if self.randomEggConf then
    local materialPath
    if self.randomEggConf.mutation_type == _G.Enum.MutationDiffType.MDT_GLASS and not self.eggInfo.mutation_type and not self.eggInfo.glass_info and self.randomEggConf.icon_mutation_safety_mat and self.randomEggConf.icon_mutation_safety_mat ~= "" then
      materialPath = self.randomEggConf.icon_mutation_safety_mat
    elseif self.randomEggConf.mutation_type == _G.Enum.MutationDiffType.MDT_GLASS and self.eggInfo and self.eggInfo.mutation_type and self.eggInfo.glass_info and PetUtils.CheckIsHiddenGlass(self.randomEggConf.mutation_type, self.eggInfo.glass_info) then
      self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
      self:LoadGlassRes()
      return
    elseif self.randomEggConf.icon_mutation_mat then
      materialPath = self.randomEggConf.icon_mutation_mat
    end
    if materialPath then
      self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
      self:LoadPanelRes(materialPath, 255, self.LoadMaterialSuc, self.LoadMaterialFailed)
      return
    end
  elseif self.eggInfo then
    if self.eggInfo.precious_egg_type == Enum.PreciousEggType.PET_SHINING_GLASS then
      if self:CheckIsGlassInfoKnown() then
        self:LoadGlassRes()
      else
        self:LoadIconMatRes()
      end
    elseif self.eggInfo.precious_egg_type == Enum.PreciousEggType.PET_PRECIOUS then
      if self.eggInfo.glass_info and self.eggInfo.glass_info.glass_type then
        if self:CheckIsGlassInfoKnown() then
          self:LoadGlassRes()
        else
          self:LoadIconMatRes()
        end
      else
        self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
        self.EggIcon:SetPathWithCallBack(self.iconPath, {
          self,
          self.OnSetEggIconFinish
        })
      end
    elseif self.eggInfo.precious_egg_type == Enum.PreciousEggType.PET_SHINING then
      self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
      self.EggIcon:SetPathWithCallBack(self.iconPath, {
        self,
        self.OnSetEggIconFinish
      })
    elseif self.eggInfo.precious_egg_type == Enum.PreciousEggType.PET_GLASS then
      if self:CheckIsGlassInfoKnown() then
        self:LoadGlassRes()
      else
        self:LoadIconMatRes()
      end
    else
      local isCustomGlassEgg = false
      if self.eggInfo.conf_id and 0 ~= self.eggInfo.conf_id then
        local PetEggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.conf_id)
        if PetEggConf and PetEggConf.precious_egg_type and PetEggConf.precious_egg_type == Enum.PreciousEggType.PET_CUSTOM_GLASS then
          isCustomGlassEgg = true
        end
      end
      if isCustomGlassEgg then
        self:LoadIconMatRes(Enum.PreciousEggType.PET_CUSTOM_GLASS)
      else
        self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
        if not self:LoadIconMatRes() then
          self.EggIcon:SetPathWithCallBack(self.iconPath, {
            self,
            self.OnSetEggIconFinish
          })
        end
      end
    end
  end
end

function UMG_PetEggItem_C:CheckIsGlassInfoKnown()
  local isGlassInfoKnown = false
  if self.eggInfo and self.eggInfo.glass_info and self.eggInfo.glass_info.glass_type and 0 ~= self.eggInfo.glass_info.glass_type then
    isGlassInfoKnown = true
  end
  return isGlassInfoKnown
end

function UMG_PetEggItem_C:SetAllEggIconCollapsed()
  if self.CanvasPanel_EggIcon then
    local ChildrenCount = self.CanvasPanel_EggIcon:GetChildrenCount()
    for i = 0, ChildrenCount - 1 do
      local ChildIcon = self.CanvasPanel_EggIcon:GetChildAt(i)
      if ChildIcon then
        ChildIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetEggItem_C:LoadMaterialSuc(_, asset)
  if self.eggInfo and asset and self.iconPath then
    self.EggIcon.MaterialInstance = asset
    self.EggIcon:SetBrushFromMaterial(asset)
    self:SetShinePetIcon()
  end
end

function UMG_PetEggItem_C:LoadMaterialFailed()
  if self.iconPath then
    self.EggIcon:SetPathWithCallBack(self.iconPath, {
      self,
      self.OnSetEggIconFinish
    })
  end
end

function UMG_PetEggItem_C:SetShinePetIcon()
  if self.iconPath then
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadIconSuccess, self.LoadMaterialFailed)
  end
end

function UMG_PetEggItem_C:OnLoadIconSuccess(req, asset)
  if asset then
    local material = self.EggIcon:GetDynamicMaterial()
    if material then
      material:SetTextureParameterValue("TargetTexture", asset)
    end
  end
  if self.randomEggConf and self.randomEggConf.icon_mark_mat then
    self:LoadPanelRes(self.randomEggConf.icon_mark_mat, 255, self.OnLoadIconMarkSuccess, self.OnLoadIconMarkFailed)
    return
  end
  self:SetGlassMat()
end

function UMG_PetEggItem_C:OnLoadIconMarkSuccess(req, asset)
  if asset then
    local material = self.EggIcon:GetDynamicMaterial()
    if material then
      if self.randomEggConf then
        if self.randomEggConf.OpenFlowRamp then
          material:SetScalarParameterValue("OpenFlowRamp", 1)
        end
        if self.randomEggConf.RradientSpeed and self.randomEggConf.RradientSpeed > 0 then
          material:SetScalarParameterValue("GradientSpeed", self.randomEggConf.RradientSpeed)
        end
      end
      material:SetTextureParameterValue("RampTex", asset)
    end
  end
  self:SetGlassMat()
end

function UMG_PetEggItem_C:OnLoadIconMarkFailed()
  self:SetGlassMat()
end

function UMG_PetEggItem_C:SetGlassMat()
  local particlePath, matchIndex
  if self.eggInfo.mutation_type and self.eggInfo.glass_info then
    if PetUtils.CheckIsCommonGlass(self.eggInfo.mutation_type, self.eggInfo.glass_info) then
      particlePath, matchIndex = self:GetParticlePathAndMatchIndex()
    end
  else
    matchIndex = 0
    if self.randomEggConf.known_mutation_glass_particle and self.randomEggConf.mutation_param2 and 0 ~= self.randomEggConf.mutation_param2 then
      local particleConf = _G.DataConfigManager:GetParticleRandomConf(self.randomEggConf.mutation_param2)
      if particleConf and particleConf.headicon_particle_res then
        particlePath = particleConf.headicon_particle_res
      end
    end
    if self.randomEggConf.known_mutation_glass_color and self.randomEggConf.mutation_param1 then
      matchIndex = self.randomEggConf.mutation_param1
    end
  end
  if particlePath and matchIndex and 0 ~= matchIndex then
    self.matchIndex = matchIndex
    self:LoadPanelRes(particlePath, 255, self.OnLoadGlassIconResSuccess, self.OnLoadGlassIconResFailed)
    return
  elseif not particlePath and matchIndex and 0 ~= matchIndex then
    self.matchIndex = matchIndex
    self:OnSetGlassyColor()
  elseif particlePath and matchIndex and 0 == matchIndex then
    self.matchIndex = 0
    self:LoadPanelRes(particlePath, 255, self.OnLoadGlassIconResSuccess, self.OnLoadGlassIconResFailed)
    return
  end
  self:OnSetEggIconFinish()
end

function UMG_PetEggItem_C:OnLoadGlassIconResFailed()
  self:OnSetEggIconFinish()
end

function UMG_PetEggItem_C:GetParticlePathAndMatchIndex()
  if PetUtils.CheckIsCommonGlass(self.eggInfo.mutation_type, self.eggInfo.glass_info) and self.eggInfo.glass_info.glass_value then
    local shineId = self.eggInfo.glass_info.glass_value
    local particleIndex, matchIndex, particlePath
    particleIndex, shineId = PetUtils.GetShineDataValue(shineId, 20)
    matchIndex, shineId = PetUtils.GetShineDataValue(shineId, 0)
    local particleConf = _G.DataConfigManager:GetParticleRandomConf(particleIndex)
    if particleConf and particleConf.headicon_particle_res then
      particlePath = particleConf.headicon_particle_res
    end
    return particlePath, matchIndex
  end
  return nil, nil
end

function UMG_PetEggItem_C:OnLoadGlassIconResSuccess(req, asset)
  if asset then
    local material = self.EggIcon:GetDynamicMaterial()
    if material then
      material:SetScalarParameterValue("OpenGlassy", 1)
      material:SetScalarParameterValue("OpenGlassyOutline", 1)
      material:SetTextureParameterValue("StarTex", asset)
    end
    self:OnSetGlassyColor()
  end
  self:OnSetEggIconFinish()
end

function UMG_PetEggItem_C:OnSetGlassyColor()
  local material = self.EggIcon:GetDynamicMaterial()
  if self.matchIndex and 0 ~= self.matchIndex and material then
    local matchConf = _G.DataConfigManager:GetColorRandomConf(self.matchIndex)
    if matchConf and matchConf.mat_color_1 then
      local color1 = matchConf.mat_color_1
      material:SetVectorParameterValue("Color01", UE4.FLinearColor(color1[1], color1[2], color1[3], color1[4]))
    end
    if matchConf and matchConf.mat_color_2 then
      local color2 = matchConf.mat_color_2
      material:SetVectorParameterValue("Color02", UE4.FLinearColor(color2[1], color2[2], color2[3], color2[4]))
    end
    material:SetScalarParameterValue("OpenOutlineFlowColor", 0)
  end
end

function UMG_PetEggItem_C:LoadUnknownGlassRes()
end

function UMG_PetEggItem_C:OnLoadUnknownGlassMaterialSuccess(req, asset)
  self.EggIcon.MaterialInstance = asset
  self.EggIcon:SetBrushFromMaterial(asset)
  if self.iconPath then
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadIconResSuccess, self.OnLoadIconFailed)
  end
end

function UMG_PetEggItem_C:OnLoadUnknownGlassMaterialFailed()
  Log.Error("UMG_PetEggItem_C:OnLoadUnknownGlassMaterialFailed")
end

function UMG_PetEggItem_C:LoadIconMatRes(target_precious_egg_type)
  if self.eggInfo == nil then
    return false
  end
  local CurPreciousEggType = target_precious_egg_type
  if nil == CurPreciousEggType then
    CurPreciousEggType = self.eggInfo.precious_egg_type
  end
  if nil == CurPreciousEggType then
    local PetEggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.conf_id)
    if PetEggConf then
      CurPreciousEggType = PetEggConf.precious_egg_type
    end
  end
  if CurPreciousEggType then
    local PetEggTypeConf = _G.DataConfigManager:GetEggTypeConf(CurPreciousEggType + 1)
    if PetEggTypeConf then
      local IconMaterialPath = PetEggTypeConf.icon_tex
      if IconMaterialPath then
        self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
        self:LoadPanelRes(IconMaterialPath, 255, self.OnLoadIconMatResSuccess, self.OnLoadIconMatResFailed)
        return true
      end
    end
  end
  return false
end

function UMG_PetEggItem_C:OnLoadIconMatResSuccess(req, asset)
  self.EggIcon.MaterialInstance = asset
  self.EggIcon:SetBrushFromMaterial(asset)
  if self.iconPath then
    self:LoadPanelRes(self.iconPath, 255, self.OnLoadIconResSuccess, self.OnLoadIconFailed)
  end
end

function UMG_PetEggItem_C:OnLoadIconMatResFailed()
  Log.Error("UMG_PetEggItem_C:OnLoadIconMatResFailed")
end

function UMG_PetEggItem_C:OnLoadIconResSuccess(req, Texture2D)
  if UE4.UObject.IsValid(self.EggIcon) then
    local material = self.EggIcon:GetDynamicMaterial()
    if material then
      material:SetTextureParameterValue("TargetTexture", Texture2D)
      local iconRawSize = UE.FVector2D(1, 1)
      if Texture2D then
        iconRawSize = UE.FVector2D(Texture2D:Blueprint_GetSizeX(), Texture2D:Blueprint_GetSizeY())
        self.EggIcon:SetBrushSize(iconRawSize)
      end
      self:OnSetEggIconFinish()
    end
  end
end

function UMG_PetEggItem_C:OnLoadIconFailed()
  Log.Error("UMG_PetEggItem_C:OnLoadIconFailed")
end

function UMG_PetEggItem_C:LoadGlassRes()
  local EggInfo = self.eggInfo
  if nil == EggInfo then
    Log.Error("UMG_PetEggItem_C:LoadGlassRes EggInfo is nil")
    return
  end
  if EggInfo.glass_info and EggInfo.glass_info.glass_type and EggInfo.glass_info.glass_value then
    self.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    if 1 == EggInfo.glass_info.glass_type then
      if NORMAL_GLASS_MATERIAL_INS_PATH then
        self:LoadPanelRes(NORMAL_GLASS_MATERIAL_INS_PATH, 255, self.OnLoadNormalGlassMaterialSuccess, self.OnLoadNormalGlassMaterialFailed)
      end
    elseif 2 == EggInfo.glass_info.glass_type then
      local Path = self:GetHiddenGlassMaterialPath(EggInfo.glass_info.glass_value)
      if "" ~= Path then
        self:LoadPanelRes(Path, 255, self.OnLoadHideenGlassResSuccess, self.OnLoadHideenGlassResFailed)
      end
    end
  end
end

function UMG_PetEggItem_C:OnSetEggIconFinish()
  self.EggIcon:SetRenderOpacity(1)
  self:ForceLayoutPrepass()
  if self.panel then
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OnSetEggIconFinished, self.panel)
  end
end

function UMG_PetEggItem_C:OnLoadShineIconResSuccess(req, asset)
  local material = self.EggIcon:GetDynamicMaterial()
  if material then
    material:SetTextureParameterValue("StarTex", asset)
  end
  local matchConf = _G.DataConfigManager:GetColorRandomConf(self.MatchIndex)
  if matchConf and matchConf.mat_color_1 then
    local color1 = matchConf.mat_color_1
    if material then
      material:SetVectorParameterValue("Color01", UE4.FLinearColor(color1[1], color1[2], color1[3], color1[4]))
    end
  end
  if matchConf and matchConf.mat_color_2 then
    local color2 = matchConf.mat_color_2
    if material then
      material:SetVectorParameterValue("Color02", UE4.FLinearColor(color2[1], color2[2], color2[3], color2[4]))
    end
  end
  self:OnSetEggIconFinish()
end

function UMG_PetEggItem_C:OnLoadShineIconResFailed(req, asset)
  self.EggIcon:SetPath(self.iconPath)
  self:OnSetEggIconFinish()
  Log.Error("\231\130\171\229\189\169\229\164\180\229\131\143\230\155\180\230\141\162\230\157\144\232\180\168\231\154\132\232\180\180\229\155\190\228\184\173\231\154\132\229\155\190\231\137\135\229\164\177\232\180\165\239\188\140\232\175\183\230\159\165\231\156\139\232\181\132\230\186\144\230\152\175\229\144\166\229\173\152\229\156\168")
end

function UMG_PetEggItem_C:OnLoadHideenGlassResSuccess(req, asset)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.EggIcon.MaterialInstance = asset
  self.EggIcon:SetBrushFromMaterial(asset)
  self.EggIcon:SetPath(self.iconPath)
  self:OnSetEggIconFinish()
end

function UMG_PetEggItem_C:OnLoadHideenGlassResFailed(req, asset)
  self.EggIcon:SetPath(self.iconPath)
  self:OnSetEggIconFinish()
  Log.Error("\233\154\144\232\151\143\231\130\171\229\189\169\229\164\180\229\131\143\230\155\180\230\141\162\230\157\144\232\180\168\231\154\132\232\180\180\229\155\190\228\184\173\231\154\132\229\155\190\231\137\135\229\164\177\232\180\165\239\188\140\232\175\183\230\159\165\231\156\139\232\181\132\230\186\144\230\152\175\229\144\166\229\173\152\229\156\168")
end

function UMG_PetEggItem_C:OnLoadNormalGlassMaterialSuccess(req, asset)
  self.EggIcon.MaterialInstance = asset
  self.EggIcon:SetBrushFromMaterial(asset)
  self.EggIcon:SetPath(self.iconPath)
  local EggInfo = self.eggInfo
  if nil == EggInfo then
    Log.Error("UMG_PetEggItem_C:OnLoadNormalGlassMaterialSuccess EggInfo is nil")
    return
  end
  if nil == EggInfo.glass_info then
    Log.Error("UMG_PetEggItem_C:OnLoadNormalGlassMaterialSuccess EggInfo.glass_info is nil")
    return
  end
  local shineId = EggInfo.glass_info.glass_value
  self.ParticleIndex = nil
  self.MatchIndex = nil
  if shineId then
    self.ParticleIndex, shineId = PetUtils.GetShineDataValue(shineId, 20)
    self.MatchIndex, shineId = PetUtils.GetShineDataValue(shineId, 0)
    local particleConf = _G.DataConfigManager:GetParticleRandomConf(self.ParticleIndex)
    if particleConf and particleConf.headicon_particle_res then
      local res = particleConf.headicon_particle_res
      self:LoadPanelRes(res, 255, self.OnLoadShineIconResSuccess, self.OnLoadShineIconResFailed)
    end
  end
end

function UMG_PetEggItem_C:OnLoadNormalGlassMaterialFailed(req, asset)
  self:OnSetEggIconFinish()
  Log.Error("\229\138\160\232\189\189\230\153\174\233\128\154\231\130\171\229\189\169\231\178\190\231\129\181\232\155\139\231\154\132\230\157\144\232\180\168\229\174\158\228\190\139\229\164\177\232\180\165\239\188\140\232\175\183\230\159\165\231\156\139\232\181\132\230\186\144\230\152\175\229\144\166\229\173\152\229\156\168")
end

function UMG_PetEggItem_C:GetHiddenGlassMaterialPath(glass_value)
  if glass_value then
    local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(glass_value)
    if HiddenGlassConf and HiddenGlassConf.egg_icon_mat then
      return HiddenGlassConf.egg_icon_mat
    end
  end
  return ""
end

return UMG_PetEggItem_C

local TipsModuleEvent = reload("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local Timer = require("Utils.Timer")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_BookPrompt_C = _G.NRCPanelBase:Extend("UMG_BookPrompt_C")

function UMG_BookPrompt_C:OnConstruct()
  self:OnAddEventListener()
  self.ShowMedalCount = 0
  local petGlobal = _G.DataConfigManager:GetPetGlobalConfig("pet_tips_medal_max_num")
  if petGlobal then
    self.ShowMedalCount = petGlobal.num or 0
  end
  _G.NRCEventCenter:RegisterEvent("UMG_BookPrompt_C", self, MainUIModuleEvent.OnCloseHandBook, self.OnCloseHandBook)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.MainPanel then
    self.MainPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PCKeySetting()
  self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
end

function UMG_BookPrompt_C:OnAddEventListener()
  self:AddButtonListener(self.btnOpenHanbook, self.OnbtnOpenHanbook)
  _G.NRCEventCenter:RegisterEvent("UMG_BookPrompt_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_BookPrompt_C:OnActive(tip)
  if self:IsPCMode() then
    self:SetRenderScale(E4.FVector2D(1, 1))
  end
end

function UMG_BookPrompt_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_BookPrompt_C:SetGoalWidget(goal)
  self.GoalWidget = goal
end

function UMG_BookPrompt_C:PCKeySetting()
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_MessageDetails")
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_BookPrompt_C:OnbtnOpenHanbook()
  if not self.CurrentTip or not self.PetData then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.umg_bookprompt_1)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnCloseHandBook)
    return
  end
  local gid = self.PetData.gid
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_PET_UI, false, true, false)
  if Ban then
    return
  end
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
  if isSelectBtn then
    return
  end
  if self.RestTime and self.RestTime > 0 and not BattleManager:IsInBattle() then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").NEWPET
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    if not _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.click_freed_pet_tips)
      return
    end
    if self:PetIsHaveTeam(gid) then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
      local index = self:GetPetTeamIndex(gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, nil, nil, petData, true)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, index)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetSKill, false)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
    elseif self:PetIsHaveBag(gid) then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, nil, nil, petData, true)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetSKill, false)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetBag, true, gid)
    else
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPanelPetData, petData, 1, true)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {subPanelIndex = 4}, nil, nil, true)
    end
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnCloseHandBook)
end

function UMG_BookPrompt_C:PetIsHaveTeam(pet_gid)
  local petList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  for i, v in pairs(petList) do
    if v.gid == pet_gid then
      return true
    end
  end
  return false
end

function UMG_BookPrompt_C:GetPetTeamIndex(pet_gid)
  local petList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  for i, v in pairs(petList) do
    if v.gid == pet_gid then
      return i
    end
  end
  return 0
end

function UMG_BookPrompt_C:PetIsHaveBag(pet_gid)
  local petList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackPetInfo()
  for i, v in pairs(petList) do
    if v.gid == pet_gid then
      return true
    end
  end
  return false
end

function UMG_BookPrompt_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnCloseHandBook, self.OnCloseHandBook)
  self:RemoveButtonListener(self.btnOpenHanbook, self.OnbtnOpenHanbook)
  self:CancelDelay()
  self.CurrentTip = nil
  self.PetData = nil
end

function UMG_BookPrompt_C:CalGoalPos()
  local GoalGeometry = self.GoalWidget:GetCachedGeometry()
  local MyGeometry = self:GetCachedGeometry()
  local TopOffSet = UE4.USlateBlueprintLibrary.GetLocalSize(GoalGeometry) * self.Slot.LayoutData.Alignment
  local DownOffSet = UE4.USlateBlueprintLibrary.GetLocalSize(MyGeometry) * self.Slot.LayoutData.Alignment
  local pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(GoalGeometry, UE4.FVector2D(0, 0))
  self.EndPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(MyGeometry, pos) + self.InitPos + TopOffSet - DownOffSet
end

function UMG_BookPrompt_C:SetIsShow(_IsShow)
  if _IsShow then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BookPrompt_C:ConsumeTip(tip, parent)
  self.parent = parent
  self.CurrentTip = tip
  self.PetData = tip.tipData
  self.glass_info = self.PetData.glass_info
  local commonAttrData = {}
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetData.base_conf_id)
  if not PetBaseConf then
    Log.Error("UMG_BookPrompt_C:ConsumeTip  PetBaseConf is nil")
    return
  end
  local gender = self.PetData.gender
  self.ElfIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.iconPath = ""
  if PetUtils.CheckIsCHAOS(self.PetData.mutation_type) then
    if PetUtils.CheckIsShiningChaos(self.PetData.mutation_type) then
      self.iconPath = PetBaseConf.JL_small_shiny_res
    else
      self.iconPath = PetBaseConf.JL_small_res
    end
  elseif PetMutationUtils.GetMutationValue(self.PetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.iconPath = PetBaseConf.JL_small_shiny_res
  elseif PetMutationUtils.GetMutationValue(self.PetData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.iconPath = PetBaseConf.JL_small_res
  elseif PetUtils.CheckIsShiningGlass(self.PetData.mutation_type) then
    self.iconPath = PetBaseConf.JL_small_shiny_res
  else
    self.iconPath = PetBaseConf.JL_small_res
  end
  self:SetIcon()
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.PetData.blood_id)
  if PetBloodConf then
    table.insert(commonAttrData, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  if 1 == gender then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif 2 == gender then
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Grade:SetText(string.format("%s%s", LuaText.petutils_1, self.PetData.level))
  self:SetOutlineImage()
  self:UpdateMedalIcon()
  self.Name:SetText(PetBaseConf.name)
  self:UpdatePetMutationIcon()
  if self.PetData.is_first_catch then
    self.Icon_New:SetVisibility(UE4.ESlateVisibility.Visible)
    self.RestTime = _G.DataConfigManager:GetGlobalConfigByKeyType("handbook_renew_show_time", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num / 1000
  else
    self.Icon_New:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RestTime = _G.DataConfigManager:GetPetGlobalConfig("catch_pet_show_time").num / 1000
  end
  self.LastTimeText:SetText(string.format(LuaText.umg_bookprompt_4, math.floor(self.RestTime)))
  self:DelaySeconds(1, self.TickSecond, self)
  local unit_type = PetBaseConf.unit_type
  for i = 1, 2 do
    local petType = unit_type[i]
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        table.insert(commonAttrData, i, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  self.Attr:InitGridView(commonAttrData)
  self:CheckIsFriendGift()
  self.UMG_Common_BIconPar:PlayLoop()
end

function UMG_BookPrompt_C:SetIcon()
  if self.PetData == nil or nil == self.PetData.mutation_type then
    self.ElfIcon:SetPathWithCallBack(self.iconPath, {
      self,
      self.OnElfIconLoaded
    })
    return
  end
  local mutation_type = self.PetData.mutation_type
  local materialPath = ""
  if mutation_type and PetUtils.CheckIsCHAOS(mutation_type) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = _G.DataConfigManager:GetGlobalConfigByKeyType("mainworld_pet_tips_chaos_mat", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
  elseif mutation_type and self.glass_info and PetUtils.CheckIsHiddenShiningGlass(mutation_type, self.glass_info) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = self:GetHiddenGlassMaterialPath()
  elseif mutation_type and PetUtils.CheckIsShiningGlass(mutation_type) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = _G.DataConfigManager:GetGlobalConfigByKeyType("mainworld_pet_tips_glass_mat", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
  elseif mutation_type and self.glass_info and PetUtils.CheckIsHiddenGlass(mutation_type, self.glass_info) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = self:GetHiddenGlassMaterialPath()
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = _G.DataConfigManager:GetGlobalConfigByKeyType("mainworld_pet_tips_glass_mat", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
  else
    self.ElfIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
  end
  if "" ~= materialPath then
    self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
  else
    self.ElfIcon:SetPathWithCallBack(self.iconPath, {
      self,
      self.OnElfIconLoaded
    })
  end
end

function UMG_BookPrompt_C:OnElfIconLoaded()
  self.ElfIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.glass_info and self.glass_info.glass_type == _G.ProtoEnum.GlassType.GT_COMMON then
    self:SetCommonGlass()
  end
  self:PlayAnimation(self.Appear)
  if self.MainPanel then
    self.MainPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BookPrompt_C:GetHiddenGlassMaterialPath()
  if self.glass_info and self.glass_info.glass_value then
    local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(self.glass_info.glass_value)
    if HiddenGlassConf and HiddenGlassConf.main_ui_tips_mat_path then
      return HiddenGlassConf.main_ui_tips_mat_path
    end
  end
  return ""
end

function UMG_BookPrompt_C:SetCommonGlass()
  if self.glass_info and self.glass_info.glass_value then
    local shineId = self.glass_info.glass_value
    self.ParticleIndex = nil
    self.MatchIndex = nil
    if shineId then
      self.ParticleIndex, shineId = PetUtils.GetShineDataValue(shineId, 20)
      self.MatchIndex, shineId = PetUtils.GetShineDataValue(shineId, 0)
      local particleConf = _G.DataConfigManager:GetParticleRandomConf(self.ParticleIndex)
      if particleConf and particleConf.headicon_particle_res then
        local res = particleConf.headicon_particle_res
        self:LoadPanelRes(res, 255, self.loadGlassResSuccess)
      end
    end
  end
end

function UMG_BookPrompt_C:loadGlassResSuccess(req, asset)
  local material = self.ElfIcon:GetDynamicMaterial()
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
end

function UMG_BookPrompt_C:OnLoadIconMaterialSucceed(_, asset)
  if asset then
    self.ElfIcon.MaterialInstance = asset
    self.ElfIcon:SetBrushFromMaterial(asset)
    self.ElfIcon:SetPathWithCallBack(self.iconPath, {
      self,
      self.OnElfIconLoaded
    })
  end
end

function UMG_BookPrompt_C:OnLoadIconMaterialFail()
end

function UMG_BookPrompt_C:UpdateMedalIcon()
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
  self.NRCGridView_Medal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if MedalList and #MedalList > 0 then
    self.NRCGridView_Medal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local shieldEnums = _G.DataConfigManager:GetGlobalConfigByKeyType("pet_tips_hide_medal_type", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).numList
    if 0 ~= self.ShowMedalCount then
      local showList = {}
      local validCount = 0
      for i = 1, #MedalList do
        if validCount >= self.ShowMedalCount then
          break
        end
        local config = _G.DataConfigManager:GetMedalConf(MedalList[i].conf_id)
        local isShield = false
        for _, enum in pairs(shieldEnums) do
          if config.medal_type == enum then
            isShield = true
            break
          end
        end
        if not isShield and validCount <= self.ShowMedalCount then
          table.insert(showList, MedalList[i])
          validCount = validCount + 1
        end
      end
      self.NRCGridView_Medal:InitGridView(showList)
    end
  end
end

function UMG_BookPrompt_C:UpdatePetMutationIcon()
  local petData = self.PetData
  local isFirst = self.PetData.is_first_catch
  local mutation_type = petData.mutation_type
  local talent_rank = petData.talent_rank
  local renew_show_time = true
  self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if mutation_type and PetUtils.CheckIsShiningChaos(mutation_type) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(9)
  elseif PetUtils.CheckIsCHAOS(mutation_type) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(4)
  elseif PetUtils.CheckIsHiddenShiningGlass(self.PetData.mutation_type, self.PetData.glass_info) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(7)
    local path = self:GetHiddenGlassLoogIcon(true)
    if "" ~= path then
      self.DifferentColorsDazzling_Hide:SetPath(path)
    end
  elseif PetUtils.CheckIsShiningGlass(mutation_type) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(5)
  elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(1)
  elseif PetUtils.CheckIsHiddenGlass(self.PetData.mutation_type, self.PetData.glass_info) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(6)
    local path = self:GetHiddenGlassLoogIcon(false)
    if "" ~= path then
      self.DazzlingColors_Hide:SetPath(path)
    end
  elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(0)
  elseif petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_47:SetActiveWidgetIndex(8)
  elseif 3 == talent_rank then
    self.NRCSwitcher_47:SetActiveWidgetIndex(3)
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif 4 == talent_rank then
    self.NRCSwitcher_47:SetActiveWidgetIndex(2)
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif isFirst then
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCSwitcher_47:SetVisibility(UE4.ESlateVisibility.Collapsed)
    renew_show_time = false
  end
  if renew_show_time then
    self.RestTime = _G.DataConfigManager:GetGlobalConfigByKeyType("handbook_renew_show_time", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num / 1000
  else
    self.RestTime = _G.DataConfigManager:GetPetGlobalConfig("catch_pet_show_time").num / 1000
  end
  if PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS) then
  end
end

function UMG_BookPrompt_C:CheckIsFriendGift()
  self.GiftColleagues:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.PetData and self.PetData.together_catch_info and self.PetData.together_catch_info.is_onwer_catch == false then
    self.GiftColleagues:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BookPrompt_C:GetHiddenGlassLoogIcon(bShiningGlass)
  if self.PetData and self.PetData.glass_info then
    local HiddenGlassID = self.PetData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if bShiningGlass and HiddenGlassConf.yise_long_icon then
          return HiddenGlassConf.yise_long_icon
        elseif HiddenGlassConf.long_icon then
          return HiddenGlassConf.long_icon
        end
      end
    end
  end
  return ""
end

function UMG_BookPrompt_C:OnCloseHandBook()
  if -1 == self.RestTime then
    self:PlayAnimation(self.Disappear)
    self.UMG_Common_BIconPar.UMG_Common_BIconParItem:StopAnimation(self.UMG_Common_BIconPar.UMG_Common_BIconParItem.loop)
    self.UMG_Common_BIconPar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BookPrompt_C:TickSecond()
  if self.RestTime and self.RestTime > 0 then
    if not self.isTipsPaused then
      self.RestTime = self.RestTime - 1
    end
    if self.RestTime <= 0 then
      if self:GetVisibility() == UE4.ESlateVisibility.Visible or self:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
        self:PlayAnimation(self.Disappear)
      else
        self:PlayNext()
      end
    else
      if self.LastTimeText then
        self.LastTimeText:SetText(string.format(LuaText.umg_bookprompt_4, math.floor(self.RestTime)))
      end
      self:DelaySeconds(1, self.TickSecond, self)
    end
  else
    self:PlayNext()
  end
end

function UMG_BookPrompt_C:SetPaused(bPaused)
  self.isTipsPaused = bPaused
end

function UMG_BookPrompt_C:OnAnimationFinished(Animation)
  if Animation == self.Disappear then
    self:PlayNext()
  end
end

function UMG_BookPrompt_C:PlayNext()
  self.parent:TipsNext()
end

return UMG_BookPrompt_C

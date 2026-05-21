local UMG_PVE_Particulars_C = _G.NRCPanelBase:Extend("UMG_PVE_Particulars_C")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_PVE_Particulars_C:OnConstruct()
  self:AddButtonListener(self.UnlockBtn.btnLevelUp, self.OnClickLightUpTalentNode)
  self:AddButtonListener(self.AccessGrantedBtn.btnLevelUp, self.OnClickLightUpTalentNode)
  self:AddButtonListener(self.Btn_FullScreenClosed, self.OnPcClose2)
  self:AddButtonListener(self.PlaceBtn.btnLevelUp, self.OnClickReplacePet)
  self:RegisterEvent(self, PVEModuleEvent.TalentNodeLockStatusChange, self.OnTalentNodeLockStatusChange)
  self:RegisterEvent(self, PVEModuleEvent.SwitchCurrentTalentNode, self.OnSwitchCurrentTalentNode)
  self:RegisterEvent(self, PVEModuleEvent.SelectFeatureItem, self.OnSelectFeatureItem)
  self.SkillList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Title1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PVE_Particulars_C:OnDestruct()
end

function UMG_PVE_Particulars_C:OnActive(nodeData)
  self.nodeData = nil
  self.selectedFeatureData = nil
  self:OnSwitchCurrentTalentNode(nodeData)
  self:ShowFeatureList()
  self:RefreshSelectedPetItem()
  self:BindInputAction()
end

function UMG_PVE_Particulars_C:DisplaySkillList(isShow)
  self.SkillList:SetVisibility(isShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.PlaceBtn:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if isShow then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.SetShowInnerPanels, false)
    self.Btn_FullScreenClosed:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVE_Particulars_C:OnDeactive()
  self:UnBindInputAction()
  self.selectedFeatureData = nil
  if self.nodeConf and self.nodeConf.type == Enum.SeasonGrowthType.SGT_PET then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.SetShowInnerPanels, true)
    self.Btn_FullScreenClosed:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PVE_Particulars_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_SubClosePanel")
  if mappingContext then
    mappingContext:BindAction("IA_CloseSubPanel", self, "OnPcClose2")
  end
end

function UMG_PVE_Particulars_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_SubClosePanel")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseSubPanel")
  end
  self:RemoveInputMappingContext("IMC_SubClosePanel")
end

function UMG_PVE_Particulars_C:OnSwitchCurrentTalentNode(nodeData)
  if self.nodeData == nodeData then
    return
  end
  self.nodeData = nodeData
  self.selectedFeatureData = nil
  if not nodeData then
    return
  end
  local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
  self.nodeConf = nodeConf
  self.SkillTitle:SetText(nodeConf.name)
  self.textBuffDesc:SetText(nodeConf.desc)
  self.textBuffDesc:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:OnTalentNodeLockStatusChange(nodeData)
end

function UMG_PVE_Particulars_C:OnTalentNodeLockStatusChange(nodeData)
  if not (self.nodeData and nodeData) or self.nodeData.id ~= nodeData.id then
    return
  end
  self.nodeData = nodeData
  local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
  self.NRCTextDes:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PlaceBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:DisplaySkillList(nodeConf.type == Enum.SeasonGrowthType.SGT_PET and nodeData.status == PVEModuleEnum.TalentNodeStatus.Unlocked)
  if nodeData.status == PVEModuleEnum.TalentNodeStatus.CanUnlock then
    local materialCnt = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentMaterialCnt)
    local hasEnoughMaterial = materialCnt >= nodeConf.material_cost
    self.Character:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnSwitcher:SetActiveWidgetIndex(hasEnoughMaterial and 0 or 4)
    local targetBtn = hasEnoughMaterial and self.UnlockBtn or self.NotUnlockedBtn
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(nodeConf.material)
    targetBtn:SetTitleTextAndIcon(bagItemConf and bagItemConf.icon, nodeConf.material_cost)
    if materialCnt >= nodeConf.material_cost then
      targetBtn:SetQuantityTextColor("F4EEE1FF")
    else
      targetBtn:SetBtnText(_G.LuaText.season_growth_unlock_button_1)
      targetBtn:SetShowLockIcon(false)
      targetBtn:SetQuantityTextColor("CF303EFF")
    end
  elseif nodeData.status == PVEModuleEnum.TalentNodeStatus.Unlocked then
    if nodeConf.type == Enum.SeasonGrowthType.SGT_PET then
      self.Character:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local newPetConfId = nodeData.newPetConfId or 0
      local hasPetSet = nil ~= newPetConfId and newPetConfId > 0
      self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.NRCSwitcher_651:SetActiveWidgetIndex(hasPetSet and 0 or 1)
      if not hasPetSet then
        if not string.IsNilOrEmpty(nodeConf.special_desc) then
          self.NRCTextDes:SetText(nodeConf.special_desc)
          self.NRCTextDes:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      else
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(newPetConfId)
        if petBaseConf then
          local skillId = petBaseConf.pet_feature or 0
          if 0 ~= skillId then
            local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
            if skillConf then
              if self.SkillIcon and skillConf.icon then
                self.SkillIcon:SetPath(skillConf.icon)
              end
              if self.SkillName then
                self.SkillName:SetText(skillConf.name or "")
              end
              if self.NRCTextDes then
                self.NRCTextDes:SetText(skillConf.desc or "")
                self.NRCTextDes:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
              end
            end
          end
        end
      end
      self:RefreshSelectedPetItem()
      self:UpdatePlaceBtn()
    else
      self.Character:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AccessGrantedBtn:SetShowLockIcon(false)
      self.BtnSwitcher:SetActiveWidgetIndex(1)
    end
  else
    self.Character:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnSwitcher:SetActiveWidgetIndex(4)
    self.NotUnlockedBtn:SetBtnText(_G.LuaText.season_growth_unlock_button_2)
    self.NotUnlockedBtn:SetShowLockIcon(true)
    self.NotUnlockedBtn:SetOnlyShowTipText(_G.LuaText.season_growth_unlock_tips)
  end
  local umgCls = PVEModuleEnum.TalentNodeUmgCls[nodeConf.level]
  if not string.IsNilOrEmpty(umgCls) then
    self.NodeSkill:UnLoadPanel(true)
    self.NodeSkill:SetWidgetClass(UE4.UKismetSystemLibrary.MakeSoftClassPath(umgCls))
    self.NodeSkill:LoadPanel(nil, nodeConf, nil, true)
  else
    Log.ErrorFormat("can not get node umgCls. nodeLevel=%d.", nodeConf.level)
  end
end

function UMG_PVE_Particulars_C:RefreshSelectedPetItem()
  if not self.nodeData then
    return
  end
  local newPetConfId = self.nodeData.newPetConfId or 0
  self.SkillList:SetCustomData(newPetConfId)
  if self.lastSelectIdx then
    self.SkillList:OpItemByIndex(self.lastSelectIdx + 1, 1)
  end
  local featureDataList = self.featureDataList
  if featureDataList and #featureDataList > 0 then
    local selectIdx = 0
    if newPetConfId and newPetConfId > 0 then
      for i, featureData in ipairs(featureDataList) do
        if featureData.petbaseId == newPetConfId then
          selectIdx = i - 1
          break
        end
      end
    end
    self.lastSelectIdx = selectIdx
    self.SkillList:OpItemByIndex(self.lastSelectIdx + 1, 1)
  end
end

function UMG_PVE_Particulars_C:ShowFeatureList()
  local nodeData = self.nodeData
  if not nodeData then
    return
  end
  local nodeConf = self.nodeConf or _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
  if not nodeConf or nodeConf.type ~= Enum.SeasonGrowthType.SGT_PET then
    return
  end
  local seasonTipsId = nodeConf.params and nodeConf.params[1]
  if not seasonTipsId then
    Log.Error("ShowFeatureList: seasonTipsId is nil")
    return
  end
  self.seasonTipsId = seasonTipsId
  self.selectedFeatureData = nil
  self:RefreshFeatureList()
end

function UMG_PVE_Particulars_C:RefreshFeatureList()
  if not self.seasonTipsId or not self.nodeData then
    return
  end
  local featureList = _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.GetPveFeatureListData, self.seasonTipsId, self.nodeData.id)
  self.featureDataList = featureList
  if featureList and #featureList > 0 then
    local curNewPetConfId = self.nodeData.newPetConfId or 0
    self.SkillList:SetCustomData(curNewPetConfId)
    self.SkillList:InitList(featureList)
    local selectIdx = 0
    if curNewPetConfId > 0 then
      for i, featureData in ipairs(featureList) do
        if featureData.petbaseId == curNewPetConfId then
          selectIdx = i - 1
          break
        end
      end
    end
    self.SkillList:SelectItemByIndex(selectIdx)
  end
end

function UMG_PVE_Particulars_C:HideFeatureList()
  self.selectedFeatureData = nil
  self.featureDataList = nil
  self.seasonTipsId = nil
end

function UMG_PVE_Particulars_C:OnSelectFeatureItem(featureData)
  if not featureData then
    return
  end
  self.selectedFeatureData = featureData
  self:UpdatePlaceBtn()
end

function UMG_PVE_Particulars_C:UpdatePlaceBtn()
  if self.nodeData == nil or self.nodeData.status ~= PVEModuleEnum.TalentNodeStatus.Unlocked then
    self.PlaceBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    return
  end
  local featureData = self.selectedFeatureData
  if not featureData then
    return
  end
  if not featureData.isActive then
    self.PlaceBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    self.PlaceBtn:SetVisibility(UE.ESlateVisibility.Visible)
    local curPetbaseId = self.nodeData and self.nodeData.newPetConfId or 0
    local selectedPetbaseId = featureData.petbaseId
    if selectedPetbaseId and selectedPetbaseId == curPetbaseId then
      self.PlaceBtn:SetCommonText(_G.LuaText.season_growth_unlock_button_5)
      return
    end
    self.PlaceBtn:SetCommonText(nil ~= curPetbaseId and 0 ~= curPetbaseId and _G.LuaText.season_growth_unlock_button_3 or _G.LuaText.season_growth_unlock_button_4)
  end
end

function UMG_PVE_Particulars_C:OnClickReplacePet()
  if not self.nodeData or not self.selectedFeatureData then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PVE_Particulars_C:OnClickReplacePet")
  local featureData = self.selectedFeatureData
  if not featureData.isActive then
    return
  end
  if featureData.isOccupied then
    local tipConf = _G.DataConfigManager:GetLocalizationConf("season_sgt_pet_repeat")
    local tipText = tipConf and tipConf.msg or ""
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipText)
    return
  end
  if self.nodeData.newPetConfId == featureData.petbaseId then
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.LightUpTalentNode, self.nodeData.id, 0)
  else
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.LightUpTalentNode, self.nodeData.id, featureData.petbaseId)
  end
end

function UMG_PVE_Particulars_C:OnClickLightUpTalentNode()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PVE_Particulars_C:OnClickLightUpTalentNode")
  local nodeData = self.nodeData
  if not nodeData then
    return
  end
  if nodeData.status == PVEModuleEnum.TalentNodeStatus.CanUnlock then
    local materialCnt = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentMaterialCnt)
    local nodeConf = self.nodeConf or _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
    if materialCnt < nodeConf.material_cost then
      local tipConf = _G.DataConfigManager:GetLocalizationConf("season_growth_cailiaobuzu")
      local tipText = tipConf and tipConf.msg or ""
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipText)
      return
    end
    _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.LightUpTalentNode, nodeData.id)
  end
end

function UMG_PVE_Particulars_C:OnPcClose2()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_PVE_Particulars_C:OnPcClose2")
  _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.ClearTalentNode)
  self:OnClose()
end

return UMG_PVE_Particulars_C

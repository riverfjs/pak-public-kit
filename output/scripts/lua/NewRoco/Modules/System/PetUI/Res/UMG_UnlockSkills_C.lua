local UMG_UnlockSkills_C = _G.NRCPanelBase:Extend("UMG_UnlockSkills_C")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_UnlockSkills_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
  self:SetCommonPopUpInfo()
  self:OnAddEventListener()
end

function UMG_UnlockSkills_C:OnActive(_data)
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
  if not _data then
    return
  end
  self.data = _data
  local needLevel = 0
  local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.data.petBaseId)
  if levelSkillConf then
    needLevel = levelSkillConf.blood_skill_level_point
  end
  self.showItemList = {}
  self.showItemListFood = {}
  self.showItemListItem = {}
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
  self.upLevelNeedItem = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSkillUnLockInfoByLevelUp, needLevel, self.data.petGid)
  local _ItemDosageInfo, _ItemSynthesisInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSkillUnLockInfoByChangeBlood, self.data.bagItemIds)
  local bCanUnlock = true
  local haveFood = true
  for i, v in ipairs(self.upLevelNeedItem) do
    if v.itemNum < v.needNum then
      bCanUnlock = false
      haveFood = false
    end
    table.insert(self.showItemList, self:CreateCommonItemIconData(v))
    table.insert(self.showItemListFood, self:CreateCommonItemIconData(v))
  end
  local bloodItem = self:CreateCommonItemIconData(_ItemDosageInfo)
  bloodItem.topLabelText = nil ~= _ItemSynthesisInfo and LuaText.skill_blood_tips_16 or nil
  table.insert(self.showItemList, bloodItem)
  table.insert(self.showItemListItem, bloodItem)
  if (_ItemDosageInfo.itemNum or 0) < _ItemDosageInfo.needNum then
    bCanUnlock = false
  end
  self.bloodItemSynthesisInfo = _ItemSynthesisInfo
  if bCanUnlock then
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.petData then
      local oldSkillConf = PetUtils.GetSkillBloodData(self.petData.blood_id, levelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.petData)
      local newSkillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
      if oldSkillConf and newSkillConf then
        self.PopUp4:SetDescInfo(string.format(LuaText.skill_blood_tips_7, self.petData.name, needLevel, oldSkillConf.name, newSkillConf.name, self.data.text))
      elseif newSkillConf then
        self.PopUp4:SetDescInfo(string.format(LuaText.skill_blood_tips_18, self.petData.name, needLevel, newSkillConf.name, self.data.text))
      end
    end
  elseif haveFood then
    if _ItemSynthesisInfo then
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
      self.PopUp4:SetBtnRightText(LuaText.skill_blood_tips_11)
      if self.petData then
        local oldSkillConf = PetUtils.GetSkillBloodData(self.petData.blood_id, levelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.petData)
        local newSkillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
        if oldSkillConf and newSkillConf then
          self.PopUp4:SetDescInfo(string.format(LuaText.skill_blood_tips_7, self.petData.name, needLevel, oldSkillConf.name, newSkillConf.name, self.data.text))
        elseif newSkillConf then
          self.PopUp4:SetDescInfo(string.format(LuaText.skill_blood_tips_18, self.petData.name, needLevel, newSkillConf.name, self.data.text))
        end
      end
    else
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(_ItemDosageInfo.itemId)
      if bagItemConf then
        self.PopUp4:SetDescInfo(string.format(LuaText.skill_blood_tips_13, bagItemConf.name))
      end
    end
  else
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4:SetDescInfo(LuaText.skill_blood_tips_12)
  end
  self.List_1:InitGridView(self.showItemList)
end

function UMG_UnlockSkills_C:CreateCommonItemIconData(ItemDosageInfo)
  local itemIconData = _G.NRCCommonItemIconData()
  itemIconData.itemType = ItemDosageInfo.itemType or _G.Enum.GoodsType.GT_BAGITEM
  itemIconData.itemId = ItemDosageInfo.itemId
  itemIconData.BagNum = ItemDosageInfo.itemNum
  itemIconData.itemNum = ItemDosageInfo.needNum
  itemIconData.bShowNum = true
  itemIconData.bShowTip = false
  return itemIconData
end

function UMG_UnlockSkills_C:OnDeactive()
  self:RemoveAllButtonListener()
  self:UnRegisterAllEvent()
end

function UMG_UnlockSkills_C:OnAddEventListener()
  self:AddButtonListener(self.DetailsBtn, self.OnDetailsBtnClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnAttributeChangeClose, self.OnAttributeChangeClose)
  self:RegisterEvent(self, PetUIModuleEvent.OnSkillLearningClose, self.OnSkillLearningClose)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpItemSuccess)
end

function UMG_UnlockSkills_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClose
  CommonPopUpData.Btn_LeftHandler = self.OnClose
  CommonPopUpData.Btn_RightHandler = self.OnConFirm
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp4:SetPanelInfo(CommonPopUpData)
  self.PopUp4:SetBtnLeftText(LuaText.umg_dialog_1)
  self.PopUp4:SetBtnRightText(LuaText.umg_dialog_2)
  self.PopUp4.Btn_Right_GrayState:SetBtnText(LuaText.umg_dialog_2)
  self.PopUp4.Btn_Right_GrayState:SetIsEnabled(false)
  self.PopUp4.Btn_Right_GrayState.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_UnlockSkills_C:OnClose()
  self:LoadAnimation(2)
  self:PlayAnimation(self.close)
end

function UMG_UnlockSkills_C:OnConFirm()
  self.skipCloseCallBackType = 2
  self:OnClose()
end

function UMG_UnlockSkills_C:OnDetailsBtnClick()
  self.skipCloseCallBackType = 1
  self:OnClose()
end

function UMG_UnlockSkills_C:OnAttributeChangeClose()
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
end

function UMG_UnlockSkills_C:OnSkillLearningClose()
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
end

function UMG_UnlockSkills_C:OnUseExpItemSuccess()
  self:DoClose()
end

function UMG_UnlockSkills_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    if 1 == self.skipCloseCallBackType then
      self.skipCloseCallBackType = 0
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenAttributeChangePanel, self.data, self.showItemListFood, self.showItemListItem)
    elseif 2 == self.skipCloseCallBackType then
      self.skipCloseCallBackType = 0
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenSkillLearningPanel, self.data, true, self.bloodItemSynthesisInfo == nil)
    else
      self:DoClose()
    end
  end
end

return UMG_UnlockSkills_C

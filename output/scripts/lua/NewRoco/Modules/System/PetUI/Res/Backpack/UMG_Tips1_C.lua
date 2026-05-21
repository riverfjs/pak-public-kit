local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_Tips1_C = _G.NRCPanelBase:Extend("UMG_Tips1_C")

function UMG_Tips1_C:OnConstruct()
  self.uiItem = {}
  self.IsLock = false
  self.uiItem.petTypeIcons = {
    self.UMG_UIIcon,
    self.UMG_UIIcon_1
  }
end

function UMG_Tips1_C:OnDestruct()
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Tips1_C:OnActive(data, openType)
  self.openType = openType
  self.uiData = data
  self:SetTipsInfo()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002013, "UMG_Pet_TeamResonance_C:OnCloseBtnClick")
  local isTemorayData = data and data.petData and _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, data.petData.gid) or false
  if isTemorayData then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    if UE4.UObject.IsValid(self.NRCText_2) then
      local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character1").str
      self.NRCText_2:SetText(str)
    end
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  self:LoadAnimation(0)
  self:OnAddEventListener()
  self:UpdateLeaveForBtnVisibility()
  self:PetFriendInterfaceDisplay()
end

function UMG_Tips1_C:OnEnable()
  if not self.uiData then
    return
  end
  local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.uiData.petData, BagModuleEnum.PetOpenUseAction.Nature)
  if CanUseInBag then
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Tips1_C:SetTipsInfo()
  local petData = self.uiData.petData
  if self.NRCText_87 then
    self.NRCText_87:SetText(LuaText.pet_nature_change_way)
  end
  if self.NRCText_76 then
    self.NRCText_76:SetText(LuaText.UMG_Tips1_Title)
  end
  if petData and petData.nature then
    self.Pet:SetIconPathAndMaterial(self.uiData.petData.base_conf_id, self.uiData.petData.mutation_type, self.uiData.petData.glass_info)
    self:updatePetNature(petData)
    local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, petData, BagModuleEnum.PetOpenUseAction.Nature)
    if CanUseInBag and self.openType and (self.openType == TipEnum.OpenPetTipsType.PetMainPanel or self.openType == TipEnum.OpenPetTipsType.PetWareHouse) then
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:updateDefaultNature()
  end
end

function UMG_Tips1_C:updatePetNature(petData)
  if not petData then
    Log.Error("petData Is nil")
    return
  end
  local petNatureConf = _G.DataConfigManager:GetNatureConf(petData.nature)
  if nil == petNatureConf then
    return
  end
  if 0 ~= petData.changed_nature_pos_attr_type or 0 ~= petData.changed_nature_neg_attr_type then
    self.ChangeCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local natureConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NATURE_CONF):GetAllDatas()
    local ChangeNatureName
    local changed_positive_effect = self:GetChangeAttrReqEnum(petData.changed_nature_pos_attr_type)
    local changed_negative_effect = self:GetChangeAttrReqEnum(petData.changed_nature_neg_attr_type)
    for i, v in ipairs(natureConf) do
      if 0 ~= petData.changed_nature_pos_attr_type and 0 ~= petData.changed_nature_neg_attr_type then
        if v.positive_effect == changed_positive_effect and v.negative_effect == changed_negative_effect then
          ChangeNatureName = v.name
          break
        end
      elseif 0 ~= petData.changed_nature_pos_attr_type and 0 == petData.changed_nature_neg_attr_type then
        if v.positive_effect == changed_positive_effect and v.negative_effect == petNatureConf.negative_effect then
          ChangeNatureName = v.name
          break
        end
      elseif 0 ~= petData.changed_nature_neg_attr_type and 0 == petData.changed_nature_pos_attr_type and v.positive_effect == petNatureConf.positive_effect and v.negative_effect == changed_negative_effect then
        ChangeNatureName = v.name
        break
      end
    end
    Log.Dump(petData, 6, "UMG_Tips1_C:updatePetNature")
    if ChangeNatureName then
      local allTextStr = string.format(LuaText.nature_change_detail, ChangeNatureName)
      if petData.nature_attr_change_way == ProtoEnum.PetNatureAttrChangeWay.EM_PET_NATURE_ATTR_CHANGE_WAY_PET_PARTNER then
        allTextStr = string.format(LuaText.PET_Partner_18, ChangeNatureName)
      end
      self.ChangeText:SetText(allTextStr)
    end
  else
    self.ChangeCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.NRCText:SetText(petNatureConf.name or "")
  if 0 == petNatureConf.negative_effect_proportion or 0 == petNatureConf.negative_effect_proportion then
    self.WidgetSwitcher_64:SetActiveWidgetIndex(1)
  else
    local attributeCfg1, attributeCfg2
    if 0 ~= petData.changed_nature_pos_attr_type then
      attributeCfg1 = self:GetNatureEffect(self:GetChangeAttrReqEnum(petData.changed_nature_pos_attr_type))
    else
      attributeCfg1 = self:GetNatureEffect(petNatureConf.positive_effect)
    end
    if 0 ~= petData.changed_nature_neg_attr_type then
      attributeCfg2 = self:GetNatureEffect(self:GetChangeAttrReqEnum(petData.changed_nature_neg_attr_type))
    else
      attributeCfg2 = self:GetNatureEffect(petNatureConf.negative_effect)
    end
    self:updatePetRedAndBlue(petNatureConf)
    self:updatePetIcon(attributeCfg1, attributeCfg2)
    self:updatePetSkillproperty(attributeCfg1, attributeCfg2)
    self:UpdatePetNumericalValue(petNatureConf)
    self.WidgetSwitcher_64:SetActiveWidgetIndex(0)
  end
end

function UMG_Tips1_C:updateDefaultNature()
  self.ChangeCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local petNatureConf = _G.DataConfigManager:GetNatureConf(self.uiData.natrueId)
  if not petNatureConf then
    return
  end
  local attributeCfg1 = self:GetNatureEffect(petNatureConf.positive_effect)
  local attributeCfg2 = self:GetNatureEffect(petNatureConf.negative_effect)
  self:updatePetIcon(attributeCfg1, attributeCfg2)
  self.NRCText:SetText(petNatureConf.name or "")
  self:updatePetSkillproperty(attributeCfg1, attributeCfg2)
  local Text = string.format("%s%s%s", "+", 10, "%")
  local Text1 = string.format("%s%s%s", "-", 10, "%")
  self.NumericalValue:SetText(Text)
  self.NumericalValue_1:SetText(Text1)
  self.Blue:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Red:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Blue_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Red_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.Pet then
    if self.uiData.base_conf_id then
      self.Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Pet:SetIconPathAndMaterial(self.uiData.base_conf_id, self.uiData.mutation_type, self.uiData.glass_info)
    else
      self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Tips1_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX then
    return Enum.AttributeType.AT_HPMAX_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYATK then
    return Enum.AttributeType.AT_PHYATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEATK then
    return Enum.AttributeType.AT_SPEATK_PERCENT
  elseif attribute == Enum.AttributeType.AT_PHYDEF then
    return Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEDEF then
    return Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif attribute == Enum.AttributeType.AT_SPEED then
    return Enum.AttributeType.AT_SPEED_PERCENT
  end
end

function UMG_Tips1_C:GetNatureEffect(_effect)
  local attribute = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ATTRIBUTE_CONF):GetAllDatas()
  for i, v in pairs(attribute) do
    if _effect == v.attribute then
      return v
    end
  end
end

function UMG_Tips1_C:updatePetSkillproperty(petNatureInfo, petNatureInfo1)
  if petNatureInfo then
    self.NRCText_72:SetText(petNatureInfo.attribute_name)
  end
  if petNatureInfo1 then
    self.NRCText_1:SetText(petNatureInfo1.attribute_name)
  end
end

function UMG_Tips1_C:UpdatePetNumericalValue(petNatureConf)
  local PetData = self.uiData.petData
  local PetGrowLevel, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(PetData)
  local Number = string.format("%s%s%s", "-", petNatureConf.negative_effect_proportion // 100, "%")
  local Number_1 = (petNatureConf.positive_effect_proportion + petNatureConf.positive_effect_grow * (GrowOrder - 1)) // 100
  local Text = string.format("%s%s%s", "+", Number_1, "%")
  self.NumericalValue:SetText(Text)
  self.NumericalValue_1:SetText(Number)
end

function UMG_Tips1_C:updatePetRedAndBlue(petNatureInfo)
  self.Red:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Blue:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Red_1:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Blue_1:SetVisibility(UE4.ESlateVisibility.Visible)
  print("UMG_Tips1_C:updatePetRedAndBlue")
end

function UMG_Tips1_C:updatePetIcon(attributeCfg1Icon, attributeCfg1Icon1)
  if attributeCfg1Icon then
    local IconPath = attributeCfg1Icon.attribute_icon
    self.UMG_UIIcon:SetPath(IconPath)
  end
  if attributeCfg1Icon1 then
    local IconPath1 = attributeCfg1Icon1.attribute_icon
    self.UMG_UIIcon_1:SetPath(IconPath1)
  end
end

function UMG_Tips1_C:OnLeaveForClick()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, BagModuleEnum.DisplayMode.PetOpenToBagByUseAction, self.uiData.petData, BagModuleEnum.PetOpenUseAction.Nature)
end

function UMG_Tips1_C:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:AddButtonListener(self.btnCloseTips, self.OnbtnCloseTipsClick)
  self:AddButtonListener(self.Btn_LeaveFor, self.OnLeaveForClick)
end

function UMG_Tips1_C:OnbtnCloseTipsClick()
  if self.IsLock then
    return
  end
  self.IsLock = true
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002014, "UMG_Bag_C:OnBtnLeft1Clicked")
  self:LoadAnimation(2)
end

function UMG_Tips1_C:_OnPreNtfEnterScene()
  self:DoClose()
end

function UMG_Tips1_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Tips1_C:OnPlayerDataUpdate()
  if self.uiData.petData then
    self.uiData.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
    self:SetTipsInfo()
  end
end

function UMG_Tips1_C:PetFriendInterfaceDisplay()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Tips1_C:UpdateLeaveForBtnVisibility()
  if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Tips1_C:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

return UMG_Tips1_C

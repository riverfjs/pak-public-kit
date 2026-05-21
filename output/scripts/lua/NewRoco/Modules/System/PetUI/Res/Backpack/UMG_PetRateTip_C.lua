local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetRateTip_C = _G.NRCPanelBase:Extend("UMG_PetRateTip_C")

function UMG_PetRateTip_C:OnConstruct()
  self.IsLock = false
end

function UMG_PetRateTip_C:OnActive(data, openType)
  self.openType = openType
  self.uiData = data
  self.exData = {}
  self:SetTipsInfo()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002013, "UMG_Pet_TeamResonance_C:OnCloseBtnClick")
  local isTemorayData = data.petData and _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, data.petData.gid) or false
  if isTemorayData then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    if UE4.UObject.IsValid(self.NRCText) then
      local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character1").str
      self.NRCText:SetText(str)
    end
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPetData and friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:LoadAnimation(0)
  self:OnAddEventListener()
  self:BindInputAction()
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").RATE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_PetRateTip_C:OnEnable()
  if not self.uiData then
    return
  end
  local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.uiData.petData, BagModuleEnum.PetOpenUseAction.Talent)
  if CanUseInBag then
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetRateTip_C:OnPlayerDataUpdate()
  if self.uiData.petData then
    self.uiData.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
    self:SetTipsInfo()
  end
end

function UMG_PetRateTip_C:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_PetRateTip_C:_OnPreNtfEnterScene()
  self:DoClose()
end

function UMG_PetRateTip_C:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:AddButtonListener(self.btnCloseTips, self.OnbtnCloseTipsClick)
  self:AddButtonListener(self.Btn_LeaveFor, self.OnLeaveForClick)
end

function UMG_PetRateTip_C:OnLeaveForClick()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, BagModuleEnum.DisplayMode.PetOpenToBagByUseAction, self.uiData.petData, BagModuleEnum.PetOpenUseAction.Talent)
end

function UMG_PetRateTip_C:OnbtnCloseTipsClick()
  if self.IsLock then
    return
  end
  self.IsLock = true
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002014, "UMG_Bag_C:OnBtnLeft1Clicked")
  self:LoadAnimation(2)
end

function UMG_PetRateTip_C:SetTipsInfo()
  local petData = self.uiData.petData
  local datas = self:GetDataEx(petData)
  if datas then
    self.exData = datas[1]
  else
    Log.Error("Exception: UMG_PetRateTip_C:SetTipsInfo")
  end
  self:updatePetRate(petData)
end

function UMG_PetRateTip_C:updatePetRate(petData)
  if not petData then
    Log.Error("petData Is nil")
    return
  end
  local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, petData, BagModuleEnum.PetOpenUseAction.Talent)
  if CanUseInBag and self.openType and (self.openType == TipEnum.OpenPetTipsType.PetMainPanel or self.openType == TipEnum.OpenPetTipsType.PetWareHouse) then
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetUpRateTitle(petData)
  self:SetUpInfos()
end

function UMG_PetRateTip_C:SetUpRateTitle(petData)
  local talent = petData.talent_rank
  self.Pet:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
  local Text
  if talent == _G.Enum.PetTalentRate.PTR_NORMAL then
    Text = _G.DataConfigManager:GetPetGlobalConfig("pet_talent_text1").str
  elseif talent == Enum.PetTalentRate.PTR_GOOD then
    Text = _G.DataConfigManager:GetPetGlobalConfig("pet_talent_text2").str
  elseif talent == Enum.PetTalentRate.PTR_AMAZING then
    Text = _G.DataConfigManager:GetPetGlobalConfig("pet_talent_text3").str
  elseif talent == Enum.PetTalentRate.PTR_PERFECT then
    Text = _G.DataConfigManager:GetPetGlobalConfig("pet_talent_text4").str
  else
    Text = _G.DataConfigManager:GetPetGlobalConfig("pet_talent_text1").str
  end
  self.NRCText_76:SetText(Text)
end

function UMG_PetRateTip_C:SetUpInfos()
  self.NRCGridView_41:InitGridView(self.exData)
end

function UMG_PetRateTip_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_PetRateTip_C:GetDataEx(petdata)
  local datas
  if petdata then
    local baseInfos = {}
    local attrBaseInfos = {}
    local attritable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ATTRIBUTE_CONF)
    for i = 1, 6 do
      table.insert(attrBaseInfos, attritable:GetData(i))
    end
    for i, conf in pairs(attrBaseInfos) do
      if conf then
        local _conf = conf
        local index = tonumber(_conf.attribute)
        local _num = index
        if _conf and _conf.is_ui_show then
          local attribute = self:Setattribute(_conf)
          local infoItem = {
            conf = _conf,
            num = _num,
            nature = petdata.nature,
            attribute = attribute,
            petdata = petdata
          }
          if _conf.attr_ui_type == Enum.AttrUIType.AUT_BASE then
            table.insert(baseInfos, infoItem)
          end
        end
      end
    end
    table.insert(baseInfos[1], {
      attrInfo = petdata.attribute_info.hp,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_2,
      showTipIndex = self.TipsOpenIndex
    })
    table.insert(baseInfos[2], {
      attrInfo = petdata.attribute_info.attack,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_3,
      showTipIndex = self.TipsOpenIndex
    })
    table.insert(baseInfos[3], {
      attrInfo = petdata.attribute_info.special_attack,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_4,
      showTipIndex = self.TipsOpenIndex
    })
    table.insert(baseInfos[4], {
      attrInfo = petdata.attribute_info.defense,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_5,
      showTipIndex = self.TipsOpenIndex
    })
    table.insert(baseInfos[5], {
      attrInfo = petdata.attribute_info.special_defense,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_6,
      showTipIndex = self.TipsOpenIndex
    })
    table.insert(baseInfos[6], {
      attrInfo = petdata.attribute_info.speed,
      petConfId = petdata.base_conf_id,
      name = LuaText.umg_petdetailedinfo_7,
      showTipIndex = self.TipsOpenIndex
    })
    datas = {baseInfos}
  end
  return datas
end

function UMG_PetRateTip_C:Setattribute(_conf)
  local attribute
  if _conf.attribute == _G.Enum.AttributeType.AT_HPMAX then
    attribute = _G.Enum.AttributeType.AT_HPMAX_PERCENT
  elseif _conf.attribute == _G.Enum.AttributeType.AT_PHYATK then
    attribute = _G.Enum.AttributeType.AT_PHYATK_PERCENT
  elseif _conf.attribute == _G.Enum.AttributeType.AT_SPEATK then
    attribute = _G.Enum.AttributeType.AT_SPEATK_PERCENT
  elseif _conf.attribute == _G.Enum.AttributeType.AT_PHYDEF then
    attribute = _G.Enum.AttributeType.AT_PHYDEF_PERCENT
  elseif _conf.attribute == _G.Enum.AttributeType.AT_SPEDEF then
    attribute = _G.Enum.AttributeType.AT_SPEDEF_PERCENT
  elseif _conf.attribute == _G.Enum.AttributeType.AT_SPEED then
    attribute = _G.Enum.AttributeType.AT_SPEED_PERCENT
  end
  return attribute
end

function UMG_PetRateTip_C:BindInputAction()
end

return UMG_PetRateTip_C

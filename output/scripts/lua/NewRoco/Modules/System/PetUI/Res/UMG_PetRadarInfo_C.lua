local Enum = reload("Data.Config.Enum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetRadarInfo_C = _G.NRCViewBase:Extend("UMG_PetRadarInfo_C")

function UMG_PetRadarInfo_C:OnInitialized()
  self.uiData = {}
end

function UMG_PetRadarInfo_C:OnConstruct()
  self.uiData = {}
  self.UMG_PetFeatures = {
    self.UMG_PetFeatureItem,
    self.UMG_PetFeatureItem_1,
    self.UMG_PetFeatureItem_2,
    self.UMG_PetFeatureItem_3
  }
  self:SetChildViews(self.UMG_PetFeatureItem, self.UMG_PetFeatureItem_1, self.UMG_PetFeatureItem_2, self.UMG_PetFeatureItem_3)
  self:OnAddEventListener()
  local icon1 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_01grew_png.ui_pet_attribute_01grew_png'"
  local icon2 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02grew_png.ui_pet_attribute_02grew_png'"
  local icon3 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_03grew_png.ui_pet_attribute_03grew_png'"
  local icon4 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_06grew_png.ui_pet_attribute_06grew_png'"
  local icon5 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04grew_png.ui_pet_attribute_04grew_png'"
  local icon6 = "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_05grew_png.ui_pet_attribute_05grew_png'"
  self.Icon = {
    hp = icon1,
    phyAtk = icon2,
    phyDef = icon3,
    speed = icon4,
    speAtk = icon5,
    speDef = icon6
  }
  self:OnGetOnAttriMaxValues()
  Log.Debug("UMG_PetRadarInfo_C:OnConstruct")
  self.playChangeTime = _G.DataConfigManager:GetPetGlobalConfig("pet_setich_attribute_time").num / 1000
  self.playChangeTimer = 0
  self.IsPlayChange = false
  self.isPlayContrast = false
  self.CacheAttri = {}
  self.CacheGapAttri = {}
  self.InServiceAttri = {}
  self.CacheAttri.Speed = 0
  self.CacheAttri.SpeDef = 0
  self.CacheAttri.SpeAtk = 0
  self.CacheAttri.HP = 0
  self.CacheAttri.Atk = 0
  self.CacheAttri.Def = 0
  self.CacheOldPetData = nil
  self.IsShowChangeValue = false
  self:PlayAnimationIn()
  if self.InitShowRadarFlag then
    self:OnShowPetRadar(self.module:GetCurrPetData())
    self.InitShowRadarFlag = false
  end
end

function UMG_PetRadarInfo_C:OnDestruct()
  table.clear(self.uiData)
  table.clear(self.UMG_PetFeatures)
  table.clear(self.Icon)
end

function UMG_PetRadarInfo_C:OnEnable()
end

function UMG_PetRadarInfo_C:OnDisable()
  self:UnRegisterEvent(self, PetUIModuleEvent.OnShowPetRadar)
end

function UMG_PetRadarInfo_C:OnAddEventListener()
  self:AddButtonListener(self.detailedBtn, self.OndetailedBtnClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnShowPetRadar, self.OnShowPetRadar)
end

function UMG_PetRadarInfo_C:OnRemoveEventListener()
end

function UMG_PetRadarInfo_C:OndetailedBtnClick()
  if not self.uiData or not self.uiData.petData then
    Log.Error("UMG_PetRadarInfo_C:OndetailedBtnClick  self.uiData.petData is nil")
    return
  end
  local petData = DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    petData = friendInfo.petData
  end
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OpenDetailPanelEvent, true)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetDetailedInfoPanel, petData)
  _G.NRCAudioManager:PlaySound2DAuto(40002028, "UMG_PetRadarInfo_C:OndetailedBtnClick")
end

function UMG_PetRadarInfo_C:OnGetOnAttriMaxValues()
  local _maxHP = _G.DataConfigManager:GetAttrGlobalConfig("at_hp_maximum")
  local _maxAtk = _G.DataConfigManager:GetAttrGlobalConfig("at_attack_maximum")
  local _maxSpeAtk = _G.DataConfigManager:GetAttrGlobalConfig("at_special_attack_maximum")
  local _maxDef = _G.DataConfigManager:GetAttrGlobalConfig("at_defense_maximium")
  local _maxSpeDef = _G.DataConfigManager:GetAttrGlobalConfig("at_special_defense_maximum")
  local _maxSpeed = _G.DataConfigManager:GetAttrGlobalConfig("at_speed_maximum")
  self.uiData.maxValue = {
    maxHP = _maxHP,
    maxAtk = _maxAtk,
    maxSpeAtk = _maxSpeAtk,
    maxDef = _maxDef,
    maxSpeDef = _maxSpeDef,
    maxSpeed = _maxSpeed
  }
end

function UMG_PetRadarInfo_C:OnPetChange()
  local _petData = self.uiData.petData
  if _petData then
    local attri_info = _petData.attribute_info
    local natureConf = {}
    local natureConfNormal = _G.DataConfigManager:GetNatureConf(_petData.nature)
    local natureConfChange = {positive_effect = nil, negative_effect = nil}
    if 0 ~= _petData.changed_nature_pos_attr_type then
      natureConfChange.positive_effect = self:GetChangeAttrReqEnum(_petData.changed_nature_pos_attr_type)
    end
    if 0 ~= _petData.changed_nature_neg_attr_type then
      natureConfChange.negative_effect = self:GetChangeAttrReqEnum(_petData.changed_nature_neg_attr_type)
    end
    if natureConfChange.positive_effect or natureConfChange.negative_effect then
      if not natureConfChange.positive_effect then
        natureConfChange.positive_effect = natureConfNormal.positive_effect
      end
      if not natureConfChange.negative_effect then
        natureConfChange.negative_effect = natureConfNormal.negative_effect
      end
      natureConf = natureConfChange
    else
      natureConf = natureConfNormal
    end
    if self.Icon then
      self:SetInfoItemAttriValue(self.PetRadarinfoLeftItem, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYATK), attri_info.attack, natureConf, Enum.AttributeType.AT_PHYATK_PERCENT, self.Icon.phyAtk, LuaText.RADAR_AT_PHYATK)
      self:SetInfoItemAttriValue(self.PetRadarinfoLeftItem_1, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYDEF), attri_info.defense, natureConf, Enum.AttributeType.AT_PHYDEF_PERCENT, self.Icon.phyDef, LuaText.RADAR_AT_PHYDEF)
      self:SetInfoItemAttriValue(self.PetRadarinfoLeftItem_2, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEED), attri_info.speed, natureConf, Enum.AttributeType.AT_SPEED_PERCENT, self.Icon.speed, LuaText.RADAR_AT_SPEED)
      self:SetInfoItemAttriValue(self.PetRadarinfoRightItem, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_HPMAX), attri_info.hp, natureConf, Enum.AttributeType.AT_HPMAX_PERCENT, self.Icon.hp, LuaText.RADAR_HP_MAX)
      self:SetInfoItemAttriValue(self.PetRadarinfoRightItem_1, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEATK), attri_info.special_attack, natureConf, Enum.AttributeType.AT_SPEATK_PERCENT, self.Icon.speAtk, LuaText.RADAR_AT_SPEATK)
      self:SetInfoItemAttriValue(self.PetRadarinfoRightItem_2, PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEDEF), attri_info.special_defense, natureConf, Enum.AttributeType.AT_SPEDEF_PERCENT, self.Icon.speDef, LuaText.RADAR_AT_SPEDEF)
      if self.CacheOldPetData then
        self:OnRadarShowContrastValues()
      else
        self:OnRadarShowValues()
      end
    end
  end
end

function UMG_PetRadarInfo_C:GetChangeAttrReqEnum(attribute)
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

function UMG_PetRadarInfo_C:SetAttriValue(umgItem, data, data1, natureConf)
  umgItem[1]:SetText(data)
  umgItem[2]:SetText(data1.talent)
  if natureConf.positive_effect == umgItem[5] then
    umgItem[3]:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    umgItem[3]:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if natureConf.negative_effect == umgItem[5] then
    umgItem[4]:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    umgItem[4]:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetRadarInfo_C:OnShowPetRadar(petInfo)
  self.uiData.petData = petInfo
  self:OnRadarShowValues()
end

function UMG_PetRadarInfo_C:OnRadarShowValues()
  self.IsPlayChange = true
  self.isPlayContrast = false
  self.playChangeTimer = 0
  local _petData = self.uiData.petData
  if nil == _petData then
    return
  end
  local HP = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_HPMAX) / self.uiData.maxValue.maxHP.num
  local Atk = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYATK) / self.uiData.maxValue.maxAtk.num
  local SpeAtk = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEATK) / self.uiData.maxValue.maxSpeAtk.num
  local Def = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYDEF) / self.uiData.maxValue.maxDef.num
  local SpeDef = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEDEF) / self.uiData.maxValue.maxSpeDef.num
  local Speed = PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEED) / self.uiData.maxValue.maxSpeed.num
  self.CacheAttri.Speed = math.min(Speed, 1)
  self.CacheAttri.SpeDef = math.min(SpeDef, 1)
  self.CacheAttri.SpeAtk = math.min(SpeAtk, 1)
  self.CacheAttri.HP = math.min(HP, 1)
  self.CacheAttri.Atk = math.min(Atk, 1)
  self.CacheAttri.Def = math.min(Def, 1)
end

function UMG_PetRadarInfo_C:OnRadarShowContrastValues()
  local _petData = self.uiData.petData
  local HP = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_HPMAX) / self.uiData.maxValue.maxHP.num, 1)
  local Atk = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYATK) / self.uiData.maxValue.maxAtk.num, 1)
  local SpeAtk = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEATK) / self.uiData.maxValue.maxSpeAtk.num, 1)
  local Def = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_PHYDEF) / self.uiData.maxValue.maxDef.num, 1)
  local SpeDef = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEDEF) / self.uiData.maxValue.maxSpeDef.num, 1)
  local Speed = math.min(PetUtils.GetPetAdditionalByType(_petData, Enum.AttributeType.AT_SPEED) / self.uiData.maxValue.maxSpeed.num, 1)
  local _oldPetData = self.CacheOldPetData
  local OldHP = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_HPMAX) / self.uiData.maxValue.maxHP.num, 1)
  local OldAtk = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_PHYATK) / self.uiData.maxValue.maxAtk.num, 1)
  local OldSpeAtk = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_SPEATK) / self.uiData.maxValue.maxSpeAtk.num, 1)
  local OldDef = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_PHYDEF) / self.uiData.maxValue.maxDef.num, 1)
  local OldSpeDef = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_SPEDEF) / self.uiData.maxValue.maxSpeDef.num, 1)
  local OldSpeed = math.min(PetUtils.GetPetAdditionalByType(_oldPetData, Enum.AttributeType.AT_SPEED) / self.uiData.maxValue.maxSpeed.num, 1)
  self.CacheAttri.Speed = math.min(OldSpeed, 1)
  self.CacheAttri.SpeDef = math.min(OldSpeDef, 1)
  self.CacheAttri.SpeAtk = math.min(OldSpeAtk, 1)
  self.CacheAttri.HP = math.min(OldHP, 1)
  self.CacheAttri.Atk = math.min(OldAtk, 1)
  self.CacheAttri.Def = math.min(OldDef, 1)
  self.CacheGapAttri.Speed = Speed - OldSpeed
  self.CacheGapAttri.SpeDef = SpeDef - OldSpeDef
  self.CacheGapAttri.SpeAtk = SpeAtk - OldSpeAtk
  self.CacheGapAttri.HP = HP - OldHP
  self.CacheGapAttri.Atk = Atk - OldAtk
  self.CacheGapAttri.Def = Def - OldDef
  if self.playChangeTimer > 0 then
    self.CacheAttri.Speed = math.min(self.InServiceAttri.Speed, 1)
    self.CacheAttri.SpeDef = math.min(self.InServiceAttri.SpeDef, 1)
    self.CacheAttri.SpeAtk = math.min(self.InServiceAttri.SpeAtk, 1)
    self.CacheAttri.HP = math.min(self.InServiceAttri.HP, 1)
    self.CacheAttri.Atk = math.min(self.InServiceAttri.Atk, 1)
    self.CacheAttri.Def = math.min(self.InServiceAttri.Def, 1)
    self.CacheGapAttri.Speed = Speed - self.CacheAttri.Speed
    self.CacheGapAttri.SpeDef = SpeDef - self.CacheAttri.SpeDef
    self.CacheGapAttri.SpeAtk = SpeAtk - self.CacheAttri.SpeAtk
    self.CacheGapAttri.HP = HP - self.CacheAttri.HP
    self.CacheGapAttri.Atk = Atk - self.CacheAttri.Atk
    self.CacheGapAttri.Def = Def - self.CacheAttri.Def
  end
  self.IsPlayChange = true
  self.isPlayContrast = true
  self.playChangeTimer = 0
end

function UMG_PetRadarInfo_C:OnTick(deltaTime)
  if not self.IsPlayChange then
    return
  end
  if self.playChangeTimer < self.playChangeTime then
    self.playChangeTimer = self.playChangeTimer + deltaTime
    local coefficient = self.playChangeTimer / self.playChangeTime
    if self.isPlayContrast then
      self.InServiceAttri.Speed = math.min(self.CacheAttri.Speed + self.CacheGapAttri.Speed * coefficient, 1)
      self.InServiceAttri.SpeDef = math.min(self.CacheAttri.SpeDef + self.CacheGapAttri.SpeDef * coefficient, 1)
      self.InServiceAttri.SpeAtk = math.min(self.CacheAttri.SpeAtk + self.CacheGapAttri.SpeAtk * coefficient, 1)
      self.InServiceAttri.HP = math.min(self.CacheAttri.HP + self.CacheGapAttri.HP * coefficient, 1)
      self.InServiceAttri.Atk = math.min(self.CacheAttri.Atk + self.CacheGapAttri.Atk * coefficient, 1)
      self.InServiceAttri.Def = math.min(self.CacheAttri.Def + self.CacheGapAttri.Def * coefficient, 1)
      self:SetPolygenValue1(math.min(self.CacheAttri.Speed + self.CacheGapAttri.Speed * coefficient, 1), math.min(self.CacheAttri.SpeDef + self.CacheGapAttri.SpeDef * coefficient, 1), math.min(self.CacheAttri.SpeAtk + self.CacheGapAttri.SpeAtk * coefficient, 1), math.min(self.CacheAttri.HP + self.CacheGapAttri.HP * coefficient, 1), math.min(self.CacheAttri.Atk + self.CacheGapAttri.Atk * coefficient, 1), math.min(self.CacheAttri.Def + self.CacheGapAttri.Def * coefficient, 1))
    else
      self.InServiceAttri.Speed = math.min(self.CacheAttri.Speed * coefficient, 1)
      self.InServiceAttri.SpeDef = math.min(self.CacheAttri.SpeDef * coefficient, 1)
      self.InServiceAttri.SpeAtk = math.min(self.CacheAttri.SpeAtk * coefficient, 1)
      self.InServiceAttri.HP = math.min(self.CacheAttri.HP * coefficient, 1)
      self.InServiceAttri.Atk = math.min(self.CacheAttri.Atk * coefficient, 1)
      self.InServiceAttri.Def = math.min(self.CacheAttri.Def * coefficient, 1)
      self:SetPolygenValue1(math.min(self.CacheAttri.Speed * coefficient, 1), math.min(self.CacheAttri.SpeDef * coefficient, 1), math.min(self.CacheAttri.SpeAtk * coefficient, 1), math.min(self.CacheAttri.HP * coefficient, 1), math.min(self.CacheAttri.Atk * coefficient, 1), math.min(self.CacheAttri.Def * coefficient, 1))
    end
  else
    if self.isPlayContrast then
      self:SetPolygenValue1(math.min(self.CacheAttri.Speed + self.CacheGapAttri.Speed, 1), math.min(self.CacheAttri.SpeDef + self.CacheGapAttri.SpeDef, 1), math.min(self.CacheAttri.SpeAtk + self.CacheGapAttri.SpeAtk, 1), math.min(self.CacheAttri.HP + self.CacheGapAttri.HP, 1), math.min(self.CacheAttri.Atk + self.CacheGapAttri.Atk, 1), math.min(self.CacheAttri.Def + self.CacheGapAttri.Def, 1))
    else
      self:SetPolygenValue1(math.min(self.CacheAttri.Speed, 1), math.min(self.CacheAttri.SpeDef, 1), math.min(self.CacheAttri.SpeAtk, 1), math.min(self.CacheAttri.HP, 1), math.min(self.CacheAttri.Atk, 1), math.min(self.CacheAttri.Def, 1))
    end
    self.playChangeTimer = 0
    self.IsPlayChange = false
  end
end

function UMG_PetRadarInfo_C:SetInfoItemAttriValue(infoItem, data, data1, natureConf, attributeType, icon, title)
  if not infoItem then
    Log.Error("UMG_PetRadarInfo_C:SetInfoItemAttriValue infoItem is nil")
    return
  end
  infoItem.attriNameTxt:SetText(title)
  infoItem.numTxt:SetText(data)
  infoItem.curNumTxt:SetText(data1.talent)
  infoItem.imageAttriIcon:SetPath(icon)
  infoItem.numTxt2:SetVisibility(UE4.ESlateVisibility.Hidden)
  infoItem.numTxt3:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.IsShowChangeValue and data1.talent and 0 ~= data1.talent then
    local addText = string.format("(+%d)", data1.talent)
    if attributeType == Enum.AttributeType.AT_SPEED_PERCENT then
      infoItem.numTxt3:SetVisibility(UE4.ESlateVisibility.Visible)
      infoItem.numTxt3:SetText(addText)
    else
      infoItem.numTxt2:SetVisibility(UE4.ESlateVisibility.Visible)
      infoItem.numTxt2:SetText(addText)
    end
  end
  if natureConf and natureConf.positive_effect == attributeType then
    infoItem.imgUp:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    infoItem.imgUp:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if natureConf and natureConf.negative_effect == attributeType then
    infoItem.imgDown:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    infoItem.imgDown:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if data1.talent and 0 ~= data1.talent then
    infoItem.numTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#ffc65f"))
  else
    infoItem.numTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
  end
end

function UMG_PetRadarInfo_C:updatePetSpecialSkill()
  if not self.uiData.petBaseConf then
    return
  end
  local skillIds = {
    self.uiData.petBaseConf.pet_feature
  }
  local skillIdCount = #skillIds
  if self.UMG_PetFeatures then
    for i = 1, #self.UMG_PetFeatures do
      local feature = self.UMG_PetFeatures[i]
      if i <= skillIdCount then
        local skillId = skillIds[i]
        if 0 ~= skillId then
          local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
          if skillCfg then
            feature:updatePetInfo(self.uiData.petData, skillCfg)
            feature:SetVisibility(UE4.ESlateVisibility.Visible)
          end
        else
          feature:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        feature:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetRadarInfo_C:OnPanelStateChange(_isShow)
  self.isShow = _isShow
  if _isShow then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self:ShowPetInfo()
  else
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetRadarInfo_C:SetImage(_IsShow)
  if _IsShow then
    self.NRCImage_91:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.NRCImage_91:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetRadarInfo_C:ShowPetInfo()
  if self.uiData and self.uiData.petData then
    self.uiData.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      self.uiData.petData = friendInfo.petData
    end
    self:OnPetChange()
    self:updatePetSpecialSkill()
  end
end

function UMG_PetRadarInfo_C:PlayAnimationIn()
  self:PlayAnimation(self.In)
end

function UMG_PetRadarInfo_C:updatePetInfo(_petData, _petBaseConf)
  self.CacheOldPetData = self.uiData.petData
  self.uiData.petData = _petData
  self.uiData.petBaseConf = _petBaseConf
  self:ShowPetInfo()
end

function UMG_PetRadarInfo_C:OnSelectPetChange(_petData, _petBaseConf)
  self.uiData.petData = _petData
  self.uiData.petBaseConf = _petBaseConf
  self:ShowPetInfo()
end

function UMG_PetRadarInfo_C:SetIsShowChangeValue(enable)
  self.IsShowChangeValue = enable
end

return UMG_PetRadarInfo_C

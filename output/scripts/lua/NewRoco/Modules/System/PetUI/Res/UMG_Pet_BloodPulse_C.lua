local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_Pet_BloodPulse_C = _G.NRCPanelBase:Extend("UMG_Pet_BloodPulse_C")

function UMG_Pet_BloodPulse_C:OnConstruct()
end

function UMG_Pet_BloodPulse_C:OnDestruct()
end

function UMG_Pet_BloodPulse_C:OnEnable()
  if not self.petData then
    return
  end
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.petData, BagModuleEnum.PetOpenUseAction.NightMareBlood)
    if CanUseInBag then
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.petData.blood_id <= Enum.PetBloodType.PBT_BOSS or self.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.petData, BagModuleEnum.PetOpenUseAction.Blood)
    if CanUseInBag then
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Pet_BloodPulse_C:OnActive(_petData, openType)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").SKILLTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  if not _petData then
    return
  end
  self.openType = openType
  self.petData = _petData
  self.descText = ""
  self:SetPaneInfo()
  self:OnAddEventListener()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002013, "UMG_Bag_C:OnBtnLeft1Clicked")
  local isTemorayData = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, self.petData.gid)
  if isTemorayData then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if UE4.UObject.IsValid(self.NRCText) then
      local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_trial_pet_character1").str
      self.NRCText:SetText(str)
    end
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  self:PetFriendInterfaceDisplay()
  if openType == TipEnum.OpenPetTipsType.FakePetData then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:LoadAnimation(0)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").PETBLOOD
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_Pet_BloodPulse_C:SetPaneInfo()
  if not self.petData then
    Log.Error("\231\178\190\231\129\181\230\149\176\230\141\174\230\178\161\230\156\137,\230\137\190yzyzeng\231\156\139\231\156\139\229\142\159\229\155\160")
    return
  end
  self.Pet:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  if PetBloodConf then
    self.BloodPulse:SetPath(PetBloodConf.icon)
  end
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.petData, BagModuleEnum.PetOpenUseAction.NightMareBlood)
    if CanUseInBag and self.openType and (self.openType == TipEnum.OpenPetTipsType.PetMainPanel or self.openType == TipEnum.OpenPetTipsType.PetWareHouse) then
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.petData.blood_id <= Enum.PetBloodType.PBT_BOSS or self.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    local CanUseInBag = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCanUseBagItemByItemId, self.petData, BagModuleEnum.PetOpenUseAction.Blood)
    if CanUseInBag and self.openType and (self.openType == TipEnum.OpenPetTipsType.PetMainPanel or self.openType == TipEnum.OpenPetTipsType.PetWareHouse) then
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.SizeBox_75:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.petData.base_conf_id)
  local PetbaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  local modelConf = _G.DataConfigManager:GetModelConf(PetbaseConf.model_conf)
  if PetBloodConf and PetBloodConf.blood_tips == Enum.PetBloodTipsType.PBTT_BOSS then
    self.Switcher:SetActiveWidgetIndex(1)
    self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local BossPetBaseId = PetbaseConf.bosspetbase_id_arry[1]
    self.BossPetBaseConf = _G.DataConfigManager:GetPetbaseConf(BossPetBaseId)
    if self.BossPetBaseConf then
      local text
      if self.BossPetBaseConf.is_boss and 1 == self.BossPetBaseConf.is_boss then
        text = string.format("<a id=\"%s\">1</>", self.BossPetBaseConf.name)
      else
        text = self.BossPetBaseConf.name
      end
      local tipsDesc = string.format(LuaText.boss_blood_explain_1, text)
      self.textBuffDesc:SetText(tipsDesc)
    end
    self.BloodPulse:SetPath(PetBloodConf.icon)
  elseif PetBloodConf and self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    self.Switcher:SetActiveWidgetIndex(1)
    self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.textBuffDesc:SetText(PetBloodConf.tips_desc)
    self.BloodPulse:SetPath(PetBloodConf.icon)
    self.SizeBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Switcher:SetActiveWidgetIndex(0)
    local skillConf = self:GetSkillData(self.petData.blood_id, LevelSkillConf)
    if skillConf then
      if PetBloodConf and LevelSkillConf then
        self.BloodPulse:SetPath(PetBloodConf.icon)
        self.NameText:SetText(skillConf.name)
        self.descText = skillConf.desc
        self.Text:SetText(skillConf.desc)
        self.icon:SetPath(skillConf.icon)
        local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
        if typeDic then
          self.SkillShuIcon_1:SetPath(typeDic.tips_res)
        end
        if 1 ~= skillConf.damage_type then
          self.SkillPower_Value:SetText(tostring(skillConf.dam_para[1]))
        else
          self.SkillPower_Value:SetText("-")
        end
        self.NumericalValue_1:SetText(skillConf.energy_cost[1])
        if PetBloodConf.blood == Enum.PetBloodType.PBT_LEGENDARY and LevelSkillConf.legendary_skill_condition and LevelSkillConf.legendary_skill_condition > 0 then
          if self.petData.base_conf_id ~= LevelSkillConf.legendary_skill_condition then
            local unLockBaseCfg = _G.DataConfigManager:GetPetbaseConf(LevelSkillConf.legendary_skill_condition)
            self.NRCText_34:SetText(string.format(LuaText.legendary_tips_1, unLockBaseCfg.name))
            self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.HeadIcon:SetPath(modelConf.icon)
          else
            self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          end
          if PetBloodConf.tips_desc then
            self.textBuffDesc_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.textBuffDesc_1:SetText(PetBloodConf.tips_desc)
          else
            self.textBuffDesc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
        else
          self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.textBuffDesc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          if self.petData.isHandbook then
            self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Spacer:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.HeadIcon:SetPath(modelConf.icon)
            self.NRCText_34:SetText(string.format(LuaText.pet_statistics_blood_description, self.petData.bloodName))
            return
          end
          if LevelSkillConf.blood_skill_level_point <= self.petData.level then
            self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          elseif self.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
            self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          else
            self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Spacer:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.HeadIcon:SetPath(modelConf.icon)
            self.NRCText_34:SetText(string.format(LuaText.umg_petskillmain_tips_1, LevelSkillConf.blood_skill_level_point))
          end
        end
      end
    else
      self.Switcher:SetActiveWidgetIndex(2)
      self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if PetBloodConf then
        self.BloodPulse:SetPath(PetBloodConf.icon)
      end
    end
  end
  if self.openType == TipEnum.OpenPetTipsType.FakePetData then
    self.CanvasPanelTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_BloodPulse_C:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function UMG_Pet_BloodPulse_C:_OnPreNtfEnterScene()
  self:DoClose()
end

function UMG_Pet_BloodPulse_C:OnPlayerDataUpdate()
  if self.petData then
    self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.gid)
    self:SetPaneInfo()
  end
end

function UMG_Pet_BloodPulse_C:OnLeaveForClick()
  if self.petData.blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, BagModuleEnum.DisplayMode.PetOpenToBagByUseAction, self.petData, BagModuleEnum.PetOpenUseAction.NightMareBlood)
  elseif self.petData.blood_id <= Enum.PetBloodType.PBT_BOSS or self.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenToBagMainPanelByOpenType, BagModuleEnum.DisplayMode.PetOpenToBagByUseAction, self.petData, BagModuleEnum.PetOpenUseAction.Blood)
  end
end

function UMG_Pet_BloodPulse_C:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_RSP, self._OnPreNtfEnterScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:AddButtonListener(self.btnCloseTips, self.OnClickbtnCloseTips)
  self:AddButtonListener(self.Btn_LeaveFor, self.OnLeaveForClick)
  self.textBuffDesc_1.OnRichTextClick:Add(self, self.OnDescTextClicked)
  self.Text.OnRichTextClick:Add(self, self.OnDescTextClicked)
  self.textBuffDesc.OnRichTextClick:Add(self, self.OnBossDescTextClicked)
  self.CloseHyperLink.OnClicked:Clear()
  self.CloseHyperLink.OnClicked:Add(self, self.OnCloseHyperLink)
end

function UMG_Pet_BloodPulse_C:OnPcClose()
  self:OnClickbtnCloseTips()
end

function UMG_Pet_BloodPulse_C:GetSkillData(blood_id, LevelSkillConf)
  if not LevelSkillConf then
    return
  end
  if blood_id == Enum.PetBloodType.PBT_COMMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_COMMON)
  elseif blood_id == Enum.PetBloodType.PBT_GRASS then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GRASS)
  elseif blood_id == Enum.PetBloodType.PBT_FIRE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIRE)
  elseif blood_id == Enum.PetBloodType.PBT_WATER then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WATER)
  elseif blood_id == Enum.PetBloodType.PBT_LIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_LIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_STONE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_STONE)
  elseif blood_id == Enum.PetBloodType.PBT_ICE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ICE)
  elseif blood_id == Enum.PetBloodType.PBT_DRAGON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DRAGON)
  elseif blood_id == Enum.PetBloodType.PBT_ELECTRIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ELECTRIC)
  elseif blood_id == Enum.PetBloodType.PBT_TOXIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_TOXIC)
  elseif blood_id == Enum.PetBloodType.PBT_INSECT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_INSECT)
  elseif blood_id == Enum.PetBloodType.PBT_FIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_WING then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WING)
  elseif blood_id == Enum.PetBloodType.PBT_MOE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MOE)
  elseif blood_id == Enum.PetBloodType.PBT_GHOST then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GHOST)
  elseif blood_id == Enum.PetBloodType.PBT_DEMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DEMON)
  elseif blood_id == Enum.PetBloodType.PBT_MECHANIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MECHANIC)
  elseif blood_id == Enum.PetBloodType.PBT_PHANTOM then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_PHANTOM)
  elseif blood_id == Enum.PetBloodType.PBT_LEGENDARY then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.legendary_skill)
  elseif blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    local petData = self.petData
    if petData.skill and petData.skill.skill_data then
      for _, skillData in ipairs(petData.skill.skill_data) do
        if skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          return _G.DataConfigManager:GetSkillConf(skillData.id)
        end
      end
    end
  end
end

function UMG_Pet_BloodPulse_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Pet_BloodPulse_C:OnClickbtnCloseTips()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002014, "UMG_Bag_C:OnBtnLeft1Clicked")
  self:LoadAnimation(2)
end

function UMG_Pet_BloodPulse_C:OnCloseHyperLink()
end

function UMG_Pet_BloodPulse_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Pet_BloodPulse_C:OnBossDescTextClicked(id)
  local skillId = self.BossPetBaseConf.pet_feature
  if 0 ~= skillId then
  else
    local evolution_pet_id = self.BossPetBaseConf.evolution_pet_id[1]
    if nil == evolution_pet_id then
      Log.Error("evolution_pet_id\233\133\141\231\189\174\233\148\153\232\175\175")
      return
    end
    local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
    if evolution_pet_id then
      skillId = evoPetbaseCfg.pet_feature
    end
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  local descText = string.format("<Orange>\227\128\144%s\227\128\145</>\n%s", self.BossPetBaseConf.name, skillCfg.desc)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.bIsUseOriginalText = true
  nounInterpretationTipsInfo.originalTextList = {}
  nounInterpretationTipsInfo.originalTextList[1] = descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Pet_BloodPulse_C:PetFriendInterfaceDisplay()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Pet_BloodPulse_C

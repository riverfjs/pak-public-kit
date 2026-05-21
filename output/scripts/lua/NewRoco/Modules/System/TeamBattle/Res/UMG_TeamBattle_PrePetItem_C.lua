local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_TeamBattle_PrePetItem_C = Base:Extend("UMG_TeamBattle_PrePetItem_C")
UMG_TeamBattle_PrePetItem_C.PetVisibleState = {
  None = 0,
  NPC = 1,
  PlayerIdle = 2,
  PlayerChangePet = 3,
  PlayerPrepared = 4
}

function UMG_TeamBattle_PrePetItem_C:OnConstruct()
end

function UMG_TeamBattle_PrePetItem_C:OnDestruct()
end

function UMG_TeamBattle_PrePetItem_C:OnItemUpdate(_data, datalist, index)
  if _data.curBattleBaseId and _data.curBattleBaseId > 0 then
    self.curBattleBaseId = _data.curBattleBaseId
    if _data.PetData then
      self.uiData = _data.PetData
    else
      self.uiData = _data
    end
    self.uiData.curBattleBaseId = _data.curBattleBaseId
    local isPetPhase = -1
    local IsPetDouble
    if self.uiData.base_conf_id then
      local petData = self.uiData
      local petEquipSkills = {}
      if petData.skill and petData.skill.skill_data then
        for i, skillData in ipairs(petData.skill.skill_data) do
          if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
            petEquipSkills[skillData.pos] = skillData
          end
        end
      end
      for i, v in pairs(petEquipSkills) do
        local skillConf = _G.DataConfigManager:GetSkillConf(v.id)
        if 1 ~= skillConf.damage_type then
          local isPhase, IsDouble = PetUtils.GetTypeRestraint(_data.curBattleBaseId, {
            skillConf.skill_dam_type
          })
          if nil == isPhase then
            if -1 == isPetPhase then
              isPetPhase = isPhase
            elseif false == isPetPhase then
              isPetPhase = nil
            end
          elseif false == isPhase then
            if -1 == isPetPhase then
              isPetPhase = false
              IsPetDouble = IsDouble
            elseif false == isPetPhase then
              isPetPhase = false
              if true == IsPetDouble then
                IsPetDouble = IsDouble
              else
                IsPetDouble = false
              end
            end
          elseif true == isPhase then
            isPetPhase = true
            if nil == IsPetDouble or false == IsPetDouble then
              IsPetDouble = IsDouble
            end
          end
        end
      end
    end
    if self.uiData.petBaseConfId then
      local petData
      if not _G.DataModelMgr.PlayerDataModel:IsVisitState() and 0 ~= self.uiData.petGid then
        petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petGid)
      elseif _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        petData = _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.GetTeamBattlePetDataByUin, self.uiData.playerInfo and self.uiData.playerInfo.uin)
      end
      if petData then
        local petEquipSkills = {}
        if petData.skill and petData.skill.skill_data then
          for i, skillData in ipairs(petData.skill.skill_data) do
            if skillData.is_equipped and 1 == skillData.type and skillData.pos > 0 and skillData.pos <= 4 then
              petEquipSkills[skillData.pos] = skillData
            end
          end
        end
        for i, v in pairs(petEquipSkills) do
          local skillConf = _G.DataConfigManager:GetSkillConf(v.id)
          if 1 ~= skillConf.damage_type then
            local isPhase, IsDouble = PetUtils.GetTypeRestraint(_data.curBattleBaseId, {
              skillConf.skill_dam_type
            })
            if nil == isPhase then
              if -1 == isPetPhase then
                isPetPhase = isPhase
              elseif false == isPetPhase then
                isPetPhase = nil
              end
            elseif false == isPhase then
              if -1 == isPetPhase then
                isPetPhase = false
                IsPetDouble = IsDouble
              elseif false == isPetPhase then
                isPetPhase = false
                if true == IsPetDouble then
                  IsPetDouble = IsDouble
                else
                  IsPetDouble = false
                end
              end
            elseif true == isPhase then
              isPetPhase = true
              if nil == IsPetDouble or false == IsPetDouble then
                IsPetDouble = IsDouble
              end
            end
          end
        end
      end
    end
    if self.uiData.pet_cfg_id then
      local monsterConf = _G.DataConfigManager:GetMonsterConf(self.uiData.pet_cfg_id)
      local petBaseID = monsterConf and monsterConf.find_param[1]
      local baseConf = _G.DataConfigManager:GetPetbaseConf(petBaseID)
      local levelSkillId = baseConf.level_skill_conf_id
      local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(levelSkillId)
      local petEquipSkills = PetUtils.GetHelpPetEquipSkills(LevelSkillConf, monsterConf.blood_id, self.uiData.petLv, self.curBattleBaseId)
      for i, v in pairs(petEquipSkills) do
        local skillConf = _G.DataConfigManager:GetSkillConf(v.id)
        if skillConf and 1 ~= skillConf.damage_type then
          local isPhase, IsDouble = PetUtils.GetTypeRestraint(_data.curBattleBaseId, {
            skillConf.skill_dam_type
          })
          if nil == isPhase then
            if -1 == isPetPhase then
              isPetPhase = isPhase
            elseif false == isPetPhase then
              isPetPhase = nil
            end
          elseif false == isPhase then
            if -1 == isPetPhase then
              isPetPhase = false
              IsPetDouble = IsDouble
            elseif false == isPetPhase then
              isPetPhase = false
              if true == IsPetDouble then
                IsPetDouble = IsDouble
              else
                IsPetDouble = false
              end
            end
          elseif true == isPhase then
            isPetPhase = true
            if nil == IsPetDouble or false == IsPetDouble then
              IsPetDouble = IsDouble
            end
          end
        end
      end
    end
    if nil == isPetPhase then
      self.EffectSwitcher:SetActiveWidgetIndex(1)
      self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif false == isPetPhase then
      if IsPetDouble then
        self.EffectSwitcher:SetActiveWidgetIndex(4)
      else
        self.EffectSwitcher:SetActiveWidgetIndex(2)
      end
      self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif true == isPetPhase then
      if IsPetDouble then
        self.EffectSwitcher:SetActiveWidgetIndex(3)
      else
        self.EffectSwitcher:SetActiveWidgetIndex(0)
      end
      self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.EffectSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if _data.PetData then
      self.uiData = _data.PetData
    else
      self.uiData = _data
    end
  end
  self.index = index
  self:UpdatePanel()
  self:PlayAnimation(self.Click_out, 0.2)
end

function UMG_TeamBattle_PrePetItem_C:OnItemSelected(_bSelected)
  local bPreparation = self.uiData.bPreparation
  if nil ~= bPreparation then
    if self:IsMyself() then
      if _bSelected then
        _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_TeamBattle_PrePetItem_C:OnItemSelected")
        local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        local PreparationInfo = _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.GetTeamMateInfoByUin, myUin)
        local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
        if PreparationInfo and PreparationInfo.prepare_state ~= _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK or nil == PreparationInfo or bOwner then
          _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.OpenChangePetPanel)
        elseif PreparationInfo and PreparationInfo.prepare_state == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.legendary_battle_tips_15)
        end
      end
    elseif _bSelected and self.uiData.playerInfo and self.uiData.playerInfo.uin and bPreparation == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
      _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_TeamBattle_PrePetItem_C:OnItemSelected")
      local petData = _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.GetTeamBattlePetDataByUin, self.uiData.playerInfo and self.uiData.playerInfo.uin)
      NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm, petData, true, {isShowPetSkill = true, IsMyself = false})
    elseif _bSelected and self.uiData.helperNPC then
      _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_TeamBattle_PrePetItem_C:OnItemSelected")
      local monsterConf = _G.DataConfigManager:GetMonsterConf(self.uiData.pet_cfg_id)
      local petBaseID = monsterConf and monsterConf.find_param[1]
      local baseConf = _G.DataConfigManager:GetPetbaseConf(petBaseID)
      local infoData = {
        petBaseId = monsterConf.base_id,
        level = self.uiData.petLv,
        curBattleBaseId = self.curBattleBaseId,
        levelSkillId = baseConf.level_skill_conf_id,
        bloodId = monsterConf.blood_id
      }
      _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm3, infoData, nil, false, false, {isShowPetTips = true})
    end
  else
    if _bSelected then
      _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_TeamBattle_PrePetItem_C:OnItemSelected")
      if self.IsSelect then
        NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm, self.uiData, true, {isShowPetSkill = true, IsMyself = true})
      else
        self:StopAllAnimations()
        self:PlayAnimation(self.Click)
        _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SetChangePetPanelChoosePet, self.uiData)
      end
    else
      self:StopAllAnimations()
      self:PlayAnimation(self.Click_out)
    end
    self.IsSelect = _bSelected
  end
end

function UMG_TeamBattle_PrePetItem_C:OnDeactive()
end

function UMG_TeamBattle_PrePetItem_C:UpdatePanel()
  local bPreparation = self.uiData.bPreparation
  if nil ~= bPreparation then
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PrepareState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:UpdatePrepareInfo()
  else
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PrepareState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:UpdateChangePetInfo()
  end
end

function UMG_TeamBattle_PrePetItem_C:UpdatePrepareInfo()
  self.Text_Sort:SetText(self.index)
  if self.uiData.helperNPC == true then
    self.NRCSwitcher_65:SetActiveWidgetIndex(0)
    local NPC_CONF = _G.DataConfigManager:GetNpcConf(self.uiData.npc_id)
    local monsterConf = _G.DataConfigManager:GetMonsterConf(self.uiData.pet_cfg_id)
    local petBaseID = monsterConf.find_param[1]
    self.PetHeadIcon:SetIconPathAndMaterial(petBaseID, self.uiData.mutation_type or 0, self.uiData.glass_info)
    self.Text_Class:SetText(tostring(self.uiData.petLv or ""))
    self.Text_Name:SetText(NPC_CONF.name)
    local modelConf = _G.DataConfigManager:GetModelConf(NPC_CONF.model_conf)
    local iconPath = modelConf.icon
    self.IconRole:SetPath(iconPath)
    self.Role:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PrepareState:SetActiveWidgetIndex(1)
  elseif self.uiData.playerInfo == nil or nil == self.uiData.playerInfo.uin then
    self:ChangePreparationPetVisibleState(UMG_TeamBattle_PrePetItem_C.PetVisibleState.NPC)
    self.Text_Name:SetText(LuaText.umg_teambattle_prepetitem_1)
    self.NRCSwitcher_65:SetActiveWidgetIndex(0)
  else
    if self:IsMyself() then
      self.Text_Name:SetText(LuaText.umg_teambattle_prepetitem_2)
      self.NRCSwitcher_65:SetActiveWidgetIndex(1)
    else
      self.Text_Name:SetText(self.uiData.playerInfo.name)
      self.NRCSwitcher_65:SetActiveWidgetIndex(0)
    end
    self.PetHeadIcon:SetIconPathAndMaterial(self.uiData.petBaseConfId, self.uiData.mutation_type, self.uiData.glass_info)
    if self.uiData.bPreparation == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
      self:ChangePreparationPetVisibleState(UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerPrepared)
    elseif self.uiData.bPreparation == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_IDLE then
      self:ChangePreparationPetVisibleState(UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerIdle)
    elseif self.uiData.bPreparation == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_SELECT_PET then
      self:ChangePreparationPetVisibleState(UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerChangePet)
    else
      self:ChangePreparationPetVisibleState(UMG_TeamBattle_PrePetItem_C.PetVisibleState.None)
    end
    if 0 ~= self.uiData.petLv then
      self.Text_Class:SetText(tostring(self.uiData.petLv))
    else
      self.Text_Class:SetText("-")
    end
  end
end

function UMG_TeamBattle_PrePetItem_C:UpdateChangePetInfo()
  Log.Dump(self.uiData, 3, "UMG_TeamBattle_PrePetItem_C:UpdatePrepareInfo")
  self.PetHeadIcon:SetIconPathAndMaterial(self.uiData.base_conf_id, self.uiData.mutation_type, self.uiData.glass_info)
  self.Text_Class:SetText(tostring(self.uiData.level))
end

function UMG_TeamBattle_PrePetItem_C:IsMyself()
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if self.uiData.playerInfo then
    if bVisit then
      if self.uiData.playerInfo.uin == playerUin then
        return true
      end
    elseif self.uiData.playerInfo.uin == playerUin then
      return true
    end
  end
  return false
end

function UMG_TeamBattle_PrePetItem_C:IsNPC()
  if self.uiData.playerInfo then
    return false
  end
  return true
end

function UMG_TeamBattle_PrePetItem_C:ChangePreparationPetVisibleState(state)
  local challengeType = _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.GetChallengeType)
  if state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.NPC then
    self.PetHeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.mysterious:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PrepareState:SetActiveWidgetIndex(1)
    self.Text_Class:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerIdle or state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerChangePet or state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.None then
    if self:IsMyself() then
      self.PetHeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.mysterious:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PrepareState:SetActiveWidgetIndex(4)
    else
      if state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerIdle then
        self.PrepareState:SetActiveWidgetIndex(4)
      else
        self.PrepareState:SetActiveWidgetIndex(3)
      end
      if state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.None then
        self.PetHeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.mysterious:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.PetHeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.mysterious:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.None then
        self.PrepareState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  elseif state == UMG_TeamBattle_PrePetItem_C.PetVisibleState.PlayerPrepared then
    self.PetHeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.mysterious:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PrepareState:SetActiveWidgetIndex(1)
  end
end

function UMG_TeamBattle_PrePetItem_C:OnTick(InDeltaTime)
  if not self._pressed or not self._timer then
    return
  end
  self._timer = self._timer - InDeltaTime
  if self._timer <= 0 then
    self:DoLongClick()
  end
end

function UMG_TeamBattle_PrePetItem_C:DoLongClick()
  if self and UE4.UObject.IsValid(self) then
    self._pressed = false
    self._timer = 0
    _G.UpdateManager:UnRegister(self)
    local bPreparation = self.uiData.bPreparation
    if not bPreparation then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm, self.uiData, true, {isShowPetSkill = true, IsMyself = true})
    end
  end
end

function UMG_TeamBattle_PrePetItem_C:OnTouchStarted(MyGeometry, InTouchEvent)
  self._pressed = true
  self._timer = BattleConst.ItemLongPressThreshold
  _G.UpdateManager:Register(self)
  Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_TeamBattle_PrePetItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local oldPress = self._pressed
  self._pressed = false
  _G.UpdateManager:UnRegister(self)
  if oldPress then
    return Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_TeamBattle_PrePetItem_C

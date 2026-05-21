local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleRoundAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Round.BattleRoundAction")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local UMG_Battle_ClickTipUI_C = require("NewRoco.Modules.System.BattleUI.Res.HUD.UMG_Battle_ClickTipUI_C")
local ClickTipData = UMG_Battle_ClickTipUI_C.Data
local Base = BattleRoundAction
local RoundSkillAction = Base:Extend("RoundSkillAction")
FsmUtils.MergeMembers(Base, RoundSkillAction, {})

function RoundSkillAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function RoundSkillAction:OnEnter()
  self.CurrentPushbackReq = self.fsm:GetProperty("CurrentPushbackReq")
  self.CurrentSkill = self.fsm:GetProperty("CurrentSkill")
  self.stateEvent = self.fsm:GetProperty("StateEvent")
  Base.OnEnter(self)
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_SKILL, BattleEvent.BATTLE_PET_SELECT_IDLE, BattleEvent.BATTLE_CLICKED_PET, BattleEvent.BATTLE_PET_SELECT_ROLE_HP, BattleEvent.Clear_SkillList, BattleEvent.ReconnetBattle_RoundStrart, BattleEvent.SkillListChangeUpdate, BattleEvent.Resend_SkillList)
  self.SelectMarkerManager:ClearSelection()
  if self.CurrentPet then
    self.CurrentPet:ShowOperation(false)
    if not self.stateEvent or self.stateEvent == BattleEvent.RoundEvent.EnterSkill then
      local restPets = self.CurrentPet.team.RestPets
      if not restPets[self.CurrentPet.card.posInField] then
        self.CurrentPet:SetHighlight(true)
      end
    end
    if self.CurrentPet.model then
      self.CurrentPet:PlayAnimByName("Show", 1, -1, 0, 0, 1, -1)
    end
  end
  if self.CurrentEnemyPets and self.CurrentPet then
    for i, v in ipairs(self.CurrentEnemyPets) do
      if self.CurrentTeamPets[i] and self.CurrentTeamPets[i].card:IsExistAtField() then
        v:SetLookAt(self.CurrentTeamPets[i].model)
        self.CurrentTeamPets[i]:SetLookAt(v.model)
      else
        v:SetLookAt(self.CurrentPet.model)
      end
    end
  end
  if self.CurrentPlayer then
    self.CurrentPlayer:StopAll()
  end
  if self.CurrentPlayer and self.CurrentPlayer.model then
    self.CurrentPlayer.model:PlayAnimByName(BattleConst.AnimNamePlayer_Idle.Idle, 1, -1, 0, 0, -1, -1)
  end
  if BattleUtils.IsWorldLeaderFight() then
    self:SetPetClickState()
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.PetSelectSkill, self.CurrentPet)
end

function RoundSkillAction:TryUseSkill(Skill)
  if not Skill.skillData.display_hp and Skill.energy > self.CurrentPet:GetEnergy() then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\189\147\229\137\141\232\131\189\233\135\143\228\184\141\232\182\179")
    return false
  end
  return true
end

function RoundSkillAction:OnSelectSkill(Skill, target, IsClickPet)
  if BattleUtils.IsWorldLeaderFight() then
    local CurrentSkillNum = self.CurrentPlayer:GetSkillList()
    local SkillNum = BattleUtils.GetWorldLeaderRewardCount()
    if SkillNum > 1 and not IsClickPet and SkillNum <= #CurrentSkillNum then
      self:SetCanClickPet()
      return
    end
    if not target and not self:TryUseSkill(Skill) then
      return
    end
  end
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  local SkillList = {}
  SkillList.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  SkillList.cast_skill = {}
  if not Skill then
    Log.Error("RoundSkillAction: on select skill nil")
    SkillList.cast_skill.skill_id = 0
    if not self:IsSelectFullSkill() then
      return
    end
  else
    SkillList.cast_skill.skill_id = Skill.id
  end
  local ClickPet, UpPet = activedPlayerSkillInfo:GetClickPetAndUpPet()
  if playerSkillPhase == BattleEnum.PlayerSkillPhase.WaitingToPerform and ClickPet and UpPet and ClickPet.guid == self.CurrentPet.guid then
    local IsChangePetEffectType = activedPlayerSkillInfo:IsChangePetEffectType()
    if IsChangePetEffectType then
      ClickPet, UpPet = activedPlayerSkillInfo:GetClickPetAndUpPet()
      SkillList.cast_skill.caster_pet_id = UpPet.guid
    else
      SkillList.cast_skill.caster_pet_id = self.CurrentPet.guid
    end
  elseif self.CurrentPet then
    SkillList.cast_skill.caster_pet_id = self.CurrentPet.guid
  else
    local battlePets = self.CurrentPlayer.deck:GetBattleFieldAliveCards()
    if #battlePets > 0 then
      SkillList.cast_skill.caster_pet_id = battlePets[1].guid
    else
      return
    end
  end
  if nil == target then
    SkillList.cast_skill.target_pet_id = nil
  else
    SkillList.cast_skill.target_pet_id = target.guid
    SkillList.cast_skill.target_pet_pos = target.card.pos
  end
  if IsClickPet then
    self:ClearAllSkillState()
  end
  self:FinishSkillSelect(Skill, req, SkillList)
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PET_SELECT_TARGET_COMPLETE, self)
end

function RoundSkillAction:OnClickedSkill(skillData)
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideTipTime()
  self.SelectMarkerManager:HideClickTipUI()
  self.CurrentSkill = skillData
  if BattleUtils.IsSinglePlayerMode() then
    self:OnSelectSkill(skillData, nil)
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillData.skill_id)
  if not self:IsCurSkillValidToCast(skillData) then
    return
  end
  local skipCheckResult, target = self:IsSkipCheckCastTarget(skillData)
  if skipCheckResult then
    self:OnSelectSkill(skillData, target)
    return
  end
  self:SetSelectMarker3dOnSkillClicked(skillCfg, true, true)
  local targets = {}
  if skillCfg.target_type == Enum.SkillTargetType.STT_ALL_ALLY or skillCfg.target_type == Enum.SkillTargetType.STT_RANDOM_ALLY then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ALLY)
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_TEAM, BattleConst.CameraTransTime)
    if pets then
      for _, pet in pairs(pets) do
        local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
        pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
        pet:SetHighlight(true, true)
        local anim = PetUtils.GetMultiplayerTargetAnimByHealth(0, true)
        pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
        table.insert(targets, pet.model)
      end
      self:ToggleDarkScene(true, targets)
    end
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_ALL_ENEMY or skillCfg.target_type == Enum.SkillTargetType.STT_RANDOM_ENEMY then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_ENEMY, BattleConst.CameraTransTime)
    if pets then
      for _, pet in pairs(pets) do
        local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
        pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
        pet:ShowRestraintUI(skillData)
        pet:SetHighlight(true, true)
        table.insert(targets, pet.model)
        local healthRate = pet.health:GetHp() / pet.health:GetMaxHp()
        local anim = PetUtils.GetMultiplayerTargetAnimByHealth(healthRate, false)
        pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
      end
      self:ToggleDarkScene(true, targets)
    end
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_MYSELF then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_MYSELF)
    local pet = self.CurrentPet
    local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
    pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
    pet:SetHighlight(true, true)
    self:ToggleDarkScene(true, {
      pet.model
    })
    local anim = PetUtils.GetMultiplayerTargetAnimByHealth(0, true)
    pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_TEAM, BattleConst.CameraTransTime)
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_ALL_OTHER_ALLY or skillCfg.target_type == Enum.SkillTargetType.STT_ONE_OTHER_ALLY then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_OTHER_ALLY)
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_TEAM, BattleConst.CameraTransTime)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
          pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
          pet:SetHighlight(true, true)
          table.insert(targets, pet.model)
          local anim = PetUtils.GetMultiplayerTargetAnimByHealth(0, true)
          pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
        end
      end
      self:ToggleDarkScene(true, targets)
    end
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_RANDOM_MY_PET then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_MYSELF_ALLY)
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, true)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_TEAM, BattleConst.CameraTransTime)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
          pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
          pet:SetHighlight(true, true)
          table.insert(targets, pet.model)
          local anim = PetUtils.GetMultiplayerTargetAnimByHealth(0, true)
          pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
        end
      end
      self:ToggleDarkScene(true, targets)
    end
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_ALL_OTHER then
    self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ALL)
    local teamPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_TEAM, BattleConst.CameraTransTime)
    if teamPets then
      for _, pet in pairs(teamPets) do
        local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
        pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
        pet:SetHighlight(true, true)
        table.insert(targets, pet.model)
      end
    end
    self:ToggleDarkScene(true, targets)
    local enemyPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    self.BattleManager.vBattleField.battleCameraManager:ChangeToSpecialCamera(BattleEnum.Team.ENUM_ENEMY, BattleConst.CameraTransTime)
    if enemyPets then
      for _, pet in pairs(enemyPets) do
        local catchGradeValue = BattleUtils.GetSkillCatchGradeValueByPetId(skillData.skillData, pet.guid)
        pet:ShowClickTipUI(ClickTipData(skillCfg.target_type, skillCfg.skill_feature, catchGradeValue, UMG_Battle_ClickTipUI_C.ColorSchemeType.Restraint))
        pet:SetHighlight(true, true)
        local healthRate = pet.health:GetHp() / pet.health:GetMaxHp()
        local anim = PetUtils.GetMultiplayerTargetAnimByHealth(healthRate, false)
        pet:PlayAnimByName(anim, 1, -1, 0, 0, 1, -1)
        table.insert(targets, pet.model)
      end
    end
    self:ToggleDarkScene(true, targets)
  elseif skillCfg.target_type == Enum.SkillTargetType.STT_AHEAD then
    self:OnSelectSkill(skillData, nil)
    return
  end
  local mainWindow = BattleUtils.GetMainWindow()
  mainWindow:ChangePanelByOperateType(BattleEnum.Operation.ENUM_NONE, true)
  mainWindow.UMG_Battle_Operate.SkillClick:PlayUnselectAnimation()
  mainWindow.UMG_Battle_Operate:SetSkillCheckedState()
  mainWindow.UMG_Battle_Operate.curIndex = -1
end

function RoundSkillAction:IsCurSkillValidToCast(Skill)
  if Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ONE_OTHER_ALLY or Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER_ALLY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if 1 == #pets and pets[1] == self.CurrentPet then
      local showTip = _G.DataConfigManager:GetLocalizationConf("Target_Not_Exist")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, showTip.msg)
      return false
    end
  end
  return true
end

function RoundSkillAction:IsSkipCheckCastTarget(Skill)
  local count = 0
  local target
  if Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ONE_OTHER_ALLY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          count = count + 1
          target = pet
        end
      end
    end
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER_ALLY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          count = count + 1
          target = pet
        end
      end
    end
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          count = count + 1
        end
      end
    end
    pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    if pets then
      for _, pet in pairs(pets) do
        if pet.guid ~= self.CurrentPet.guid then
          count = count + 1
          target = pet
        end
      end
    end
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_MYSELF then
    target = self.CurrentPet
    return true, target
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_RANDOM_ALLY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    count = #pets
    target = pets[1]
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_RANDOM_ENEMY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    count = #pets
    target = pets[1]
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ALL_ALLY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    count = #pets
    target = pets[1]
  elseif Skill.config.target_type == ProtoEnum.SkillTargetType.STT_ALL_ENEMY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    count = #pets
    target = pets[1]
  end
  if 1 == count then
    return true, target
  else
    return false, target
  end
end

function RoundSkillAction:SetCanClickPet()
  self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
  local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
  if pets then
    local targets = {}
    for _, pet in pairs(pets) do
      pet:ShowClickTipUI()
      pet:SetHighlight(true, true)
      table.insert(targets, pet.model)
    end
    self:ToggleDarkScene(true)
  end
  if self.CurrentPet.model then
    self.CurrentPet:PlayAnimByName("Show", 1, -1, 0, 0, 1, -1)
  end
end

function RoundSkillAction:ClearAllSkillState()
  if self.SelectMarkerManager then
    self.SelectMarkerManager:ClearSelection()
    self.SelectMarkerManager:HideTipTime()
    self.SelectMarkerManager:HideClickTipUI()
    self.SelectMarkerManager:HideAllSelectMarkers()
  end
  self:ResetPetsLight()
  self:SetEnemyPetHighlight(false)
  self:SetTeamPetHighlight(false)
  self:ToggleDarkScene(false)
end

function RoundSkillAction:SetPetClickState()
  if self:IsSelectFullSkill() then
    self:SetCanClickPet()
  end
end

function RoundSkillAction:IsSelectFullSkill()
  if not BattleUtils.IsWorldLeaderFight() then
    return false
  end
  if not BattleUtils.IsWorldLeaderRewardRound() then
    return false
  end
  if not self.CurrentPlayer then
    Log.Error("RoundSkillAction Player is nil")
    return false
  end
  local CurrentSkillNum = self.CurrentPlayer:GetSkillList()
  local SkillNum = _G.BattleManager.battleRuntimeData.battleStartParam.battleInitInfo.world_leader_fight_info.boss_register_skill_cnt or 3
  if SkillNum <= #CurrentSkillNum then
    return true
  end
  return false
end

function RoundSkillAction:FinishSkillSelect(Skill, Req, SkillList)
  if not self.CurrentPlayer.IsCanUseSkill then
    return
  end
  self.CurrentPet.opParam = Skill
  local SkillListInfo = {}
  if BattleUtils.IsWorldLeaderFight() then
    local SkillNum = BattleUtils.GetWorldLeaderRewardCount()
    if SkillNum > 1 then
      local CurrentSkillNum = self.CurrentPlayer:GetSkillList()
      if SkillNum > #CurrentSkillNum then
        self.CurrentPlayer:AddSkillList(SkillList)
        self.CurrentPlayer:AddCalCuLusSkillList()
        SkillListInfo = self.CurrentPlayer:GetSkillList()
        _G.NRCAudioManager:PlaySound2DAuto(1220002010, "RoundSkillAction:FinishSkillSelect")
        _G.BattleEventCenter:Dispatch(BattleEvent.Skill_Preload, SkillListInfo)
      elseif SkillNum <= #CurrentSkillNum then
        Req.is_confirm = true
        SkillListInfo = CurrentSkillNum
      else
        Log.Error("\230\138\128\232\131\189\233\135\138\230\148\190\230\149\176\233\135\143\229\164\167\228\186\142\231\144\134\230\131\179\231\154\132\233\135\138\230\148\190\230\149\176\233\135\143")
      end
      self:SetPetClickState()
      self.CurrentPlayer:SetContinuousSkillSucceed(Req.is_confirm)
    else
      Req.is_confirm = true
      table.insert(SkillListInfo, SkillList)
    end
  else
    table.insert(SkillListInfo, SkillList)
  end
  Req.req = SkillListInfo
  if self:SendPushbackReq(Req) then
    self:DisablePlayerOp(true)
  end
end

function RoundSkillAction:OnPushbackSent(rsp)
  if not (rsp and rsp.req) or 0 ~= rsp.ret_info.ret_code then
    self:DisablePlayerOp(false)
  end
  Base.OnPushbackSent(self, rsp)
end

function RoundSkillAction:DisablePlayerOp(disable)
  if self.CurrentPlayer then
    self.CurrentPlayer:SetIsCanUseSkill(not disable)
  end
end

function RoundSkillAction:ClearAllSkill()
  self:ClearAllSkillState()
end

function RoundSkillAction:OnSelectedIdle()
  local BattleRoundFlowReqList = {}
  local BattleRoundFlowReq = {}
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  local skill_id = self.CurrentPet.skillComponent:GetExSkillID(ProtoEnum.SkillActiveType.SAT_IDLE)
  BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  BattleRoundFlowReq.cast_skill = {}
  BattleRoundFlowReq.cast_skill.skill_id = skill_id
  BattleRoundFlowReq.cast_skill.caster_pet_id = self.CurrentPet.guid
  BattleRoundFlowReq.cast_skill.target_pet_id = self.CurrentPet.guid
  BattleRoundFlowReq.cast_skill.target_pet_pos = self.CurrentPet.card.pos
  table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
  req.req = BattleRoundFlowReqList
  self:SendPushbackReq(req)
end

function RoundSkillAction:OnSelectedRoleEnergySkill()
  local BattleRoundFlowReqList = {}
  local BattleRoundFlowReq = {}
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  local skill_id = self.CurrentPet.skillComponent:GetExSkillID(ProtoEnum.SkillActiveType.SAT_LACKENERGY)
  BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  BattleRoundFlowReq.cast_skill = {}
  BattleRoundFlowReq.cast_skill.skill_id = skill_id
  BattleRoundFlowReq.cast_skill.caster_pet_id = self.CurrentPet.guid
  BattleRoundFlowReq.cast_skill.target_pet_id = self.CurrentPet.guid
  BattleRoundFlowReq.cast_skill.target_pet_pos = self.CurrentPet.card.pos
  table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
  req.req = BattleRoundFlowReqList
  self:SendPushbackReq(req)
end

function RoundSkillAction:OnPetClicked(Pet)
  if not self.CurrentSkill and not self:IsSelectFullSkill() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.roundskillaction_1)
    return
  end
  if self.CurrentSkill and not BattleUtils.IsSinglePlayerMode() then
    local skillCfg = _G.DataConfigManager:GetSkillConf(self.CurrentSkill.skill_id)
    self:SetSelectMarker3dOnSkillClicked(skillCfg, false, false)
    self:SetSelectMarker3dOnPetClicked(skillCfg, Pet)
    local waitTime = 0
    if self:CheckIsAOE(skillCfg) then
      waitTime = BattleConst.SkillSelectSettings.WaitSelectorUIAnimTimeAOE
    else
      waitTime = BattleConst.SkillSelectSettings.WaitSelectorUIAnimTime
    end
    self.DelayId = _G.DelayManager:DelaySeconds(waitTime, self.OnPetClickedFinish, self, Pet)
  else
    self:OnPetClickedFinish(Pet)
  end
end

function RoundSkillAction:OnPetClickedFinish(Pet)
  if self.CurrentSkill or self:IsSelectFullSkill() then
    self:OnSelectSkill(self.CurrentSkill, Pet, true)
  end
end

function RoundSkillAction:SetSelectMarker3dOnSkillClicked(skillCfg, bShow, immediately)
  if skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_ENEMY then
    local teamPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    if teamPets then
      for _, pet in pairs(teamPets) do
        if immediately then
          pet:ShowSelectMarker3d(bShow)
        end
        pet:OperateSelectMarker3dWithAnimation(bShow)
      end
    end
  elseif skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_ALLY then
    local teamPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if teamPets then
      for _, pet in pairs(teamPets) do
        if immediately then
          pet:ShowSelectMarker3d(bShow)
        end
        pet:OperateSelectMarker3dWithAnimation(bShow)
      end
    end
  elseif skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER then
    local teamPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if teamPets then
      for _, pet in pairs(teamPets) do
        if pet ~= self.CurrentPet then
          if immediately then
            pet:ShowSelectMarker3d(bShow)
          end
          pet:OperateSelectMarker3dWithAnimation(bShow)
        end
      end
    end
    local enemyPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY, false)
    if enemyPets then
      for _, pet in pairs(enemyPets) do
        if immediately then
          pet:ShowSelectMarker3d(bShow)
        end
        pet:OperateSelectMarker3dWithAnimation(bShow)
      end
    end
  elseif skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER_ALLY then
    local teamPets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false)
    if teamPets then
      for _, pet in pairs(teamPets) do
        if pet ~= self.CurrentPet then
          if immediately then
            pet:ShowSelectMarker3d(bShow)
          end
          pet:OperateSelectMarker3dWithAnimation(bShow)
        end
      end
    end
  end
end

function RoundSkillAction:SetSelectMarker3dOnPetClicked(skillCfg, pet)
  if skillCfg.target_type == ProtoEnum.SkillTargetType.STT_RANDOM_ENEMY or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_RANDOM_ALLY or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ONE_OTHER_ALLY or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_MYSELF then
    pet:ShowSelectMarker3d(true)
    pet:OperateSelectMarker3dWithAnimation(true)
    _G.DelayManager:DelaySeconds(BattleConst.SkillSelectSettings.SingleTargetSelectorExistingTime, pet.OperateSelectMarker3dWithAnimation, pet, false)
  end
end

function RoundSkillAction:CheckIsAOE(skillCfg)
  if skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_ENEMY or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_ALLY or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER or skillCfg.target_type == ProtoEnum.SkillTargetType.STT_ALL_OTHER_ALLY then
    return true
  end
  return false
end

function RoundSkillAction:ReSendSkillListOnReconnect()
  if not BattleUtils.IsWorldLeaderFight() then
    return
  end
  local SkillNum = BattleUtils.GetWorldLeaderRewardCount()
  if SkillNum <= 1 then
    return
  end
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  self.CurrentPlayer:ChangeListToPreSuccess()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  local CurrentSkillList = self.CurrentPlayer:GetSkillList()
  req.req = CurrentSkillList
  if self:SendPushbackReq(req) then
    self:DisablePlayerOp(true)
  end
end

function RoundSkillAction:OnReSendSkillList()
  if not BattleUtils.IsWorldLeaderFight() then
    return
  end
  local SkillNum = BattleUtils.GetWorldLeaderRewardCount()
  if SkillNum <= 1 then
    return
  end
  local CurrentSkillList = self.CurrentPlayer:GetSkillList()
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
  req.req = CurrentSkillList
  if self:SendPushbackReq(req) then
    self:DisablePlayerOp(true)
  end
end

function RoundSkillAction:SkillListChangeUpdate()
  if self:IsSelectFullSkill() then
    self:SetCanClickPet()
  else
    self:ClearAllSkillState()
  end
end

function RoundSkillAction:OnExit()
  if not BattleUtils.IsSinglePlayerMode() and self.CurrentSkill then
    local skillCfg = _G.DataConfigManager:GetSkillConf(self.CurrentSkill.skill_id)
    self:SetSelectMarker3dOnSkillClicked(skillCfg, false, true)
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  _G.BattleEventCenter:UnBind(self)
  _G.BattleEventCenter:Dispatch(BattleEvent.LeaveSkillRound)
  self.SelectMarkerManager:HideClickTipUI()
  self.SelectMarkerManager:HideAllSelectMarkers()
  Base.OnExit(self)
  self.CurrentSkill = nil
  self.CurrentPushbackReq = nil
end

function RoundSkillAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_SKILL then
    self:OnClickedSkill(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PET_SELECT_IDLE then
    self:OnSelectedIdle()
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_PET then
    self:OnPetClicked(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PET_SELECT_ROLE_HP then
    self:OnSelectedRoleEnergySkill()
    return true
  elseif eventName == BattleEvent.Clear_SkillList then
    self:ClearAllSkill(...)
    return true
  elseif eventName == BattleEvent.ReconnetBattle_RoundStrart then
    self:ReSendSkillListOnReconnect()
    return true
  elseif eventName == BattleEvent.Resend_SkillList then
    self:OnReSendSkillList()
    return true
  elseif eventName == BattleEvent.SkillListChangeUpdate then
    self:SkillListChangeUpdate()
    return true
  end
end

return RoundSkillAction

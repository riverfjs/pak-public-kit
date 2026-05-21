local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Timer = require("Utils.Timer")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleRoundSelectMarkerManager = require("NewRoco.Modules.Core.Battle.BattleRoundSelectMarkerManager")
local RoundSelectFsm = require("NewRoco.Modules.Core.Battle.Fsm.RoundSelectFsm")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger_Declare")
local Enum = require("Data.Config.Enum")
local BattleRoundSelectAction = BattleActionBase:Extend("BattleRoundSelectAction")
FsmUtils.MergeMembers(BattleActionBase, BattleRoundSelectAction, {
  {name = "RoundState", type = "number"}
})

function BattleRoundSelectAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.battleManager = _G.BattleManager
  self.battleSelectMarkerMgr = BattleRoundSelectMarkerManager()
  self.SelectFsm = RoundSelectFsm()
  self.SelectFsm:SetProperty("MarkerManager", self.battleSelectMarkerMgr)
  self.SelectFsm:SetProperty("WillChangePet", false)
  self.SelectFsm:SetProperty("WillCatchPet", false)
  self.RelaxTimer = Timer()
  self.OnLookersIdleAnimTimerHandlerMap = {}
  self.NotNeedSelectSkillPlayerSkillIdList = {
    BattleUtils.GetFBCallNameMagicId()
  }
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function BattleRoundSelectAction:OnEnter()
  self.roundState = self:GetProperty("RoundState")
  local operateType = self:GetStartOperate()
  self.curEvent = self:GetStateNameFromOperate(operateType)
  self.SelectFsm:SetInitStateName(self.curEvent)
  self.wl_req_id = BattleNetManager:GetWlReqID()
  if self.battleManager.vBattleField.battleCameraManager then
    self.battleManager.vBattleField.battleCameraManager.KontrolEnabled = true
  end
  self.SelectFsm:SetProperty("WillChangePet", false)
  self.SelectFsm:SetProperty("WillCatchPet", false)
  self.SelectFsm:SetProperty("CurrentSelectGuid", 0)
  self.SelectFsm:Play()
  self.fsm:Pause()
  self.timeout = self:GetTimeoutValue()
  _G.BattleManager:ClearCraneCameraTemporaryPosData()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattlePetEvolutionFinishPanel)
  local mainWindow = BattleUtils.GetMainWindow()
  local battlePawnManager = self.battleManager.battlePawnManager
  _G.BattleEventCenter:Dispatch(BattleEvent.ROUND_STATE_SELECT)
  _G.BattleEventCenter:Bind(self, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.PUSHBACK_CMD_SENT, BattleEvent.POPBACK_CMD_SENT, BattleEvent.PET_SPAWNED, BattleEvent.BATTLE_PLAY_PLAYERSKILL_SUCCESS, BattleEvent.BATTLE_RECOVER_PLAYERSKILL, BattleEvent.BATTLE_SET_PLAYERSKILL, BattleEvent.Clear_SkillList, BattleEvent.SHOW_MAIN_WHEN_SKILLOVER, BattleEvent.ALL_ONLOOKER_SPAWNED, BattleEvent.LEAVE_ESCAPE_STATE, BattleEvent.ReconnetBattle_RoundStrart, BattleEvent.UPDATE_UI_ON_ROUND_SELECT)
  BattleUtils.CheerPetsStartRandomMove()
  self.battleManager.EscapeContext:Close()
  if mainWindow then
    mainWindow:SetSelectMarkerMgr(self.battleSelectMarkerMgr)
    mainWindow:SetSkillPanelUndoCallback(self, self.UndoSelect, self.UndoBattleSelectRsp)
  end
  _G.BattleManager.battleRuntimeData.PlayerSkillManager:SetIsPlayerSkillSuccess(false)
  local team = battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  if not team then
    Log.Error("BattleRoundSelectAction:OnEnter \230\136\152\229\156\186\229\138\160\232\189\189\229\164\177\232\180\165\229\149\166\239\188\129 \233\186\187\231\131\166\232\129\148\231\179\187Jinfuwang")
    return
  end
  self.operationPets = battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
  self.CurrentPlayer = team.player
  self.CurrentPlayer:SetIsCanUseSkill(true)
  if BattleUtils.IsFinalBattleP1() then
    self.index = 1
  end
  if self.roundState == ProtoEnum.BATTLE_STATE_NOTIFY_TYPE.BATTLE_STATE_SELECT_CATCH then
    local Boss = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
    if Boss and not Boss.card.petState:GetCatchStun() then
      Boss.buffComponent:RemoveBuffs(true)
      Boss.buffComponent:ClearBuff()
      Boss.buffComponent:PlayStateEffect(Enum.BuffGroupSign.BGS_CATCHSTUN)
      Boss.card.petState:SetCatchStun(true)
    end
  end
  local nextPet, nextIndex = self:GetNextNoOpPet()
  if nextPet then
    self.index = nextIndex - 1
  else
    local forceCallYase = BattleUtils.CheckFinalBattleEnergyIsFull()
    if not forceCallYase and self.roundState ~= ProtoEnum.BATTLE_STATE_NOTIFY_TYPE.BATTLE_STATE_SELECT_CATCH then
      Log.Warning("zgx \230\136\145\230\150\185\230\137\128\230\156\137\229\174\160\231\137\169\233\131\189\230\156\137\230\147\141\228\189\156  \228\184\141\233\156\128\232\166\129\233\128\137\230\139\155\228\186\134")
      if not BattleUtils.IsRunAwayFree() then
        self:ChangeToWaitOther()
        return
      else
        local pets = _G.BattleManager.battlePawnManager:GetCanSelectPetsByPlayer(self.CurrentPlayer)
        if pets and #pets > 0 then
          self:ChangeToWaitOther()
          return
        end
      end
    end
  end
  self:CheckChangePet()
  self.battleSelectMarkerMgr:HideAllSelectMarkers()
  self.CurrentEnemyPet = self.battleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  local curEventIsSkillState = self.curEvent == BattleEnum.RoundStateNames.SkillState
  local isObserverMode2 = false
  if _G.BattleUtils.IsWatchingBattle() then
    local observeMode = ProtoEnum.ObserveBattleMode.OBM_MODE_2
    local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    if playerSettings then
      observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
    end
    if observeMode == ProtoEnum.ObserveBattleMode.OBM_MODE_2 then
      isObserverMode2 = true
    end
  end
  local moveView = curEventIsSkillState or isObserverMode2
  local notMoveView = not moveView
  self:StartSelect(notMoveView)
  self.battleManager:ChangeOperateMode(operateType)
  local roundIndex = self.battleManager.battleRuntimeData.roundIndex
  if 1 == roundIndex then
    _G.BattleEventCenter:Dispatch(BattleEvent.MONSTER_RUNAWAY_SHOW_POPUP)
  end
  self.battleManager.battleRuntimeData.startRoundSelectRoundIndex = _G.BattleManager:GetCurRound()
  if battlePawnManager.EnemyPlayer and battlePawnManager.EnemyPlayer.model then
    local relaxEnumMap = {
      [1] = UE4.EBattlePlayerAnimType.Relax1,
      [2] = UE4.EBattlePlayerAnimType.Relax2,
      [3] = UE4.EBattlePlayerAnimType.Relax3,
      [4] = UE4.EBattlePlayerAnimType.Relax4
    }
    self.RelaxTimerHandler = self.RelaxTimer:Every(9.34, function()
      local index = math.random(BattleConst.Show.BattlePlayerRelaxCount)
      battlePawnManager.EnemyPlayer.model:PlayAnimByType(relaxEnumMap[index])
    end)
    if not BattleUtils.IsDeepWater() then
      battlePawnManager.EnemyPlayer:PinOnTheGround()
    end
  end
  local playerPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, playerPet in pairs(playerPets) do
    playerPet:SwimSetLockIdle(true)
    playerPet:PlayAnimByName("Show", 1, -1, 0, 0, 1, -1)
  end
  local enemyPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  for _, enemyPet in pairs(enemyPets) do
    enemyPet:SwimSetLockIdle(true)
    if BattleUtils.IsPve() then
    end
    if enemyPet.card.petState:GetSleep() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.Sleeping,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetBackStab() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsBacking,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetDrill() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsDrill,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetMimic() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsMimic,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetStatic() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsStatic,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetStun() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsStun,
        enemyPet
      }, self)
    end
    if enemyPet.card.petState:GetThunder() then
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
        BattleEnum.InfoPopupType.IsThunder,
        enemyPet
      }, self)
    end
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetBattleHidePanelState, true)
  _G.BattleEventCenter:Dispatch(BattleEvent.ROUND_SELECT_START)
  if BattleUtils.IsWorldLeaderFight() then
    self.battleManager.battleRuntimeData:SetOnSelectWorldLeaderSkill(true)
    if BattleUtils.GetWorldLeaderRewardCount() > 1 and self.CurrentPet then
      self.CurrentPet.health:SetOldHp(self.CurrentPet.health:GetHp())
    end
  end
  if BattleUtils.CheckFinalBattleEnergyIsFull() then
    BattleResourceManager:LoadResAsync(self, BattleConst.FinalBattleP1ToP2Seq)
  end
end

function BattleRoundSelectAction:RefreshActionData()
  if not self.battleManager then
    return
  end
  local battlePawnManager = self.battleManager.battlePawnManager
  local team = battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  self.operationPets = battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
  self.CurrentPlayer = team.player
end

function BattleRoundSelectAction:ChangeToWaitOther()
  if self.battleManager.battleRuntimeData.operateType == BattleEnum.Operation.ENUM_NONE then
    self.battleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_NONE)
  end
  Log.Debug("zgx No op \230\136\145\230\150\185\229\174\160\231\137\169\230\147\141\228\189\156\229\174\140\230\136\144 \232\191\155\229\133\165\232\161\168\230\131\133\230\181\129\231\168\139")
  self.fsm:SendEvent(BattleEvent.EnterWaitOther, nil, {
    self.state.name
  })
end

function BattleRoundSelectAction:GetStartOperate()
  local operateType = BattleEnum.Operation.ENUM_SKILL
  local IsCanCatch = self.roundState == ProtoEnum.BATTLE_STATE_NOTIFY_TYPE.BATTLE_STATE_SELECT_CATCH
  if BattleUtils.IsTeam() and IsCanCatch then
    operateType = BattleEnum.Operation.ENUM_CATCH
  elseif BattleUtils.CheckFinalBattleEnergyIsFull() then
    operateType = BattleEnum.Operation.ENUM_ITEM
  elseif BattleUtils.IsWatchingBattle() then
    local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    local observeMode = 1
    if playerSettings then
      observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
    end
    local runtimeDateObservingInfo = _G.BattleManager.battleRuntimeData.observingInfo
    if 1 == observeMode then
      operateType = BattleEnum.Operation.ENUM_NONE
    end
  elseif self.battleManager.debugEnv and self.battleManager.debugEnv.GmChangeMagicPet then
    operateType = BattleEnum.Operation.ENUM_CHANGE
  elseif self.battleManager.battleRuntimeData.backOperateType ~= BattleEnum.Operation.ENUM_NONE then
    if self.battleManager.battleRuntimeData.backOperateType == BattleEnum.Operation.ENUM_CATCH then
      local hasBall = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_PET_BALL)
      operateType = hasBall and self.battleManager.battleRuntimeData.backOperateType or BattleEnum.Operation.ENUM_SKILL
    else
      operateType = self.battleManager.battleRuntimeData.backOperateType
    end
  else
    self:SafeDelayFrames("d_UpdateEnergy", 1.0, function()
      _G.BattleEventCenter:Dispatch(BattleEvent.UI_UPDATE_ENERGY)
    end)
  end
  return operateType
end

function BattleRoundSelectAction:HidePopup()
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, nil, self)
end

function BattleRoundSelectAction:GetNextPetIndex(curIndex)
  curIndex = curIndex or self.index
  if self.operationPets then
    local index = curIndex + 1
    if index <= 0 then
      index = 1
    end
    if index > #self.operationPets then
      index = 1
    end
    return self.operationPets[index], index
  end
end

function BattleRoundSelectAction:GetNextNoOpPet()
  local cur = self.index
  local restPets = self.CurrentPlayer.team.RestPets
  if self.CurrentPlayer.opState ~= BattleEnum.Operation.ENUM_NONE then
    return
  end
  for i = 1, #self.operationPets do
    cur = cur + 1
    if cur <= 0 then
      cur = 1
    end
    if cur > #self.operationPets then
      cur = 1
    end
    local pet = self.operationPets[cur]
    Log.DebugFormat("GetNextNoOpPet cur %s, index %s, petName %s, opState %s, pos %s, operationPets %s, RestPets %s", cur, self.index, pet.card.name, pet.opState, pet.card.pos, #self.operationPets, #restPets)
    if pet.opState == BattleEnum.Operation.ENUM_NONE and restPets[pet.card.pos] ~= pet then
      return pet, cur
    elseif pet.teamEnm == BattleEnum.Team.ENUM_TEAM and BattleUtils.IsWorldLeaderFight() then
      return pet, cur
    end
  end
end

function BattleRoundSelectAction:CheckChangePet()
  local restPets = self.CurrentPlayer.team.RestPets
  for _, v in ipairs(self.operationPets) do
    if v.opState == BattleEnum.Operation.ENUM_CHANGE and not restPets[v.card.pos] and self:SetChangePet(v.opParam) then
      self.changeToBattlePet = v.opParam.battle_pet_id
    end
  end
end

function BattleRoundSelectAction:StartSelect(noMoveView)
  local data = self.battleManager.battleRuntimeData
  self.SelectFsm:SetProperty("CurrentSkill", nil)
  self.CurrentPet, self.index = self:GetNextPetIndex()
  if not noMoveView and self.battleManager.vBattleField.battleCameraManager then
    if BattleUtils.IsFinalBattleP1() and self.CurrentPet and self.operationPets and #self.operationPets < 3 then
      self.battleManager.vBattleField.battleCameraManager:PetSelectCameraUpdate(self.CurrentPet.card.posInField)
    else
      self.battleManager.vBattleField.battleCameraManager:PetSelectCameraUpdate(self.index)
    end
  end
  if not self.CurrentPet then
    Log.Error("\230\178\161\230\156\137\229\143\175\228\187\165\233\128\137\230\139\169\230\138\128\232\131\189\231\154\132\229\174\160\231\137\169")
    return
  end
  Log.Debug(self.CurrentPet.card.name, self.CurrentPet.card.guid, self.index, "BattleRoundSelectAction:StartSelect")
  self.SelectFsm:SetProperty("CurrentPet", self.CurrentPet)
  _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, self.CurrentPet, true)
end

function BattleRoundSelectAction:UndoSelect()
  if not self.battleManager then
    return
  end
  local nextPet, _ = self:GetNextPetIndex()
  if nextPet then
    if nextPet.opState == BattleEnum.Operation.ENUM_SKILL then
      local battleNetManager = self.battleManager.battleNetManager
      local req = _G.ProtoMessage:newZoneBattleCmdPopbackReq()
      req.pet_id = nextPet.guid
      battleNetManager:SendBattleCmdPopbackReq(req, self, self.UndoBattleSelectRsp)
    else
      self:StartSelect()
      self:SendFsmEvent()
    end
  end
  if self.battleSelectMarkerMgr then
    self.battleSelectMarkerMgr:HideAllSelectMarkers()
    self.battleSelectMarkerMgr:ClearSelection()
    self.battleSelectMarkerMgr:HideTipTime()
    self.battleSelectMarkerMgr:HideClickTipUI()
  end
end

function BattleRoundSelectAction:UndoBattleSelectRsp(rsp)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(rsp)
  if not rsp or 0 ~= rsp.ret_info.ret_code then
    return
  end
  if rsp.req and rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET then
    local data = rsp.req.change_pet
    if data then
      local battlePet = _G.BattleManager.battlePawnManager:GetPetByGuid(data.battle_pet_id)
      if battlePet then
        local restPet = battlePet.team.RestPets[battlePet.card.pos]
        battlePet.team:ResumeRest(battlePet.card.pos, true)
        if restPet == self.CurrentPet then
          _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, restPet, true)
          restPet:InitOp()
        end
        self:SendFsmEvent()
      end
    end
  else
    self:UpdateUIInfo(rsp.sync_data)
    local nextPet, _ = self:GetNextPetIndex()
    if nextPet and nextPet.opState == BattleEnum.Operation.ENUM_SKILL then
      nextPet:InitOp()
      self:StartSelect()
      self:SendFsmEvent()
    end
  end
end

function BattleRoundSelectAction:UpdatePlayerInfo(rsp)
  local magicOpInfo = rsp.magic_op_info
  if magicOpInfo and self.CurrentPlayer then
    local playerUin = self.CurrentPlayer and self.CurrentPlayer.guid
    local rspRound = rsp and rsp.round
    local roleInfo = {}
    roleInfo.magic_op_info = magicOpInfo
    local battleInfoManager = _G.BattleManager.battleInfoManager
    battleInfoManager:AddBattleRoleInfoDataFromPushPop(playerUin, roleInfo, rspRound)
    self.CurrentPlayer:UpdateMagicOpInfo(magicOpInfo)
  end
end

function BattleRoundSelectAction:UpdateUIInfo(sync_data)
  if not sync_data then
    return
  end
  local shouldDelayHp = false
  local ignoreHpPetIds
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  if playerSkillPhase ~= BattleEnum.PlayerSkillPhase.NoSkill and activedPlayerSkillInfo then
    local effectType = activedPlayerSkillInfo:GetEffectType()
    shouldDelayHp = effectType == Enum.EffectType.ET_BOSS_BLOOD
    if shouldDelayHp and activedPlayerSkillInfo.OnClickPet and activedPlayerSkillInfo.OnClickPet.guid then
      ignoreHpPetIds = {
        activedPlayerSkillInfo.OnClickPet.guid
      }
    end
  end
  if sync_data.pet_sync_info then
    for _, v in ipairs(sync_data.pet_sync_info) do
      local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(v.pet_id)
      if pet then
        pet:SetEnergy(v.energy_result)
        pet.health:SetValue(v.hp_result)
      end
    end
  end
  if sync_data.role_sync_info then
    for _, v in ipairs(sync_data.role_sync_info) do
      local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(v.role_uin)
      if player and v.hp_result then
        local hp_result = v.hp_result
        if hp_result < player.roleInfo.base.hp then
          local hp_change = hp_result - player.roleInfo.base.hp
          self:ProcessRoleHpStart(player, hp_result, hp_change, false)
        end
        player.roleInfo.base.hp = hp_result
      end
    end
  end
  if sync_data.pet_info then
    for _, v in ipairs(sync_data.pet_info) do
      local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(v.battle_inside_pet_info.pet_id)
      if pet then
        pet:SetEnergy(v.battle_common_pet_info.energy)
        if v.battle_inside_pet_info.skill_round_data then
          pet.skillComponent:UpdateSkillDataByID(v.battle_inside_pet_info.skill_round_data, UsingSkillID)
        end
      end
    end
  end
  if sync_data.item_sync_info then
    local team = _G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
    local player = team.player
    for _, info in pairs(sync_data.item_sync_info) do
      player:RefreshMagicItem(info)
    end
  end
  BattleUtils.DirectUpdateUI(ignoreHpPetIds and {ignoreHp = ignoreHpPetIds} or nil)
end

function BattleRoundSelectAction:ProcessRoleHpEnd(player)
  if player and player.model then
    if BattleUtils.HasUI("BattleRoleHpDefeatedTipPanel") then
      _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_ROLE_HP_DEFEAT_TIP_END)
    else
      _G.NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel)
    end
  end
end

function BattleRoundSelectAction:ProcessRoleHpStart(player, hp_result, hp_change, isShowLetter, pvp_result, pvp_change)
  _G.BattleManager.battleRuntimeData.isWaitingRoleHP = true
  local asyncData = {
    player = player,
    isLast = false,
    hp_result = hp_result,
    hp_change = hp_change,
    isShowLetter = isShowLetter,
    pvp_result = pvp_result,
    pvp_change = pvp_change
  }
  _G.NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenRoleHpDefeatedTipPanel)
  if self.ProcessRoleHpHandler then
    _G.DelayManager:CancelDelayById(self.ProcessRoleHpHandler)
  end
  self.ProcessRoleHpHandler = _G.DelayManager:DelaySeconds(BattleConst.Show.PveRoleHpShowTime, self.ProcessRoleHpEnd, self, player)
end

function BattleRoundSelectAction:SetEnemyPetHighlight(needHighlight)
  if not _G.BattleManager.battlePawnManager then
    return
  end
  local enemyPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  for _, enemyPet in pairs(enemyPets) do
    enemyPet:SetHighlight(needHighlight)
  end
end

function BattleRoundSelectAction:OnFinish()
  if BattleManager.vBattleField.battleCameraManager then
    BattleManager.vBattleField.battleCameraManager.KontrolEnabled = false
  end
  self.fsm:Resume()
  self.SelectFsm:Stop()
  self.battleSelectMarkerMgr:HideClickTipUI()
  self.battleSelectMarkerMgr:HideAllSelectMarkers()
  self.battleSelectMarkerMgr:HideTipTime()
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_CLEAR_PRESELECT_POPUPS)
  _G.BattleEventCenter:UnBind(self)
  if not BattleManager.isInBattle then
    return
  end
  if not self.CurrentPlayer then
    Log.Error("BattleRoundSelectAction:OnFinish() CurrentPlayer is nil")
    return
  end
  if BattleUtils.IsWorldLeaderFight() then
    self.CurrentPlayer:ClearSkillList()
    self.CurrentPlayer:ClearCalCuLusSkillList()
    BattleManager.battleRuntimeData:SetOnSelectWorldLeaderSkill(false)
  end
  if self.fsm:GetNextStateName() ~= BattleEnum.StateNames.StartInstant then
    self.CurrentPlayer.team:ResumeRest()
  end
  local currentPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  if currentPets then
    for _, v in ipairs(currentPets) do
      v:ShowActiveState(false)
      v:SetHighlight(false)
      v:SetLookAt(nil)
      v:SetClickable(false)
      v:ShowOperation(false)
    end
  end
  if self.CurrentEnemyPet then
    for _, v in ipairs(self.CurrentEnemyPet) do
      v:SetLookAt(nil)
      v:ShowOperation(false)
      v:SetHighlight(false)
    end
  end
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  if playerSkillPhase ~= BattleEnum.PlayerSkillPhase.NoSkill then
    self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
    if playerSkillPhase == BattleEnum.PlayerSkillPhase.WaitingToPerform then
      activedPlayerSkillInfo:CancelLinkEffect()
    end
  end
  self.CurrentPlayer:StopAll(self.SelectFsm:GetProperty("WillChangePet", false), self.SelectFsm:GetProperty("WillCatchPet", false))
  if BattleManager.vBattleField.battleFieldActor then
    BattleManager.vBattleField.battleFieldActor:ToggleDarkScene(false)
  end
  self.battleSelectMarkerMgr.ClearSelection()
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:ChangeBattleOperateEnable(false)
  end
  if self.RelaxTimer and self.RelaxTimerHandler then
    self.RelaxTimer:Cancel(self.RelaxTimerHandler)
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetBattleHidePanelState, false)
end

function BattleRoundSelectAction:OnCmdPushRsp(rsp)
  Log.Dump(rsp, nil, "BattleRoundSelectAction:OnCmdPushRsp")
  if rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.BattleErr.ERR_BATTLE_BLOOD_NOT_MATCH then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText["Error_Code_" .. rsp.ret_info.ret_code])
  end
  Log.Debug("zgx No op OnCmdPushRsp")
  self:UpdatePlayerInfo(rsp)
  self:UpdateUIInfo(rsp.sync_data)
  self:UpdateChiefInfo(rsp)
  if rsp.req and 0 == rsp.ret_info.ret_code then
    if rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL or rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_IDLE then
      local OpPet
      if rsp.req.cast_skill and rsp.req.cast_skill.caster_pet_id > 0 then
        OpPet = self.battleManager.battlePawnManager:GetPetByGuid(rsp.req.cast_skill.caster_pet_id)
      elseif rsp.req.idle and rsp.req.idle.caster_pet_id > 0 then
        OpPet = self.battleManager.battlePawnManager:GetPetByGuid(rsp.req.idle.caster_pet_id)
      end
      OpPet = OpPet or self.CurrentPet
      OpPet:SetOp(BattleEnum.Operation.ENUM_SKILL)
      if self.battleManager.battleRuntimeData.subBattleType == BattleEnum.SubBattleType.Single and BattleUtils.IsPve() and rsp.has_npc_delay then
        self:ChangeToWaitOther()
      end
      local nextPet, nextIndex = self:GetNextNoOpPet()
      if nextPet and nextPet ~= OpPet then
        if self.CurrentPlayer then
          self.CurrentPlayer:SetIsCanUseSkill(true)
        end
        self.index = nextIndex - 1
        self:StartSelect()
        self.battleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_SKILL)
        self.curEvent = BattleEvent.RoundEvent.EnterSkill
        self:SendFsmEvent()
      end
    elseif rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET then
      if self.battleManager.battleRuntimeData.subBattleType == BattleEnum.SubBattleType.Single and BattleUtils.IsPve() and rsp.has_npc_delay then
        self:ChangeToWaitOther()
      end
      if self:SetChangePet(rsp.req.change_pet) then
        self.changeToBattlePet = rsp.req.change_pet.battle_pet_id
      end
    elseif rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_ROLE_MAGIC then
      local MagicInfo = rsp.magic_op_info
      local playerSkillId = MagicInfo and MagicInfo.player_skill_id
      local SkillConf = _G.SkillUtils.GetSkillConf(MagicInfo.player_skill_id)
      if SkillConf.skill_result and #SkillConf.skill_result > 0 then
        local EffectConf = _G.DataConfigManager:GetEffectConf(SkillConf.skill_result[1].effect_id)
        if EffectConf then
          local OpPet = self.battleManager.battlePawnManager:GetPetByGuid(MagicInfo.pet_id)
          self.PlayerSkillData = {EffectConf = EffectConf, OpPet = OpPet}
          if BattleUtils.IsFinalBattleP1() then
            if OpPet.opState == BattleEnum.Operation.ENUM_NONE then
              if self.operationPets then
                for i, v in ipairs(self.operationPets) do
                  if v.guid == OpPet.guid then
                    self.index = OpPet.card.pos - 1
                    break
                  end
                end
              end
            elseif self.CurrentPet then
              self.index = self.CurrentPet.card.pos - 1
            end
          else
            self.index = OpPet.card.pos - 1
            OpPet:InitOp()
          end
          _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_USE_PLAYERSKILL_SUCCESS)
          _G.BattleManager.battleRuntimeData.PlayerSkillManager:SetIsPlayerSkillSuccess(true)
          if EffectConf.effect_order == Enum.EffectType.ET_ROLE_CHANGE_SKILL or EffectConf.effect_order == Enum.EffectType.ET_PURIFY or EffectConf.effect_order == Enum.EffectType.ET_BOSS_BLOOD then
            self:RefreshByServer(rsp, OpPet)
          end
        end
      end
    elseif rsp.req.req_type == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CATCH_PET then
      self.CurrentPlayer:SetOp(BattleEnum.Operation.ENUM_CATCH)
      if self.battleManager.battleRuntimeData.subBattleType == BattleEnum.SubBattleType.Single and BattleUtils.IsPve() and rsp.has_npc_delay then
        self:ChangeToWaitOther()
      end
    end
  end
end

function BattleRoundSelectAction:OnCmdPopRsp(rsp)
  Log.Dump(rsp, nil, "BattleRoundSelectAction:OnCmdPopRsp")
  local retInfo = rsp and rsp.ret_info
  local retCode = retInfo and retInfo.ret_code
  if not retCode or 0 ~= retCode then
    return
  end
  local req = rsp and rsp.req
  local reqType = req and req.req_type
  local currentPlayer = self.CurrentPlayer
  local currentPet = self.CurrentPet
  local battleManager = self.battleManager
  local battlePawnManager = battleManager and battleManager.battlePawnManager
  local playerSkill = currentPlayer and currentPlayer:GetPlayerSkillInfo()
  if reqType == _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_ROLE_MAGIC then
    local magicInfo = req and req.magic_op
    local targetPetId = magicInfo and magicInfo.target_pet_id
    local opPet = battlePawnManager and battlePawnManager:GetPetByGuid(targetPetId)
    if opPet then
      opPet:InitOp()
    end
    local EffectType = playerSkill and playerSkill:GetEffectType()
    local battlePet
    if EffectType == Enum.EffectType.ET_ROLE_CHANGE_SKILL or EffectType == Enum.EffectType.ET_ADD_BUFF_BY_BLOOD or EffectType == Enum.EffectType.ET_BOSS_BLOOD then
      local sync_data = rsp and rsp.sync_data
      local battleInfoManager = _G.BattleManager.battleInfoManager
      local rspRound = rsp and rsp.round
      if opPet then
        battlePet = opPet
      else
        battlePet = currentPet
      end
      local battlePetId = battlePet and battlePet.guid
      local petInfoList = sync_data and sync_data.pet_info or {}
      for i, petInfo in ipairs(petInfoList) do
        local insideInfo = petInfo and petInfo.battle_inside_pet_info
        local petId = insideInfo and insideInfo.pet_id
        if petId and petId == battlePetId then
          battleInfoManager:AddBattlePetInfoDataFromPushPop(petId, petInfo, rspRound)
          battlePet:OverwriteByServer(petInfo)
          battlePet:RefreshByServer()
        end
      end
      self:UpdateUIInfo(sync_data)
      _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, currentPet, true)
    elseif EffectType == Enum.EffectType.ET_ROLE_CHANGE_PET then
      local upPetId = magicInfo and magicInfo.up_pet_id
      opPet = battlePawnManager and battlePawnManager:GetPetByGuid(upPetId)
      if opPet then
        opPet:InitOp()
      end
      if playerSkill then
        playerSkill:Cancel()
        local ClickPet, UpPet = playerSkill:GetClickPetAndUpPet()
        battlePet = UpPet and UpPet.BattlePet
      end
      _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, currentPet, true)
    end
    do
      local playerUin = currentPlayer and currentPlayer.guid
      local rspRound = rsp and rsp.round
      local roleInfo = {}
      local magicOpInfo = _G.ProtoMessage:newBattleRoleMagicOpInfo()
      roleInfo.magic_op_info = magicOpInfo
      local battleInfoManager = _G.BattleManager.battleInfoManager
      battleInfoManager:AddBattleRoleInfoDataFromPushPop(playerUin, roleInfo, rspRound)
    end
    if playerSkill then
      playerSkill:CancelLinkEffect()
    end
    if currentPlayer then
      currentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.NoSkill)
      currentPlayer:ClearMagicOpInfo()
    end
    local vBattleField = battleManager and battleManager.vBattleField
    local battleCameraManager = vBattleField and vBattleField.battleCameraManager
    if battleCameraManager then
      battleCameraManager:ChangeByOperateType(BattleEnum.Operation.ENUM_ITEM)
    end
  end
end

function BattleRoundSelectAction:RefreshByServer(rsp, OpPet)
  if not rsp then
    return
  end
  local sync_data = rsp.sync_data
  if sync_data and sync_data.pet_info then
    local PetInfo = sync_data.pet_info
    local rspRound = rsp and rsp.round
    local battleInfoManager = _G.BattleManager.battleInfoManager
    for i, Pet in ipairs(PetInfo) do
      if OpPet then
        local petId = OpPet and OpPet.guid
        battleInfoManager:AddBattlePetInfoDataFromPushPop(petId, Pet, rspRound)
        OpPet:OverwriteByServer(Pet)
        OpPet:RefreshByServer()
        break
      else
        Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\149\176\230\141\174")
      end
    end
  end
end

function BattleRoundSelectAction:UpdateChiefInfo(rsp)
  if BattleUtils.IsWorldLeaderFight() then
    if 0 ~= rsp.ret_info.ret_code or rsp.ignored then
      self.CurrentPlayer:RemoveCalCuLusSkillByWlReqId(rsp.wl_req_id)
    else
      self.CurrentPlayer:CalCuLusSkillSucceedUpdateSkillList(rsp.wl_req_id)
    end
    if self.CurrentPlayer:GetContinuousSkillSucceed() then
      self.CurrentPet.health:SetValue(self.CurrentPet.health:GetOldHp())
      self.CurrentPlayer:SetContinuousSkillSucceed(false)
    end
    self:UpdateReduceSelfHp(rsp.sync_data)
    self:UpdateGatherSkill(rsp)
    BattleUtils.DirectUpdateUI()
  end
end

function BattleRoundSelectAction:UpdateGatherSkill(rsp)
  local PreGatherSkillID
  local hasSendGatherInfo = false
  if rsp.sync_data and rsp.sync_data.pet_info then
    for _, petInfo in pairs(rsp.sync_data.pet_info) do
      PreGatherSkillID = petInfo.battle_inside_pet_info.charging_skill_id
      if PreGatherSkillID and 0 ~= PreGatherSkillID then
        _G.BattleEventCenter:Dispatch(BattleEvent.ChangeGatherState, true, PreGatherSkillID, petInfo.battle_inside_pet_info.pet_id)
        hasSendGatherInfo = true
        break
      else
        hasSendGatherInfo = false
        break
      end
    end
  else
    hasSendGatherInfo = nil
  end
  if false == hasSendGatherInfo or nil == hasSendGatherInfo then
    local UsingSkillID
    if rsp.req then
      UsingSkillID = rsp.req.cast_skill and rsp.req.cast_skill.skill_id
    end
    if not UsingSkillID then
      _G.BattleEventCenter:Dispatch(BattleEvent.ChangeGatherState, hasSendGatherInfo, 0, nil)
    elseif UsingSkillID and 0 ~= UsingSkillID then
      _G.BattleEventCenter:Dispatch(BattleEvent.ChangeGatherState, hasSendGatherInfo, UsingSkillID, nil)
    end
  end
end

function BattleRoundSelectAction:UpdateReduceSelfHp(sync_data)
  if sync_data and sync_data.pet_info then
    for _, v in ipairs(sync_data.pet_info) do
      local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(v.battle_inside_pet_info.pet_id)
      if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
        local hp = PetUtils.GetHP(v.battle_inside_pet_info)
        pet.health:SetValue(hp)
      end
    end
  end
end

function BattleRoundSelectAction:PlayPlayerSkillSuccess()
  local PlayerSkillData = self.PlayerSkillData
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_USE_PLAYERSKILL_UPDATE, PlayerSkillData)
  self:PushResSendFsmEvent()
  if PlayerSkillData and PlayerSkillData.EffectConf.effect_order == Enum.EffectType.ET_ROLE_CHANGE_PET then
    local PlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillInfo()
    local ClickPet, UpPet = PlayerSkillInfo:GetClickPetAndUpPet()
    _G.BattleEventCenter:Dispatch(BattleEvent.UPDATE_DATA, UpPet.BattlePet, true)
  end
end

function BattleRoundSelectAction:PushResSendFsmEvent()
  local nextPet, nextIndex = self:GetNextNoOpPet()
  if nextPet then
    self.index = nextIndex - 1
    Log.Debug(self.index, "BattleRoundSelectAction:PushResSendFsmEvent")
    self.curEvent = BattleEvent.RoundEvent.EnterSkill
    _G.BattleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_SKILL)
    self:SendFsmEvent()
    self:StartSelect()
  end
end

function BattleRoundSelectAction:SetChangePet(data)
  local restPet = self.battleManager.battlePawnManager:GetPetByGuid(data.rest_pet_id)
  local restPets = self.CurrentPlayer.team.RestPets
  if not restPet then
    for i = 1, self.battleManager.battleRuntimeData.playerPetNumber do
      if restPets[i] and restPets[i].guid == data.rest_pet_id then
        restPet = restPets[i]
      end
    end
  end
  if not restPet then
    Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176\228\184\139\229\156\186\231\154\132\229\174\160\231\137\169\239\188\129\239\188\129 ", data.rest_pet_id)
    return
  end
  Log.Debug("zgx No op SetChangePet", restPet.card.name, restPet.guid, restPet.card.pos)
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  if playerSkillPhase == BattleEnum.PlayerSkillPhase.NoSkill then
    restPet:SetOp(BattleEnum.Operation.ENUM_CHANGE)
  else
    restPet:SetOp(BattleEnum.Operation.ENUM_NONE)
  end
  restPet:SetOpParam(data)
  local CurrentTeamPets = self.battleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, v in ipairs(CurrentTeamPets) do
    Log.Debug(v.card.pos, restPet.card.pos, v.opState, "BattleRoundSelectAction:SetChangePet")
    if v.card.pos ~= restPet.card.pos and v.opState == BattleEnum.Operation.ENUM_NONE then
      self:ChangeOnStagePet(restPets, restPet, data)
      return true
    end
  end
end

function BattleRoundSelectAction:ChangeOnStagePet(restPets, restPet, data)
  Log.Debug("zgx No op ChangeOnStagePet", restPet.card.name, restPet.guid, restPet.card.pos)
  if not restPets[restPet.card.pos] then
    restPets[restPet.card.pos] = restPet
    if restPet.model then
      restPet:ChangeBuffVisibility(false)
      restPet:HidePet()
    end
  end
  if restPet.card.guid ~= data.battle_pet_id then
    local fieldPet = self.CurrentPlayer.team.pets[restPet.card.pos]
    if fieldPet ~= restPet then
      fieldPet.card:SetInBattleField(false)
      fieldPet:Destroy()
    end
    local supplyInfo = _G.ProtoMessage:newBattleSupplyPetInfo()
    supplyInfo.pet_id = data.battle_pet_id
    supplyInfo.pet_pos = restPet.card.pos
    supplyInfo.posInField = restPet.card.posInField
    local battlePet = self.CurrentPlayer.deck:SummonPetOnce(BattleEnum.Team.ENUM_TEAM, self.CurrentPlayer.team, {supplyInfo})[1]
    battlePet:SetOp(BattleEnum.Operation.ENUM_CHANGE)
    battlePet:SetOpParam(data)
    restPet.card:SetInBattleField(false)
  end
end

function BattleRoundSelectAction:PawnPetOver(pet)
  if pet.player == self.CurrentPlayer then
    local fieldPet = self.CurrentPlayer.team.pets[pet.card.pos]
    local restPet = self.CurrentPlayer.team.RestPets[pet.card.pos]
    if pet == fieldPet then
      if restPet then
        pet.model:SetActorScale3D(UE4.FVector(1, 1, 1))
        if pet.transparentSkill then
          pet:HidePet()
          pet.transparentSkill:SetEventCallback("Start", self.TransparentSkillStart, self)
          pet:ShowTransparent(true)
        else
          pet:ShowPet(false)
        end
        pet:ChangeBuffVisibility(false)
      end
      if pet.guid == self.changeToBattlePet then
        self.changeToBattlePet = nil
        self:PushResSendFsmEvent()
      end
    else
      pet:Destroy()
    end
  end
end

function BattleRoundSelectAction:TransparentSkillStart(skillPlayer)
  if skillPlayer and self.CurrentPlayer then
    if skillPlayer.Caster then
      for idx, v in pairs(self.CurrentPlayer.team.pets) do
        if v.model == skillPlayer.Caster then
          self:SafeDelayFrames("d_ShowPet", 2, v.ShowPet, v, false)
          if skillPlayer.Current then
            local skill = skillPlayer.Current
            local endTime = math.max(0.001, skill:GetLength() - 0.2)
            self:SafeDelaySeconds("d_StopTransparent", endTime, function()
              if skill == skillPlayer.Current then
                skillPlayer.Current:SetPlayRate(0)
              end
            end)
          end
        end
      end
    end
    skillPlayer:SetEventCallback("Start")
  end
end

function BattleRoundSelectAction:RecoverPlayerSkill()
  self.CurrentPlayer:SetPlayerSkill(BattleEnum.PlayerSkillPhase.WaitingToPerform)
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  activedPlayerSkillInfo:PlayLinkEffect(self.CurrentPet)
  _G.BattleManager.battleRuntimeData.PlayerSkillManager:SetIsPlayerSkillSuccess(true)
end

function BattleRoundSelectAction:SetPlayerSkillItemData(itemData)
  local playerSkillPhase, activedPlayerSkillInfo = self.CurrentPlayer:GetPlayerSkillPhase()
  activedPlayerSkillInfo:SetData(itemData)
end

function BattleRoundSelectAction:ChangeOperateType(operateType, isChecked)
  Log.Debug("BattleRoundSelectAction:ChangeOperateType")
  if not isChecked then
    return
  end
  if self.battleSelectMarkerMgr and _G.BattleManager.battleRuntimeData.subBattleType ~= BattleEnum.SubBattleType.Single then
    self.battleSelectMarkerMgr:HideAllSelectMarkers()
    self.battleSelectMarkerMgr:ClearSelection()
    self.battleSelectMarkerMgr:HideTipTime()
    self.battleSelectMarkerMgr:HideClickTipUI()
  end
  local data = self.battleManager.battleRuntimeData
  if data.operateType ~= operateType then
    local curOperateType = data.operateType
    data.operateType = operateType
    self.battleSelectMarkerMgr:HideClickTipUI()
    self.battleSelectMarkerMgr:HideAllSelectMarkers()
    self.battleSelectMarkerMgr:HideTipTime()
    self:SetEnemyPetHighlight(false)
    if self.CurrentPet and self.CurrentEnemyPet and self.CurrentEnemyPet[1] then
      self.CurrentPet:SetLookAt(self.CurrentEnemyPet[1].model)
    end
    if BattleConst.PlayerTurnAnim[curOperateType] then
      local animName = BattleConst.PlayerTurnAnim[curOperateType][operateType]
      if animName then
        Log.Debug("Turn", animName, BattleConst.OperationSelectSettings.ChangeOperateBlendTime)
      end
    else
      local animName = BattleConst.PlayerFinalAnim[operateType]
      if animName then
        Log.Debug("Final", animName, BattleConst.OperationSelectSettings.ChangeOperateBlendTime)
        if self.CurrentPlayer and self.CurrentPlayer.model then
          self.CurrentPlayer.model:PlayAnimByName(animName, 1, -1, BattleConst.OperationSelectSettings.ChangeOperateBlendTime, BattleConst.OperationSelectSettings.ChangeOperateBlendTime, -1, -1)
        end
      end
    end
  elseif data.backOperateType ~= BattleEnum.Operation.ENUM_NONE then
    local animName = BattleConst.PlayerFinalAnim[data.backOperateType]
    if animName and self.CurrentPlayer and self.CurrentPlayer.model then
      self.CurrentPlayer.model:PlayAnimByName(animName, 1, -1, 0.0, 0.0, -1, -1)
    end
    data.backOperateType = BattleEnum.Operation.ENUM_NONE
  else
    Log.Debug("BattleRoundSelectAction: OperateType\228\184\128\232\135\180")
  end
  self.curEvent = self:GetEventFromOperate(operateType)
  self:SendFsmEvent()
end

function BattleRoundSelectAction:ClearAllSkill(index)
  if not BattleUtils.IsWorldLeaderFight() then
    return
  end
  if index then
    self.CurrentPlayer:ClearSkillListByIndex(index)
  else
    local CurrentSkillNum = self.CurrentPlayer:GetSkillList()
    if #CurrentSkillNum > 0 then
      self.CurrentPlayer:ClearSkillList()
      self.CurrentPlayer:ClearCalCuLusSkillList()
      local req = BattleNetManager:BuildBattleCmdPushbackReq()
      req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CAST_SKILL
      _G.BattleNetManager:SendBattleCmdPushbackReq(req, self, self.OnPushbackSent)
    end
  end
end

function BattleRoundSelectAction:OnPushbackSent(rsp)
  if self.battleManager then
    _G.BattleEventCenter:Dispatch(BattleEvent.PUSHBACK_CMD_SENT, rsp)
  end
  self:ClearPushbackReq()
end

function BattleRoundSelectAction:ClearPushbackReq()
  if self:IsValid() then
    self.fsm:SetProperty("CurrentPushbackReq", nil)
  end
end

function BattleRoundSelectAction:SendFsmEvent()
  if self.curEvent then
    self.SelectFsm:SendEvent(self.curEvent)
    self.SelectFsm:SetProperty("StateEvent", self.curEvent)
  end
end

function BattleRoundSelectAction:OnExit()
  self.SelectFsm:SetProperty("CurrentSelectGuid", 0)
  BattleUtils.CheerPetsStopRandomMove()
end

function BattleRoundSelectAction:GetEventFromOperate(Operate)
  if Operate == BattleEnum.Operation.ENUM_SKILL then
    return BattleEvent.RoundEvent.EnterSkill
  elseif Operate == BattleEnum.Operation.ENUM_CHANGE then
    return BattleEvent.RoundEvent.EnterSwap
  elseif Operate == BattleEnum.Operation.ENUM_CATCH then
    return BattleEvent.RoundEvent.EnterCatch
  elseif Operate == BattleEnum.Operation.ENUM_ITEM then
    return BattleEvent.RoundEvent.EnterItem
  elseif Operate == BattleEnum.Operation.ENUM_ESCAPE then
    return BattleEvent.RoundEvent.EnterEscape
  elseif Operate == BattleEnum.Operation.ENUM_SURRENDER then
    return BattleEvent.RoundEvent.EnterSurrender
  elseif Operate == BattleEnum.Operation.ENUM_STEPAWAY then
    return BattleEvent.RoundEvent.EnterStepAway
  elseif Operate == BattleEnum.Operation.ENUM_GIVEUP then
    return BattleEvent.RoundEvent.EnterGiveUp
  else
    return BattleEvent.RoundEvent.EnterNone
  end
end

function BattleRoundSelectAction:GetStateNameFromOperate(Operate)
  if Operate == BattleEnum.Operation.ENUM_SKILL then
    return BattleEnum.RoundStateNames.SkillState
  elseif Operate == BattleEnum.Operation.ENUM_CHANGE then
    return BattleEnum.RoundStateNames.SwapState
  elseif Operate == BattleEnum.Operation.ENUM_CATCH then
    return BattleEnum.RoundStateNames.CatchState
  elseif Operate == BattleEnum.Operation.ENUM_ITEM then
    return BattleEnum.RoundStateNames.ItemState
  elseif Operate == BattleEnum.Operation.ENUM_ESCAPE then
    return BattleEnum.RoundStateNames.EscapeState
  elseif Operate == BattleEnum.Operation.ENUM_SURRENDER then
    return BattleEnum.RoundStateNames.SurrenderState
  else
    return BattleEnum.RoundStateNames.NoneState
  end
end

function BattleRoundSelectAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:ChangeOperateType(...)
    return true
  elseif eventName == BattleEvent.PUSHBACK_CMD_SENT then
    self:OnCmdPushRsp(...)
    return true
  elseif eventName == BattleEvent.POPBACK_CMD_SENT then
    self:OnCmdPopRsp(...)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:PawnPetOver(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PLAY_PLAYERSKILL_SUCCESS then
    self:PlayPlayerSkillSuccess()
    return true
  elseif eventName == BattleEvent.BATTLE_RECOVER_PLAYERSKILL then
    self:RecoverPlayerSkill()
    return true
  elseif eventName == BattleEvent.BATTLE_SET_PLAYERSKILL then
    self:SetPlayerSkillItemData(...)
    return true
  elseif eventName == BattleEvent.Clear_SkillList then
    self:ClearAllSkill()
    return true
  elseif eventName == BattleEvent.SHOW_MAIN_WHEN_SKILLOVER then
    if self.battleManager then
      self.battleManager:ChangeOperateMode(self.battleManager.battleRuntimeData.operateType)
    end
    return true
  elseif eventName == BattleEvent.LEAVE_ESCAPE_STATE then
    self:RefreshActionData()
    return true
  elseif eventName == BattleEvent.ReconnetBattle_RoundStrart then
    if self.CurrentPlayer then
      self.CurrentPlayer:SetIsCanUseSkill(true)
    end
  elseif eventName == BattleEvent.UPDATE_UI_ON_ROUND_SELECT then
    self:UpdateUIInfo(...)
  end
end

return BattleRoundSelectAction

local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local Base = BattleActionBase
local skillPath = "/Game/ArtRes/Effects/G6Skill/Jineng/A1/G6_A1_Battle_Callout"
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger_Declare")
local BattleFBP2SummerAction = Base:Extend("BattleFBP2SummerAction")
FsmUtils.MergeMembers(Base, BattleFBP2SummerAction, {})

function BattleFBP2SummerAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
  self.timeout = self.timeoutValue
  self.PetArray = {}
  self.isFSMPause = false
end

function BattleFBP2SummerAction:OnEnter()
  if not BattleUtils.IsFinalBattleP2() then
    self:Finish()
    return
  end
  self.IsSummonPet = false
  self.player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  NRCModeManager:DoCmd(BattleUIModuleCmd.MainHideAll, false)
  NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
  BattleSkillManager:PreLoadSingleRes(skillPath, true)
  self:ShowDialog()
end

function BattleFBP2SummerAction:ShowDialog()
  if self.player and self.player.model then
    self.isFSMPause = true
    self.fsm:Pause()
    local dialogId = DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_summon_dialogue_ID").num
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.StartDialogueInBattle, self.player, dialogId, self, self.LoadSkill)
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.OverridePropertiesInBattleFsm, {ReturnCamera = false})
  else
    self:LoadSkill()
  end
end

function BattleFBP2SummerAction:LoadSkill()
  _G.BattleEventCenter:Bind(self, BattleEvent.OnFinalBattleSummer, BattleEvent.PET_SPAWNED, BattleEvent.OnSummerResLoaded)
  BattleSkillManager:PreLoadSingleRes(skillPath, true, self, self.OnSkillLoad)
end

function BattleFBP2SummerAction:OnSkillLoad(isLoadSucceed, resPath)
  if not (isLoadSucceed and self.player) or not self.player.model then
    Log.Error("BattleFBP2SummerAction:OnSkillLoad Skill Object not found %s", resPath)
    self:Finish()
    return
  end
  self.RocoSkill = self.player.model.RocoSkill
  local CastParam = CastSkillObject.Create()
  CastParam.ResID = resPath
  CastParam:SetCaster(self.player.model)
  CastParam:SetCallbackOwner(self)
  CastParam:SetCompleteCallback(self.OnSkillComplete)
  CastParam:SetExtraEvents({
    StartSummerPet = self.OpenSelectPetPanel,
    OpenLight = self.OpenFBSceneLight,
    CloseLight = self.CloseFBSceneLight
  })
  local _, skillObj = BattleSkillManager:PrepareSkill(self.player, self.RocoSkill, CastParam)
  if not skillObj then
    Log.Error("BattleFBP2SummerAction:OnSkillLoad Skill Object not found %s", resPath)
    self:Finish()
    return
  end
  local blackBoard = skillObj:GetBlackboard()
  if blackBoard then
    blackBoard:SetValueAsBool("WaitSummerPet", true)
  end
  self.skillObj = skillObj
  local result = self.RocoSkill:PlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    self:OnSkillComplete()
  end
end

function BattleFBP2SummerAction:OpenSelectPetPanel()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenCallNamePanel)
end

function BattleFBP2SummerAction:OpenFBSceneLight()
  _G.BattleManager:ModifySceneSpotLight(true)
end

function BattleFBP2SummerAction:CloseFBSceneLight()
  _G.BattleManager:ModifySceneSpotLight(false)
end

function BattleFBP2SummerAction:ConfirmPet(retInfo)
  local Req = ProtoMessage:newZoneBattleFinalBattleP2SummonReq()
  Req.confirmed = 1
  Req.pet = retInfo.pet
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINAL_BATTLE_P2_SUMMON_REQ, Req, self, self.OnSelectPetRsp, true, false)
end

function BattleFBP2SummerAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.OnFinalBattleSummer then
    self:OnSelectPetRsp(...)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:PawnPetOver(...)
    return true
  elseif eventName == BattleEvent.OnSummerResLoaded then
    self:ResumeSummerPet()
    return true
  end
end

function BattleFBP2SummerAction:OnSelectPetRsp(retInfo)
  BattleDebugger:HookGetter_ZoneBattleMessage__battle_attr(rsp)
  local supplyPetInfo
  if retInfo.perform_cmd then
    for i, v in ipairs(retInfo.perform_cmd.perform_info) do
      if v.type == ProtoEnum.BattlePerformType.BPT_SUPPLY_PET then
        supplyPetInfo = v.supply_pet
        break
      end
    end
  end
  if not supplyPetInfo then
    Log.Error("BattleFBP2SummerAction:OnSelectPetRsp supplyPetInfo is nil")
    return
  end
  local petInfos = {}
  for i, v in ipairs(supplyPetInfo.pet_infos) do
    v.posInField = self.player.FirstPetPosInField + (v.pet_pos <= 0 and 1 or v.pet_pos)
    petInfos[i] = v.pet_info
  end
  self.player.deck:IncrementalRefreshByServer(petInfos)
  self.PetArray = self.player.deck:SummonPetOnce(self.player.teamEnm, self.player.team, supplyPetInfo.pet_infos)
end

function BattleFBP2SummerAction:PawnPetOver(battlePet)
  if self.finished then
    return
  end
  if not UE.UObject.IsValid(self.skillObj) or not battlePet then
    self:Finish()
    return
  end
  battlePet:SetScale(1)
  battlePet:SwimSetLockIdle(false)
  self.skillObj:SetTargets({
    battlePet.model
  })
  self.skillObj:SetDynamicData({
    BallPath = battlePet:GetBallPath()
  })
  self.battlePet = battlePet
  if battlePet.model and battlePet.card.medalBlackBoard then
    BattleUtils.SetParticleKeyForSkillObj(battlePet.model, self.skillObj, battlePet.card.medalBlackBoard)
    self.skillObj.OnAsyncLoadCompleted:Add(battlePet.model, self.OnSkillAsyncLoadComplete)
    self.skillObj:StartAsyncLoadAtPlaying()
    self:SafeDelaySeconds("d_SummerPet", 5, self.DelaySummerPet, self)
  else
    self:ResumeSummerPet()
  end
end

function BattleFBP2SummerAction:OnSkillAsyncLoadComplete()
  BattleEventCenter:Dispatch(BattleEvent.OnSummerResLoaded)
end

function BattleFBP2SummerAction:DelaySummerPet()
  Log.Error("zgx \229\138\160\232\189\189\229\164\177\232\180\165 \232\167\166\229\143\145\228\186\134\228\191\157\229\186\149\239\188\129\239\188\129\239\188\129")
  self:ResumeSummerPet()
end

function BattleFBP2SummerAction:ResumeSummerPet()
  self:SafeCancelDelayById("d_SummerPet")
  if self.finished then
    return
  end
  if self.IsSummonPet then
    return
  end
  self.IsSummonPet = true
  local blackBoard = self.skillObj:GetBlackboard()
  if blackBoard then
    blackBoard:SetValueAsBool("WaitSummerPet", false)
  end
  if _G.enableAdaptiveBattlePetPos then
    local myPet = BattleManager.battlePawnManager:GetInFieldPet(BattleEnum.Team.ENUM_TEAM)
    if myPet then
      BattleManager.vBattleField:AdaptiveMyBattlePetPos(myPet.model)
      myPet:PinOnTheGround()
    end
  end
  _G.BattleManager:PlayBattleBGM()
  _G.BattleManager.vBattleField.battleCameraManager:CalcPosCache()
end

function BattleFBP2SummerAction:ShowPopup(pet)
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
    BattleEnum.InfoPopupType.SummonPet,
    pet.player,
    pet.card
  })
end

function BattleFBP2SummerAction:HidePopup()
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.player)
end

function BattleFBP2SummerAction:OnSkillComplete()
  if not self.battlePet then
    self:Finish()
    return
  end
  if self.battlePet then
    self.battlePet:ShowPet()
    self.battlePet = nil
  end
  self:HidePopup()
  self:Finish()
end

function BattleFBP2SummerAction:ClearVar(name)
  FsmUtils.ClearProperty(self.fsm, name)
end

function BattleFBP2SummerAction:OnFinish()
  if self.isFSMPause and self.fsm then
    self.fsm:Resume()
  end
  self:ClearVar("camActor_0001")
  self:ClearVar("camActor_0001_SA")
  BattleEventCenter:UnBind(self)
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:RefreshOperatePanel()
    mainWindow:CheckOpenFinalBattleP2HPBar()
  end
end

return BattleFBP2SummerAction

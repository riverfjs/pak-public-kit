local BattleComponent = require("NewRoco.Modules.Core.Battle.Entity.BattleComponent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Enum = require("Data.Config.Enum")
local Buff = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.Buff")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local Base = BattleComponent
local BuffGroupSign = Enum.BuffGroupSign
local BuffComponent = BattleComponent:Extend("BuffComponent")

function BuffComponent:Ctor(owner)
  Base.Ctor(self)
  self.owner = owner
  self.destroyed = false
  self.buffs = {}
  self.buffSkillObjLst = {}
  self.buffSkillObjLoadingLst = {}
  self.skillObjToBuffSign = {}
  self.skillEventCallBack = {}
  self.skillCallBack = {}
  self.log = false
  self.stateEffectCfg = {
    [BuffGroupSign.BGS_SLEEP] = {
      skillPath = BattleConst.Define.SleepResID,
      playOnPawn = true,
      needRestart = true,
      restartCheckAnim = {"SleepStand", "SleepLoop"},
      HideOnCatchFail = true
    },
    [BuffGroupSign.BGS_DRILL] = {
      aniName = BattleConst.PetStateOverrideAnimName.DrillLoop,
      playOnPawn = true
    },
    [BuffGroupSign.BGS_STATIC] = {
      aniName = BattleConst.PetStateOverrideAnimName.StaticLoop,
      playOnPawn = true
    },
    [BuffGroupSign.BGS_MAGICDIZZY] = {
      playOnPawn = true,
      needRestart = true,
      restartCheckAnim = {"Stun"},
      HideOnCatchFail = true
    },
    [BuffGroupSign.BGS_BACKSTAB] = {
      playOnPawn = true,
      customFunc = "TriggerTurnToBack"
    },
    [BuffGroupSign.BGS_GHOST] = {
      playOnPawn = true,
      customFunc = "TriggerGhost"
    },
    [BuffGroupSign.BGS_LEADERDIZZY] = {
      playOnPawn = true,
      needRestart = true,
      restartCheckAnim = {"Stun"},
      HideOnCatchFail = true
    },
    [BuffGroupSign.BGS_GATHER] = {
      playOnPawn = true,
      needRestart = true,
      restartCheckAnim = {
        "Skill2Loop1"
      },
      hasEndEffect = true
    },
    [BuffGroupSign.BGS_NIGHTMARE] = {
      playOnPawn = true,
      hasEndEffect = true,
      keepOnBeCatch = true,
      skillEvents = {
        BattleConst.NightmareMutationChangeEventName
      }
    },
    [BuffGroupSign.BGS_NIGHTMARE_ONE] = {
      playOnPawn = true,
      keepOnBeCatch = true,
      keepOnDie = true
    },
    [BuffGroupSign.BGS_IDLE] = {
      needRestart = false,
      restartCheckAnim = {"happy"}
    },
    [BuffGroupSign.BGS_BLACK_MAGIC] = {playOnPawn = true},
    [BuffGroupSign.BGS_PERSISTENT_SHIELD] = {playOnPawn = true},
    [BuffGroupSign.BGS_RIVERSOUL_PARTICLES] = {playOnPawn = true},
    [BuffGroupSign.BGS_CATCHSTUN] = {
      skillPath = BattleConst.Define.StunResID,
      playOnPawn = true,
      needRestart = true,
      restartCheckAnim = {"Stun"}
    }
  }
end

function BuffComponent:SetModel()
  self.petState = self.owner.card.petState
  if self.owner and self.owner.model then
    self.RocoSkill = self.owner.model.RocoSkill
    self.RocoAnim = self.owner:GetAnimComponent()
  end
end

function BuffComponent:InitByCard(Card)
  Base.InitByCard(self)
  Card.petState:ResetAllState()
  self.petState = Card.petState
  self:RefreshBuffs(Card.petInfo.battle_inside_pet_info.buffs)
end

function BuffComponent:UpdateByCard(Card, needRefresh)
  if self.destroyed then
    return
  end
  self:RefreshBuffs(Card.petInfo.battle_inside_pet_info.buffs)
end

function BuffComponent:RefreshBuffs(buffInfos, needRefresh)
  buffInfos = buffInfos or {}
  for _, v in ipairs(buffInfos) do
    self:BuffHelper(v)
  end
  for _, m in ipairs(self.buffs) do
    local found = false
    for _, o in ipairs(buffInfos) do
      if m.id == o.buff_id then
        found = true
        break
      end
    end
    if not found then
      self:BuffHelper({
        buff_id = m.id,
        stack = 0
      })
    end
  end
  if needRefresh or nil == needRefresh then
    _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_BUFF, self.owner)
  end
end

local function SortBuffs(buff1, buff2)
  if not buff1 or not buff2 then
    return false
  end
  return buff1:GetSortOrder() < buff2:GetSortOrder()
end

function BuffComponent:ChangeBuffData(buffChange, sync_data)
  local buff_id = buffChange.buff_id
  if not buff_id or 0 == buff_id then
    BattleLog.BuffError("Can't find valid buff id: ", buff_id)
    return
  end
  local changeType = buffChange.type
  if changeType == ProtoEnum.BuffChangeType.BCT_ADD then
    local buffEntity = self:OnAddBuff(buffChange.buff_info)
    return buffEntity, table.indexOf(self.buffs, buffEntity)
  elseif changeType == ProtoEnum.BuffChangeType.BCT_CHANGE then
    for i, v in ipairs(self.buffs) do
      if v.id == buffChange.buff_id then
        local stackPre = v.stack or 0
        v:Refresh(buffChange.buff_info)
        return v, stackPre < (buffChange.buff_info and buffChange.buff_info.stack or 0)
      end
    end
  elseif changeType == ProtoEnum.BuffChangeType.BCT_REMOVE then
    for i, v in ipairs(self.buffs) do
      if v.id == buffChange.buff_id then
        self:OnRemoveBuff(v, false)
        table.removeValue(self.buffs, v)
        return v, false
      end
    end
  else
    BattleLog.BuffError("ChangeBuffData invalid changeType:", changeType)
  end
end

function BuffComponent:GetBuff(id)
  for i, v in ipairs(self.buffs) do
    if v.id == id then
      return v
    end
  end
  return nil
end

function BuffComponent:GetAllBuffsByOrderType(orderType)
  local buffs = {}
  if self.buffs == nil then
    return buffs
  end
  for i, buff in ipairs(self.buffs) do
    if buff:GetBuffBaseOrder() == orderType then
      table.insert(buffs, buff)
    end
  end
  return buffs
end

function BuffComponent:IsExistBuffsByOrderType(orderType)
  if self.buffs then
    for _, buff in ipairs(self.buffs) do
      if buff:GetBuffBaseOrder() == orderType then
        return true
      end
    end
  end
  return false
end

function BuffComponent:BuffHelper(buffInfo)
  local buff_id = buffInfo.buff_id
  if not buff_id or 0 == buff_id then
    BattleLog.BuffError("Can't find valid buff id: ", buff_id)
    Log.Dump(buffInfo, 3, "Dumping wrong buff id")
    return
  end
  local hasBuff = false
  for i, v in ipairs(self.buffs) do
    if v.id == buffInfo.buff_id then
      if 0 == buffInfo.stack then
        self:OnRemoveBuff(v, false)
        table.removeValue(self.buffs, v)
        hasBuff = true
        break
      end
      v:Refresh(buffInfo)
      hasBuff = true
      break
    end
  end
  if not hasBuff and buffInfo.stack > 0 then
    self:OnAddBuff(buffInfo)
  end
end

function BuffComponent:OnAddBuff(buff_info)
  BattleLog.BuffWarning("OnAddBuff ", buff_info.buff_id)
  local buffEntity = Buff(self.owner)
  if not buffEntity:InitByInfo(buff_info) then
    return
  end
  table.insert(self.buffs, buffEntity)
  table.sort(self.buffs, SortBuffs)
  if self.owner and self.owner.card and buffEntity.config then
    self.owner.card:UpdateStateByAddingBuff(buffEntity.config)
  end
  return buffEntity
end

function BuffComponent:RemoveBuffs(immediate)
  local cacheBuffs = self.buffs
  self.buffs = {}
  for _, buff in ipairs(cacheBuffs) do
    self:OnRemoveBuff(buff, immediate)
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.REMOVE_BUFF, self.owner, immediate)
end

function BuffComponent:OnRemoveBuff(buff, immediate)
  BattleLog.BuffWarning("OnRemoveBuff ", buff.id)
  if not self.owner or not self.petState then
    return
  end
  if self.owner.card and not self.petState:GetDead() then
    local preIsHide = self.petState:GetPetIsInHide()
    local resLst = self.owner.card:UpdateStateByRemovingBuff(buff.config)
    for _, sign in ipairs(resLst) do
      if sign == ProtoEnum.BuffGroupSign.BGS_MIMIC then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsStopMimic)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_DRILL then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsStopDrill)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_STATIC then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsStopStatic)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_SLEEP then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.WakeUp)
        self:StopStateEffect(sign)
        self.owner:PlayAnimByName("Idle", 1, -1, 0.2, 0.2, 1, -1)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_BACKSTAB then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsNotBacking)
        if self.owner.IsHeadBack then
          self.owner:ResetRotation(true)
        end
      elseif sign == ProtoEnum.BuffGroupSign.BGS_MAGICDIZZY then
        self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsStopStun)
        self:StopStateEffect(sign)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_GHOST then
        self:StopStateEffect(sign)
      elseif sign == ProtoEnum.BuffGroupSign.BGS_LEADERDIZZY then
        self:StopStateEffect(sign)
        if buff.id == BattleConst.BuffId.LeaderStun0 then
          self:PopupStateByRemovingBuff(BattleEnum.InfoPopupType.IsStopLeaderStun)
        end
      end
    end
    if preIsHide ~= self.petState:GetPetIsInHide() then
      self.owner:SetOutLineMaterial()
    end
  end
end

function BuffComponent:PopupStateByRemovingBuff(type)
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
    type,
    self.owner
  }, nil)
  self.delayId = _G.DelayManager:DelaySeconds(1, self.owner.HidePopup, self.owner, nil, nil)
end

function BuffComponent:HasBuff()
  return #self.buffs > 0
end

function BuffComponent:HasDebuff()
  for _, v in ipairs(self.buffs) do
    if v:IsDebuff() then
      return true
    end
  end
  return false
end

function BuffComponent:CheckHasStuckBuff(damage_type)
  for _, buff in ipairs(self.buffs) do
    if buff:CheckHasStuckBuff(damage_type) then
      return true
    end
  end
  return false
end

function BuffComponent:CheckStateIsPlaying(buffSign)
  BattleLog.BuffWarning("CheckStateIsPlaying: ", buffSign)
  local stateCfg = self.stateEffectCfg[buffSign]
  if not stateCfg then
    return false
  end
  if not string.IsNilOrEmpty(stateCfg.aniName) then
    return self.RocoAnim:IsAnimPlaying(stateCfg.aniName)
  else
    return self.buffSkillObjLst[buffSign] ~= nil
  end
end

function BuffComponent:PlayStateEffect(buffSign)
  self:OnStateValueChange(buffSign, true)
end

function BuffComponent:StopStateEffect(buffSign, forceStop)
  if forceStop then
    self:StopStateSkill(buffSign, forceStop)
  else
    self:OnStateValueChange(buffSign, false)
  end
end

function BuffComponent:OnStateValueChange(buffSign, isOn)
  BattleLog.BuffDebug("OnStateValueChange ", buffSign, isOn)
  if self.destroyed then
    return
  end
  if _G.BattleManager.battleRuntimeData:GetOnSelectWorldLeaderSkill() then
    return
  end
  local stateCfg = self.stateEffectCfg[buffSign]
  if not stateCfg then
    local callBackInfo = self.skillCallBack[buffSign]
    if callBackInfo then
      self.skillCallBack[buffSign] = nil
      callBackInfo.callBack(callBackInfo.owner)
    end
    return
  end
  if not string.IsNilOrEmpty(stateCfg.customFunc) then
    self[stateCfg.customFunc](self, isOn)
    return
  end
  if isOn then
    if string.IsNilOrEmpty(stateCfg.aniName) then
      self:PlayStateSkill(buffSign)
    else
      self:PlayStateAnimation(stateCfg.aniName)
    end
  elseif string.IsNilOrEmpty(stateCfg.aniName) then
    self:StopStateSkill(buffSign)
  else
    self:StopStateAnimation(stateCfg.aniName)
  end
end

function BuffComponent:RestartStateEffect(buffSign)
  if self.petState:GetStateBySign(buffSign) then
    self:StopStateEffect(buffSign, true)
    self:PlayStateEffect(buffSign)
  end
end

function BuffComponent:RestartBattleState(buffSign)
  if not self.petState then
    self:SetModel()
    if not self.petState then
      return
    end
  end
  if not self.RocoAnim then
    return
  end
  if self.owner:IsDead() then
    return
  end
  for i, v in pairs(self.stateEffectCfg) do
    if v.needRestart and self.petState:GetStateBySign(i) then
      if v.restartCheckAnim then
        local isAnimPlay = false
        for key, anim in ipairs(v.restartCheckAnim) do
          if self.RocoAnim:IsAnimPlaying(anim) then
            isAnimPlay = true
            break
          end
        end
        if not isAnimPlay then
          if string.IsNilOrEmpty(v.aniName) and self.buffSkillObjLst[i] then
            self.buffSkillObjLst[i]:RestoreG6Effect()
            break
          end
          self:RestartStateEffect(i)
        end
      elseif buffSign then
        if buffSign == i then
          self:RestartStateEffect(i)
        end
      else
        self:RestartStateEffect(i)
      end
    end
  end
end

function BuffComponent:PlayStateAnimation(aniName)
  if string.IsNilOrEmpty(aniName) then
    return
  end
  if not self:IsCanPlayAnimation(aniName) then
    return
  end
  if _G.BattleManager.debugEnv and _G.BattleManager.debugEnv.EnableAnimLog then
    local actorName = "Unknown"
    if self.owner and self.owner.model then
      actorName = self.owner.model:GetFullName() or "Unknown"
    end
    local curAnimName = "None"
    if self.RocoAnim and self.RocoAnim.GetCurAnimNameWithCheck then
      curAnimName = self.RocoAnim:GetCurAnimNameWithCheck() or "None"
    end
    BattleLog.AnimWarning(string.format("PlayStateAnimation - \229\189\147\229\137\141\229\138\168\231\148\187: %s, \232\166\129\230\146\173\230\148\190\231\154\132\229\138\168\231\148\187: %s, Owner: %s ", curAnimName, aniName, actorName))
  end
  if self.owner and self.owner.model then
    self.owner.model:PlayAnimByName(aniName, 1, 0, 0, 0, -1)
  end
end

function BuffComponent:IsCanPlayAnimation(aniName)
  if not (self.owner and self.owner.model) or not self.owner.model.PlayAnimByName then
    return false
  end
  return self.petState:IsAnimable(aniName)
end

function BuffComponent:PlayStateSkill(buffSign)
  if not self.owner then
    return
  end
  BattleLog.BuffWarning("PlayStateSkill1 ", buffSign, self.owner:IsDead())
  if self.buffSkillObjLst[buffSign] or self.buffSkillObjLoadingLst[buffSign] then
    local lastSkillObj = self.buffSkillObjLst and self.buffSkillObjLst[buffSign]
    if lastSkillObj and lastSkillObj:GetBlackboard() then
      local isLastEnd = not lastSkillObj:GetBlackboard():GetValueAsBool("BuffLoop")
      if isLastEnd then
        self:OnSkillComplete("PreEnd", lastSkillObj)
        self.RocoSkill:CancelSkill(lastSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
      else
        return
      end
    else
      return
    end
  end
  if buffSign == Enum.BuffGroupSign.BGS_NIGHTMARE or buffSign == Enum.BuffGroupSign.BGS_NIGHTMARE_ONE then
    local isSheild = PetUtils.CheckHasNightMareShield(self.owner.card.petInfo.battle_inside_pet_info)
    local status = self.owner.card.petInfo.battle_inside_pet_info.ai_info.ai_status
    local isNightmare = BattleUtils.IsNightmareKeep(status)
    if not isSheild and not isNightmare then
      return
    end
  end
  local skillPath = self:GetSkillPath(buffSign)
  if string.IsNilOrEmpty(skillPath) then
    return
  end
  if BattleSkillManager:IsResLoaded(skillPath) then
    self:OnBuffResLoad(true, skillPath, buffSign)
  else
    self.buffSkillObjLoadingLst[buffSign] = true
    BattleSkillManager:PreLoadSingleRes(skillPath, true, self, self.OnBuffResLoad, buffSign)
  end
end

function BuffComponent:OnBuffResLoad(isLoadSucceed, resPath, ...)
  if not isLoadSucceed then
    return
  end
  BattleLog.BuffWarning("OnBuffResLoad", resPath)
  local params = {
    ...
  }
  local buffSign = params[1]
  local stateCfg = self.stateEffectCfg[buffSign]
  local CastParam = CastSkillObject.Create()
  CastParam.ResID = resPath
  CastParam:SetIsPassive(true)
  if self.owner then
    CastParam:SetCaster(self.owner.model)
  else
    BattleLog.BuffWarning("OnBuffResLoad self.owner.model is nil")
  end
  CastParam:SetTargetPets({
    self.owner
  })
  CastParam:SetCallbackOwner(self)
  CastParam:SetCompleteCallback(self.OnSkillComplete)
  CastParam:AddExtraEvent("ActionStart", self.OnActionStart)
  if stateCfg and stateCfg.skillEvents then
    for i, eventName in ipairs(stateCfg.skillEvents) do
      CastParam:AddExtraEvent(eventName, self.OnSkillEvent)
    end
  end
  local _, skillObj = BattleSkillManager:PrepareSkill(self.owner, self.RocoSkill, CastParam)
  if not skillObj then
    Log.DebugFormat("OnBuffResLoad Skill Object not found %s", resPath)
    return
  end
  self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultSuccessful)
  local blackBoard = skillObj:GetBlackboard()
  if blackBoard and buffSign == BuffGroupSign.BGS_SLEEP then
    if _G.BattleManager.EnterSleepAnim == "SleepLoop" then
      blackBoard:SetValueAsString("SleepLoop", "True")
    else
      blackBoard:SetValueAsString("SleepStand", "True")
    end
  end
  local result = self.RocoSkill:PlaySkill(skillObj)
  if result ~= UE4.ESkillStartResult.Success then
    BattleLog.BuffWarning("OnBuffResLoad Error", result)
  end
  self.buffSkillObjLst[buffSign] = skillObj
  self.skillObjToBuffSign[skillObj] = buffSign
  self.buffSkillObjLoadingLst[buffSign] = false
end

function BuffComponent:GetSkillPath(buffSign)
  local stateCfg = self.stateEffectCfg[buffSign]
  if stateCfg and not string.IsNilOrEmpty(stateCfg.skillPath) then
    return stateCfg.skillPath
  end
  for _, buff in ipairs(self.buffs) do
    local skillPath = buff:GetDefaultSkillPath(buffSign)
    if not string.IsNilOrEmpty(skillPath) then
      return skillPath
    end
  end
  return nil
end

function BuffComponent:StopStateAnimationByCfg(stateCfg)
  if not self.RocoAnim then
    return
  end
  if stateCfg and stateCfg.restartCheckAnim then
    for key, anim in ipairs(stateCfg.restartCheckAnim) do
      if self.RocoAnim:IsAnimPlaying(anim) then
        self:StopStateAnimation(anim)
        break
      end
    end
  end
end

function BuffComponent:StopStateAnimation(aniName)
  if string.IsNilOrEmpty(aniName) then
    return
  end
  if self.RocoAnim and self.RocoAnim:IsAnimPlaying(aniName) then
    self.RocoAnim:StopAnimByName(aniName)
  end
end

function BuffComponent:StopStateSkill(buffSign, forceStop)
  BattleLog.BuffWarning("StopStateSkill1 ", buffSign)
  local skillObj = self.buffSkillObjLst and self.buffSkillObjLst[buffSign]
  if not skillObj then
    local callBackInfo = self.skillCallBack[buffSign]
    if callBackInfo then
      self.skillCallBack[buffSign] = nil
      callBackInfo.callBack(callBackInfo.owner)
    end
    return
  end
  local stateCfg = self.stateEffectCfg[buffSign]
  self:StopStateAnimationByCfg(stateCfg)
  skillObj:UnregisterEventCallback("ActionStart", self, self.OnActionStart)
  if stateCfg and stateCfg.hasEndEffect and not forceStop then
    self:SetBuffLoopBlackBoard(skillObj, false)
  else
    self:SetBuffLoopBlackBoard(skillObj, false)
    self:OnSkillComplete("PreEnd", skillObj)
    self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
end

function BuffComponent:OnActionStart(eventName, skillObj)
  self:SetBuffLoopBlackBoard(skillObj, true)
end

function BuffComponent:OnSkillEvent(eventName, skillObj)
  local buffSign = self.skillObjToBuffSign[skillObj]
  if buffSign then
    local eventNameToCallBackInfo = self.skillEventCallBack[buffSign]
    local callBackInfo = eventNameToCallBackInfo and eventNameToCallBackInfo[eventName]
    if callBackInfo then
      eventNameToCallBackInfo[eventName] = nil
      callBackInfo.callBack(callBackInfo.owner)
    end
  end
end

function BuffComponent:OnSkillComplete(eventName, skillObj)
  local buffSign = self.skillObjToBuffSign[skillObj]
  BattleLog.BuffWarning("OnSkillComplete", eventName, buffSign, skillObj:GetName())
  if buffSign then
    local callBackInfo = self.skillCallBack[buffSign]
    if callBackInfo then
      self.skillCallBack[buffSign] = nil
      callBackInfo.callBack(callBackInfo.owner)
    end
    self.buffSkillObjLst[buffSign] = nil
    self.skillObjToBuffSign[skillObj] = nil
    if buffSign == BuffGroupSign.BGS_NIGHTMARE then
      _G.BattleEventCenter:Dispatch(BattleEvent.NightmareShieldBreak, self.owner)
    end
  end
  if buffSign == BuffGroupSign.BGS_NIGHTMARE then
    local status = self.owner.card.petInfo.battle_inside_pet_info.ai_info.ai_status
    local isNightmare = BattleUtils.IsNightmareKeep(status)
    if not isNightmare then
      self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
  end
end

function BuffComponent:RegisterSkillEventCallBack(buffSign, owner, eventName, callBack)
  local eventNameToCallbackInfo = self.skillEventCallBack[buffSign]
  if not eventNameToCallbackInfo then
    eventNameToCallbackInfo = {}
    self.skillEventCallBack[buffSign] = eventNameToCallbackInfo
  end
  if eventNameToCallbackInfo then
    eventNameToCallbackInfo[eventName] = {owner = owner, callBack = callBack}
  end
end

function BuffComponent:RegisterCompleteCallBack(buffSign, owner, callBack)
  self.skillCallBack[buffSign] = {owner = owner, callBack = callBack}
end

function BuffComponent:SetBuffLoopBlackBoard(skillObj, value)
  if not UE.UObject.IsValid(skillObj) then
    return
  end
  BattleLog.BuffWarning("SetBuffLoopBlackBoard", value, skillObj:GetName())
  local Blackboard = skillObj:GetBlackboard()
  if Blackboard then
    Blackboard:SetValueAsBool("BuffLoop", value)
  end
end

function BuffComponent:CanPlayBuff(buffId)
  local buffConf = _G.DataConfigManager:GetBuffConf(buffId, true)
  if not buffConf then
    return false
  end
  for i, v in ipairs(buffConf.buff_groupsigns) do
    if self.petState:CheckOnBuffTrigger(v) and (self.buffSkillObjLst[v] or self.buffSkillObjLoadingLst[v]) then
      return false
    end
  end
  if self.petState:GetBeRidOf() and not BuffUtils.IsRidOfBuff(buffId) then
    return false
  end
  if buffConf.buff_list_priority >= 5 and self.petState:GetMimic() then
    return false
  end
  if BuffUtils.IsGatherBuff(buffId) then
    return false
  end
  return true
end

function BuffComponent:TriggerStateOnPawn()
  for i, v in pairs(self.stateEffectCfg) do
    if v.playOnPawn and self.petState:GetStateBySign(i) then
      self:PlayStateEffect(i)
    end
  end
end

function BuffComponent:TriggerTurnToBack(isOn)
  if isOn and self.petState:GetBackStab() then
    self.owner:TurnToBack()
  end
end

function BuffComponent:TriggerGhost(isOn)
  if isOn and self.petState:GetGhost() then
    self.owner:SetGhost(true)
  end
end

function BuffComponent:OnPetDie()
  for buffSign, skillObj in pairs(self.buffSkillObjLst or {}) do
    local stateCfg = self.stateEffectCfg[buffSign]
    if stateCfg and not stateCfg.keepOnDie then
      if skillObj then
        self:SetBuffLoopBlackBoard(skillObj, false)
        self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
      self.buffSkillObjLst[buffSign] = nil
    end
  end
end

function BuffComponent:OnPetBeCatch(isSucceed)
  if isSucceed then
    for buffSign, skillObj in pairs(self.buffSkillObjLst or {}) do
      local stateCfg = self.stateEffectCfg[buffSign]
      if stateCfg and not stateCfg.keepOnBeCatch then
        if skillObj then
          self:SetBuffLoopBlackBoard(skillObj, false)
          self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
        end
        self.buffSkillObjLst[buffSign] = nil
      end
    end
  else
    for buffSign, skillObj in pairs(self.buffSkillObjLst or {}) do
      local stateCfg = self.stateEffectCfg[buffSign]
      if stateCfg and stateCfg.HideOnCatchFail then
        if skillObj then
          self:SetBuffLoopBlackBoard(skillObj, false)
          self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
        end
        self.buffSkillObjLst[buffSign] = nil
      end
    end
  end
end

function BuffComponent:ClearBuff()
  if self.destroyed then
    return
  end
  for buffSign, skillObj in pairs(self.buffSkillObjLst) do
    self:SetBuffLoopBlackBoard(skillObj, false)
    if UE4.UObject.IsValid(self.RocoSkill) then
      self.RocoSkill:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
  end
  self.buffSkillObjLst = {}
end

function BuffComponent:OnBattlePetDestroy()
  self:Log("BuffComponent:OnBattlePetDestroy ", self.destroyed)
  if self.destroyed then
    return
  end
  self:ClearBuff()
  self.buffs = {}
  self.buffSkillObjLst = nil
  self.skillObjToBuffSign = nil
  self.skillEventCallBack = nil
  self.skillCallBack = nil
  self.RocoSkill = nil
  self.RocoAnim = nil
  self.owner = nil
  self.petState = nil
  self.destroyed = true
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

return BuffComponent

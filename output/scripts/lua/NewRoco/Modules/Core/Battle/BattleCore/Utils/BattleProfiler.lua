local BattleProfiler = NRCClass:Extend("BattleEventCenter")
local FsmEnum = require("NewRoco.Modules.Core.Fsm.FsmEnum")
local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local FsmState = require("NewRoco.Modules.Core.Fsm.FsmState")
BattleProfilerTag = {
  EnterBattle,
  LeaveBattle
}
_G.BattleProfilerType = {
  Seamless = 1,
  ThrowBall = 2,
  NPCEnter = 3,
  NpcChallenge = 4,
  LeaderEnter = 5,
  FlowerEnter = 6,
  PVPRank = 7,
  PVPFriend = 8,
  FinalBattle = 9,
  LegendaryBattle = 10,
  Wild1VN = 11,
  WeeklyChallenge = 12,
  PVPFate = 13,
  PVPRapids = 14,
  PVPInsect = 15,
  PVPSpeed = 16
}
_G.BattleProfilerCheckPoint = {
  None = 0,
  NPCActionBattle = 1,
  ThrowBallHitMonster = 2,
  NPCDialog = 3,
  NPCChallenge = 4,
  BattleEnterNotify = 5,
  PVPRank = 6,
  PVPFriend = 7,
  FinalBattle = 8,
  LegendaryBattleSingleChallengeClick = 9,
  CommonPopUpRightBtn = 10,
  LegendaryBattleConfirmHelpClick = 11,
  FlowerMainPanelClick = 12,
  LegendaryMainPanelClick = 19,
  NPCTalk = 13,
  PVPRankClickChallenge = 14,
  PVPRankClickPrepareConfirm = 15,
  PVPFriendRequireCompetition = 16,
  PVPFriendResponseCompetition = 17,
  WeeklyChallengeClick = 18,
  PVPFateDuel = 19,
  PVPRapidsDuel = 20,
  PVPInsectDuel = 21,
  PVPSpeedDuel = 22,
  PVPFriendDuel = 23,
  PVPRankDuel = 24
}

function BattleProfiler:Init()
  self.isInit = true
  self.battleProfilerDict = {}
  self.registerIntervalDict = {}
  self.battleProfilerJson = {}
  self.isCheckedActionDict = {}
  self.nameLessStr = "NamelessInterval"
  self.ClickState = "StartBattleState"
  self.ClickAction = "ReqBattleAction"
  self.battleType = 1
  self.battleID = 1
  if RocoEnv.IS_EDITOR then
    self.isEnable = true
  else
    self.isEnable = false
  end
  self.isConstruct = false
  self.checkPointLst = {}
  self.isHitFirstCheckPointLst = {}
  self.hitIndex = 1
  self:BuildBattleCheckPointDict()
end

function BattleProfiler:BuildBattleCheckPointDict()
  self.battleTypeCheckPointLst = {
    {
      t = BattleProfilerType.Seamless,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.NPCActionBattle,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.ThrowBall,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.ThrowBallHitMonster,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NPCEnter,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.NPCDialog,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NPCEnter,
      p = {
        BattleProfilerCheckPoint.NPCTalk,
        BattleProfilerCheckPoint.NPCDialog,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NPCEnter,
      p = {
        BattleProfilerCheckPoint.NPCTalk,
        BattleProfilerCheckPoint.NPCTalk,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NPCEnter,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.NPCTalk,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NpcChallenge,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.NPCChallenge,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.NpcChallenge,
      p = {
        BattleProfilerCheckPoint.NPCDialog,
        BattleProfilerCheckPoint.NPCChallenge,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.FlowerEnter,
      p = {
        BattleProfilerCheckPoint.FlowerMainPanelClick,
        BattleProfilerCheckPoint.CommonPopUpRightBtn,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.LegendaryBattle,
      p = {
        BattleProfilerCheckPoint.LegendaryBattleSingleChallengeClick,
        BattleProfilerCheckPoint.CommonPopUpRightBtn,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.LegendaryBattle,
      p = {
        BattleProfilerCheckPoint.LegendaryBattleConfirmHelpClick,
        BattleProfilerCheckPoint.CommonPopUpRightBtn,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.LegendaryBattle,
      p = {
        BattleProfilerCheckPoint.LegendaryMainPanelClick,
        BattleProfilerCheckPoint.CommonPopUpRightBtn,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.FinalBattle,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.NPCTalk,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.FinalBattle,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.LeaderEnter,
      p = {
        BattleProfilerCheckPoint.None,
        BattleProfilerCheckPoint.ThrowBallHitMonster,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPRank,
      p = {
        BattleProfilerCheckPoint.PVPRankClickChallenge,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPFriend,
      p = {
        BattleProfilerCheckPoint.PVPFriendRequireCompetition,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPFriend,
      p = {
        BattleProfilerCheckPoint.PVPFriendResponseCompetition,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPFriend,
      p = {
        BattleProfilerCheckPoint.PVPFriendDuel,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPSpeed,
      p = {
        BattleProfilerCheckPoint.PVPSpeedDuel,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.PVPFate,
      p = {
        BattleProfilerCheckPoint.PVPFateDuel,
        BattleProfilerCheckPoint.PVPRankClickPrepareConfirm,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    },
    {
      t = BattleProfilerType.WeeklyChallenge,
      p = {
        BattleProfilerCheckPoint.NPCDialog,
        BattleProfilerCheckPoint.WeeklyChallengeClick,
        BattleProfilerCheckPoint.BattleEnterNotify
      },
      e = true
    }
  }
end

function BattleProfiler:SetEnable()
  self.isEnable = true
end

function BattleProfiler:IsEnable()
  return self.isEnable
end

function BattleProfiler:CheckPoint(pointType)
  if not self:IsEnable() then
    return
  end
  if RocoEnv.IS_EDITOR then
    Log.Msg("CheckPoint:", pointType)
  end
  local data = {
    pt = pointType,
    time = self:GetTime()
  }
  table.insert(self.checkPointLst, data)
  self:TryStartProfiler()
end

function BattleProfiler:ClearCheckPoint()
  self.checkPointLst = {}
end

function BattleProfiler:SetRecordClickState(boo)
  self.isRecordClickState = boo
end

function BattleProfiler:SetTypeCheckPointLstEnable()
  local SceneModule = NRCModuleManager:GetModule("SceneModule")
  local MapId = SceneModule:GetCurrentMapId()
  local isInWorldBattle = NRCModuleManager:DoCmd(WorldCombatModuleCmd.IsInWorldCombat)
  if RocoEnv.IS_EDITOR then
    Log.Error("MapId:", MapId)
  end
  if 130 == MapId then
    for i = 1, #self.battleTypeCheckPointLst do
      local d = self.battleTypeCheckPointLst[i]
      if d.t == BattleProfilerType.FinalBattle then
        d.e = true
      else
        d.e = false
      end
    end
  elseif isInWorldBattle then
    for i = 1, #self.battleTypeCheckPointLst do
      local d = self.battleTypeCheckPointLst[i]
      if d.t == BattleProfilerType.LeaderEnter then
        d.e = true
      else
        d.e = false
      end
    end
  else
    for i = 1, #self.battleTypeCheckPointLst do
      local d = self.battleTypeCheckPointLst[i]
      if d.t == BattleProfilerType.LeaderEnter or d.t == BattleProfilerType.FinalBattle then
        d.e = false
      else
        d.e = true
      end
    end
  end
end

function BattleProfiler:TryStartProfiler()
  self:SetTypeCheckPointLstEnable()
  if 1 == #self.checkPointLst then
    local lstP = self.checkPointLst[#self.checkPointLst].pt
    Log.Msg("BattleProfiler TryStartProfiler:", lstP)
    for i = 1, #self.battleTypeCheckPointLst do
      local battleProfilerType = self.battleTypeCheckPointLst[i].t
      local e = self.battleTypeCheckPointLst[i].e
      if e then
        local p = self.battleTypeCheckPointLst[i].p
        if p[3] == lstP then
          self:StartProfiler(battleProfilerType)
        end
      end
    end
  elseif 2 == #self.checkPointLst then
    local lstP = self.checkPointLst[#self.checkPointLst].pt
    local lstP1 = self.checkPointLst[#self.checkPointLst - 1].pt
    Log.Msg("BattleProfiler TryStartProfiler:", lstP, lstP1)
    for i = 1, #self.battleTypeCheckPointLst do
      local battleProfilerType = self.battleTypeCheckPointLst[i].t
      local e = self.battleTypeCheckPointLst[i].e
      if e then
        local p = self.battleTypeCheckPointLst[i].p
        if p[2] == lstP1 and p[3] == lstP then
          self:StartProfiler(battleProfilerType)
        end
      end
    end
  elseif #self.checkPointLst > 2 then
    local lstP = self.checkPointLst[#self.checkPointLst].pt
    local lstP1 = self.checkPointLst[#self.checkPointLst - 1].pt
    local lstP2 = self.checkPointLst[#self.checkPointLst - 2].pt
    Log.Msg("BattleProfiler TryStartProfiler:", lstP, lstP1, lstP2)
    for i = 1, #self.battleTypeCheckPointLst do
      local battleProfilerType = self.battleTypeCheckPointLst[i].t
      local e = self.battleTypeCheckPointLst[i].e
      if e then
        local p = self.battleTypeCheckPointLst[i].p
        if p[1] == lstP2 and p[2] == lstP1 and p[3] == lstP then
          self:StartProfiler(battleProfilerType)
        end
      end
    end
  end
end

function BattleProfiler:StartProfiler(profilerType)
  self.battleProfilerDict = {}
  self.battleProfilerJson = {}
  self.isCheckedActionDict = {}
  local startProfilerSucc = true
  if profilerType == BattleProfilerType.Seamless then
    self.battleName = "\230\142\165\232\167\166\232\191\155\229\133\165\230\136\152\230\150\151"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartWildSeamlessBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.ThrowBall then
    self.battleName = "\230\138\149\230\142\183\232\191\155\229\133\165\230\136\152\230\150\151"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartWildThrowBallBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.NPCEnter then
    self.battleName = "NPC\229\175\185\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartNPCBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.NpcChallenge then
    self.battleName = "\229\137\167\229\156\186\230\136\152\230\150\151"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartNPCChallengeProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.WeeklyChallenge then
    self.battleName = "\229\145\168\233\170\140\232\175\129\231\142\169\230\179\149"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartWeeklyChallengeProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.FlowerEnter then
    self.battleName = "\232\138\177\231\167\141\230\136\152\230\150\151"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartFlowerBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.LegendaryBattle then
    self.battleName = "\228\188\160\232\175\180\231\178\190\231\129\181\230\136\152\230\150\151"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartLegendaryBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.FinalBattle then
    self.battleName = "\230\156\128\231\187\136\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartFinalBattleProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.LeaderEnter then
    self.battleName = "\233\166\150\233\162\134\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartLeaderProfiler()
    self:SetRecordClickState(true)
  elseif profilerType == BattleProfilerType.PVPRank then
    self.battleName = "PVP\230\142\146\228\189\141"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartPVPRankProfiler()
    self:SetRecordClickState(false)
  elseif profilerType == BattleProfilerType.PVPFriend then
    self.battleName = "PVP\229\165\189\229\143\139\229\175\185\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartPVPRankProfiler()
    self:SetRecordClickState(false)
  elseif profilerType == BattleProfilerType.PVPFate then
    self.battleName = "PVP\229\145\189\232\191\144\229\175\185\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartPVPRankProfiler()
    self:SetRecordClickState(false)
  elseif profilerType == BattleProfilerType.PVPSpeed then
    self.battleName = "PVP\230\158\129\233\128\159\229\175\185\230\136\152"
    self:ConstructJson(self.battleType, self.battleID, self.battleName)
    self:StartPVPRankProfiler()
    self:SetRecordClickState(false)
  else
    self:SetRecordClickState(true)
    Log.Error("\230\178\161\230\156\137\230\179\168\229\134\140\230\136\152\230\150\151\231\177\187\229\158\139:", profilerType)
    startProfilerSucc = false
    return
  end
  self:EnterClickState()
end

function BattleProfiler:GetBattleProfilerData(battleType, battleID)
  if not self.battleProfilerDict[battleType] then
    self.battleProfilerDict[battleType] = {}
  end
  if not self.battleProfilerDict[battleType][battleID] then
    self.battleProfilerDict[battleType][battleID] = {}
    self.battleProfilerDict[battleType][battleID].intervals = {}
    self.battleProfilerDict[battleType][battleID].actions = {}
  end
  return self.battleProfilerDict[battleType][battleID]
end

function BattleProfiler:GetJsonData(battleType, battleID)
  for i = 1, #self.battleProfilerJson do
    if self.battleProfilerJson[i].BattleType == battleType and self.battleProfilerJson[i].BattleID == battleID then
      return self.battleProfilerJson[i]
    end
  end
  return nil
end

function BattleProfiler:GetInterval(battleType, battleID)
  local intervals = self:GetJsonData(battleType, battleID).Intervals
  return intervals[#intervals]
end

function BattleProfiler:IsIntervalDone(battleType, battleID)
  local interval = self:GetInterval(battleType, battleID)
  if not interval then
    self:StartInterval(battleType, battleID, self.nameLessStr)
  end
  return self:GetInterval(battleType, battleID).isDone
end

function BattleProfiler:AutoStopNamelessInterval(battleType, battleID)
  local interval = self:GetInterval(battleType, battleID)
  if interval and interval.IntervalName == self.nameLessStr then
    interval.isDone = true
  end
end

function BattleProfiler:StartInterval(battleType, battleID, intervalName)
  table.insert(self:GetJsonData(battleType, battleID).Intervals, {
    bTime = UE4.UNRCStatics.GetMilliSeconds(),
    isDone = false,
    Actions = {},
    IntervalName = intervalName
  })
end

function BattleProfiler:StopInterval(battleType, battleID)
  self:GetInterval(battleType, battleID).isDone = true
  self:GetInterval(battleType, battleID).eTime = UE4.UNRCStatics.GetMilliSeconds()
  if self:GetInterval(battleType, battleID).bTime then
    self:GetInterval(battleType, battleID).costTime = self:GetInterval(battleType, battleID).eTime - self:GetInterval(battleType, battleID).bTime
  end
end

function BattleProfiler:InsertAction(battleType, battleID, actionData)
  if self:IsIntervalDone(battleType, battleID) then
    self:StartInterval(battleType, battleID, self.nameLessStr)
  end
  table.insert(self:GetInterval(battleType, battleID).Actions, actionData)
end

function BattleProfiler:PrintProfiler()
  if not self.isEnable then
    return
  end
  for battleType, v in pairs(self.battleProfilerDict) do
    for battleID, battleProfilerData in pairs(v) do
      for i = 1, #battleProfilerData.intervals do
        local interval = battleProfilerData.intervals[i]
        Log.Debug("BattleProfiler Interval:", interval.intervalName, interval.costTime)
      end
      for i = 1, #battleProfilerData.actions do
        local action = battleProfilerData.actions[i]
        Log.Debug("BattleProfiler Action:", action.actionName, action.costTime)
      end
    end
  end
  self:SaveJson()
end

function BattleProfiler:SaveJson()
  local rapidjson = require("rapidjson")
  local dumpTable = {}
  table.deepCopy(self.battleProfilerJson, dumpTable, false)
  local totalTime = 0
  for battleType, n in pairs(dumpTable) do
    for i = 1, #n.Intervals do
      local interval = n.Intervals[i]
      local needCalcCostTime = false
      local costTime = 0
      if not interval.costTime then
        needCalcCostTime = true
      end
      for m = 1, #interval.Actions do
        local action = interval.Actions[m]
        if action.costTime then
          costTime = costTime + action.costTime
        end
      end
      interval.isDone = nil
      if needCalcCostTime then
        interval.costTime = costTime
      end
      totalTime = totalTime + interval.costTime
    end
    n.TotalTime = totalTime
  end
  local JsonUtils = require("Common.JsonUtils")
  local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), os.date("%m-%d_%H_%M_%S_BattleProfiler"))
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  local Content = rapidjson.encode(dumpTable, {pretty = true, sort_keys = true})
  local Success = UE4.UNRCStatics.WriteToFile(File, Content)
end

function BattleProfiler:RegisterFsm(battleFsm)
  self.battleFsm = battleFsm
  if self:IsJsonConstruct(self.battleType, self.battleID) then
    self:RegisterFsmEvent()
  end
end

function BattleProfiler:RegisterFsmEvent()
  if self.battleFsm then
    self.battleFsm:RegisterEvent(FsmEnum.Events.EnterState, self, self.OnEnterState)
    self.battleFsm:RegisterEvent(FsmEnum.Events.EnterAction, self, self.OnEnterAction)
    self.battleFsm:RegisterEvent(FsmEnum.Events.FinishAction, self, self.OnFinishAction)
    self.battleFsm:RegisterEvent(FsmEnum.Events.ExitAction, self, self.OnExitAction)
  end
end

function BattleProfiler:LeaveBattle()
  if self.isEnable then
    self:UnRegisterFsm()
    self:PrintProfiler()
    self:ClearCheckPoint()
  end
end

function BattleProfiler:UnRegisterFsm()
  self:UnRegisterFsmEvent()
  self.battleFsm = nil
end

function BattleProfiler:UnRegisterFsmEvent()
  if self.battleFsm then
    self.battleFsm:RemoveEvent(FsmEnum.Events.EnterState, self, self.OnEnterState)
    self.battleFsm:RemoveEvent(FsmEnum.Events.EnterAction, self, self.OnEnterAction)
    self.battleFsm:RemoveEvent(FsmEnum.Events.FinishAction, self, self.OnFinishAction)
    self.battleFsm:RemoveEvent(FsmEnum.Events.ExitAction, self, self.OnExitAction)
  end
end

function BattleProfiler:OnEnterState(Fsm, State)
  self.curState = State:GetName()
end

function BattleProfiler:OnEnterAction(Fsm, FsmAction)
  Log.Debug("BattleProfiler OnEnterAction:", FsmAction:GetName())
  if self.stopRecordActionTime then
    return
  end
  local boo = self:IsHitIntervalBegin(self.curState, FsmAction:GetName())
  if not boo then
  end
  local action = self:GetAction(FsmAction.state:GetName(), FsmAction:GetName())
  action.bTime = UE4.UNRCStatics.GetMilliSeconds()
  self:InsertAction(self.battleType, self.battleID, action)
end

function BattleProfiler:OnFinishAction(Fsm, FsmAction)
  Log.Debug("BattleProfiler OnFinishAction:", self.curState, FsmAction:GetName())
  if self:MarkActionIsChecked(self.curState, FsmAction:GetName()) then
    return
  end
  if self.stopRecordActionTime then
    return
  end
  local action = self:GetAction(FsmAction.state:GetName(), FsmAction:GetName())
  action.eTime = UE4.UNRCStatics.GetMilliSeconds()
  if action.bTime then
    action.costTime = action.eTime - action.bTime
  else
    action.costTime = 0
  end
  local boo = self:IsHitIntervalEnd(self.curState, FsmAction:GetName())
  if boo then
  end
  self:IsHitStopRecordActionPos(self.curState, FsmAction:GetName())
end

function BattleProfiler:OnExitAction(Fsm, FsmAction)
  if self:MarkActionIsChecked(self.curState, FsmAction:GetName()) then
    return
  end
  self:IsHitStopRecordActionPos(self.curState, FsmAction:GetName())
  local action = self:GetAction(FsmAction.state:GetName(), FsmAction:GetName())
  if not action.costTime and action.bTime then
    action.eTime = UE4.UNRCStatics.GetMilliSeconds()
    action.costTime = action.eTime - action.bTime
  end
end

function BattleProfiler:MarkActionIsChecked(stateName, actionName)
  if self.isCheckedActionDict[stateName] and self.isCheckedActionDict[stateName][actionName] then
    return true
  end
  if not self.isCheckedActionDict[stateName] then
    self.isCheckedActionDict[stateName] = {}
  end
  self.isCheckedActionDict[stateName][actionName] = 1
  return false
end

function BattleProfiler:GetAction(stateName, actionName)
  local actions = self:GetInterval(self.battleType, self.battleID).Actions
  for i = 1, #actions do
    if actions[i].stateName == stateName and actions[i].actionName == actionName then
      Log.Debug("BattleProfiler GetAction succ:", actionName)
      return actions[i]
    end
  end
  Log.Debug("BattleProfiler GetAction fail:", actionName)
  local action = {}
  action.stateName = stateName
  action.actionName = actionName
  return action
end

function BattleProfiler:MarkInterval(battleType, battleID, intervalName, bStateName, bActionName, eStateName, eActionName)
  local d = {}
  d.intervalName = intervalName
  d.bStateName = bStateName
  d.eStateName = eStateName
  d.bActionName = bActionName
  d.eActionName = eActionName
  d.beginTimeStamp = 0
  d.endTimeStamp = 0
  d.costTime = 0
  table.insert(self:GetBattleProfilerData(battleType, battleID).intervals, d)
end

function BattleProfiler:MarkStopActionRecordPos(battleType, battleID, stopRecordState, stopRecordAction)
  self:GetBattleProfilerData(battleType, battleID).stopRecordState = stopRecordState
  self:GetBattleProfilerData(battleType, battleID).stopRecordAction = stopRecordAction
end

function BattleProfiler:ClearAllMarker()
end

function BattleProfiler:IsHitIntervalBegin(stateName, actionName)
  local lst = self:GetBattleProfilerData(self.battleType, self.battleID).intervals
  if lst then
    for i = 1, #lst do
      local d = lst[i]
      if stateName == d.bStateName and actionName == d.bActionName then
        Log.Msg("\233\152\182\230\174\181:", d.intervalName, "\229\188\128\229\167\139\230\160\135\232\174\176")
        d.beginTimeStamp = UE4.UNRCStatics.GetMilliSeconds()
        self:StartInterval(self.battleType, self.battleID, d.intervalName)
        return true
      end
    end
  end
  return false
end

function BattleProfiler:IsHitIntervalEnd(stateName, actionName)
  local lst = self:GetBattleProfilerData(self.battleType, self.battleID).intervals
  if lst then
    for i = 1, #lst do
      local d = lst[i]
      if stateName == d.eStateName and actionName == d.eActionName then
        Log.Msg("\233\152\182\230\174\181:", d.intervalName, "\231\187\147\230\157\159\230\160\135\232\174\176")
        d.endTimeStamp = UE4.UNRCStatics.GetMilliSeconds()
        d.costTime = d.endTimeStamp - d.beginTimeStamp
        self:StopInterval(self.battleType, self.battleID)
        return true
      end
    end
  end
  return false
end

function BattleProfiler:IsHitStopRecordActionPos(stateName, actionName)
  if self:GetBattleProfilerData(self.battleType, self.battleID).stopRecordState == stateName and self:GetBattleProfilerData(self.battleType, self.battleID).stopRecordAction == actionName then
    self.stopRecordActionTime = true
  end
end

function BattleProfiler:ConstructJson(battleType, battleID, battleName)
  local data = {}
  data.BattleType = battleType
  data.BattleID = battleID
  data.Name = battleName
  data.Intervals = {}
  table.insert(self.battleProfilerJson, data)
  self.stopRecordActionTime = false
end

function BattleProfiler:IsJsonConstruct(battleType, battleID)
  for i = 1, #self.battleProfilerJson do
    local data = self.battleProfilerJson[i]
    if data.BattleType == battleType and data.BattleID then
      return true
    end
  end
  return false
end

function BattleProfiler:StartWildSeamlessBattleProfiler()
  if _G.EnableSpeedUpNearbyEnterBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "EnterPerform", "PreEnterBattlePerformAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "EnterPerform", "BattlePlayBattleStandAnimAction", "NearbyEnter", "BattleCheckPrepareResIsOverAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\181\132\230\186\144\229\138\160\232\189\189\233\152\182\230\174\181", "NearbyEnter", "HideBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "EnterPerform", "BattleContactPerformInWorldAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "EnterPerform", "BattlePlayBattleStandAnimAction", "EnterPerform", "BattlePlayBattleStandAnimAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\181\132\230\186\144\229\138\160\232\189\189\233\152\182\230\174\181", "EnterPerform", "BattleAfterPerformAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartWildThrowBallBattleProfiler()
  if _G.EnableSpeedUpNearbyEnterBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "EnterPerform", "BattlePrepareWithoutWaitAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "EnterPerform", "BattleStopBattleStandAnimation", "ThrowBallEnter", "BattlePlayPetStartBattleAnimAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\181\132\230\186\144\229\138\160\232\189\189\233\152\182\230\174\181", "ThrowBallEnter", "BattleFriendAssistEnterAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "EnterPerform", "BattleContactPerformInWorldAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "EnterPerform", "BattlePlayBattleStandAnimAction", "EnterPerform", "BattlePlayBattleStandAnimAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\181\132\230\186\144\229\138\160\232\189\189\233\152\182\230\174\181", "EnterPerform", "BattleAfterPerformAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartNPCBattleProfiler()
  if _G.EnableSpeedUpEnterBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "PvePreInit", "BattlePreparePveResAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "PvePreInit", "BattlePvePlayBattleStandAnimAction", "PvePreInit", "BattleHideScenePetAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "PvePreInit", "BattleMultiPvPEnter2Action", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "PVERoleShow", "BattleHideScenePetAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "PVERoleShow", "BattleMultiPvPEnter1Action", "PVERoleShow", "BattleMultiPvPEnter1Action")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "PVERoleShow", "ShowBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartWeeklyChallengeProfiler()
  self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "Init", "PreEnterBattlePerformAction")
  self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "Init", "PreProcessEnterBattleAction", "WeeklyChallengeEnter", "BattleMultiPvPEnter1Action")
  self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "WeeklyChallengeEnter", "BattleMultiPvPEnter2Action", "RoundSelect", "BattleOpenPredictionAction")
  self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
end

function BattleProfiler:StartNPCChallengeProfiler()
  self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "Init", "PreEnterBattlePerformAction")
  self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "Init", "PreProcessEnterBattleAction", "NpcChallengeEnter", "BattleMultiPvPEnter1Action")
  self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "NpcChallengeEnter", "ShowBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
  self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
end

function BattleProfiler:StartFlowerBattleProfiler()
  if _G.EnableSpeedUpEnterBeastTeamBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "TeamBloodEnter", "BattlePreloadMainWindowAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "TeamBloodEnter", "PreEnterBloodTeamBattlePerformAction", "TeamBloodEnter", "CloseBlackScreenAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "TeamBloodEnter", "BattlePlayTeamBossEffectAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "Init", "PreEnterBattlePerformAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "Init", "PreProcessEnterBattleAction", "TeamBloodEnter", "CloseBlackScreenAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "TeamBloodEnter", "BattlePlayTeamBossEffectAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartPVPRankProfiler()
  if _G.EnableSpeedUpEnterPVPBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "PvpPreInit", "BattleCheckBattlePlayerOverAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "PvpPreInit", "BattleMultiPvPEnter1Action", "PvpPreInit", "BattleHideScenePetAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "PvpPreInit", "BattleMultiPvPEnter2Action", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "PVPEnter", "BattlePvPCloseAirWallAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "PVPEnter", "BattleMultiPvPEnter1Action", "PVPEnter", "BattleMultiPvPEnter1Action")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "PVPEnter", "ShowBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartLeaderProfiler()
  if _G.EnableSpeedUpEnterLeaderBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "WorldLeaderRoleShow", "BattleHideScenePetAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "WorldLeaderRoleShow", "BattleWorldLeaderShowAction", "WorldLeaderRoleShow", "BattleWorldLeaderShowAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "WorldLeaderRoleShow", "ShowBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "WorldLeaderRoleShow", "BattleHideScenePetAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "WorldLeaderRoleShow", "BattleWorldLeaderShowAction", "WorldLeaderRoleShow", "BattleWorldLeaderShowAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "WorldLeaderRoleShow", "ShowBattlePawnsAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:StartFinalBattleProfiler()
  self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "Init", "BattlePreloadResAction")
  self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "Init", "PreEnterBattlePerformAction", "FinalBattleEnter", "BattleFinalBattleShowAction")
  self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "FinalBattleEnter", "BattleOpenCriticalRedPanelAction", "RoundSelect", "BattleOpenPredictionAction")
  self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
end

function BattleProfiler:StartLegendaryBattleProfiler()
  if _G.EnableSpeedUpEnterBeastTeamBattle then
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "BeastPreInit", "BeastPreloadStart")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "BeastPreInit", "BeastPreloadField", "PrePlay", "BattlePreloadTurnPlayResAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "PrePlay", "BattlePrePlayAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  else
    self:MarkInterval(self.battleType, self.battleID, "\229\147\141\229\186\148\232\128\151\230\151\182", self.ClickState, self.ClickAction, "Init", "BattlePreloadResAction")
    self:MarkInterval(self.battleType, self.battleID, "\229\138\160\232\189\189\232\128\151\230\151\182", "Init", "PreEnterBattlePerformAction", "TeamBeastEnter", "BattleTeamBeastEnterAction")
    self:MarkInterval(self.battleType, self.battleID, "\230\136\152\229\156\186\232\161\168\230\188\148\233\152\182\230\174\181\232\128\151\230\151\182", "TeamBeastEnter", "BattleReconnectShowEnterBuffAction", "RoundSelect", "BattleOpenPredictionAction")
    self:MarkStopActionRecordPos(self.battleType, self.battleID, "RoundSelect", "BattleOpenPredictionAction")
  end
end

function BattleProfiler:CheckIsReconnect()
  if BattleManager.battleRuntimeData.battleStartParam:IsReconnect() then
    local showTip = _G.DataConfigManager:GetLocalizationConf("Reconnect_Battle_Tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, showTip)
    return true
  end
  return false
end

function BattleProfiler:GetTime()
  return UE4.UNRCStatics.GetMilliSeconds()
end

function BattleProfiler:EnterClickState()
  self.curState = self.ClickState
  local fsmAction = FsmAction()
  fsmAction.name = self.ClickAction
  fsmAction.state = FsmState("Init")
  self:OnEnterAction(nil, fsmAction)
  self:OnFinishAction(nil, fsmAction)
  local action = self:GetAction(fsmAction.state:GetName(), fsmAction:GetName())
  local bTime = 0
  local eTime = 0
  if action then
    eTime = self.checkPointLst[#self.checkPointLst].time
    action.eTime = eTime
    if self.checkPointLst[#self.checkPointLst - 1] then
      bTime = self.checkPointLst[#self.checkPointLst - 1].time
      if 0 == bTime or "" == bTime or not bTime then
        self.checkPointLst[#self.checkPointLst - 1].time = eTime
        bTime = eTime
      end
      action.bTime = bTime
    else
      action.bTime = eTime
      bTime = eTime
    end
    if self.isRecordClickState then
      action.costTime = eTime - bTime
    else
      action.bTime = eTime
      action.costTime = 0
    end
  end
  local interval = self:GetInterval(self.battleType, self.battleID)
  if self.isRecordClickState then
    interval.bTime = bTime
  else
    interval.bTime = eTime
  end
end

return BattleProfiler

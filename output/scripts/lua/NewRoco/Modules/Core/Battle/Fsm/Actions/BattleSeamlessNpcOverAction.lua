local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattlePlayAnimBaseAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattlePlayAnimBaseAction")
local Base = BattlePlayAnimBaseAction
local BattleSeamlessNpcOverAction = Base:Extend("BattleSeamlessNpcOverAction")
FsmUtils.MergeMembers(BattleActionBase, BattleSeamlessNpcOverAction, {})

function BattleSeamlessNpcOverAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.LevelHelper = _G.LevelHelper
end

function BattleSeamlessNpcOverAction:OnEnter()
  Log.Debug("BattleSeamlessNpcOverAction OnEnter ")
  self.result = self.BattleManager.battleRuntimeData.battleExitParam:GetLastTurnSettleResult()
  self.result = BattleUtils.IsBattleWin(self.result)
  self.needShowSceneTrees = false
  self.isSceneTreesShow = false
  if BattleUtils.IsSkipRecycleBall() then
    Log.Debug("BattleSeamlessNpcOverAction PVE Lose")
    local asyncData = {
      owner = self,
      callback = self.OnBlackShown
    }
    NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenLoading)
  elseif BattleUtils.IsPve() or BattleUtils.EndBattleByNpc() then
    self.needShowSceneTrees = true
    if self.result then
      if BattleUtils.ContainTaskPerformControl(Enum.TaskBattlePerformanceControl.TBPC_EXIT_SKIP) then
        self:Finish()
      else
        Log.Debug("BattlePveNpcLeaveAction PVE Win!")
        local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        self:TryGetNpc()
        _G.BattleManager.vBattleField:HideAllWaterPlatforms()
        _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, false)
        self:Play(self.npc, {
          Player.viewObj
        }, BattleConst.Define.PveNPCLeaveBattleWin, false)
        NRCModeManager:DoCmd(BattleUIModuleCmd.HideMainWindow, false, true)
      end
    else
      Log.Debug("BattleSeamlessNpcOverAction PVE Lose")
      local asyncData = {
        owner = self,
        callback = self.OnBlackShown
      }
      NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenLoading)
    end
  else
    Log.Debug("BattleSeamlessNpcOverAction: not PVE")
    if BattleUtils.IsDeepWater() and BattleExitHelper.IsFinishSeamless() then
      BattleExitHelper.ClearFinishSeamlessFlag()
      BattleExitHelper.SetFinishHandleSeamless()
      self.fsm:SendEvent(BattleEvent.EnterPureBlackOut)
      return
    end
    self:Finish()
  end
end

function BattleSeamlessNpcOverAction:TryGetNpc()
  self.npc, self.id = self.BattleManager.battleRuntimeData:GetNPCByIdx(self.BattleManager.battleRuntimeData.lastDeadNpcIdx)
  if not self.npc or not self.npc.viewObj then
    Log.Error("BattleManager:TryGetNpc Can't Restore TraceNPC\239\188\140\229\166\130\230\158\156\230\152\175\230\181\139\232\175\149\233\157\162\230\157\191\232\191\155\229\133\165\230\136\152\230\150\151\230\151\160\232\167\134\230\173\164\230\138\165\233\148\153")
    self:Finish()
  end
end

function BattleSeamlessNpcOverAction:CustomCastG6BeforePlay(skillObj)
  local allNPC = self.BattleManager.battleRuntimeData:GetAllNPCs()
  local characters = {}
  local curIdx = 9
  for i, v in ipairs(allNPC) do
    local npc = v.npc
    if v.id ~= self.id and npc.viewObj then
      characters[curIdx] = npc.viewObj
      curIdx = curIdx + 1
    end
  end
  skillObj:SetCharacters(characters)
end

function BattleSeamlessNpcOverAction:PostStart(eventName)
  self:UpdateVisibility()
end

function BattleSeamlessNpcOverAction:UpdateVisibility()
  local npcInfos = self.BattleManager.battleRuntimeData:GetAllNPCs()
  local isNpcFound = false
  if npcInfos then
    for _, npcInfo in ipairs(npcInfos) do
      local npc = npcInfo.npc
      if npc and npc.viewObj then
        npc:SetVisibleForBattleReason(true)
        isNpcFound = true
      end
    end
  else
    Log.Error("no npc")
  end
  if not isNpcFound then
    Log.Error("BattleManager:UpdateVisibility Can't Restore TraceNPC\239\188\140\229\166\130\230\158\156\230\152\175\230\181\139\232\175\149\233\157\162\230\157\191\232\191\155\229\133\165\230\136\152\230\150\151\230\151\160\232\167\134\230\173\164\230\138\165\233\148\153")
    self:Finish()
  end
  _G.BattleManager.battlePawnManager:HideAll(false)
  self:ShowSceneTrees()
  BattleExitHelper.SetFinishPveSeamless()
  NRCModeManager:DoCmd(PlayerModuleCmd.HIDE_ALL, false)
end

function BattleSeamlessNpcOverAction:OnBlackShown()
  _G.NRCModuleManager:DoCmd(PlayerModuleCmd.HIDE_ALL, true)
  self:UpdateVisibility()
  self:Finish()
end

function BattleSeamlessNpcOverAction:ShowSceneTrees()
  if not self.needShowSceneTrees then
    return
  end
  if self.isSceneTreesShow then
    return
  end
  self.isSceneTreesShow = true
  local ShowSceneTreesDelegate = self:GetProperty(BattleConst.FsmVarNames.ShowSceneTreesDelegate)
  if ShowSceneTreesDelegate then
    ShowSceneTreesDelegate:Invoke()
  end
end

function BattleSeamlessNpcOverAction:OnExit()
end

function BattleSeamlessNpcOverAction:OnBlackScreenRemoved()
  BattleUtils.FocusPlayer()
  self:Finish()
end

function BattleSeamlessNpcOverAction:AdjustCamera(event, skill)
  if BattleUtils.IsPve() and self.result then
    local Player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if Player and skill then
      local Controller = Player:GetUEController()
      local Blackboard = skill:GetBlackboard()
      if Blackboard and Controller then
        local rotator = UE.FRotator(0, 0, 90)
        local Camera = Blackboard:GetValueAsObject("camActor_0001")
        if Camera then
          rotator = Camera:K2_GetActorRotation()
          Controller:SetControlRotation(rotator)
        end
      end
    end
    local isSucess = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.RestoreCamera, 0.8, nil, 2)
    if not isSucess then
      BattleUtils.FocusPlayer(BattleConst.NPCOverBlendCamTime)
    end
  end
end

function BattleSeamlessNpcOverAction:OnFinish()
  Base.OnFinish(self)
  self:ShowSceneTrees()
end

return BattleSeamlessNpcOverAction

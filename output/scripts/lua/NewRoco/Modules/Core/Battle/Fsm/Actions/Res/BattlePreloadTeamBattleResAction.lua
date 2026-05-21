local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local Base = BattleActionBase
local BattlePreloadTeamBattleResAction = Base:Extend("BattlePreloadTeamBattleResAction")
local MaxCheckTime = 20
local MaxFindTime = 20
FsmUtils.MergeMembers(Base, BattlePreloadTeamBattleResAction, {})

function BattlePreloadTeamBattleResAction:OnEnter()
  self.isLevelLoad = false
  self.waitTime = 0
  _G.BattleLevelHelper:LoadBloodTeamLevelStream()
  self:OnTick(0)
end

function BattlePreloadTeamBattleResAction:OnTick(DeltaTime)
  self.waitTime = self.waitTime + DeltaTime
  if self.isLevelLoad then
    self:FindLevelBattleCenter()
    return
  end
  if not _G.BattleLevelHelper:GetIsLevelLoad() then
    return
  end
  local skillPath = BattleUtils.IsPlayerCanSeeTarget() and BattleConst.TeamBloodPerEnterBattle or BattleConst.BloodTeamEnterFarBattle
  if BattleSkillManager:IsResLoaded(skillPath) then
    _G.BattleManager:InitBattleField()
    self.isLevelLoad = true
    self:FindLevelBattleCenter()
    return
  end
end

function BattlePreloadTeamBattleResAction:FindLevelBattleCenter()
  local BattleCenterTable = UE4.UGameplayStatics.GetAllActorsOfClassWithTag(_G.UE4Helper.GetCurrentWorld(), UE4.AActor, "LevelBattleCenter"):ToTable()
  if BattleCenterTable and #BattleCenterTable > 0 then
    if #BattleCenterTable > 1 then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\137\190\229\136\176\229\164\154\228\184\170LevelBattleCenter\239\188\129\239\188\129\239\188\129 \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\231\154\132\233\128\137\231\130\185\230\152\175\229\144\166\230\173\163\231\161\174!!!")
    end
    local BattleCenter = BattleCenterTable[1]
    self.npcPos = BattleCenter:Abs_K2_GetActorLocation()
    _G.BattleManager.battleRuntimeData.TeleportBattleCenter = self.npcPos
    _G.BattleManager.battleRuntimeData.ServerBattleRotate = BattleCenter:K2_GetActorRotation().Yaw
    _G.BattleManager.battleRuntimeData.teamBattleCenterTrans = BattleCenter:Abs_GetTransform()
    self:CheckGround()
  elseif self.waitTime > MaxFindTime then
    Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\230\136\152\229\156\186\228\184\173\229\191\131\231\130\185")
    self.waitTime = 0
    self:CheckGround()
  end
end

function BattlePreloadTeamBattleResAction:CheckGround()
  if self.waitTime > MaxCheckTime or self:FindPointAtGround(self.npcPos, true) then
    if self.waitTime > MaxCheckTime then
      Log.Error("ZGX \230\136\152\229\156\186\228\188\160\233\128\129\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176\229\156\176\233\157\162\239\188\129\239\188\129\239\188\129 \232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\231\154\132\233\128\137\231\130\185\230\152\175\229\144\166\230\173\163\231\161\174!!! \230\156\172\229\156\186\230\136\152\230\150\151\231\154\132\233\128\137\231\130\185\228\184\186 ", self.npcPos)
    end
    BattleManager.battleRuntimeData.battleStartEnemyPos = self.npcPos
    self:Finish()
  end
end

function BattlePreloadTeamBattleResAction:FindPointAtGround(pos, isWrite)
  local findPos, _, isHit = LineTraceUtils.GetPointValidLocationByLine(pos)
  if findPos and isHit then
    if isWrite then
      pos.X = findPos.X
      pos.Y = findPos.Y
      pos.Z = findPos.Z
    end
    return true
  else
    return false
  end
end

return BattlePreloadTeamBattleResAction

local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleFinishPerformPlayer = BattlePlayerBase:Extend()

function BattleFinishPerformPlayer:Ctor()
  BattlePlayerBase.Ctor(self)
end

function BattleFinishPerformPlayer:Reset()
end

function BattleFinishPerformPlayer:Play(performNode)
  self:Reset()
  self.performNode = performNode
  self:CallTimeDilation()
end

function BattleFinishPerformPlayer:CallTimeDilation()
  _G.NRCAudioManager:PlaySound2DAuto(1503, "BattlePetDiePlayer:OnLastHit")
  self.LastHitTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.ActionPerform, UE.EBulletTimeChangeType.Change, _G.UE4Helper.GetCurrentWorld(), BattleConst.Show.HitTimeDilation, UE.EBulletTimeChangeType.None, {}, 1)
  self:SafeDelaySeconds("d_RestoreTimeDilation", BattleConst.Show.HitTimeDilationTime, self.OnFinish, self)
end

function BattleFinishPerformPlayer:RestoreTimeDilation()
  if self.LastHitTimeId and self.LastHitTimeId > 0 then
    _G.BattleBulletTimeManager:LeaveBulletTime(self.LastHitTimeId)
    self.LastHitTimeId = -1
  end
end

function BattleFinishPerformPlayer:OnFinish()
  self:RestoreTimeDilation()
  self.performNode:PerformComplete()
end

return BattleFinishPerformPlayer

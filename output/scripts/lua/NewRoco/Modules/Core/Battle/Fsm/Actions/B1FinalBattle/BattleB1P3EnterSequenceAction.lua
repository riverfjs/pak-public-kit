local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleActionBase
local BattleB1P3EnterSequenceAction = Base:Extend("BattleB1P3EnterSequenceAction")
local MovieConfId = 42
FsmUtils.MergeMembers(Base, BattleB1P3EnterSequenceAction, {})

function BattleB1P3EnterSequenceAction:OnEnter()
  if _G.BattleManager.debugEnv.closeB1FBP3MP4 then
    self:Finish()
    return
  end
  self.fsm:Pause()
  self.timeout = 99999999
  local param = {}
  param.Conf = _G.DataConfigManager:GetMovieConf(MovieConfId)
  param.Caller = self
  param.Callback = self.OnVideoFinish
  param.CustomBlackScreen = true
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.PlayVideo, param)
end

function BattleB1P3EnterSequenceAction:OnVideoFinish()
  if self.fsm then
    self.fsm:Resume()
  else
    Log.Warning("BattleB1P3EnterSequenceAction fsm is nil")
  end
  NRCModuleManager:DoCmd(BlackScreenModuleCmd.OpenGlobalBlackScreenIfNeed, -100, false)
  self:Finish()
end

return BattleB1P3EnterSequenceAction

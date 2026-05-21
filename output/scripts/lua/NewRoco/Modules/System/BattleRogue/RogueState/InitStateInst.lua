local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local InitStateInst = Base:Extend("InitStateInst")

function InitStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
end

function InitStateInst:GetServerReq()
  local Req = ProtoMessage:newZoneGrassTrialGetInfoReq()
  return ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_GET_INFO_REQ, Req
end

function InitStateInst:GetPreLoadResList()
end

function InitStateInst:OnResReady(LoadedAssets, Rsp)
  self.Context.CacheTrialData = Rsp.trial_data
  if Rsp.trial_data then
    self.Context:UpdateChallengeInfo(Rsp.trial_data.challenge_data)
  end
  self:OpenPanel("Entrance")
  self:SetOtherCharacterHide(true)
end

function InitStateInst:OnDoEnter()
end

function InitStateInst:OnEnter()
end

function InitStateInst:OnExit()
  if -1 == self.Direction then
    self:HidePanel("Entrance")
  else
    self:FoldPanel("Entrance")
  end
end

return InitStateInst

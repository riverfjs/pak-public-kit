local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ChallengeLobbyStateInst = Base:Extend("ChallengeLobbyStateInst")

function ChallengeLobbyStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
  self.OpenRogueMainPanel = nil
end

function ChallengeLobbyStateInst:OnDoEnter()
  self:CloseAllFlowPanels()
  self:SetOtherCharacterHide(false)
  self:GetBindModule().Data:ClearCacheTrialData()
  self.OpenRogueMainPanel = au.CreateOpenPanelFuture("HerbologyBadgeMain", 5)
  _G.NRCModuleManager:GetModule("MainUIModule"):SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.RogueLobbyMain, false, true)
end

local CustomThunks = {}

function ChallengeLobbyStateInst:GetCustomThunks()
  table.clear(CustomThunks)
  if self.OpenRogueMainPanel then
    CustomThunks.OpenRogueMainPanel = self.OpenRogueMainPanel
  end
  return CustomThunks
end

function ChallengeLobbyStateInst:GetServerReq()
  return Base.GetServerReq(self)
end

function ChallengeLobbyStateInst:OnReceiveRsp()
end

function ChallengeLobbyStateInst:OnEnter()
end

function ChallengeLobbyStateInst:OnExit()
end

return ChallengeLobbyStateInst

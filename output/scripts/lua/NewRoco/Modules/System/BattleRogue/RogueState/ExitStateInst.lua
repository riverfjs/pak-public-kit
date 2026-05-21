local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local RogueStateEnum = require("NewRoco.Modules.System.BattleRogue.RogueModuleEnum")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ExitStateInst = Base:Extend("InitStateInst")

function ExitStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
end

function ExitStateInst:OnDoEnter()
  self:CloseAllFlowPanels()
  self:SetOtherCharacterHide(false)
end

function ExitStateInst:OnResReady(LoadedAssets, Rsp)
  _G.NRCModuleManager:GetModule("MainUIModule"):SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.LobbyMain, false, true)
  self:GetBindModule():CloseAllPanel()
end

function ExitStateInst:OnEnter()
end

function ExitStateInst:OnExit()
end

return ExitStateInst

local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ChallengeBattleStateInst = Base:Extend("ChallengeBattleStateInst")

function ChallengeBattleStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
end

function ChallengeBattleStateInst:OnDoEnter()
  self:CloseAllFlowPanels()
  local BindModule = self:GetBindModule()
  BindModule.Data:ClearCacheTrialData()
  if not BindModule:HasPanel("HerbologyBadgeMain") then
    self.OpenRogueMainPanel = au.CreateOpenPanelFuture("HerbologyBadgeMain", 5)
    _G.NRCModuleManager:GetModule("MainUIModule"):SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.RogueLobbyMain, false, true)
  end
  _G.NRCEventCenter:RegisterEvent(self.name, self, NPCModuleEvent.VIEW_SHELL_LOADED, self.HookNpcTickDist)
end

local BornDir = UE.FRotator(0, -90, 0)

function ChallengeBattleStateInst:OnResReady()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local PlayerController = Player:GetUEController()
  if Player and PlayerController then
    PlayerController:SetIsSideView(true)
    Player:SetActorRotation(BornDir)
    _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.AddFuncEntranceConstraints, "ChallengeBattleStateInst", Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP, self.DisablePlayerJump)
  else
    self:ErrorLog("Player or PlayerController is nil")
  end
end

function ChallengeBattleStateInst:RegisterAllNPC()
end

function ChallengeBattleStateInst:OnEnter()
end

function ChallengeBattleStateInst:OnExit()
  _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.RemoveFuncEntranceConstraints, Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP, self.DisablePlayerJump)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.HookNpcTickDist)
end

function ChallengeBattleStateInst:HookNpcTickDist(NPC)
  local MainOption = NPC.InteractionComponent:GetOptionByID(8600001)
  if MainOption and NPC.viewObj then
    NPC.viewObj:AddCustomTickDistance(MainOption.config.option_radius + 30)
  end
end

function ChallengeBattleStateInst:DisablePlayerJump()
  return true
end

return ChallengeBattleStateInst

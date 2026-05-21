local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local ShowHideBase = require("NewRoco.Modules.Core.NPC.ShowHide.ShowHideBase")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local Base = ShowHideBase
local DialogueShowHide = Base:Extend("DialogueShowHide")

function DialogueShowHide:Ctor()
  Base.Ctor(self)
  local Conf = _G.DataConfigManager:GetNrcAiGlobalConfigConf("dialogue_hidden_range")
  local R = Conf and Conf.num or 1000 or 1000
  self.Radius = R * R
end

function DialogueShowHide:GetReason()
  return 2
end

function DialogueShowHide:ShouldPauseFind()
  return true
end

function DialogueShowHide:ShouldPauseTick()
  return true
end

function DialogueShowHide:StartHide()
  self.CenterActor = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.GetDialogueCenter)
  if not self.CenterActor then
    self.CenterActor = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  end
  if self.CenterActor then
    self.CenterLocation = self.CenterActor:GetActorLocation()
  end
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true, UE4.EPlayerForceHiddenType.Cinematic)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local DialogueOption = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.GetCurDialogueOption)
  local bShowBoth = DialogueOption and DialogueOption.config and DialogueOption.config.show_holding_2p
  local bHideLocalPlayer = not bShowBoth and player and player:IsInTogetherMove() and player:IsTogetherMove2P()
  local bShowOtherPlayer = bShowBoth or player and player:IsInTogetherMove() and player:IsTogetherMove2P()
  if not bShowBoth and player and player:IsInTogetherMove() then
    player:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, false, PlayerModuleEvent.LinkReasonFlags.DIALOGUE)
  end
  if bHideLocalPlayer then
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_LOCAL_PLAYER, true, UE4.EPlayerForceHiddenType.Cinematic)
  end
  if bShowOtherPlayer then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player and other_player.viewObj then
      other_player.viewObj:SetHiddenMask(false, UE4.EPlayerForceHiddenType.Cinematic)
    end
    if other_player and other_player.hudComponent and bHideLocalPlayer then
      other_player.hudComponent:SetHeadWidgetRenderStatus(false, _G.MainUIModuleEnum.DisableHudOpSource.Dialogue)
    end
  end
  return true
end

function DialogueShowHide:CheckShouldHide(npc)
  if npc == self.CenterActor then
    self:ToggleHUD(npc, false)
    return false
  end
  if not npc then
    return false
  end
  if not npc.config then
    return false
  end
  local npcPos = npc:GetActorLocation()
  if not npcPos then
    Log.Error("CheckShouldHide\229\156\168\232\142\183\229\143\150Location\231\154\132\230\151\182\229\128\153\231\169\186\228\186\134!!!!!!!!!!!!!")
    if npc and npc.serverData and npc.serverData.base then
      Log.Error("\230\156\137\233\151\174\233\162\152\231\154\132NPC\230\152\175: ", npc.serverData.base.name, npc.serverData.base.actor_id)
    end
    return false
  end
  local Dist = UE.FVector.DistSquared(npcPos, self.CenterLocation)
  if Dist > self.Radius then
    return false
  end
  self:ToggleHUD(npc, false)
  if 1 ~= npc.config.can_hide_in_player_condition then
    return false
  end
  if not npc:IsTraceNpc() and npc:IsLocal() then
    return false
  end
  return true
end

function DialogueShowHide:EndHide()
  self.CenterActor = nil
  Base.EndHide(self)
end

function DialogueShowHide:StartShow()
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_ALL, false, UE4.EPlayerForceHiddenType.Cinematic)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() then
    player:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, true, PlayerModuleEvent.LinkReasonFlags.DIALOGUE)
  end
  if player and player:IsInTogetherMove() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player and other_player.hudComponent then
      other_player.hudComponent:SetHeadWidgetRenderStatus(true, _G.MainUIModuleEnum.DisableHudOpSource.Dialogue)
    end
  end
  return true
end

function DialogueShowHide:CheckShouldShow(npc)
  self:ToggleHUD(npc, true)
  return true
end

function DialogueShowHide:EndShow()
  self.CenterLocation = nil
  Base.EndShow(self)
end

function DialogueShowHide:ToggleHUD(npc, enable)
  local HUD = npc and npc.PetHUDComponent
  if HUD then
    HUD:SetRenderStatus(enable, MainUIModuleEnum.DisableHudOpSource.Dialogue)
  end
end

return DialogueShowHide

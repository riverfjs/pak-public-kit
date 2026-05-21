local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Base = NPCActionBase
local NPCActionDialogue = Base:Extend("NPCActionDialogue")
NPCActionDialogue:SetMemberCount(5)

function NPCActionDialogue.NeedRestoreAction(Info, OwnerNpc)
  if not OwnerNpc then
    Log.Warning("[NpcAction][Common][NPCActionDialogue] OwnerNpc is nil")
    return false
  end
  if not Info then
    return false
  end
  if Info.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.NotExecute then
    return false
  end
  if Info.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commited then
    return false
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    Log.Debug("Can't find local player")
    return false
  end
  if 0 == Player.serverData.attrs.hp then
    Log.DebugFormat("[NpcAction][Common][NPCActionDialogue] Player is dead %s", OwnerNpc:DebugNPCNameAndID())
    return false
  end
  if not Player:IsLogicStatus(_G.ProtoEnum.SpaceActorLogicStatus.SALS_INTERACTING) then
    Log.DebugFormat("[NpcAction][Common][NPCActionDialogue] Player not interacting %s", OwnerNpc:DebugNPCNameAndID())
    return false
  end
  local OwnerID = OwnerNpc:GetServerId()
  local ServerData = Player.serverData
  local AvatarInteract = ServerData and ServerData.avatar_interact
  local PlayerInteractNPCID = AvatarInteract and (AvatarInteract.interact_npc_id or 0) or 0
  if OwnerID ~= PlayerInteractNPCID then
    Log.DebugFormat("[NpcAction][Common][NPCActionDialogue] Npc id (%u) mismatch (%u)", OwnerID, PlayerInteractNPCID)
    return false
  end
  if Info.act_type == Enum.ActionType.ACT_BATTLE and Info.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing then
    return true
  end
  return false
end

function NPCActionDialogue.PostInit(Option, Action, Info, OwnerNpc)
  local NeedRestore = NPCActionDialogue.NeedRestoreAction(Info, OwnerNpc)
  if not NeedRestore then
    return
  end
  local Instance = NPCActionDialogue(Option, Action, Info, OwnerNpc)
  Instance.ShouldRestore = true
  Option.CurrentAction = Instance
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.RestoreDialogue, Option, Instance)
  return Instance
end

function NPCActionDialogue:UpdateInfo(Info, Reconnect)
  Base.UpdateInfo(self, Info, Reconnect)
  if not Reconnect then
    return
  end
  local NeedRestore = NPCActionDialogue.NeedRestoreAction(Info, self:GetOwnerNPC())
  if not NeedRestore then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.RestoreDialogue, self.Owner, self)
end

function NPCActionDialogue:Ctor(Owner, Config, Info)
  self.bIsSubmitting = false
  Base.Ctor(self, Owner, Config, Info)
  self.NeedModal = true
end

function NPCActionDialogue:OnNpcAction()
  if self.ShouldRestore then
    self:Log("\231\173\137\229\190\133\229\175\185\232\175\157\230\129\162\229\164\141\228\184\173")
    return false
  end
  if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    self:Log("\229\183\178\231\187\143\229\156\168\229\175\185\232\175\157\228\184\173\239\188\140\231\166\129\230\173\162\229\188\128\229\144\175\230\150\176\231\154\132\229\175\185\232\175\157")
    return false
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player.PlayerThrowInteractionComponent and Player.PlayerThrowInteractionComponent:IsPlaying() then
    self:Log("\230\173\163\229\156\168\229\135\134\229\164\135\232\191\155\230\136\152\230\150\151...")
    return false
  end
  if Player.viewObj and Player.viewObj.CharacterMovement.MovementMode == UE4.EMovementMode.MOVE_Falling then
    self:Log("\231\142\169\229\174\182\229\164\132\228\186\142\230\142\137\232\144\189\231\138\182\230\128\129")
    return false
  end
  if _G.BattleManager:IsInBattle() then
    self:Log("NPCActionDialogue:OnNpcAction, \230\173\163\229\156\168\230\136\152\230\150\151\228\184\173\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  elseif _G.BattleManager.isSendWaiting then
    self:Log("NPCActionDialogue:OnNpcAction, \230\173\163\229\156\168\231\148\179\232\175\183\232\191\155\229\133\165\230\136\152\230\150\151\231\173\137\229\190\133\228\184\173\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  end
  if #_G.BattleManager.battleNetManager.cachedBattleNotify > 0 then
    self:Log("NPCActionDialogue:OnNpcAction, \230\156\137\229\190\133\229\164\132\231\144\134\231\154\132\230\136\152\230\150\151\229\141\143\232\174\174\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    self:Log("\230\137\147\229\188\128\233\157\162\230\157\191\228\184\173...\233\128\128\229\135\186")
    return false
  end
  if _G.NRCPanelManager:GetLayerWindowCount(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN) > 0 then
    self:Log("\230\156\137\229\133\168\229\177\143\231\149\140\233\157\162UI_LAYER_FULLSCREEN...\233\128\128\229\135\186")
    return false
  end
  if self:GetLayerVisiblePanelCount(_G.Enum.UILayerType.UI_LAYER_LEVEL_LOADING) > 0 then
    self:Log("\230\156\137\229\133\168\229\177\143\231\149\140\233\157\162UI_LAYER_LEVEL_LOADING...\233\128\128\229\135\186")
    return false
  end
  if not Base.OnNpcAction(self) then
    return false
  end
  self:FreezePlayer()
  return true
end

function NPCActionDialogue:GetLayerVisiblePanelCount(panelLayer)
  local Ctrl = _G.NRCPanelManager.layerCenter:GetLayerCtrl(panelLayer)
  local Panels = Ctrl:GetAllWindow()
  local Count = 0
  if Panels then
    for _, Panel in ipairs(Panels) do
      if Panel.enableView then
        Count = Count + 1
        Log.Debug("Visible!", table.getKeyName(_G.Enum.UILayerType, panelLayer), Panel.panelName)
      end
    end
  end
  return Count
end

function NPCActionDialogue:Submit()
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.RegisterOption, self.Owner)
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.SetPreDialogueFlag, true)
  Base.Submit(self)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, false, "PreDialogue")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddInputBlockMappingContext, "NPCActionDialogue.Submit")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "NPCActionDialogue.Submit")
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
end

function NPCActionDialogue:OnSubmit(rsp)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true, "PreDialogue")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "NPCActionDialogue.Submit")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "NPCActionDialogue.Submit")
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  if 0 == rsp.ret_info.ret_code then
    local first_dialog_id = self.Owner.optionInfo.first_dialog_id
    if not first_dialog_id or not (first_dialog_id > 0) then
      first_dialog_id = tonumber(self.Config.action_param1)
    end
    if rsp.simulate then
      _G.NRCModeManager:DoCmd(_G.DialogueModuleCmd.StartDialogueLocal, self.Owner, self, first_dialog_id)
    else
      _G.NRCModeManager:DoCmd(_G.DialogueModuleCmd.StartDialogue, self.Owner, self, first_dialog_id)
    end
    _G.NRCSDKManager:SetEnterDialogue()
  else
    _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.UnregisterOption, self.Owner)
  end
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.SetPreDialogueFlag, false)
  Base.OnSubmit(self, rsp)
end

function NPCActionDialogue:HasLocalPerform()
  return false
end

function NPCActionDialogue:OnReConnect()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true, "PreDialogue")
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "NPCActionDialogue.Submit")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "NPCActionDialogue.Submit")
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.SetPreDialogueFlag, false)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
end

return NPCActionDialogue

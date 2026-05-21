local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local RealtimeDialogModuleCmd = require("NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleCmd")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local NPCDialogRealtimeAction = NPCActionBase:Extend("NPCDialogRealtimeAction")

function NPCDialogRealtimeAction:Ctor(Owner, Config, Info)
  NPCActionBase.Ctor(self, Owner, Config, Info)
  self.DialogConf = _G.DataConfigManager:GetDialogueConf(tonumber(self.Config.action_param1))
end

function NPCDialogRealtimeAction:OnNpcAction()
  local RealtimeDialogModule = NRCModuleManager:GetModule("RealtimeDialogModule")
  if not RealtimeDialogModule then
    Log.Error("NPCDialogRealtimeAction:OnNpcAction\239\188\154\230\151\160\230\179\149\232\142\183\229\143\150RealtimeDialogModule\230\168\161\229\157\151\239\188\140\232\175\183\230\138\138\229\164\141\231\142\176\230\150\185\229\188\143\229\146\140log\229\143\145\231\187\153amonsu")
    return false
  end
  if _G.BattleManager:IsInBattle() then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction, \230\173\163\229\156\168\230\136\152\230\150\151\228\184\173\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  elseif _G.BattleManager.isSendWaiting then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction, \230\173\163\229\156\168\231\148\179\232\175\183\232\191\155\229\133\165\230\136\152\230\150\151\231\173\137\229\190\133\228\184\173\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  end
  if #_G.BattleManager.battleNetManager.cachedBattleNotify > 0 then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction, \230\156\137\229\190\133\229\164\132\231\144\134\231\154\132\230\136\152\230\150\151\229\141\143\232\174\174\239\188\140\229\143\150\230\182\136\230\143\144\228\186\164")
    return false
  end
  if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction, \229\183\178\231\187\143\229\156\168\229\175\185\232\175\157\228\184\173!")
    return false
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player.PlayerThrowInteractionComponent and Player.PlayerThrowInteractionComponent:IsPlaying() then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction, \230\173\163\229\156\168\229\135\134\229\164\135\232\191\155\230\136\152\230\150\151...")
    return false
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction\239\188\154\230\137\147\229\188\128\233\157\162\230\157\191\228\184\173\239\188\129")
    return false
  end
  if _G.NRCPanelManager:GetLayerWindowCount(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN) > 0 then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction\239\188\154\230\156\137\229\133\168\229\177\143\231\149\140\233\157\162UI_LAYER_FULLSCREEN...\233\128\128\229\135\186")
    return false
  end
  if self:GetLayerVisiblePanelCount(_G.Enum.UILayerType.UI_LAYER_LEVEL_LOADING) > 0 then
    Log.Debug("NPCDialogRealtimeAction:OnNpcAction \230\156\137\229\133\168\229\177\143\231\149\140\233\157\162UI_LAYER_LEVEL_LOADING...\233\128\128\229\135\186")
    return false
  end
  if not NPCActionBase.OnNpcAction(self) then
    return false
  end
  return true
end

function NPCDialogRealtimeAction:OnSubmit(rsp)
  _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.StartRealtimeDialogByOption, self.Owner, self.DialogConf)
  NPCActionBase.OnSubmit(self, rsp)
  self:Finish(true)
end

function NPCDialogRealtimeAction:GetLayerVisiblePanelCount(panelLayer)
  local Ctrl = _G.NRCPanelManager.layerCenter:GetLayerCtrl(panelLayer)
  local Panels = Ctrl:GetAllWindow()
  local Count = 0
  if Panels then
    for _, Panel in ipairs(Panels) do
      if Panel.enableView then
        Count = Count + 1
        Log.Debug("NPCDialogRealtimeAction:GetLayerVisiblePanelCount Visible!", table.getKeyName(_G.Enum.UILayerType, panelLayer), Panel.panelName)
      end
    end
  end
  return Count
end

return NPCDialogRealtimeAction

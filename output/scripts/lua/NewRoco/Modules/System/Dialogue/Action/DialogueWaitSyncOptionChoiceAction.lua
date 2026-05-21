local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Base = DialogueActionBase
local DialogueWaitSyncOptionChoiceAction = Base:Extend("DialogueWaitSyncOptionChoiceAction")
FsmUtils.MergeMembers(Base, DialogueWaitSyncOptionChoiceAction, {
  {
    name = "ParentModule",
    type = "var"
  },
  {
    name = "PendingSyncList",
    type = "var"
  }
})

function DialogueWaitSyncOptionChoiceAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueWaitSyncOptionChoiceAction:OnEnter()
  self:InjectProperties()
  local OptionsUI = self:CheckOptionUI()
  if not OptionsUI then
    return
  end
  OptionsUI:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  local NextSync = self:ResolveNextSync()
  if NextSync then
    self:OnSyncOptionChoice(NextSync)
    return
  end
  if self.ParentModule then
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.SyncNextDialogue, self.OnSyncReceive)
    self.fsm:Pause()
  else
    Log.Error("DialogueWaitSyncOptionChoiceAction:OnEnter\239\188\140\229\175\185\232\175\157\230\168\161\229\157\151\228\184\141\229\173\152\229\156\168...")
    self:Finish()
  end
end

function DialogueWaitSyncOptionChoiceAction:OnSyncReceive()
  local NextSync = self:ResolveNextSync()
  if NextSync then
    self:OnSyncOptionChoice(NextSync)
  else
    Log.Error("DialogueWaitSyncOptionChoiceAction:OnEnter\239\188\140fail to find next conf id when receive next sync notify!")
    self:Finish()
  end
end

function DialogueWaitSyncOptionChoiceAction:ResolveNextSync()
  if #self.PendingSyncList > 0 then
    local NextSync = self.PendingSyncList[1]
    return NextSync
  end
  return nil
end

function DialogueWaitSyncOptionChoiceAction:OnSyncOptionChoice(NextSync)
  local OptionsUI = self:CheckOptionUI()
  if not OptionsUI or not OptionsUI.ObjListNew then
    self:Finish()
    return
  end
  for i = OptionsUI.ObjListNew:GetItemCount() - 1, 0, -1 do
    local item = OptionsUI.ObjListNew:GetItemByIndex(i)
    if item and item.SelectConf and item.SelectConf.id == NextSync.LastSelectID then
      item:PlaySelectAnimation()
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1067, "UMG_DialogueSelectItem_C:OnMouseEnter")
    end
  end
  self.DelayHandle = _G.DelayManager:DelaySeconds(0.5, function()
    self.DelayHandle = nil
    self:Finish()
  end)
end

function DialogueWaitSyncOptionChoiceAction:CheckOptionUI()
  local DialogueModule = self.ParentModule
  if not DialogueModule then
    Log.Error("DialogueWaitSyncOptionChoiceAction\228\184\165\233\135\141\233\148\153\232\175\175\239\188\140\229\175\185\232\175\157\230\168\161\229\157\151\228\184\141\229\173\152\229\156\168...")
    return false
  end
  local PanelName = DialogueModule._currentMainPanel
  if string.IsNilOrEmpty(PanelName) then
    return false
  end
  local HasPanel = DialogueModule:HasPanel(PanelName)
  if not HasPanel then
    Log.Debug("DialogueWaitSyncOptionChoiceAction\230\151\160\230\179\149\232\142\183\229\143\150\229\175\185\232\175\157\233\157\162\230\157\191...\231\173\137\228\184\128\228\184\139\229\134\141\232\175\149", PanelName)
    return false
  end
  local Panel = DialogueModule:GetPanel(PanelName)
  if not Panel then
    Log.Debug("DialogueWaitSyncOptionChoiceAction\230\151\160\230\179\149\232\142\183\229\143\150\229\175\185\232\175\157\233\157\162\230\157\191...\231\173\137\228\184\128\228\184\139\229\134\141\232\175\149", PanelName)
    return false
  end
  if not Panel.enableView then
    Log.Debug("DialogueWaitSyncOptionChoiceAction\229\175\185\232\175\157\233\157\162\230\157\191\232\191\152\230\178\161\229\135\134\229\164\135\229\165\189...\231\173\137\228\184\128\228\184\139\229\134\141\232\175\149", PanelName)
    return false
  end
  if not Panel.ShowOptions then
    Log.Error("DialogueWaitSyncOptionChoiceAction\229\175\185\232\175\157\233\157\162\230\157\191\230\178\161\230\156\137\230\152\190\231\164\186\233\128\137\233\161\185\231\154\132\229\138\159\232\131\189", PanelName)
    return false
  end
  if Panel.DialogueSelector and Panel.DialogueSelector:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
    return Panel.DialogueSelector
  end
  return false
end

function DialogueWaitSyncOptionChoiceAction:OnFinish()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
  end
  if self.ParentModule then
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.SyncNextDialogue)
  end
  self.fsm:Resume()
end

function DialogueWaitSyncOptionChoiceAction:OnExit()
  self:OnFinish()
end

function DialogueWaitSyncOptionChoiceAction:OnTimeout()
  Base.OnTimeout(self)
  self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
end

return DialogueWaitSyncOptionChoiceAction

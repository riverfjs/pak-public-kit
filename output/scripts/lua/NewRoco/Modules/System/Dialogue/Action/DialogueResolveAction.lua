local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialogueResolveAction = Base:Extend("DialogueResolveAction")
FsmUtils.MergeMembers(Base, DialogueResolveAction, {
  {
    name = "DialogueConf",
    type = "var"
  },
  {name = "ConfID", type = "var"}
})

function DialogueResolveAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueResolveAction:OnEnter()
  self:InjectProperties()
  if 0 == self.ConfID or not self.ConfID then
    self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
    return
  end
  local Conf = _G.DataConfigManager:GetDialogueConf(self.ConfID)
  if not Conf then
    Log.Error("\230\151\160\230\179\149\230\159\165\229\136\176\229\175\185\232\175\157\233\133\141\231\189\174", self.ConfID)
    if RocoEnv.IS_SHIPPING then
      self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
    else
      local Ctx = _G.DialogContext()
      Ctx:SetTitle("\233\157\158Shipping\231\137\136\230\156\172\228\184\147\229\177\158\228\184\165\233\135\141\233\148\153\232\175\175\230\143\144\231\164\186")
      Ctx:SetContent(string.format("\229\174\162\230\136\183\231\171\175\231\188\186\229\176\145\229\175\185\232\175\157\233\133\141\231\189\174%d\239\188\140\232\191\153\228\184\128\232\136\172\230\152\175\229\137\141\229\144\142\229\143\176\233\133\141\231\189\174\229\175\185\228\184\141\228\184\138\228\186\134\239\188\140\232\175\183\230\138\138\229\174\162\230\136\183\231\171\175\231\137\136\230\156\172\229\143\183\228\187\165\229\143\138\231\153\187\229\133\165\231\142\175\229\162\131(\228\189\141\228\186\142\229\177\143\229\185\149\229\183\166\228\184\139\232\167\146)\229\145\138\232\175\137\231\137\136\230\156\172PM\239\188\140\232\176\162\232\176\162\227\128\130", self.ConfID))
      Ctx:SetMode(_G.DialogContext.Mode.OK)
      Ctx:SetButtonText("\231\187\147\230\157\159\229\175\185\232\175\157", "\231\187\147\230\157\159\229\175\185\232\175\157")
      Ctx:SetCallback(nil, function()
        if self and self.fsm and self.fsm.SendEvent then
          self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
        end
      end)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
    end
    return
  end
  if not self:CheckConfValid(Conf) then
    Log.Error("\230\151\160\230\149\136\229\175\185\232\175\157\233\133\141\231\189\174\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165\239\188\129\239\188\129\239\188\129 ", self.ConfID)
    self.fsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
    return
  end
  local LastConf = self.fsm:GetProperty("CurrentDialogue", nil)
  self.fsm:SetProperty("LastConfID", LastConf and LastConf.id or 0)
  self:SetProperty("DialogueConf", Conf)
  self:Finish()
end

function DialogueResolveAction:CheckConfValid(Conf)
  if not Conf then
    return false
  end
  if not string.IsNilOrEmpty(Conf.text) then
    return true
  end
  if 0 ~= Conf.next_dialog_id then
    return true
  end
  if Conf.select_ids and #Conf.select_ids > 0 then
    return true
  end
  if DialogueUtils.HasValidAction(Conf) then
    return true
  end
  if Conf.ui_source_type == Enum.UIsourceType.UIT_BLACK_EXIT then
    return true
  end
  if Conf.ui_source_type == Enum.UIsourceType.UIT_BLACK then
    return true
  end
  return false
end

function DialogueResolveAction:OnExit()
end

return DialogueResolveAction

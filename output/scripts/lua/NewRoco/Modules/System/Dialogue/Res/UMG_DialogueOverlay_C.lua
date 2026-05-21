local UMG_DialogueOverlay_C = _G.NRCPanelBase:Extend("UMG_DialogueOverlay_C")

function UMG_DialogueOverlay_C:OnConstruct()
  self:AddButtonListener(self.UMG_Skip.Button, self.OnDialogueSkip)
  self:AddButtonListener(self.ExitBtn.btnLevelUp, self.OnDialogueExit)
end

function UMG_DialogueOverlay_C:OnDestruct()
end

function UMG_DialogueOverlay_C:OnDisable()
  self.ExitConfirmMsgOn = false
end

function UMG_DialogueOverlay_C:OnActive(caller, callback)
  if caller and callback then
    callback(caller)
  end
end

function UMG_DialogueOverlay_C:OnDialogueSkip()
  local Visible = self.UMG_Skip:GetVisibility()
  if Visible == UE.ESlateVisibility.Visible then
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.SkipDialogue)
  end
end

function UMG_DialogueOverlay_C:OnDialogueExit()
  if self.ExitConfirmMsgOn then
    return
  end
  self.ExitConfirmMsgOn = true
  _G.NRCModuleManager:DoCmd(DialogueModuleCmd.UpdateExitConfirmMsgOn, true)
  OpenMessageBoxWthCaller(LuaText.Title_SyncDialogueExit, LuaText.Text_SyncDialogueExit, LuaText.tips_dialog_butten_accept, LuaText.CANCEL, DialogContext.Mode.OK_CANCEL, self.OnConfirmExitClick, self, nil, true)
end

function UMG_DialogueOverlay_C:OnConfirmExitClick(bResult)
  self.ExitConfirmMsgOn = false
  if bResult then
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.CloseDialogue)
  end
end

return UMG_DialogueOverlay_C

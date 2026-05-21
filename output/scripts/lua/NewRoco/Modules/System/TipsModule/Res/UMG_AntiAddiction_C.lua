local UMG_AntiAddiction_C = _G.NRCPanelBase:Extend("UMG_AntiAddiction_C")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")

function UMG_AntiAddiction_C:OnConstruct()
end

function UMG_AntiAddiction_C:OnDestruct()
end

function UMG_AntiAddiction_C:OnActive(_instruction, IsBan)
  self.data = _instruction
  if IsBan then
    self.ContentText:SetJustification(UE4.ETextJustify.Center)
  end
  self.NRCTitle_1:SetText(_instruction.title)
  self.ContentText:SetText(_instruction.msg)
  self:PlayAnimation(self.open)
  self:OnAddEventListener()
  UE4Helper.SetDesiredShowCursor(true, "UMG_AntiAddiction_C")
end

function UMG_AntiAddiction_C:OnPcClose()
  Log.Debug("UMG_AntiAddiction_C:ClosePanel invoked")
end

function UMG_AntiAddiction_C:OnDeactive()
  UE4Helper.ReleaseDesiredShowCursor("UMG_AntiAddiction_C")
end

function UMG_AntiAddiction_C:OnAddEventListener()
  self:AddButtonListener(self.OkBtn.btnLevelUp, self.OnClickOK)
end

function UMG_AntiAddiction_C:OnClickOK()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_AntiAddiction_C:OnClickOK")
  self:PlayAnimation(self.close)
end

function UMG_AntiAddiction_C:OnAnimationFinished(anim)
  if anim == self.close then
    if 1 == self.data.modal then
      _G.GlobalConfig.UserKickedOutFromGame = true
      _G.AppMain.BackToLogin()
    end
    if self.data.type then
      _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.FinishAntiAddictionTips, self.data.type)
    end
    self:DoClose()
  end
end

return UMG_AntiAddiction_C

require("UnLuaEx")
local UMG_Battle_Popup_DamageNumber_base = NRCUmgClass()

function UMG_Battle_Popup_DamageNumber_base:Ctor()
  NRCUmgClass.Ctor(self)
  self.AnimType = 1
end

function UMG_Battle_Popup_DamageNumber_base:SetContent(content, color, OutlineColor)
  self:SetupText(self.TextContent, content, color, OutlineColor)
  self:SetupText(self.TextContent_1, content, color, OutlineColor)
  self:SetupText(self.TextContent_2, content, color, OutlineColor)
end

function UMG_Battle_Popup_DamageNumber_base:SetAnimType(AnimType)
  self.AnimType = AnimType
end

function UMG_Battle_Popup_DamageNumber_base:SetupText(text, content, color, OutlineColor)
  if not text then
    return
  end
  if color then
    text:SetColorAndOpacity(color)
  end
  if OutlineColor then
    local font = text.Font
    font.OutlineSettings.OutlineColor = OutlineColor
    text:SetFont(font)
    text:SetFont(text.Font)
  end
  if content then
    text:SetText(content)
  end
end

function UMG_Battle_Popup_DamageNumber_base:Play()
  if 2 == self.AnimType then
    self:PlayAnimation(self.Anim1)
  else
    self:PlayAnimation(self.Anim1)
  end
end

function UMG_Battle_Popup_DamageNumber_base:OnAnimationFinished(Animation)
  if self.PopupData then
    self.PopupData:RecycleUMG(self)
  else
    self:RemoveFromParent()
  end
end

function UMG_Battle_Popup_DamageNumber_base:SetCallBack(Caller, CallBack, PopupData)
  self.Caller = Caller
  self.CallBack = CallBack
  self.PopupData = PopupData
end

function UMG_Battle_Popup_DamageNumber_base:Reset()
  if self.Caller and self.CallBack then
    self.CallBack(self.Caller, self.PopupData)
  end
  self.Caller = nil
  self.CallBack = nil
  self.PopupData = nil
end

function UMG_Battle_Popup_DamageNumber_base:OnDestruct()
  self:Reset()
end

return UMG_Battle_Popup_DamageNumber_base

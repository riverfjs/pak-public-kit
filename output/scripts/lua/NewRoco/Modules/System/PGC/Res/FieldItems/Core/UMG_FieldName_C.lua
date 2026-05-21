local UMG_AbstractView = require("NewRoco.Modules.System.PGC.Res.FieldItems.Base.UMG_AbstractView")
local UMG_FieldName_C = UMG_AbstractView:Extend("UMG_FieldName_C")

function UMG_FieldName_C:OnAddEventListener()
  self:AddButtonListener(self.Warning, self.OnClickWarningButton)
  self:AddButtonListener(self.Help, self.OnClickHelpButton)
  self:AddButtonListener(self.Execute, self.OnClickExecuteButton)
end

function UMG_FieldName_C:OnNormalizeData(Data)
  if Data.RTTI == nil then
    return false
  elseif nil == Data.RTTI.TypeInfo or nil == Data.RTTI.FieldInfo then
    return false
  end
  if nil == Data.Record then
    return false
  end
  return true
end

function UMG_FieldName_C:OnFlushData()
  local NameText = self.Data.RTTI.FieldInfo.Description or self.Data.RTTI.FieldInfo.Name
  self.Name:SetText(NameText)
  local Execute = self.Data.Execute
  if Execute and Execute.ExecuteName and Execute.Caller and Execute.Callback then
    self.Execute:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ExecuteName:SetText(Execute.ExecuteName)
  else
    self.Execute:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Data.WarningMessage then
    self.Warning:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Warning:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Data.HelpDescription then
    self.Help:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Help:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_FieldName_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.Warning, self.OnClickWarningButton)
  self:RemoveButtonListener(self.Help, self.OnClickHelpButton)
  self:RemoveButtonListener(self.Execute, self.OnClickExecuteButton)
end

function UMG_FieldName_C:OnClickWarningButton()
  if self.Data.WarningMessage then
  end
end

function UMG_FieldName_C:OnClickHelpButton()
  if self.Data.HelpDescription then
  end
end

function UMG_FieldName_C:OnClickExecuteButton()
  if self.Data.Execute and self.Execute.Caller and self.Execute.Callback then
    self.Execute.Callback(self.Execute.Caller, self.Execute.CallArgs)
  end
end

return UMG_FieldName_C

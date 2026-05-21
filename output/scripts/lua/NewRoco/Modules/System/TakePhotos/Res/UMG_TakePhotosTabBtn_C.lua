local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TakePhotosTabBtn_C = Base:Extend("UMG_TakePhotosTabBtn_C")

function UMG_TakePhotosTabBtn_C:OnConstruct()
end

function UMG_TakePhotosTabBtn_C:OnDestruct()
end

function UMG_TakePhotosTabBtn_C:OnItemUpdate(_data, datalist, index)
  self.Data = _data
  self.Suit_Ordinary:SetPath(_data.NormalIconPath or "")
  self.Suit_Selected:SetPath(_data.BlackIconPath or "")
  if self.RedDot then
    if _data.RedDotKey then
      self.RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.RedDot:SetupKey(_data.RedDotKey, _data.RedDotExtraKey)
    else
      self.RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_TakePhotosTabBtn_C:OnItemSelected(_bSelected)
  Log.Debug("UMG_TakePhotosTabBtn_C:OnItemSelected", _bSelected, self.Data.NormalIconPath)
  self:StopAllAnimations()
  if _bSelected then
    if self.Data.OnClicked then
      self:PlayAnimation(self.Btn_Suit_A)
      self.Data.OnClicked()
    end
  else
    self:PlayAnimation(self.Btn_Suit_A_Out)
  end
end

function UMG_TakePhotosTabBtn_C:OnDeactive()
end

return UMG_TakePhotosTabBtn_C

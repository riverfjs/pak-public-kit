local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TabButton_C = Base:Extend("UMG_TabButton_C")

function UMG_TabButton_C:OnConstruct()
end

function UMG_TabButton_C:OnDestruct()
end

function UMG_TabButton_C:OnTouchEnded(MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_TabButton_C:OnTouchEnded")
  return Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
end

function UMG_TabButton_C:OnItemUpdate(_data, datalist, index)
  self.itemIndex = index
  self.itemData = _data
  if _data.icon then
    self.Ordinary:SetPath(_data.icon)
  end
  if _data.icon_selected then
    self.PitchOn:SetPath(_data.icon_selected)
  end
  if _data.tag then
    self.NRCImage_73:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_73:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if _data.recommend_flag then
    self.NRCImage_73:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCImage_73:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  self:UpdateName(self.itemData.name)
end

function UMG_TabButton_C:UpdateName(Name)
  self.itemData.name = Name or ""
  if self.itemData.name ~= "" then
    self.ItemName:SetText(self.itemData.name)
    self.ItemName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ItemName:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_TabButton_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.change1)
    if self.itemData and self.itemData.onClicked then
      self.itemData.onClicked(self.itemData, self.itemIndex)
    end
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_TabButton_C:OnAnimationFinished(Anim)
  if Anim == self.change1 then
    self:PlayAnimation(self.select_loop)
  end
end

function UMG_TabButton_C:OnDeactive()
end

return UMG_TabButton_C

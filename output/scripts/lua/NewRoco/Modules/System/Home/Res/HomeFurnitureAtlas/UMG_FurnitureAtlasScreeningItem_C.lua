local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FurnitureAtlasScreeningItem_C = Base:Extend("UMG_FurnitureAtlasScreeningItem_C")

function UMG_FurnitureAtlasScreeningItem_C:OnItemUpdate(_data, datalist, index)
  if not _data or not _data.tabId then
    return
  end
  self.data = _data
  self.Text:SetText(_data.text)
  self.imageAttriIcon:SetPath(_data.iconPath)
  if _data.displayNum then
    self.NumberText:SetText(_data.displayNum)
    self.ScreeningQuantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ScreeningQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bCurSelected = false
end

function UMG_FurnitureAtlasScreeningItem_C:OnItemSelected(_bSelected, placeHolder, userClick)
  if self.data.OnClick and self.data.firstTabItemIndex then
    self.data.OnClick(self.data.firstTabItemIndex, self._index, self.data, _bSelected, userClick)
  end
end

function UMG_FurnitureAtlasScreeningItem_C:DoSelect()
  if not self.bCurSelected then
    self.bCurSelected = true
    self:StopAllAnimations()
    self:PlayAnimation(self.Press)
  end
end

function UMG_FurnitureAtlasScreeningItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_FurnitureAtlasScreeningItem_C:OnItemSelected")
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_FurnitureAtlasScreeningItem_C:DoUnSelect()
  if self.bCurSelected then
    self.bCurSelected = false
    self:StopAllAnimations()
    self:PlayAnimation(self.Cancel)
  end
end

return UMG_FurnitureAtlasScreeningItem_C

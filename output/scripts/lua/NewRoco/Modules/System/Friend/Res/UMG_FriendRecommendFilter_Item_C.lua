local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FriendRecommendFilter_Item_C = Base:Extend("UMG_FriendRecommendFilter_Item_C")

function UMG_FriendRecommendFilter_Item_C:OnConstruct()
end

function UMG_FriendRecommendFilter_Item_C:OnDestruct()
end

function UMG_FriendRecommendFilter_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  if not _data then
    return
  end
  if self.FlagText and _data.text then
    self.FlagText:SetText(_data.text)
  end
  if self.FlagIcon and _data.iconPath and _data.iconPath ~= "" then
    self.FlagIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.FlagIcon:SetPath(_data.iconPath)
  elseif self.FlagIcon then
    self.FlagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_FriendRecommendFilter_Item_C:OnItemSelected(_bSelected, bScrollChoose, bUserClick)
  if self.data and self.data.OnClick then
    self.data.OnClick(self.data, _bSelected)
  end
  if self.data and self.data.bDisableClickSelect then
    return
  end
  if _bSelected then
    self:PlayAnimation(self.Press)
  else
    self:PlayAnimation(self.Cancel)
  end
end

function UMG_FriendRecommendFilter_Item_C:DoSelect()
  self:PlayAnimation(self.Press)
end

function UMG_FriendRecommendFilter_Item_C:DoUnSelect()
  self:PlayAnimation(self.Cancel)
end

return UMG_FriendRecommendFilter_Item_C

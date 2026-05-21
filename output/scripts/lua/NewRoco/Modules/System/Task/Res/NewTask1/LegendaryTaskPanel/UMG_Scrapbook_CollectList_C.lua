local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Scrapbook_CollectList_C = Base:Extend("UMG_Scrapbook_CollectList_C")

function UMG_Scrapbook_CollectList_C:OnConstruct()
end

function UMG_Scrapbook_CollectList_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Scrapbook_CollectList_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.isDone = self.data.isDone
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:SetUpInfo()
  if 5 == self.index then
    self.PartingLine:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PlayInAnimation()
end

function UMG_Scrapbook_CollectList_C:PlayInAnimation()
  self.DelayId = _G.DelayManager:DelaySeconds(0.05 * self.index, function()
    self:PlayAnimation(self.In)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
end

function UMG_Scrapbook_CollectList_C:PlayGetAnimation()
  self.DelayId = _G.DelayManager:DelaySeconds(0.05 * self.index, function()
    self:PlayAnimation(self.Get)
  end)
end

function UMG_Scrapbook_CollectList_C:OnItemSelected(_bSelected)
end

function UMG_Scrapbook_CollectList_C:IsListDone()
  self.CrossOut:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.isDone then
    self:PlayAnimation(self.Get)
    self.CrossOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Scrapbook_CollectList_C:SetUpInfo()
  self.Text:SetText(self.data[1].to_do_list)
  self:IsListDone()
end

function UMG_Scrapbook_CollectList_C:OnAnimationFinished(Anim)
end

function UMG_Scrapbook_CollectList_C:OnDeactive()
end

return UMG_Scrapbook_CollectList_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Pass_AwardItem1_C = Base:Extend("UMG_Pass_AwardItem1_C")

function UMG_Pass_AwardItem1_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Pass_AwardItem1_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self:RefreshItem()
end

function UMG_Pass_AwardItem1_C:RefreshItem()
  local data = self.data
  if data.level >= 999 then
    self.Text_Class:SetText("\226\136\158")
  else
    self.Text_Class:SetText(string.format("%02d", data.level))
  end
  local freeItemArray = {}
  for i, v in pairs(data.freeItems) do
    table.insert(freeItemArray, {
      ItemData = v,
      ItemID = data.level,
      isPremiumReward = false
    })
  end
  local paidItemArray = {}
  for i, v in pairs(data.paidItems) do
    table.insert(paidItemArray, {
      ItemData = v,
      ItemID = data.level,
      isPremiumReward = true
    })
  end
  self.Icon:InitGridView(freeItemArray)
  self.Icon1:InitGridView(paidItemArray)
  self.Empty:SetVisibility(0 == #data.paidItems and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if 0 == data.freeState and 0 == data.paidState then
    self.Text_Class:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1"))
  else
    self.Text_Class:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#929086"))
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_AwardItem1", self)
end

function UMG_Pass_AwardItem1_C:SetupAwardFx(isOn)
  if isOn then
    self.UMG_Pass_AwardItem_Lizi:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Pass_AwardItem_Lizi:PlayLoopAnim()
    if self.preState ~= isOn then
      self:PlayAnimation(self.Lizi_In)
    end
  else
    if self.preState ~= isOn then
      self:PlayAnimation(self.Lizi_Out)
    end
    self.UMG_Pass_AwardItem_Lizi:StopLoopAnim()
  end
  self.preState = isOn
end

function UMG_Pass_AwardItem1_C:OnAnimationFinished(Animation)
  if Animation == self.Lizi_Out then
    self.UMG_Pass_AwardItem_Lizi:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pass_AwardItem1_C:PlayInAnimation(delaySec)
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.DelayId = _G.DelayManager:DelaySeconds(delaySec, function()
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.In)
  end)
end

return UMG_Pass_AwardItem1_C

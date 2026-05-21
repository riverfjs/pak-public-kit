local UMG_Pass_AwardItem2_C = _G.NRCViewBase:Extend("UMG_Pass_AwardItem2_C")

function UMG_Pass_AwardItem2_C:OnActive()
end

function UMG_Pass_AwardItem2_C:OnDeactive()
end

function UMG_Pass_AwardItem2_C:OnAddEventListener()
end

function UMG_Pass_AwardItem2_C:RefreshItem(_data)
  local data = _data
  if data.level >= 999 then
    self.Text_Class:SetText("\226\136\158")
  else
    self.Text_Class:SetText(string.format("%02d", data.level))
  end
  self.Text_Class:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#252525"))
  self:SetupAwardFx(1 == data.freeState or 1 == data.paidState)
  self.Icon:SetVisibility(0 == #data.freeItems and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Icon1:SetVisibility(0 == #data.paidItems and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Decorate:SetVisibility(0 == #data.paidItems and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Decorate_1:SetVisibility(0 == #data.paidItems and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Decorate_2:SetVisibility(0 == #data.paidItems and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
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
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_AwardItem2", self)
end

function UMG_Pass_AwardItem2_C:SetupAwardFx(isOn)
  if isOn then
    self.UMG_Pass_AwardItem_Lizi:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Pass_AwardItem_Lizi:PlayLoopAnim()
  else
    self.UMG_Pass_AwardItem_Lizi:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Pass_AwardItem_Lizi:StopLoopAnim()
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeThemeColor, "UMG_Pass_AwardItem2", self)
end

return UMG_Pass_AwardItem2_C

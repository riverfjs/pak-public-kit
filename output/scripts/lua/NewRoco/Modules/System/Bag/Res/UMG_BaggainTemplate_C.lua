local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_BaggainTemplate_C = Base:Extend("UMG_BaggainTemplate_C")

function UMG_BaggainTemplate_C:OnConstruct()
  self.uiData = {}
  self.Btn_Skip.OnPressed:Add(self, self.OnSkipClick)
end

function UMG_BaggainTemplate_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self:SetVisibility(UE.ESlateVisibility.Collapsed)
  self:updateItemInfo()
end

function UMG_BaggainTemplate_C:updateItemInfo()
  if self.uiData.IsFirstOpenPanel == true then
    self:PlayAnimation(self.In)
  end
  self.uiData.IsFirstOpenPanel = false
  if self.uiData.acquire_struct then
    self.GainWayDesc:SetText(self.uiData.acquire_struct.acquire_way_text)
  end
  if self.uiData.acquire_struct.text then
    self.Btn_Skip:SetVisibility(UE.ESlateVisibility.Visible)
    self.GainWayIcon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F4EEE1FF"))
    self.GainWayDesc:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
  else
    self.GainWayIcon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("676761FF"))
    self.GainWayDesc:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("676761FF"))
    self.Btn_Skip:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_BaggainTemplate_C:OnItemClick()
  Log.Debug("UMG_BaggainTemplate_C:OnItemClick")
end

function UMG_BaggainTemplate_C:OnSkipClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_BaggainTemplate_C:OnSkipClick")
  _G.DataModelMgr.PlayerDataModel:SetIsTraceByBag(true)
  if self.uiData and self.uiData.acquire_struct and self.uiData.acquire_struct.text then
    if self.uiData.acquire_struct.text == "ActivityModuleCmd.OpenMainPanel" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param2, self.uiData.acquire_struct.param3)
    elseif self.uiData.acquire_struct.text == "BigMapModuleCmd.OnTraceBossByEggItemId" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, LuaText.jump_to_error_tips, self.uiData.acquire_struct.param1[1])
    elseif self.uiData.acquire_struct.text == "ShopModuleCmd.OpenMainPanel" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param1[1], nil, self.uiData.acquire_struct.param3)
    elseif self.uiData.acquire_struct.text == "BigMapModuleCmd.SendZoneNpcTraceQueryReq" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param1)
    elseif self.uiData.acquire_struct.text == "BagModuleCmd.OpenWebView" then
      _G.NRCSDKManager:OpenWebView(self.uiData.acquire_struct.param3, nil, false, false, nil, false)
    elseif self.uiData.acquire_struct.text == "BagModuleCmd.OpenWebViewWithEncode" then
      _G.NRCSDKManager:OpenWebView(self.uiData.acquire_struct.param3, nil, false, false, nil, true)
    elseif self.uiData.acquire_struct.text == "HandbookModuleCmd.OpenHandbookByRewardItemId" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, Enum.GoodsType.GT_BAGITEM, self.uiData.itemId)
    elseif self.uiData.acquire_struct.text == "BigMapModuleCmd.SendZoneNpcTraceCollectibles" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param1, self.uiData.itemId)
    elseif self.uiData.acquire_struct.text == "HandbookModuleCmd.OpenHandbookAchievementRewardByRewardItemId" then
      if self.uiData.acquire_struct.param1 and #self.uiData.acquire_struct.param1 > 0 then
        _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param1[1], _G.Enum.GoodsType.GT_BAGITEM, self.uiData.itemId)
      end
    elseif self.uiData.acquire_struct.text == "BigMapModuleCmd.OnTraceForceShowNpc" then
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, self.uiData.acquire_struct.param1[1])
    else
      _G.NRCModuleManager:DoCmd(self.uiData.acquire_struct.text, LuaText.jump_to_error_tips)
    end
  end
  _G.DataModelMgr.PlayerDataModel:SetIsTraceByBag(false)
end

return UMG_BaggainTemplate_C

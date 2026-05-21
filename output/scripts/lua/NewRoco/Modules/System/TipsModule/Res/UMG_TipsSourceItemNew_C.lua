local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_TipsSourceItemNew_C = Base:Extend("UMG_TipsSourceItemNew_C")

function UMG_TipsSourceItemNew_C:OnConstruct()
  self.uiData = {}
  self.Btn_Skip.OnClicked:Add(self, self.OnSkipClick)
end

function UMG_TipsSourceItemNew_C:OnDestruct()
  self.uiData = {}
end

function UMG_TipsSourceItemNew_C:OnSkipClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_TipsSourceItemNew_C:OnSkipClick")
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_ResetTipsDescText)
  _G.DataModelMgr.PlayerDataModel:SetIsTraceByBag(true)
  if self.uiData.text then
    if self.uiData.text == "ActivityModuleCmd.OpenMainPanel" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param2, self.uiData.param3)
    elseif self.uiData.text == "BigMapModuleCmd.OnTraceBossByEggItemId" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, LuaText.jump_to_error_tips, self.uiData.param1[1])
    elseif self.uiData.text == "ShopModuleCmd.OpenMainPanel" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1[1], nil, self.uiData.param3)
    elseif self.uiData.text == "BigMapModuleCmd.SendZoneNpcTraceQueryReq" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1)
    elseif self.uiData.text == "HomeModuleCmd.OpenSeedCraftPanel" or self.uiData.text == "HomeModuleCmd.OpenSeedBagPanel" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1[1])
    elseif self.uiData.text == "HandbookModuleCmd.OpenHandbookByRewardItemId" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.ItemType, self.ItemId)
    elseif self.uiData.text == "ActivityModuleCmd.OpenFreeHuggersCardPanel" then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1)
    elseif self.uiData.text == "BigMapModuleCmd.SendZoneNpcTraceCollectibles" then
      _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1, self.ItemId)
    elseif self.uiData.text == "HandbookModuleCmd.OpenHandbookAchievementRewardByRewardItemId" then
      if self.uiData.param1 and #self.uiData.param1 > 0 then
        _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1[1], self.ItemType, self.ItemId)
      end
    elseif self.uiData.text == "BigMapModuleCmd.OnTraceForceShowNpc" then
      if self.uiData.param1 and #self.uiData.param1 > 0 then
        _G.NRCModuleManager:DoCmd(self.uiData.text, self.uiData.param1[1])
      end
    else
      _G.NRCModuleManager:DoCmd(self.uiData.text, LuaText.jump_to_error_tips)
    end
  end
  _G.DataModelMgr.PlayerDataModel:SetIsTraceByBag(false)
end

function UMG_TipsSourceItemNew_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data.acquire_struct
  self.ItemType = _data.ItemType
  self.ItemId = _data.ItemId
  self.index = index
  self:updateItemInfo(self.uiData)
end

function UMG_TipsSourceItemNew_C:updateItemInfo(_data)
  if _data.acquire_way_text == nil then
    self.SourceBtn2:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SourceBtn1:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    if _data.text then
      self.Image_48:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F4EEE1FF"))
      self.SourceText1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      self.Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F4EEE1FF"))
      self.SourceText2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      self.Btn_Skip:SetVisibility(UE.ESlateVisibility.Visible)
    else
      self.Image_48:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("676761FF"))
      self.SourceText1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("676761FF"))
      self.Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("676761FF"))
      self.SourceText2:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("676761FF"))
      self.Btn_Skip:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if 0 == _data.behavior_id or nil == _data.behavior_id then
      self.SourceBtn2:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SourceBtn1:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.SourceText2:SetText(_data.acquire_way_text)
    else
      local behaviorConf = _G.DataConfigManager:GetBehaviorConf(_data.behavior_id)
      if behaviorConf.behavior_type == _G.Enum.BehaviorType.BT_OPEN_WORLDMAP then
        local worldMapConfigId = tonumber(behaviorConf.action_param1)
        local worldMapConfig = _G.DataConfigManager:GetWorldMapConf(worldMapConfigId)
        if worldMapConfig.unexplored_in_map == false and false == worldMapConfig.explored_in_map and false == worldMapConfig.unfinished_in_map then
          self.SourceBtn2:SetVisibility(UE4.ESlateVisibility.visible)
          self.SourceBtn1:SetVisibility(UE4.ESlateVisibility.Hidden)
          self.SourceText2:SetText(_data.acquire_way_text)
        else
          self.SourceBtn2:SetVisibility(UE4.ESlateVisibility.Hidden)
          self.SourceBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
          self.SourceText1:SetText(_data.acquire_way_text)
        end
      else
        self.SourceBtn2:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.SourceBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
        self.SourceText1:SetText(_data.acquire_way_text)
      end
    end
  end
  if _G.BinDataUtils.IsPropertyExist(_data, "isPreviewCard") then
    if _data.isPreviewCard then
      self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/TipsModule/Raw/Atlas/TipsUI/Frames/img_yulan_png.img_yulan_png'")
    else
      self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/TipsModule/Raw/Atlas/TipsUI/Frames/img_laiyuan_png.img_laiyuan_png'")
    end
  else
    self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/TipsModule/Raw/Atlas/TipsUI/Frames/img_laiyuan_png.img_laiyuan_png'")
  end
end

function UMG_TipsSourceItemNew_C:OnItemSelected(_bSelected)
end

function UMG_TipsSourceItemNew_C:OnDeactive()
end

return UMG_TipsSourceItemNew_C

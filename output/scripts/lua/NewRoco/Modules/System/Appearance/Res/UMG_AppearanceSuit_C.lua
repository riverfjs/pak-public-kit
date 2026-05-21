local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UMG_AppearanceSuit_C = _G.NRCPanelBase:Extend("UMG_AppearanceSuit_C")

function UMG_AppearanceSuit_C:OnConstruct()
  self.data = self.module:GetData("AppearanceModuleData")
  self.suit3_1 = {
    self.AppearanceSuitItem3_1,
    self.AppearanceSuitItem3_2,
    self.AppearanceSuitItem3_3
  }
  self.suit4_1 = {
    self.AppearanceSuitItem4_1,
    self.AppearanceSuitItem4_2,
    self.AppearanceSuitItem4_3,
    self.AppearanceSuitItem4_4
  }
  self.suit5_1 = {
    self.AppearanceSuitItem5_1,
    self.AppearanceSuitItem5_2,
    self.AppearanceSuitItem5_3,
    self.AppearanceSuitItem5_4,
    self.AppearanceSuitItem5_5,
    self.AppearanceSuitItem5_6,
    self.AppearanceSuitItem5_7,
    self.AppearanceSuitItem5_8
  }
  self.fashionLabelSortTable = {}
end

function UMG_AppearanceSuit_C:OnActive(param, fashionItemId, callParam)
  self:OnAddEventListener()
  if not param then
    Log.Error("UMG_AppearanceSuit_C:OnActive invalid param", param, shopId, fashionItemId)
    return
  end
  self.suitId = param
  self.fashionItemId = fashionItemId
  self.Caller = callParam and callParam.Caller
  self.CallBack = callParam and callParam.CallBack
  self.suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.suitId)
  if not self.suitConf then
    Log.Error("UMG_AppearanceSuit_C:OnActive invalid param", self.suitId, shopId, fashionItemId)
    return
  end
  self.fashionItemConf = _G.DataConfigManager:GetFashionItemConf(self.fashionItemId, true)
  self:UpdatePanelInfo()
  _G.NRCAudioManager:PlaySound2DAuto(40007008, "UMG_AppearanceSuit_C:OnActive")
  self:LoadAnimation(0)
end

function UMG_AppearanceSuit_C:OnDeactive()
  if self.PerformDelayId then
    self:CancelDelayByID(self.PerformDelayId)
    self.PerformDelayId = nil
  end
end

function UMG_AppearanceSuit_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnCloseBtnClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_AppearanceSuit_C", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
end

function UMG_AppearanceSuit_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
end

function UMG_AppearanceSuit_C:OnReConnectStart()
  self:OnCloseBtnClicked()
end

function UMG_AppearanceSuit_C:OnDestruct()
  self:OnRemoveEventListener()
  if self.PerformDelayId then
    self:CancelDelayByID(self.PerformDelayId)
    self.PerformDelayId = nil
  end
end

function UMG_AppearanceSuit_C:OnAnimationFinished(anim)
  if self:GetAnimByIndex(2) == anim then
    self:DoClose()
  end
end

function UMG_AppearanceSuit_C:OnCloseBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40007009, "UMG_AppearanceSuit_C:OnCloseBtnClicked")
  if self.Caller and self.CallBack then
    self.CallBack(self.Caller)
  end
  if self:GetAnimByIndex(2) then
    self:LoadAnimation(2)
  else
    self:DoClose()
  end
end

function UMG_AppearanceSuit_C:UpdatePanelInfo()
  local name = self.fashionItemConf and self.fashionItemConf.name or self.suitConf.name
  self.SuitName:SetText(name)
  if self.suitConf.suit_grade ~= Enum.SuitGrade.SG_BOND and self.suitConf.flavor_text == nil then
    self.DescSwitcher:SetActiveWidgetIndex(0)
  else
    self.DescSwitcher:SetActiveWidgetIndex(1)
  end
  self.Pose:SetPath(self.suitConf.suits_icon_big)
  self:SetInfoByGrade(self.suitConf.suit_grade)
  self:SetSuitIcon()
  local GainWayData = self.suitConf.acquire_struct
  self.GainWay:InitGridView(GainWayData)
  self.Bg_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_AppearanceSuit_C:SetInfoByGrade(suitQuality)
  local color = "ffffffff"
  local descText = ""
  if suitQuality == Enum.SuitGrade.SG_DAILY then
    color = "5fb5d5ff"
    descText = self.suitConf.flavor_text
    self.PetShowPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TimesText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif suitQuality == Enum.SuitGrade.SG_UNIFORM then
    color = "9b73f8ff"
    descText = self.suitConf.flavor_text
    self.PetShowPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TimesText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif suitQuality == Enum.SuitGrade.SG_UNIBOND then
    color = "9b73f8ff"
    descText = self.suitConf.flavor_text
    self.TimesText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetShowPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.suitConf.petbase_id and #self.suitConf.petbase_id > 0 then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.suitConf.petbase_id[1])
      if petBaseConf then
        local petid = self.suitConf.petbase_id[1]
        if self.suitConf.suits_original_id and 0 ~= self.suitConf.suits_original_id then
          petid = string.format("%s_1", petid)
        end
        local IconPath = string.format("%s%s.%s", _G.UIIconPath.BigHeadIconPath, petid, petid)
        self.PetHeadIcon:SetPath(IconPath)
      end
    end
  elseif suitQuality == Enum.SuitGrade.SG_BOND then
    color = "f8a955ff"
    local desc = _G.DataConfigManager:GetLocalizationConf("fashion_suits_countpvp").msg
    self.PetShowPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.suitConf.petbase_id and #self.suitConf.petbase_id > 0 then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.suitConf.petbase_id[1])
      if petBaseConf then
        descText = string.format(desc, petBaseConf.name, 0)
        local petid = self.suitConf.petbase_id[1]
        if self.suitConf.suits_original_id and 0 ~= self.suitConf.suits_original_id then
          petid = string.format("%s_1", petid)
        end
        local IconPath = string.format("%s%s.%s", _G.UIIconPath.BigHeadIconPath, petid, petid)
        self.PetHeadIcon:SetPath(IconPath)
      end
    end
    self.TimesText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TimesText:SetText(self.data:GetCurSuitPvPInfo(self.suitId))
  end
  self.SuitQualityColor3_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  self.SuitQualityColor3_2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  self.SuitQualityColor2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  self.SuitQualityColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  self.DescText:SetText(descText)
  return color, descText
end

function UMG_AppearanceSuit_C:SetSuitIcon()
  local suitIconPath
  if self.suitConf.suit_grade == Enum.SuitGrade.SG_DAILY then
    suitIconPath = DataConfigManager:GetRoleGlobalConfig("fashion_icon_suitgrade_daily").str
  elseif self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIFORM then
    suitIconPath = DataConfigManager:GetRoleGlobalConfig("fashion_icon_suitgrade_uniform").str
  elseif self.suitConf.suit_grade == Enum.SuitGrade.SG_BOND or self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIBOND then
    suitIconPath = DataConfigManager:GetRoleGlobalConfig("fashion_icon_suitgrade_bond").str
  end
  self.SuitIcon:SetPath(suitIconPath)
  local suitNum = #self.suitConf.item_id
  local fashionOwned, fashionNotOwned = self.data:GetFashionOwnedBySuitId(self.suitId)
  
  local function HasOwned(fashionItemId)
    for _, val in ipairs(fashionOwned) do
      if fashionItemId == val then
        return true
      end
    end
    return false
  end
  
  local ArrangeFashionItemArray = {}
  for k, v in ipairs(self.suitConf.item_id) do
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v, true)
    if fashionItemConf then
      local hasOwned = HasOwned(v)
      table.insert(ArrangeFashionItemArray, {
        ItemId = v,
        icon = fashionItemConf.icon,
        bSelected = v == self.fashionItemId,
        bHasOwned = hasOwned,
        fashionLabelType = fashionItemConf.type
      })
    end
  end
  table.sort(ArrangeFashionItemArray, function(a, b)
    if a.bSelected or b.bSelected then
      return a.bSelected
    end
    if a.bHasOwned ~= b.bHasOwned then
      return a.bHasOwned
    end
    return AppearanceUtils.GetFashionLabelSortPriority(a.fashionLabelType, self.fashionLabelSortTable) < AppearanceUtils.GetFashionLabelSortPriority(b.fashionLabelType, self.fashionLabelSortTable)
  end)
  if 3 == suitNum then
    self.Suit:SetActiveWidgetIndex(0)
    for idx, itemData in ipairs(ArrangeFashionItemArray) do
      self:UpdateAppearanceSuitItemIcon(self.suit3_1[idx], itemData, true, idx)
    end
  elseif 4 == suitNum then
    self.Suit:SetActiveWidgetIndex(1)
    for idx, itemData in ipairs(ArrangeFashionItemArray) do
      self:UpdateAppearanceSuitItemIcon(self.suit4_1[idx], itemData, true, idx)
    end
  else
    self.Suit:SetActiveWidgetIndex(2)
    if 5 == suitNum then
      self.AppearanceSuitItem5_6:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AppearanceSuitItem5_7:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AppearanceSuitItem5_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif 6 == suitNum then
      self.AppearanceSuitItem5_6:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AppearanceSuitItem5_7:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.AppearanceSuitItem5_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif 7 == suitNum then
      self.AppearanceSuitItem5_6:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AppearanceSuitItem5_7:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AppearanceSuitItem5_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.AppearanceSuitItem5_6:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AppearanceSuitItem5_7:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AppearanceSuitItem5_8:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    for idx, itemData in ipairs(ArrangeFashionItemArray) do
      self:UpdateAppearanceSuitItemIcon(self.suit5_1[idx], itemData, false, idx)
    end
  end
  self:SetCollectProgress(fashionOwned, fashionNotOwned)
end

function UMG_AppearanceSuit_C:SetCollectProgress(fashionwOwned, fashionNotOwned)
  if self.suitConf == nil then
    Log.Warning("UMG_AppearanceSuit_C:SetCollectProgress self.suitConf is nil")
    return
  end
  local isCollected = nil == fashionNotOwned or 0 == #fashionNotOwned
  local fashionOwnedNum = fashionwOwned and #fashionwOwned or 0
  local fashionNotOwnedNum = fashionNotOwned and #fashionNotOwned or 0
  local fashionTotalNum = fashionOwnedNum + fashionNotOwnedNum
  if self.suitConf.suit_grade == Enum.SuitGrade.SG_BOND then
    if isCollected then
      self:SetPvPInfo()
    else
      self:SetCollectInfo(fashionOwnedNum, fashionTotalNum)
    end
  elseif self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIBOND or self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIFORM then
    if isCollected then
      self:SetFlavorText()
    else
      self:SetCollectInfo(fashionOwnedNum, fashionTotalNum)
      if self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIFORM then
        self.DescText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.DescText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  else
    self:SetFlavorText()
  end
  self.DescSwitcher:SetActiveWidgetIndex(1)
  if self.Bg then
    self.Bg:SwitchToSetBrushFromMaterialInstanceMode(not isCollected)
    self.Bg:SetPath("Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Monthly/Textures/img_xingxing1.img_xingxing1'")
  end
end

function UMG_AppearanceSuit_C:SetCollectInfo(ownedNum, totalNum)
  local desc = _G.DataConfigManager:GetLocalizationConf("fashion_suits_collect_text").msg
  local timeText = _G.DataConfigManager:GetLocalizationConf("fashion_suits_collect_process").msg
  self.DescText:SetText(desc)
  self.TimesText:SetText(string.format(timeText, ownedNum, totalNum))
  self.TimesText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_AppearanceSuit_C:SetPvPInfo()
  local desc = _G.DataConfigManager:GetLocalizationConf("fashion_suits_countpvp").msg
  self.PetShowPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.suitConf.petbase_id and #self.suitConf.petbase_id > 0 then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.suitConf.petbase_id[1])
    if petBaseConf then
      self.DescText:SetText(string.format(desc, petBaseConf.name, 0))
    end
  end
  self.TimesText:SetText(self.data:GetCurSuitPvPInfo(self.suitId))
  self.TimesText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_AppearanceSuit_C:SetFlavorText()
  self.DescText:SetText(self.suitConf.flavor_text or "")
  self.TimesText:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_AppearanceSuit_C:UpdateAppearanceSuitItemIcon(widget, itemData, bBig, index)
  if not widget or not itemData then
    return
  end
  local color = "ffffffff"
  local greyColor = "e1dcd0ff"
  if itemData.bHasOwned or itemData.bSelected then
    if self.suitConf.suit_grade == Enum.SuitGrade.SG_DAILY then
      color = "5fb5d5ff"
    elseif self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIFORM or self.suitConf.suit_grade == Enum.SuitGrade.SG_UNIBOND then
      color = "9b73f8ff"
    elseif self.suitConf.suit_grade == Enum.SuitGrade.SG_BOND then
      color = "f8a955ff"
    end
  else
    color = greyColor
  end
  if widget.SetData and widget.StartPerform then
    widget:SetData(index, itemData.bSelected, itemData.bHasOwned, bBig, itemData.icon, color, greyColor)
    if itemData.bSelected and not itemData.bHasOwned then
      self.SelectedWidget = widget
      if self.PerformDelayId then
        self:CancelDelayByID(self.PerformDelayId)
        self.PerformDelayId = nil
      end
      self.PerformDelayId = self:DelaySeconds(0.5, function()
        if self.SelectedWidget and UE4.UObject.IsValid(self.SelectedWidget) and self.SelectedWidget.StartPerform then
          self.SelectedWidget:StartPerform()
        end
      end)
    end
  end
end

return UMG_AppearanceSuit_C

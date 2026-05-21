local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Common_ListItemIcon_C = Base:Extend("UMG_Common_ListItemIcon_C")

function UMG_Common_ListItemIcon_C:OnConstruct()
end

function UMG_Common_ListItemIcon_C:OnDestruct()
end

function UMG_Common_ListItemIcon_C:OnTick(InDeltaTime)
  if not self._pressed or not self._longPressTimer then
    return
  end
  if not self.uiData.bEnableLongClick then
    return
  end
  self._longPressTimer = self._longPressTimer - InDeltaTime
  if self._longPressTimer <= 0 then
    self:OnItemBeLongClicked()
  end
end

function UMG_Common_ListItemIcon_C:OnItemUpdate(_data, datalist, index)
  if not _data or not index then
    Log.Debug("UMG_Common_ListItemIcon_C:OnItemUpdate: input param _data or index is nil, check call stack to find why")
    return
  end
  self.IsSelect = false
  self.uiData = _data
  self._index = index
  self:SetInfo()
  if _data.SpecialShowHandle then
    _data.SpecialShowHandle = nil
    self:SpecialShowHandle()
  end
end

function UMG_Common_ListItemIcon_C:SpecialShowHandle()
  self.BGColor:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.change1)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41400001, "UMG_ItemRewards_C:OnActive")
end

function UMG_Common_ListItemIcon_C:SetInfo()
  local _data = self.uiData
  local iconPath = ""
  local iconNum = _data.itemNum
  local tag = self.uiData.tag
  local colorRed = "#AF3A3DFF"
  if _data.itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(_data.itemId)
    if nil ~= vItemConf then
      self.visualItemId = vItemConf.id
      self:SetQuality(vItemConf.item_quality)
      iconPath = vItemConf.bigIcon
    end
    if _data.checkIsEnough then
      local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_data.itemId)
      if nil == num then
        num = 0
      end
      if iconNum > num then
        self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorRed))
      end
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(_data.itemId)
    if nil ~= bagItemConf then
      local item_quality = self.uiData.AssignQuality or bagItemConf.item_quality
      local bagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self.uiData and self.uiData.bagItemGid)
      if not bagItemInfo and _data.bag_item then
        bagItemInfo = _data.bag_item
      end
      local egg_data = bagItemInfo and bagItemInfo.egg_data
      if egg_data then
        local IsPrecious = egg_data.precious_egg_type and egg_data.precious_egg_type ~= ProtoEnum.PreciousEggType.PET_NONE
        if IsPrecious then
          item_quality = 5
        end
      end
      self:SetQuality(item_quality)
      iconPath = bagItemConf.icon
    end
    if _data.checkIsEnough then
      local bagItem = NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, _data.itemId)
      if bagItem then
        if iconNum > bagItem.num then
          self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorRed))
        end
      else
        self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(colorRed))
      end
    end
    if self.Time then
      self.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if _data.IsShowExpire then
      self:SafeCall(self.Mask, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
      self:SafeCall(self.Expired_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_BP_GIFT_SUB then
      local bagModule = _G.NRCModuleManager:GetModule("BagModule")
      if bagModule then
        local bagModuleData = bagModule:GetData()
        if bagModuleData then
          local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
          local expireStatus = bagModuleData:CheckItemExpireStatus(bagItemConf, expireThreshold)
          if self.Time then
            self.Time:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Time_Black:SetVisibility(UE4.ESlateVisibility.Visible)
            self.Time_Red:SetVisibility(UE4.ESlateVisibility.Visible)
            self.Expired:SetVisibility(UE4.ESlateVisibility.Visible)
            if expireStatus.isExpired then
              self.Time:SetActiveWidgetIndex(2)
            elseif expireStatus.isNearExpire then
              self.Time:SetActiveWidgetIndex(1)
            else
              self.Time:SetActiveWidgetIndex(0)
            end
          end
        end
      end
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_PET then
    if _data.IsShowPetbase then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_data.itemId)
      if nil ~= petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        if petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and modelConf.shiny_icon then
          iconPath = modelConf.shiny_icon
        else
          iconPath = modelConf.icon
        end
      end
    else
      local petInfo = _G.DataConfigManager:GetPetConf(_data.itemId, true)
      if petInfo then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
        if nil ~= petBaseConf then
          local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
          if petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and modelConf.shiny_icon then
            iconPath = modelConf.shiny_icon
          else
            iconPath = modelConf.icon
          end
        end
      else
        local monsterConf = _G.DataConfigManager:GetMonsterConf(_data.itemId)
        if nil ~= monsterConf then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
          if nil ~= petBaseConf then
            local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
            if petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and modelConf.shiny_icon then
              iconPath = modelConf.shiny_icon
            else
              iconPath = modelConf.icon
            end
          end
        end
      end
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(_data.itemId)
    if cardSkinConf then
      self:SetQuality(cardSkinConf.card_quality)
      iconPath = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(_data.itemId)
    if GetCardIconConf then
      self:SetQuality(GetCardIconConf.card_quality)
      iconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path)
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(_data.itemId)
    if CardLabelConf then
      self:SetQuality(CardLabelConf.card_quality)
      iconPath = CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(_data.itemId)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      self:SetQuality(grade)
      iconPath = fashionConf.suits_icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(_data.itemId)
    if fashionConf then
      local grade = fashionConf.item_quality
      self:SetQuality(grade)
      iconPath = fashionConf.icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(_data.itemId)
    if salonConf then
      local grade = salonConf.item_quality
      self:SetQuality(grade)
      iconPath = salonConf.icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(_data.itemId)
    if shareConf then
      self:SetQuality(shareConf.item_quality)
      iconPath = shareConf.item_icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(_data.itemId)
    if itemConf then
      self:SetQuality(5)
      iconPath = itemConf.icon_path
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(_data.itemId)
    if ChatEmojiConf then
      self:SetQuality(ChatEmojiConf.card_quality)
      iconPath = ChatEmojiConf.emoji_goods_icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_REWARD then
    local rewardData = ActivityUtils.GetActivityRewardData(_data.itemId, true)
    self:SetQuality(rewardData.itemQuality)
    iconPath = rewardData.showIcon
  elseif _data.itemType == _G.Enum.GoodsType.GT_FASHION_BOND then
    local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(_data.itemId)
    if fashionBondConf then
      if fashionBondConf.fashion_bond_quality == Enum.FashionBondQuality.FBQ_S then
        self:SetQuality(5)
      else
        self:SetQuality(4)
      end
      iconPath = fashionBondConf.fashion_bond_icon
    end
  elseif _data.itemType == _G.Enum.GoodsType.GT_MEDAL then
    local medalConf = _G.DataConfigManager:GetMedalConf(_data.itemId)
    if medalConf then
      iconPath = medalConf.icon
      self:SetQuality(medalConf.quality)
    end
  end
  if _data.bShowNum == true then
    self.Quantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetNumSize(self.uiData.itemNum)
  if iconNum then
    self.Text_Quantity:SetText(string.format("x%d", iconNum))
  end
  if _data.numTextHexColor then
    self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(_data.numTextHexColor))
  elseif _data.isAddNum then
    self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#5c9f11ff"))
  elseif _data.isSubNum then
    self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#ae3d3eff"))
  elseif _data.checkIsEnough then
  else
    self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#908F85FF"))
  end
  if _data.itemType == _G.Enum.GoodsType.GT_SALON then
    if UE.UObject.IsValid(self.MakeupProp) then
      local salonConf = _G.DataConfigManager:GetSalonItemConf(_data.itemId)
      if salonConf and #salonConf.colour_id > 0 then
        self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Closet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      self.IconSwitcher:SetActiveWidgetIndex(3)
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.MakeupProp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Icon_Makeup:SetPath(iconPath)
      self.Closet:OnItemUpdate({
        isOther = true,
        lockState = true,
        salonConfId = _data.itemId
      })
    end
  else
    local isEgg
    if _data.itemType == _G.Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.itemId)
      if bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_EGG then
        isEgg = true
      end
    end
    if isEgg then
      self:SetIcon(iconPath)
    else
      if self.IconSwitcher then
        self.IconSwitcher:SetActiveWidgetIndex(0)
      end
      self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if string.IsNilOrEmpty(iconPath) and _data.showDefaultIconWhenConfigError then
        local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
        if commonIconConfig and commonIconConfig.str then
          Log.Debug("UMG_Common_ListItemIcon_C:SetInfo showDefaultIconWhenNotFound, iconpath is empty, set to default", tostring(commonIconConfig.str))
          iconPath = commonIconConfig.str
          self:SetQuality(1)
        else
          Log.Error("UMG_Common_ListItemIcon_C:SetInfo showDefaultIconWhenNotFound no default image config for common_reward_icon in activity_global_config")
        end
      end
      if _data.showDefaultIconWhenConfigError then
        Log.Debug("UMG_Common_ListItemIcon_C:SetInfo showDefaultIconWhenConfigError", tostring(iconPath))
        self.itemIconPath = iconPath
        self.Icon:SetPathWithSuccessAndFailedCallBack(iconPath, {
          self,
          self.IconSetPathSuccess
        }, {
          self,
          self.IconSetPathFailed
        })
      else
        self.Icon:SetPath(iconPath)
      end
      if UE.UObject.IsValid(self.MakeupProp) then
        self.MakeupProp:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  self:SetConverted(self.uiData.bConverted)
  self:SetAlreadyReceived(self.uiData.bShowGetTag or self.uiData.isDone or self.uiData.bGray)
  self:SetExtra_1(self.uiData.bShowFirstVictory)
  if self.NRCImage_38 then
    self.NRCImage_38:SetVisibility(self.uiData.bGray and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if _data.bShowTaskTag or _data.isPreciousPetEgg and not self.uiData.isDone then
    self.UP:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if _data.isPreciousPetEgg then
      self.UP:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_zhangui_dan_png.img_zhangui_dan_png'")
    end
  else
    self.UP:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.Extra then
    self.Extra:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if _data.reward_reason and _data.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_LEADER_FIGHT_EXTRA_REWARD then
      self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.ExtraText then
        self.ExtraText:SetText("\232\191\189\229\138\160")
      end
    elseif tag and 0 ~= tag and _data.reward_reason and _data.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_AWARD_USE_STAR or _data.reward_reason and _data.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_HOME_PLANT_SEED_GOOD_YIELD or _data.reward_reason and _data.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_HOME_PET_SURPRISE_REWARD then
      self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ExtraText:SetText("\233\162\157\229\164\150")
    elseif tag == Enum.RewardTag.RTA_ACTIVITY and _data.reward_reason and _data.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_ACTIVITY_DROP then
      self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ExtraText:SetText(LuaText.activity_special_tip)
    elseif tag == _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_MEDAL then
      self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ExtraText:SetText(_G.LuaText.FlowerHard_RewardTag_Medal)
    elseif tag == _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
      self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ExtraText:SetText(_G.LuaText.FlowerHard_RewardTag_First)
    elseif _data.itemId and _data.itemType == _G.Enum.GoodsType.GT_BAGITEM then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(_data.itemId)
      if BagItemConf then
        local BagItemType = BagItemConf.type
        if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO then
          self.Extra:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.ExtraText:SetText(LuaText.BossEvoItem_Title)
        end
      end
    end
  elseif self.CountLabel then
    if tag == _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_MEDAL then
      self.CountLabel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NumberText:SetText(_G.LuaText.FlowerHard_RewardTag_Medal)
    elseif tag == _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
      self.CountLabel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NumberText:SetText(_G.LuaText.FlowerHard_RewardTag_First)
    end
  end
  if nil == self.uiData.IsCanClick then
    self:SetClickable(true)
  elseif not self.uiData.IsCanClick then
    self:SetClickable(false)
  else
    self:SetClickable(true)
  end
  if self.Additional then
    if _data.bShowAdditional then
      self.Additional:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Additional:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
  if UE.UObject.IsValid(self.CanvasPanel) then
    if _data.bShowAdditional or _data.topLabelText then
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      if _data.topLabelText then
        self.NRCText:SetText(_data.topLabelText)
        self:SetTextSize(self.NRCText, _data.topLabelText)
      end
    else
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
  self.Color:SetVisibility(_data.itemType == _G.Enum.GoodsType.GT_PET and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.ClassUMG then
    if _data.classIcon then
      self.ClassUMG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ClassUMG.ClassIcon:SetPath(_data.classIcon)
      if not string.IsNilOrEmpty(_data.classNumber) then
        self.ClassUMG.Switcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.ClassUMG.Switcher_1:SetActiveWidgetIndex(0)
        self.ClassUMG.DanGrading:SetPath(_data.classNumber)
      else
        self.ClassUMG.Switcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.ClassUMG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Common_ListItemIcon_C:SetTextSize(textWidget, text)
  if textWidget then
    local length = string.len(text)
    local Font = textWidget.Font
    if length <= 6 then
      Font.Size = 22
      textWidget:SetFont(Font)
    else
      Font.Size = 18
      textWidget:SetFont(Font)
    end
  end
end

function UMG_Common_ListItemIcon_C:OnTouchStarted(MyGeometry, InTouchEvent)
  _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.EnableShowDescTips, false)
  self._pressed = true
  if self.uiData.bEnableLongClick then
    self._longPressTimer = BattleConst.ItemLongPressThreshold
    _G.UpdateManager:Register(self)
  end
  Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Common_ListItemIcon_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local oldPress = self._pressed
  oldPress = true
  self._pressed = false
  if self.uiData.bEnableLongClick then
    _G.UpdateManager:UnRegister(self)
  end
  if oldPress then
    return Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Common_ListItemIcon_C:IconSetPathSuccess()
  Log.Debug("UMG_Common_ListItemIcon_C:IconSetPathSuccess")
end

function UMG_Common_ListItemIcon_C:IconSetPathFailed()
  Log.Warning("UMG_Common_ListItemIcon_C:IconSetPathFailed", tostring(self.itemIconPath))
  local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
  if commonIconConfig and commonIconConfig.str then
    self.itemDefaultIconPath = commonIconConfig.str
    self.Icon:SetPathWithSuccessAndFailedCallBack(commonIconConfig.str, {
      self,
      self.IconSetDefaultPathSuccess
    }, {
      self,
      self.IconSetDefaultPathFailed
    })
  else
    Log.Error("UMG_Common_ListItemIcon_C:IconSetPathFailed no default image config for common_reward_icon in activity_global_config")
  end
end

function UMG_Common_ListItemIcon_C:SetNumSize(Count)
  local number = Count
  local numberStr = tostring(number)
  local length = string.len(numberStr)
  local Font = self.Text_Quantity.Font
  if length > 5 then
    Font.Size = 22
    self.Text_Quantity:SetFont(Font)
  elseif self.uiData.bIsEmail then
    Font.Size = 30
    self.Text_Quantity:SetFont(Font)
  end
  self:SetRedDotData()
end

function UMG_Common_ListItemIcon_C:SetIconPath(iconPath, isShowDefaultIconWhenConfigError)
  self.itemIconPath = iconPath
  if isShowDefaultIconWhenConfigError then
    self.Icon:SetPathWithSuccessAndFailedCallBack(iconPath, {
      self,
      self.IconSetPathSuccess
    }, {
      self,
      self.IconSetPathFailed
    })
  else
    self.Icon:SetPath(iconPath)
  end
end

function UMG_Common_ListItemIcon_C:IconSetDefaultPathSuccess()
  Log.Debug("UMG_Common_ListItemIcon_C:IconSetDefaultPathSuccess")
end

function UMG_Common_ListItemIcon_C:IconSetDefaultPathFailed()
  Log.Error("UMG_Common_ListItemIcon_C:IconSetDefaultPathFailed", tostring(self.itemDefaultIconPath))
end

function UMG_Common_ListItemIcon_C:HideTextQuantity()
  self.Quantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Common_ListItemIcon_C:SetConverted(bConverted)
  if bConverted then
    self:SafeCall(self.Converted, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SafeCall(self.ConvertedText, "SetText", LuaText.goods_return_text)
  else
    self:SafeCall(self.Converted, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_ListItemIcon_C:SetAlreadyReceived(bShowGetTag)
  if true == bShowGetTag then
    self.AlreadyReceived:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.Time then
      self.Time:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.AlreadyReceived:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_ListItemIcon_C:SetExtra_1(bShowFirstVictory)
  local bShowExtra = bShowFirstVictory
  if bShowExtra then
    self:SafeCall(self.Extra_1, "SetVisibility", UE4.ESlateVisibility.SelfHitTestInvisible)
    local index
    if bShowFirstVictory then
      index = 2
    end
    if index then
      self:SafeCall(self.Switcher, "SetActiveWidgetIndex", UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self:SafeCall(self.Extra_1, "SetVisibility", UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_ListItemIcon_C:SetRedDotData()
  if self.RedDot ~= nil and self.uiData and self.uiData.Key and self.uiData.extraKey then
    self.RedDot:SetupKey(self.uiData.Key, self.uiData.extraKey)
  end
end

function UMG_Common_ListItemIcon_C:SetPlaySound(_IsBPlaySound)
  if self.uiData then
    self.uiData.IsBPlaySound = _IsBPlaySound
  end
end

function UMG_Common_ListItemIcon_C:UpdateNum(num)
  if self.uiData then
    self.uiData.itemNum = num
    self.uiData.BagNum = num
    self:SetNumSize(self.uiData.itemNum)
    if self.uiData.itemNum then
      self.Text_Quantity:SetText(string.format("x%d", self.uiData.itemNum))
    end
  end
end

function UMG_Common_ListItemIcon_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_1)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_2)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_3)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_4)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.BGColor:SetPath(UEPath.PROP_QUALITY_5)
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Common_ListItemIcon_C:SetCanClick(IsCanClick)
  if not IsCanClick then
    self:SetClickable(false)
  else
    self:SetClickable(true)
  end
end

function UMG_Common_ListItemIcon_C:OnItemSelected(_bSelected, _isScroll)
  Log.Debug(self.IsSelect, "UMG_Common_ListItemIcon_C:OnItemSelected")
  if _bSelected then
    if not self.uiData then
      return
    end
    if self.uiData.OnClicked then
      self.uiData.OnClicked(self.uiData, self._index)
    end
    if self.uiData.bShowTip and not self.uiData.IsDoCmd and not _isScroll then
      self:OpenTips()
      return
    end
    if self.uiData.IsDoCmd then
      if self.uiData.IsOnlyShowDebris and self.uiData.IsOnlyShowDebris == true then
        self:OpenTips()
        return
      end
      if self.IsSelect then
        self:OpenTips()
      else
        if self.uiData.DoCmd then
          _G.NRCModuleManager:DoCmd(self.uiData.DoCmd, self._index, self.uiData)
        end
        self:StopAllAnimations()
        self:PlayAnimation(self.change1)
        self.IsSelect = true
        if self.uiData.bSelectItem and true == self.uiData.bSelectItem then
          if self.visualItemId and self.visualItemId == Enum.VisualItem.VI_STAR then
            _G.NRCModeManager:DoCmd(StarChainModuleCmd.ShowStarDebrisText, false)
            _G.NRCModeManager:DoCmd(StarChainModuleCmd.RefreshConfirmation, _G.Enum.VisualItem.VI_STAR, self.uiData, self._index)
            _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetSelectRecoveryItem, _G.Enum.VisualItem.VI_STAR)
          elseif self.visualItemId and self.visualItemId == Enum.VisualItem.VI_STAR_DEBRIS then
            _G.NRCModeManager:DoCmd(StarChainModuleCmd.ShowStarDebrisText, true)
            _G.NRCModeManager:DoCmd(StarChainModuleCmd.RefreshConfirmation, _G.Enum.VisualItem.VI_STAR_DEBRIS, self.uiData, self._index)
            _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetSelectRecoveryItem, _G.Enum.VisualItem.VI_STAR_DEBRIS)
          end
        end
      end
    elseif self.visualItemId and self.visualItemId == Enum.VisualItem.VI_STAR then
      self:StopAllAnimations()
      self:PlayAnimation(self.change1)
      self.IsSelect = true
      _G.NRCModeManager:DoCmd(StarChainModuleCmd.ShowStarDebrisText, false)
      _G.NRCModeManager:DoCmd(StarChainModuleCmd.RefreshConfirmation, _G.Enum.VisualItem.VI_STAR)
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetSelectRecoveryItem, _G.Enum.VisualItem.VI_STAR)
    elseif self.visualItemId and self.visualItemId == Enum.VisualItem.VI_STAR_DEBRIS then
      self:StopAllAnimations()
      self:PlayAnimation(self.change1)
      self.IsSelect = true
      _G.NRCModeManager:DoCmd(StarChainModuleCmd.ShowStarDebrisText, true)
      _G.NRCModeManager:DoCmd(StarChainModuleCmd.RefreshConfirmation, _G.Enum.VisualItem.VI_STAR_DEBRIS)
      _G.NRCModeManager:DoCmd(BattleUIModuleCmd.SetSelectRecoveryItem, _G.Enum.VisualItem.VI_STAR_DEBRIS)
    else
      self:StopAllAnimations()
      local _data = self.uiData
      if _data.itemType == _G.Enum.GoodsType.GT_BAGITEM then
        if _data.IsPetBall then
          self:PlayAnimation(self.change1)
          self.IsSelect = true
        else
          if _isScroll then
            return
          end
          local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
          local showErrorTipsWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
          local showDefaultIconWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
          local quality = self.uiData and self.uiData.AssignQuality
          _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, _data.itemId, _G.Enum.GoodsType.GT_BAGITEM, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound, nil, quality)
        end
      elseif _data.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
        _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, _data.itemId)
      elseif _data.itemType == _G.Enum.GoodsType.GT_VITEM then
        local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
        local showErrorTipsWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
        local showDefaultIconWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, _data.itemId, _data.itemType, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
      elseif _data.itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
        local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
        local showErrorTipsWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
        local showDefaultIconWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, _data.itemId, _data.itemType, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
      end
    end
  elseif self.IsSelect == true then
    self:StopAllAnimations()
    self:PlayAnimation(self.change2)
    self.IsSelect = false
  end
end

function UMG_Common_ListItemIcon_C:OnItemBeLongClicked()
  if self and UE4.UObject.IsValid(self) then
    self._pressed = false
    self._longPressTimer = 0
    _G.UpdateManager:UnRegister(self)
    if self.uiData.IsPetBall then
      local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
      local showErrorTipsWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
      local showDefaultIconWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.itemId, _G.Enum.GoodsType.GT_BAGITEM, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
    end
  end
end

function UMG_Common_ListItemIcon_C:OnAnimationFinished(Animation)
  if Animation == self.change1 then
    self:PlayAnimation(self.select, 0, 9999)
  elseif Animation == self.change2 then
    self:PlayAnimation(self.normal, 0, 9999)
  elseif Animation == self.Loop and self.needLoop then
    self:PlayAnimation(self.Loop)
  end
end

function UMG_Common_ListItemIcon_C:PlayLoopAnim()
  self.needLoop = true
  self:PlayAnimation(self.Loop)
end

function UMG_Common_ListItemIcon_C:StopPlayLoopAnim()
  self.needLoop = false
  self:StopAnimation(self.Loop)
end

function UMG_Common_ListItemIcon_C:OpenTips()
  if self:CheckIsSelectBtn() then
    return
  end
  self:LockSelectBtn()
  if self.uiData.openTipsSoundId then
    _G.NRCAudioManager:PlaySound2DAuto(self.uiData.openTipsSoundId, "UMG_Common_ListItemIcon_C:OpenTips")
  else
    _G.NRCAudioManager:PlaySound2DAuto(1303, "UMG_Common_ListItemIcon_C:OpenTips")
  end
  if self.uiData.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.uiData.itemId)
  elseif self.uiData.itemType == _G.Enum.GoodsType.GT_REWARD then
    ActivityUtils.ShowRewardPreview(self.uiData.itemId)
  elseif self.uiData.bagItemGid then
    local bagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self.uiData.bagItemGid)
    if not bagItemInfo then
      Log.Error("bagItemGid\229\175\185\229\186\148\231\154\132\231\137\169\229\147\129\228\184\141\229\173\152\229\156\168", self.uiData.bagItemGid)
      return
    end
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpenItemTipsBrief, self.uiData.itemId, self.uiData.itemType, {
      eggData = bagItemInfo.egg_data,
      quality = 5
    })
  else
    local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
    local showErrorTipsWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
    local showDefaultIconWhenNotFound = self.uiData and self.uiData.showDefaultIconWhenConfigError
    if self.uiData.IsShowPetbase then
      local param = {
        GoodsID = self.uiData.itemId,
        GoodsType = self.uiData.itemType,
        IsShowPetbase = self.uiData.IsShowPetbase
      }
      _G.NRCModeManager:DoCmd(TipsModuleCmd.OpenItemTipsSimplify, param)
      return
    end
    local param, GID
    if self.uiData and self.uiData.bagItemGid then
      GID = self.uiData.bagItemGid
    end
    if self.uiData and self.uiData.bag_item then
      GID = self.uiData.bag_item.gid
    end
    if self.uiData and self.uiData.gid then
      GID = self.uiData.gid
    end
    if self.uiData and self.uiData.eggInfo then
      param = {
        EggInfo = self.uiData.eggInfo
      }
    end
    local quality = self.uiData and self.uiData.AssignQuality
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.itemId, self.uiData.itemType, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound, GID, quality, param)
  end
end

function UMG_Common_ListItemIcon_C:OnDeactive()
  self.uiData = nil
end

function UMG_Common_ListItemIcon_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if self.clickable and not self.IsSelect then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Common_ListItemIcon_C:OnItemSelected")
  end
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Common_ListItemIcon_C:CheckIsSelectBtn()
  if self.uiData.touchLimitData then
    return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, self.uiData.touchLimitData.module, self.uiData.touchLimitData.panel)
  else
    return false
  end
end

function UMG_Common_ListItemIcon_C:LockSelectBtn()
  if self.uiData.touchLimitData then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, self.uiData.touchLimitData.panel).TIPSITEM
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, self.uiData.touchLimitData.module, self.uiData.touchLimitData.panel, touchReasonType)
  end
end

function UMG_Common_ListItemIcon_C:SetIcon(icon_path)
  if self.uiData and self.uiData.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.itemId)
    if bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_EGG then
      local bagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self.uiData and self.uiData.bagItemGid)
      if not bagItemInfo and self.uiData.bag_item then
        bagItemInfo = self.uiData.bag_item
      end
      local egg_data = bagItemInfo and bagItemInfo.egg_data
      if not egg_data then
        if bagItemConf.item_behavior and bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].ratio2 and bagItemConf.item_behavior[1].ratio2[1] then
          egg_data = {}
          egg_data.random_egg_conf = bagItemConf.item_behavior[1].ratio2[1]
          local randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(bagItemConf.item_behavior[1].ratio2[1])
          if randomEggConf then
            local PreciousEggType = randomEggConf.precious_egg_type
            if PreciousEggType ~= _G.Enum.PreciousEggType.PET_NONE then
              local quality = 5
              self:SetQuality(quality)
            end
          end
        end
        if self.uiData.eggInfo then
          egg_data = self.uiData.eggInfo
          if self.uiData.eggInfo and self.uiData.eggInfo.glass_info then
            local quality = 5
            self:SetQuality(quality)
          end
        end
      end
      if egg_data and self.IconSwitcher and self.PetEggIcon then
        self.IconSwitcher:SetActiveWidgetIndex(2)
        self.PetEggIcon:SetEggIcon(egg_data, icon_path)
        return
      end
    end
  end
  if self.IconSwitcher then
    self.IconSwitcher:SetActiveWidgetIndex(0)
  end
  self.Icon:SetPath(icon_path)
end

return UMG_Common_ListItemIcon_C

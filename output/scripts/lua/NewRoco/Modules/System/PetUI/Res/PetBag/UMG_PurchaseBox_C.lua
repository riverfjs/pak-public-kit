local UMG_PurchaseBox_C = _G.NRCPanelBase:Extend("UMG_PurchaseBox_C")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")

function UMG_PurchaseBox_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
  self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PurchaseBox_C:OnActive(data)
  if data then
    self.warehouseConf = data.conf
    self.box_id = data.id
    self.unlockRuleGroupList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetUnlockBoxRuleGroupList, self.box_id)
  end
  self:OnAddEventListener()
  self:InitPanel()
end

function UMG_PurchaseBox_C:OnDeactive()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnVItemChanged)
end

function UMG_PurchaseBox_C:OnAddEventListener()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnVItemChanged)
end

function UMG_PurchaseBox_C:OnVItemChanged()
  if self.box_id then
    self.unlockRuleGroupList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetUnlockBoxRuleGroupList, self.box_id)
  end
  local selectedIndex = self.ExChangeItemList:GetSelectedIndex()
  self.ExChangeItemList:ClearSelection()
  self:InitItemList(selectedIndex)
end

function UMG_PurchaseBox_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = LuaText.warehouse_buy_new_one
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  CommonPopUpData.Btn_LeftText = LuaText.CANCEL
  CommonPopUpData.Btn_RightText = LuaText.umg_bag_11
  CommonPopUpData.Btn_LeftHandler = self.OnCloseBtn
  CommonPopUpData.Btn_RightHandler = self.UnlockBox
  CommonPopUpData.Btn_Right_GrayState2_Text = LuaText.umg_bag_11
  CommonPopUpData.Btn_RightGrayState2Handler = self.UnlockBox
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp4:SetPanelInfo(CommonPopUpData)
end

function UMG_PurchaseBox_C:OnCloseBtn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401002, "UMG_Dialog_C:OnClickCancelButton")
  self:LoadAnimation(2)
end

function UMG_PurchaseBox_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_PurchaseBox_C:InitItemList(selectedIndex)
  local itemList = {}
  local moneyList = {}
  local rules = self.warehouseConf.unlock_rule
  for i = 1, #rules do
    local rule = rules[i]
    if rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_EXPEND_MONEY or rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_USE_BAGITEM then
      local itemData = {}
      itemData.itemId = rule.unlock_id
      itemData.ConsumeNum = rule.value
      itemData.bShowNum = true
      itemData.IsDoCmd = true
      itemData.DoCmd = "PetUIModuleCmd.SelectUnlockBoxItem"
      itemData.groupId = rule.group_id[1]
      if rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_EXPEND_MONEY then
        itemData.itemType = _G.Enum.GoodsType.GT_VITEM
        local itemNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(rule.unlock_id) or 0
        itemData.itemNum = itemNum
        itemData.BagNum = itemNum
        table.insert(itemList, itemData)
        local totalNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(rule.unlock_id) or 0
        local moneyInfo = {
          moneyType = rule.unlock_id,
          sum = totalNum,
          IsShowBuyIcon = true,
          currencyId = rule.unlock_id
        }
        table.insert(moneyList, moneyInfo)
      else
        itemData.itemType = _G.Enum.GoodsType.GT_BAGITEM
        local item = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, rule.unlock_id)
        if item then
          local itemNum = item.num or 0
          if itemNum > 0 then
            itemData.itemNum = itemNum
            itemData.BagNum = itemNum
            table.insert(itemList, itemData)
          end
        end
      end
    end
  end
  table.sort(itemList, function(a, b)
    return a.groupId < b.groupId
  end)
  self.ExChangeItemList:InitGridView(itemList)
  if #moneyList > 0 then
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.MoneyBtn:InitGridView(moneyList)
  else
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:DelayFrames(5, function()
    self.ExChangeItemList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if selectedIndex then
      self.ExChangeItemList:SelectItemByIndex(selectedIndex)
    else
      self.ExChangeItemList:SelectItemByIndex(0)
    end
  end)
end

function UMG_PurchaseBox_C:SelectUnlockBoxItem(index, uiData)
  if uiData and uiData.groupId then
    self.curGroupId = uiData.groupId
    local ruleGroup = self.unlockRuleGroupList[self.curGroupId]
    if ruleGroup then
      for _, info in pairs(ruleGroup or {}) do
        if info and info.rule then
          if info.rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_EXPEND_MONEY then
            local vItemConf = _G.DataConfigManager:GetVisualItemConf(info.rule.unlock_id)
            if vItemConf then
              local desc = string.format(LuaText.warehouse_unlock_cost_text, info.rule.value, vItemConf.displayName)
              self.PopUp4:SetDescInfo(desc)
            end
            local iconPath, _ = NPCShopUtils:GetGoodsCurrencyIconByType(_G.Enum.GoodsType.GT_VITEM, info.rule.unlock_id)
            self.PopUp4:ShowOrHideBtnRight(true)
            self.PopUp4:ShowOrHideRightGrayState2(false)
            local Color = "#F4EEE0FF"
            if not info.checkPass then
              Color = "#C7494AFF"
            end
            local titleInfo = {
              MoneyIcon = iconPath,
              QuantityText = info.rule.value,
              Color = Color
            }
            self.PopUp4:SetRightBtnTitleTextAndIconShow(true, titleInfo)
          elseif info.rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_USE_BAGITEM then
            local name, iconPath
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(info.rule.unlock_id)
            if bagItemConf then
              name = bagItemConf.name
              iconPath = bagItemConf.icon
            end
            if name and iconPath then
              local desc = string.format(LuaText.warehouse_unlock_cost_text, info.rule.value, name)
              self.PopUp4:SetDescInfo(desc)
              if info.checkPass then
                self.PopUp4:ShowOrHideBtnRight(true)
                self.PopUp4:ShowOrHideRightGrayState2(false)
                local titleInfo = {
                  MoneyIcon = iconPath,
                  QuantityText = info.rule.value,
                  Color = "#F4EEE0FF"
                }
                self.PopUp4:SetRightBtnTitleTextAndIconShow(true, titleInfo)
              else
                self.PopUp4:ShowOrHideBtnRight(false)
                self.PopUp4:ShowOrHideRightGrayState2(true)
                local titleInfo = {
                  MoneyIcon = iconPath,
                  QuantityText = info.rule.value,
                  Color = "#C7494AFF"
                }
                self.PopUp4:SetRightGrayState2TitleTextAndIconShow(true, titleInfo)
              end
            end
          elseif info.rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_RECORD_PET and info.rule.unlock_rule_text and info.rule.value then
            self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Desc:SetText(string.format(info.rule.unlock_rule_text, info.rule.value))
          end
        end
      end
    end
  end
end

function UMG_PurchaseBox_C:InitPanel()
  self:SetCommonPopUpInfo()
  self:InitItemList()
  self:LoadAnimation(0)
end

function UMG_PurchaseBox_C:OpenPopUpTips(coinNum, coinType)
  if coinType == Enum.VisualItem.VI_COUPON then
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.JudgeBuyCouponGiftItem, coinNum)
  elseif coinType == Enum.VisualItem.VI_DIAMOND then
    _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.JudgeBuyDiamondGiftItem, coinNum)
  end
end

function UMG_PurchaseBox_C:UnlockBox()
  if self.curGroupId and self.unlockRuleGroupList and self.unlockRuleGroupList[self.curGroupId] then
    local bAllPass = true
    local notPassRules = {}
    for _, ruleInfo in pairs(self.unlockRuleGroupList[self.curGroupId]) do
      if not ruleInfo.checkPass then
        bAllPass = false
        if ruleInfo and ruleInfo.rule then
          table.insert(notPassRules, ruleInfo.rule)
        end
      end
    end
    if bAllPass then
      if self.box_id and self.curGroupId then
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OnCmdZonePetBoxUnlockReq, self.box_id, self.curGroupId)
        self:OnCloseBtn()
      end
    else
      for _, rule in pairs(notPassRules or {}) do
        if rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_EXPEND_MONEY then
          self:OpenPopUpTips(rule.value, rule.unlock_id)
        elseif rule.unlockcondition == _G.Enum.WarehouseUnlockCondition.WUC_RECORD_PET then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.warehouse_unlock_not_enough_pet)
        end
      end
    end
  end
end

return UMG_PurchaseBox_C

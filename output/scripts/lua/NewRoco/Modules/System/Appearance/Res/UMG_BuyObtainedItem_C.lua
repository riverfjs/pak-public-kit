local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UMG_BuyObtainedItem_C = Base:Extend("UMG_BuyObtainedItem_C")

function UMG_BuyObtainedItem_C:OnConstruct()
  self.bShouldEnableMarquee = false
  self.startMarquee = false
  self.marqueeSpeed = 0.05
end

function UMG_BuyObtainedItem_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
end

function UMG_BuyObtainedItem_C:OnActive(shopId, rewardData)
  _G.UpdateManager:Register(self)
  if nil == rewardData then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.ShopId = shopId
  self.uiData = rewardData
  self:UpdateUI()
end

function UMG_BuyObtainedItem_C:OnDeactive()
  _G.UpdateManager:UnRegister(self)
end

function UMG_BuyObtainedItem_C:UpdateUI()
  if self.uiData == nil then
    return
  end
  local myUIData = self.uiData
  local name = ""
  local quality = 4
  local cardFaceIcon = ""
  local goodsType = myUIData.type
  local itemId = myUIData.id
  self.petIconBgColor = nil
  self.Protagonist:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local ItemPartType = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetItemPartType, goodsType, itemId)
  if goodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if suitConf and suitConf.suit_grade and suitConf.suits_icon_big then
      self.petIconBgColor, quality = AppearanceUtils:GetSuitGradeColor(suitConf.suit_grade)
      cardFaceIcon = suitConf.suits_icon_big
      name = suitConf.name
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if suitConf.suit_grade == Enum.SuitGrade.SG_BOND or suitConf.suit_grade == Enum.SuitGrade.SG_UNIBOND then
        local petBg = UEPath.FASHION_MALL_REWARD_QUALITY_PET_BG[5]
        if quality and UEPath.FASHION_MALL_REWARD_QUALITY_PET_BG[quality] then
          petBg = UEPath.FASHION_MALL_REWARD_QUALITY_PET_BG[quality]
        end
        self.QualityBg:SetPath(petBg)
        local petBaseId
        if type(suitConf.petbase_id) == "table" and #suitConf.petbase_id > 0 then
          petBaseId = suitConf.petbase_id[1]
        end
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
        if petBaseConf then
          self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          if suitConf.suits_original_id and 0 ~= suitConf.suits_original_id then
            local id = string.format("%s_1", suitConf.petbase_id[1])
            self.PetHeadIcon:SetPathWithCallBack(AppearanceUtils:GetPetIconById(id), {
              self,
              self.OnPetHeadIconSet
            })
          else
            self.PetHeadIcon:SetPathWithCallBack(petBaseConf.JL_res, {
              self,
              self.OnPetHeadIconSet
            })
          end
        end
      end
    end
    self.Protagonist:SetPath(cardFaceIcon)
    self.Protagonist:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif goodsType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemId)
    if cardSkinConf then
      quality = cardSkinConf.card_quality
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(cardSkinConf.bagitem_id)
      if bagItemConf then
        cardFaceIcon = bagItemConf.big_icon
      end
      name = cardSkinConf.skin_resource_name
      bHasOwned = _G.NRCModuleManager:DoCmd(FriendModuleCmd.HasCardSkin, cardSkinConf.id)
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Icon:SetPath(cardFaceIcon)
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif goodsType == _G.Enum.GoodsType.GT_FASHION then
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionItemConf and fashionItemConf.item_quality and fashionItemConf.icon then
      quality = fashionItemConf.item_quality
      cardFaceIcon = fashionItemConf.icon
      name = fashionItemConf.name
      bHasOwned = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckHasOwned, _G.Enum.GoodsType.GT_FASHION, itemId)
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Icon:SetPath(cardFaceIcon)
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    Log.Error("\230\156\170\229\164\132\231\144\134\231\177\187\229\158\139", goodsType, itemId)
  end
  local cardFaceBgImage = UEPath.FASHION_MALL_REWARD_QUALITY_BG[4]
  if quality and UEPath.FASHION_MALL_REWARD_QUALITY_BG[quality] then
    cardFaceBgImage = UEPath.FASHION_MALL_REWARD_QUALITY_BG[quality]
  end
  self.SuitName:SetText(name)
  self.SuitQualityColor:SetPath(cardFaceBgImage)
  if ItemPartType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
    local appearanceModule = NRCModuleManager:GetModule("AppearanceModule")
    local IconPath = appearanceModule.data:GetItemIconPathByItemType(ItemPartType)
    if nil ~= IconPath and self.SuitIcon then
      self.SuitIcon:SetPath(IconPath)
    end
  end
  _G.NRCViewBase:DelayFrames(1, function()
    self:CheckShouldEnableMarquee()
  end)
end

function UMG_BuyObtainedItem_C:CheckShouldEnableMarquee()
  local textComp = self.SuitName
  if not textComp or not UE.UObject.IsValid(textComp) then
    return
  end
  local textContent = textComp:GetText()
  self.bShouldEnableMarquee = self:CalculateTextWidth(textComp, textContent)
end

function UMG_BuyObtainedItem_C:CalculateTextWidth(textComp, textContent)
  local textWidth = textComp:GetDesiredSize().X
  local scrollBoxWidth = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_61):GetSize().x
  if textWidth >= scrollBoxWidth then
    textComp:SetText(string.format("%s    %s    ", textContent, textContent))
    _G.NRCViewBase:DelayFrames(1, function()
      self.totalScrollEnd = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ScrollBox_61):GetSize().x + self.ScrollBox_61:GetScrollOffsetOfEnd()
      self.startMarquee = true
    end)
    return true
  end
  return false
end

function UMG_BuyObtainedItem_C:OnTick(DeltaTime)
  if self.bShouldEnableMarquee and self.startMarquee then
    local nextProgress = self.marqueeSpeed * DeltaTime * self.totalScrollEnd + self.ScrollBox_61:GetScrollOffset()
    if nextProgress > self.totalScrollEnd / 2 then
      nextProgress = nextProgress - self.totalScrollEnd / 2
    end
    self.ScrollBox_61:SetScrollOffset(nextProgress)
  end
end

function UMG_BuyObtainedItem_C:OnPetHeadIconSet()
  if self and UE4.UObject.IsValid(self) then
    local dynamicMaterial = self.PetHeadIcon:GetDynamicMaterial()
    if dynamicMaterial and self.petIconBgColor then
      dynamicMaterial:SetVectorParameterValue("BackgroundColor", UE4.UNRCStatics.HexToLinearColor(self.petIconBgColor))
    end
  end
end

return UMG_BuyObtainedItem_C

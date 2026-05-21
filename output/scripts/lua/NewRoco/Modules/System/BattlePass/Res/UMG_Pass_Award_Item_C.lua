local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local UMG_Pass_Award_Item_C = Base:Extend("UMG_Pass_Award_Item_C")

function UMG_Pass_Award_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data.ItemData
  local id = _data.ItemID - 1
  self.bpLevel = _data.ItemID
  self.isPremiumReward = _data.isPremiumReward or false
  local state = self.data.state
  self.ReceiveAward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if 1 == state then
    self.ReceiveAward:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.ReceiveAward:SetupKey(142, {id})
  end
  if 2 == state then
    _G.NRCModeManager:DoCmd(_G.RedPointModuleCmd.UnRegRedPointUI, self.ReceiveAward)
  end
  self:RefreshItem()
end

function UMG_Pass_Award_Item_C:OnItemSelected(_bSelected)
  if _bSelected then
    local panelName = "BattlePassAwardMain"
    local moduleName = "BattlePassModule"
    local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
    if isSelectBtn then
      return
    end
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).TIPS
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
    if 1 == self.data.state and self.bpLevel and self.curLevel and self.bpLevel <= self.curLevel then
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReceiveBattlePassReward, false, self.data.awardInfo.index)
      return
    end
    local data = self.data.cfg
    if data.Type == _G.Enum.GoodsType.GT_BAGITEM then
      local Itemdata = _G.DataConfigManager:GetBagItemConf(data.Id)
      if Itemdata.lable_type == _G.Enum.ItemLableType.ILT_SKILL_MACHINE then
        local skillMachineid = Itemdata.item_behavior[1].ratio[1]
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetSKillTips, skillMachineid, true, Itemdata.id)
      else
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, data.Id, data.Type, false)
      end
    elseif data.Type == _G.Enum.GoodsType.GT_PET then
      local pet_id = data.Id
      local pet_conf = _G.DataConfigManager:GetPetConf(pet_id)
      local param = {
        petbaseId = pet_conf.base_id,
        needBlur = false,
        notAcquired = false,
        isSketch = true
      }
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_OpenMagicDetailTips, param)
      _G.NRCAudioManager:PlaySound2DAuto(1284, "UMG_Pass_Award_Item_C:OnItemSelected")
    elseif data.Type == Enum.GoodsType.GT_FASHION_SUITS then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, data.Id)
    elseif data.Type == Enum.GoodsType.GT_FASHION then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(data.Id, true)
      if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
        local context = {}
        context.bIsWand = true
        context.context = {}
        context.context.WandId = data.Id
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
      elseif fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, data.Id, data.Type, false)
      else
        local suitId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetSuitIdFromFashionId, data.Id)
        if nil == suitId or 0 == suitId then
          Log.Warning("UMG_Pass_Award_Item_C:OnItemSelected suitId is nil")
        else
          _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, suitId, data.Id)
        end
      end
    else
      _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, data.Id, data.Type, false)
    end
  end
end

function UMG_Pass_Award_Item_C:SetNumSize(Count)
  local number = Count
  local numberStr = tostring(number)
  local length = string.len(numberStr)
  local Font = self.txtLV.Font
  if length > 5 then
    Font.Size = 22
    self.txtLV:SetFont(Font)
  end
end

function UMG_Pass_Award_Item_C:CancelSelect()
end

function UMG_Pass_Award_Item_C:RefreshItem()
  local data = self.data.cfg
  local Type = data.Type
  local ID = data.Id
  local Count = data.Count
  local _IconPath, _BgQuality
  if Type == Enum.GoodsType.GT_REWARD then
    local RewardConf = _G.DataConfigManager:GetRewardConf(ID)
    for i = 1, #RewardConf.RewardItem do
      if RewardConf.RewardItem[i].Type == Enum.GoodsType.GT_BAGITEM then
        local BagItemConf = _G.DataConfigManager:GetBagItemConf(RewardConf.RewardItem[i].Id)
        _IconPath = BagItemConf.big_icon
        _BgQuality = BagItemConf.item_quality
        break
      end
    end
  elseif Type == Enum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(ID)
    if nil == BagItemConf then
      Log.Error("BagItem config not found", ID)
      return
    end
    _IconPath = BagItemConf.big_icon
    _BgQuality = BagItemConf.item_quality
  elseif Type == Enum.GoodsType.GT_VITEM then
    local VIItemConf = _G.DataConfigManager:GetVisualItemConf(ID)
    _IconPath = VIItemConf.bigIcon
    _BgQuality = VIItemConf.item_quality
  elseif Type == _G.Enum.GoodsType.GT_PET then
    local petInfo = _G.DataConfigManager:GetPetConf(ID)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
    if nil ~= petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        _IconPath = modelConf.icon
      end
      _BgQuality = petBaseConf.quality
    end
  elseif Type == Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(ID)
    _IconPath = fashionConf.suits_icon
    _BgQuality = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
  elseif Type == _G.Enum.GoodsType.GT_CARD_ICON then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(ID)
    if cardIconConf then
      _IconPath = string.format("%s%s.%s'", _G.UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
      _BgQuality = cardIconConf.card_quality
    end
  elseif Type == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(ID)
    if cardSkinConf then
      _IconPath = string.format(_G.UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      _BgQuality = cardSkinConf.card_quality
    end
  elseif Type == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(ID)
    if fashionConf then
      _IconPath = fashionConf.icon
      _BgQuality = fashionConf.item_quality
    end
  end
  self:SetNumSize(Count)
  self.txtLV:SetText("x" .. Count)
  if Type ~= _G.Enum.GoodsType.GT_PET then
    self.iconSwitcher:SetActiveWidgetIndex(0)
    self:SetIconPath(_IconPath)
    self:SetTagQuality(_BgQuality)
    self:SetQuality(_BgQuality)
  else
    self.iconSwitcher:SetActiveWidgetIndex(0)
    self.Pet:SetPath(_IconPath)
    self:SetPetQuality(_BgQuality)
  end
  local state = self.data.state
  self:SetState(state)
end

function UMG_Pass_Award_Item_C:SetQuality(quality)
  self.QualityBg:SetVisibility(UE4.ESlateVisibility.Visible)
  if 0 == quality then
    self.QualityBg:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UMG_Pass_Award_Item_C:SetPetQuality(quality)
  self.QualityBg:SetVisibility(UE4.ESlateVisibility.Visible)
  if quality == _G.Enum.PetQuality.PQ_BLUE then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_3)
  elseif quality == _G.Enum.PetQuality.PQ_PURPLE then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_4)
  elseif quality == _G.Enum.PetQuality.PQ_ORANGE then
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_5)
  else
    self.QualityBg:SetPath(UEPath.PROP_QUALITY_NONE)
  end
end

function UMG_Pass_Award_Item_C:SetTagQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.Color:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Pass_Award_Item_C:SetState(state)
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if 0 == state then
  elseif 1 == state then
    if 1 ~= self.preState then
      self:PlayAwardEffect(true)
    end
  elseif 2 == state then
    if 1 == self.preState then
      self:PlayAwardEffect(false)
    end
    self.BlackMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local battlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  self.curLevel = battlePassInfo.exp_info and battlePassInfo.exp_info.level or 0
  if self.bpLevel > self.curLevel or self.isPremiumReward and 0 == state then
    self.lock:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.preState = state
end

function UMG_Pass_Award_Item_C:PlayAwardEffect(isPlay)
  if isPlay then
    self:ChangeAwardEffectColor()
  else
  end
end

function UMG_Pass_Award_Item_C:ChangeAwardEffectColor()
  local battlePassInfo = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo)
  if battlePassInfo and battlePassInfo.theme_id then
    local themCfg = _G.DataConfigManager:GetBattlePassThemeConf(battlePassInfo.theme_id)
    local hexColor = themCfg.reward_highlight_color
  end
end

function UMG_Pass_Award_Item_C:SetIconPath(iconPath)
  local data = self.data.cfg
  if data.Type and data.Type == _G.Enum.GoodsType.GT_BAGITEM and data.Id then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(data.Id)
    if bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_EGG and bagItemConf.item_behavior and bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].ratio2 and bagItemConf.item_behavior[1].ratio2[1] then
      local eggInfo = {}
      eggInfo.random_egg_conf = bagItemConf.item_behavior[1].ratio2[1]
      self.IconSwitcher:SetActiveWidgetIndex(2)
      self.PetEggIcon:SetEggIcon(eggInfo, iconPath)
      return
    end
  end
  self.IconSwitcher:SetActiveWidgetIndex(0)
  self.icon:SetPath(iconPath)
end

return UMG_Pass_Award_Item_C

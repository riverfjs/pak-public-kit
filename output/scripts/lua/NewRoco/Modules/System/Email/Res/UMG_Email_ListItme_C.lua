local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local EmailModuleEvent = require("NewRoco.Modules.System.Email.EmailModuleEvent")
local UMG_Email_ListItme_C = Base:Extend("UMG_Email_ListItme_C")

function UMG_Email_ListItme_C:OnConstruct()
end

function UMG_Email_ListItme_C:OnDestruct()
end

function UMG_Email_ListItme_C:OnItemUpdate(_data, datalist, index)
  self:StopAllAnimations()
  self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Visible)
  self.isSelect = false
  self:PlayAnimation(self.Get_normal)
  self:PlayAnimation(self.Unselect_normal0)
  self.isPlayingDeletAnim = false
  self.RedDot:SetupKey(62, _data.mail_gid)
  self.data = _data
  self.GetAnimFinishe = self.data and self.data.is_read and self.data.is_recv
  local item = self.data.icon_head
  self:ShowIcon(item)
  self:ShowUnSelect()
  self:ShowSelect()
  self.itemIndex = index - 1
  self:ChangeItemColor()
  local selectMailGid = _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.GetSelectMailGid)
  if selectMailGid == self.data.mail_gid then
  end
end

function UMG_Email_ListItme_C:GetIconPath(itemId, itemType, IsShowPetbase)
  local iconPath
  if itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(itemId)
    if nil ~= vItemConf then
      self:SetQuality(vItemConf.item_quality)
      iconPath = vItemConf.bigIcon
    end
  elseif itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
    if nil ~= bagItemConf then
      self:SetQuality(bagItemConf.item_quality)
      iconPath = bagItemConf.icon
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(itemId)
    if GetCardIconConf then
      self:SetQuality(GetCardIconConf.card_quality)
      iconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path)
    end
  elseif itemType == _G.Enum.GoodsType.GT_PET then
    if IsShowPetbase then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(itemId)
      if nil ~= petBaseConf then
        self:SetQuality(7)
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        if petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and modelConf.shiny_icon then
          iconPath = modelConf.shiny_icon
        else
          iconPath = modelConf.icon
        end
      end
    else
      local petInfo = _G.DataConfigManager:GetPetConf(itemId, true)
      if petInfo then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
        if nil ~= petBaseConf then
          self:SetQuality(7)
          local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
          if petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and modelConf.shiny_icon then
            iconPath = modelConf.shiny_icon
          else
            iconPath = modelConf.icon
          end
        end
      else
        local monsterConf = _G.DataConfigManager:GetMonsterConf(itemId)
        if nil ~= monsterConf then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
          if nil ~= petBaseConf then
            self:SetQuality(7)
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
  elseif itemType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemId)
    if cardSkinConf then
      self:SetQuality(cardSkinConf.card_quality)
      iconPath = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(itemId)
    if GetCardIconConf then
      self:SetQuality(GetCardIconConf.card_quality)
      iconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path)
    end
  elseif itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(itemId)
    if CardLabelConf then
      self:SetQuality(CardLabelConf.card_quality)
      iconPath = CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
    end
  elseif itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(itemId)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      self:SetQuality(grade)
      iconPath = fashionConf.suits_icon
    end
  elseif itemType == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if fashionConf then
      local fashionSuitsId = tonumber(fashionConf.suits_id)
      local grade = fashionConf.item_quality
      self:SetQuality(grade)
      iconPath = fashionConf.icon
    end
  elseif itemType == _G.Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if salonConf then
      local grade = salonConf.item_quality
      self:SetQuality(grade)
      iconPath = salonConf.icon
    end
  elseif itemType == _G.Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(itemId)
    if itemConf then
      self:SetQuality(5)
      iconPath = itemConf.icon_path
    end
  end
  return iconPath
end

function UMG_Email_ListItme_C:ShowIcon(reward)
  self.NRCSwitcher_0:SetActiveWidgetIndex(1)
  if self.data.is_recv == true then
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if reward then
    local itemId = reward.Id
    local iconPath, itemType
    if reward.Type == _G.Enum.GoodsType.GT_REWARD then
      local rewardConf = _G.DataConfigManager:GetRewardConf(itemId)
      if rewardConf.RewardItem and #rewardConf.RewardItem > 0 then
        local Id = rewardConf.RewardItem[1].Id
        local Type = rewardConf.RewardItem[1].Type
        itemType = Type
        iconPath = self:GetIconPath(Id, Type, reward.IsShowPetbase)
      end
    else
      itemType = reward.Type
      iconPath = self:GetIconPath(itemId, reward.Type, reward.IsShowPetbase)
    end
    if not iconPath or "" == iconPath then
      local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
      if commonIconConfig and commonIconConfig.str then
        iconPath = commonIconConfig.str
        Log.WarningFormat("UMG_Email_ListItme_C:ShowIcon iconPath is empty for itemId=%s,itemType=%s,use default icon", tostring(itemId), tostring(itemType))
        self:SetQuality(1)
      end
    end
    if iconPath then
      self.IconSwitcher:SetActiveWidgetIndex(0)
      if itemType and itemType == _G.Enum.GoodsType.GT_PET then
        self.cachedItemIcon = self.PetIcon
        self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local isEgg
        if itemType and itemId and itemType == _G.Enum.GoodsType.GT_BAGITEM then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
          if bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_EGG then
            isEgg = self:SetEggIcon(iconPath, bagItemConf)
          end
        end
        if not isEgg then
          self.cachedItemIcon = self.icon
          self.icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
      if self.cachedItemIcon then
        self.itemIconPath = iconPath
        self.cachedItemIcon:SetPathWithSuccessAndFailedCallBack(iconPath, {
          self,
          self.IconSetPathSuccess
        }, {
          self,
          self.IconSetPathFailed
        })
      end
    end
  end
end

function UMG_Email_ListItme_C:IconSetPathSuccess()
  Log.Debug("UMG_Email_ListItme_C:IconSetPathSuccess")
end

function UMG_Email_ListItme_C:IconSetPathFailed()
  Log.Warning("UMG_Email_ListItme_C:IconSetPathFailed", tostring(self.itemIconPath))
  local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
  if commonIconConfig and commonIconConfig.str and self.cachedItemIcon then
    self.itemDefaultIconPath = commonIconConfig.str
    self.cachedItemIcon:SetPathWithSuccessAndFailedCallBack(commonIconConfig.str, {
      self,
      self.IconSetDefaultPathSuccess
    }, {
      self,
      self.IconSetDefaultPathFailed
    })
  else
    Log.Error("UMG_Email_ListItme_C:IconSetPathFailed no default image config for common_reward_icon in activity_global_config")
  end
end

function UMG_Email_ListItme_C:IconSetDefaultPathSuccess()
  Log.Debug("UMG_Email_ListItme_C:IconSetDefaultPathSuccess")
end

function UMG_Email_ListItme_C:IconSetDefaultPathFailed()
  Log.Error("UMG_Email_ListItme_C:IconSetDefaultPathFailed", tostring(self.itemDefaultIconPath))
end

function UMG_Email_ListItme_C:UpdateItemState()
  self:ChangeItemColor()
end

function UMG_Email_ListItme_C:PlayGetAnimation()
  self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  if not self.GetAnimFinishe then
    self:PlayAnimation(self.Get)
  end
end

function UMG_Email_ListItme_C:SetQuality(quality)
  self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Visible)
  if nil == quality then
    quality = 8
  end
  if quality > 0 then
    self.NRCSwitcher_1:SetActiveWidgetIndex(quality - 1)
  end
  if 0 == quality then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 6 == quality then
    self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Email_ListItme_C:ShowSelect()
  self.Title:SetText(self:TruncateUTF8(self.data.title))
  self.MagicAcademy:SetText(self.data.name)
  self.Number:SetText(self.data.expire_str())
end

function UMG_Email_ListItme_C:ShowUnSelect()
  self.Title_1:SetText(self:TruncateUTF8(self.data.title))
  self.MagicAcademy:SetText(self.data.name)
  self.Number_1:SetText(self.data.expire_str())
end

function UMG_Email_ListItme_C:TruncateUTF8(text)
  if not text or 0 == #text then
    return ""
  end
  local currentWidth = 0
  local bytePos = 1
  local maxWidth = ActivityUtils.GetActivityGlobalConfig("email_title_limit_characters").num
  while currentWidth < maxWidth and bytePos <= #text do
    local firstByte = text:byte(bytePos)
    local charWidth, charBytes = 0, 0
    if firstByte < 128 then
      charWidth = 1
      charBytes = 1
    elseif firstByte >= 240 then
      charWidth = 2
      charBytes = 4
    elseif firstByte >= 224 then
      charWidth = 2
      charBytes = 3
    elseif firstByte >= 192 then
      charWidth = 1
      charBytes = 2
    else
      charBytes = 1
    end
    if bytePos + charBytes - 1 > #text or maxWidth < currentWidth + charWidth then
      break
    end
    bytePos = bytePos + charBytes
    currentWidth = currentWidth + charWidth
  end
  local safeEnd = bytePos - 1
  if safeEnd <= 0 then
    return ""
  end
  if safeEnd < #text then
    return text:sub(1, safeEnd) .. "..."
  else
    return text
  end
end

function UMG_Email_ListItme_C:OnItemSelected(_bSelected)
  if self.isPlayingDeletAnim then
    return
  end
  if not UE4.UObject.IsValid(self) then
    return
  end
  self:StopAnimation(self.Unselect)
  self:StopAnimation(self.Unselect_1)
  self:StopAnimation(self.Unselect_normal0)
  self:StopAnimation(self.Select)
  if _bSelected then
    self:StopAllAnimations()
    self:PlayAnimation(self.Select)
    if self.isSelect ~= _bSelected then
      _G.NRCAudioManager:PlaySound2DAuto(40007005, "UMG_Email_ListItme_C:OnItemSelected")
    end
    if self.data then
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.SetSelectEmailIndex, self.itemIndex)
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.ZoneEmailReadReq, self.data.mail_gid)
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.SetSelectMailGid, self.data.mail_gid)
      _G.NRCModuleManager:GetModule("EmailModule"):DispatchEvent(EmailModuleEvent.SelectMailEvent, self.data, self.itemIndex, true, self.data.mail_gid)
    end
  else
    if not self:IsChangeSelectItem(self.data.mail_gid) then
    end
    if self.data and self.data.is_read and self.data.is_recv then
      self:PlayAnimation(self.Unselect)
    else
      self:PlayAnimation(self.Unselect_1)
    end
  end
  self.isSelect = _bSelected
end

function UMG_Email_ListItme_C:PlaySelectAnimation()
  self:PlayAnimation(self.Select)
end

function UMG_Email_ListItme_C:PlayUnSelectAnimation()
  self:PlayAnimation(self.Unselect)
end

function UMG_Email_ListItme_C:GetCurSelect(index)
  local curSelectIndex = _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.GetSelectEmailIndex)
  local curSelect = curSelectIndex == index
  return curSelect
end

function UMG_Email_ListItme_C:IsChangeSelectItem(gid)
  local OldSelectGid = _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.GetSelectMailGid)
  local isChange = gid ~= OldSelectGid
  return isChange
end

function UMG_Email_ListItme_C:ChangeItemColor()
  self.Normalwen:SetRenderOpacity(1)
  local is_read, is_recv = _G.NRCModuleManager:DoCmd(EmailModuleCmd.GetMailState, self.data.mail_gid)
  if self.data and is_read and is_recv then
    self.Normalgou:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Normalgou:SetRenderOpacity(1)
    self.gou:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.CanvasPanel_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not self.isSelect then
      self.Title:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("625F5DFF"))
      self.Number:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("625F5DFF"))
      self.NRCImage_179:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("625F5DFF"))
    end
  else
    self.Normalgou:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.gou:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Title:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("050505FF"))
    self.Number:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3A3DFF"))
    self.NRCImage_179:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("AF3A3DFF"))
  end
end

function UMG_Email_ListItme_C:OnDeactive()
end

function UMG_Email_ListItme_C:PlayDeletAnimation()
  self.isPlayingDeletAnim = true
  self:PlayAnimation(self.Close)
end

function UMG_Email_ListItme_C:OpItem(opType)
  if 0 == opType then
    self:UpdateItemState()
    local is_read, is_recv = _G.NRCModuleManager:DoCmd(EmailModuleCmd.GetMailState, self.data.mail_gid)
    if self.data and is_read and is_recv then
      self:PlayGetAnimation()
    end
  elseif 1 == opType then
    self:UpdateItemState()
  elseif 2 == opType then
    self:PlayDeletAnimation()
  end
end

function UMG_Email_ListItme_C:OnAnimationFinished(anim)
  if anim == self.Unselect or self.Unselect_1 == anim or self.Unselect_normal0 then
    self:ChangeItemColor()
  elseif anim == self.Get then
    self.GetAnimFinishe = true
  end
end

function UMG_Email_ListItme_C:OnLogin()
end

function UMG_Email_ListItme_C:SetEggIcon(iconPath, bagItemConf)
  if bagItemConf and bagItemConf.type == _G.Enum.BagItemType.BI_PET_EGG then
    if bagItemConf.item_behavior and bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].ratio2 and bagItemConf.item_behavior[1].ratio2[1] then
      local eggInfo = {}
      eggInfo.random_egg_conf = bagItemConf.item_behavior[1].ratio2[1]
      self.IconSwitcher:SetActiveWidgetIndex(2)
      self.PetEggIcon:SetEggIcon(eggInfo, iconPath)
      return true
    elseif self.data and self.data.reward and self.data.reward.rewards and self.data.reward.rewards[1] and self.data.reward.rewards[1].egg_info then
      local eggInfo = self.data.reward.rewards[1].egg_info
      if eggInfo.glass_info then
        self:SetQuality(5)
      end
      self.IconSwitcher:SetActiveWidgetIndex(2)
      self.PetEggIcon:SetEggIcon(eggInfo, iconPath)
      return true
    end
  end
  return false
end

return UMG_Email_ListItme_C

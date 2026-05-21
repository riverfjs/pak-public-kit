local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local BagModuleData = reload("NewRoco.Modules.System.Bag.BagModuleData")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local UMG_BagItemTemplate_C = Base:Extend("UMG_BagItemTemplate_C")

function UMG_BagItemTemplate_C:Construct()
  Base.Construct(self)
  self.Module = NRCModuleManager:GetModule("BagModule")
  self.Module:RegisterEvent(self, BagModuleEvent.NotifySwapEggsChanged, self.OnNotifySwapEggsChanged)
  self.Module:RegisterEvent(self, BagModuleEvent.RefreshBagItemFurnitureInfoByGid, self.RefreshBagItemFurnitureInfoByGid)
  self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SwapEggs_Precious:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BagItemTemplate_C:OnDestruct()
  self.Module:UnRegisterEvent(self, BagModuleEvent.NotifySwapEggsChanged)
  self.Module:UnRegisterEvent(self, BagModuleEvent.RefreshBagItemFurnitureInfoByGid)
end

function UMG_BagItemTemplate_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.uiData = _data
  self.module = NRCModuleManager:GetModule("BagModule")
  self.moduleData = self.module:GetData("BagModuleData")
  self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
  if self.uiData.FromBag ~= nil and self.uiData.FromBag == false then
    self.FromBag = false
  else
    self.FromBag = true
  end
  self.showBit = nil
  self:updateItemInfo()
  self.data = self.module:GetData("BagModuleData")
  local tabItemType = self.data:GetCurItemType()
  self.RedDot:SetupKey(51, {
    tabItemType,
    self.uiData.id
  })
  self.RedDot_New:SetupKey(469, {
    self.uiData.id
  })
  self.RedDot_New:SetRedStatusChangeListener(self, self.OnRedPointSpecialStatusChange)
  if self.RedDot_New:IsRed() then
    self:SetTagOrEquipIcon(false, "")
    self.FurnitureNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NearDate:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagItemTemplate_C:OnRedPointSpecialStatusChange(redPoint, isRed)
  if not isRed and self.uiData then
    local bagItemConf = self.uiData.conf
    self:UpdateVouchGiftInfo(bagItemConf)
    self:UpdateFurnitureDecomposeInfo()
    if self.uiData.egg_data and self.uiData.gid and self.uiData.type == _G.Enum.BagItemType.BI_PET_EGG then
      self.PetEggTypeIconItem:SetItemIcon(self.uiData.gid, false)
      self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if self.uiData.egg_data.precious_egg_type and self.uiData.egg_data.precious_egg_type ~= Enum.PreciousEggType.PET_NONE then
        self:SetQuality(5)
      end
    end
  end
end

function UMG_BagItemTemplate_C:UpdateFromBag()
  self.FromBag = true
end

function UMG_BagItemTemplate_C:SetParentPanel(Panel)
  self.Panel = Panel
end

function UMG_BagItemTemplate_C:OnDespawn()
  if self._parent and self._parent._selectedItemIndex == self.index then
    self:PlayAnimation(self.normal)
    self:StopAllAnimations()
    self:PlayAnimation(self.change2)
  end
end

function UMG_BagItemTemplate_C:updateItemInfo()
  self:PlayAnimation(self.normal)
  local displayMode = self.moduleData.displayMode
  if self.FromBag == true then
    if displayMode == BagModuleEnum.DisplayMode.BattleCatch then
      local catchData = self.moduleData:GetCurSelectedItemDataBattle()
      local curSelectInBattle = catchData and catchData.curUseBallGID == self.uiData.gid
      if not catchData or not catchData.curUseBallGID then
        if 1 ~= self.index then
          self:SetSelectedVisible(false)
        end
        if true == self.uiData.IsFirstOpenPanel and 1 == self.index then
          self.laterPlayChange1 = true
          self._parent._selectedItem = self
          self._parent._selectedItemIndex = self.index
          self:OnClick()
        end
      else
        if not curSelectInBattle then
          self:SetSelectedVisible(false)
        end
        if true == self.uiData.IsFirstOpenPanel and curSelectInBattle then
          self.laterPlayChange1 = true
          self._parent._selectedItem = self
          self._parent._selectedItemIndex = self.index
          self:OnClick()
        end
      end
      if curSelectInBattle then
        self.showBit = 9
        self:SetTagOrEquipIcon(true, "")
      elseif 1 == self.uiData.bag_item_flags then
        self.showBit = 8
        self:SetTagOrEquipIcon(true, "")
      elseif 8 == self.uiData.bag_item_flags then
        self.showBit = 8
        self:SetTagOrEquipIcon(true, "")
      elseif 9 == self.uiData.bag_item_flags then
        self.showBit = 8
        self:SetTagOrEquipIcon(true, "")
      else
        self.showBit = 0
        self:SetTagOrEquipIcon(false, "")
      end
    else
      if -1 ~= self.uiData.FirstOpenPanelId then
        if self.uiData.FirstOpenPanelId ~= self.uiData.id then
          self:SetSelectedVisible(false)
        end
      elseif 1 ~= self.index then
        self:SetSelectedVisible(false)
      end
      local getEquipMagic = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetEquipMagicInfo)
      self.showBit = self.uiData.bag_item_flags
      if self.uiData.type ~= _G.Enum.BagItemType.BI_PET_BALL and self.uiData.bag_item_flags and 1 == self.uiData.bag_item_flags & 1 or getEquipMagic and self.uiData.gid == getEquipMagic.gid then
        self:SetTagOrEquipIcon(true, "")
      else
        self:SetTagOrEquipIcon(false, "")
      end
    end
  else
    self:SetSelectedVisible(false)
  end
  if self.uiData.bag_item_flags then
    self.showBit = self.uiData.bag_item_flags
    self:SetTagEquipIcon()
  end
  local itemNum = ""
  itemNum = "x" .. tostring(self.uiData.num)
  self:SetNumSize(self.uiData.num)
  self.NumText:SetText(itemNum)
  local bagItemConf = self.uiData.conf
  if self.uiData.type == _G.Enum.BagItemType.BI_PLAYERSKILL and 0 == self.uiData.remain_use_cnt then
    self.ItemIcon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#A1A1A1FF"))
  else
    self.ItemIcon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
  end
  if bagItemConf then
    self:SetIcon(bagItemConf.icon)
    self.Skillicon:SetPath(bagItemConf.icon)
    self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SwapEggs_Check:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SwapEggs_Precious:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.uiData.type == _G.Enum.BagItemType.BI_SKILL_MACHINE then
      if self.SelectBGColor then
        self.SelectBGColor:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Bag/Raw/BagStatic/Frames/img_skillBg_png.img_skillBg_png'")
      end
      self.SelectBGColor_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetQuality(bagItemConf.item_quality)
      self.SkillBG:SetVisibility(UE4.ESlateVisibility.Visible)
      local skillMachineid = bagItemConf.item_behavior[1].ratio[1]
      local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
      self.SkillBG:SetPath(skillConf.icon)
      self.skilliconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Skillicon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      if self.FromBag then
        if self.SelectBGColor then
          self.SelectBGColor:SetPath(UEPath.PROP_QUALITY_NONE)
        end
      elseif self.SelectBGColor then
        self.SelectBGColor:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Bag/Raw/BagStatic/Frames/img_petBg_png.img_petBg_png'")
      end
      self.SelectBGColor_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.BGColor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.skilliconBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Skillicon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetCornerColor()
      self.ItemIcon:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SkillBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if self.uiData.type == _G.Enum.BagItemType.BI_PET_EGG then
      local Conf
      if bagItemConf.item_behavior[1].ratio[1] and 0 ~= bagItemConf.item_behavior[1].ratio[1] then
        Conf = _G.DataConfigManager:GetPetEggConf(bagItemConf.item_behavior[1].ratio[1])
      elseif bagItemConf.item_behavior[1].ratio2[1] then
        Conf = _G.DataConfigManager:GetPetRandomEggConf(bagItemConf.item_behavior[1].ratio2[1])
      end
      if self.uiData.egg_data and self.uiData.gid then
        self.PetEggTypeIconItem:SetItemIcon(self.uiData.gid, false)
        self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if self.uiData.egg_data.precious_egg_type and self.uiData.egg_data.precious_egg_type ~= Enum.PreciousEggType.PET_NONE then
          self:SetQuality(5)
        end
      end
    else
      self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if 0 == bagItemConf.show_quantity then
      self:SetNumVisible(false)
    else
      self:SetNumVisible(true)
    end
    self:UpdateFruitCD()
    if bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_OPEN_GP_BAG then
      local equipSeedId = _G.NRCModeManager:DoCmd(HomeModuleCmd.GetEquipSeed)
      if equipSeedId and equipSeedId > 0 then
        self:SetTagOrEquipIcon(true)
      else
        self:SetTagOrEquipIcon(false)
      end
    end
    if self.uiData.type == _G.Enum.BagItemType.BI_PET_BALL then
      self:UpdateCollectMark()
    end
    self:UpdateVouchGiftInfo(bagItemConf)
  end
  self:UpdateFurnitureDecomposeInfo()
end

function UMG_BagItemTemplate_C:UpdateFruitCD()
  if self.uiData == nil then
    return
  end
  local isNotCd = _G.NRCModuleManager:DoCmd(_G.SleepingOwlModuleCmd.OnGetFruitCd, self.uiData.fruit_active_timestamp)
  if isNotCd then
    self.CountdownIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CountdownIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BagItemTemplate_C:UpdateFurnitureDecomposeInfo()
  if self.FromBag then
    local BagData = NRCModuleManager:GetModule("BagModule"):GetData()
    local num = BagData and BagData:GetFurnitureDecomposeNum(self.uiData) or 0
    if 0 ~= num then
      self.FurnitureNumber:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      self.Text_Number:SetText(tostring(num))
    else
      self.FurnitureNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_BagItemTemplate_C:RefreshBagItemFurnitureInfoByGid(itemGid)
  if self.uiData and self.uiData.gid == itemGid then
    self:UpdateFurnitureDecomposeInfo()
  end
end

function UMG_BagItemTemplate_C:SetNumSize(Count)
  local number = Count
  local numberStr = tostring(number)
  local length = string.len(numberStr)
  local Font = self.NumText.Font
  if length > 5 then
    Font.Size = 22
    self.NumText:SetFont(Font)
  end
end

function UMG_BagItemTemplate_C:GetUnpackIconPath(name)
  local path = "Texture2D'/Game/NewRoco/Modules/System/TUI/IconTest/BagItem/" .. name .. "." .. name
  return path
end

function UMG_BagItemTemplate_C:GetUnpackIconPath190(name)
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/Item190/" .. name .. "." .. name
  return path
end

function UMG_BagItemTemplate_C:SetNumVisible(visible)
  if visible then
    self.NumText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.TextBG:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.NumText:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.TextBG:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_BagItemTemplate_C:SetTagOrEquipIcon(visible, path)
  if visible then
    if 9 == self.showBit then
      self.TagIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.TagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.TagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagItemTemplate_C:SetTagEquipIcon()
  if 0 ~= self.uiData.bag_item_flags then
  else
    self.TagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagItemTemplate_C:OnClick()
  _G.NRCModuleManager:GetModule("BagModule"):DispatchEvent(BagModuleEvent.ClearSelecteState)
  _G.NRCModuleManager:DoCmd(BagModuleCmd.SetSelectedItem, self.uiData, 0, self.bTouchClickByUser)
end

function UMG_BagItemTemplate_C:UnClick()
end

function UMG_BagItemTemplate_C:OnTouchEnded(MyGeometry, InTouchEvent)
  self.bTouchClickByUser = true
  local Ret = Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  self.bTouchClickByUser = false
  return Ret
end

function UMG_BagItemTemplate_C:OnItemSelected(selected)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if not selected then
    NRCModuleManager:DoCmd(RedPointModuleCmd.EraseRedPoint, 469, {
      self.uiData.id
    })
    if self.uiData.egg_data and self.uiData.gid and self.uiData.type == _G.Enum.BagItemType.BI_PET_EGG then
      self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  if self and self.PlayAnimation then
    self:PlayAnimation(self.normal)
  end
  self:StopAllAnimations()
  if selected then
    self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
    self:SetSelectedVisible(true)
    if self.FromBag and self.FromBag == true then
      self:PlayAnimation(self.change1)
      self:OnClick()
    else
      self:PlayAnimation(self.change1)
      _G.NRCModuleManager:DoCmd(BagModuleCmd.SetSelectedItem, self.uiData, 1)
    end
    if self.Panel then
      self.Panel:ItemSelect(self.index)
      if self.canOpenTips then
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.id, _G.Enum.GoodsType.GT_BAGITEM, false)
      end
      self.canOpenTips = true
    end
  else
    if self.uiData and self.uiData.type ~= _G.Enum.BagItemType.BI_SKILL_MACHINE then
      if self.FromBag then
        if self.SelectBGColor then
          self.SelectBGColor:SetPath(UEPath.PROP_QUALITY_NONE)
        end
      elseif self.SelectBGColor then
        self.SelectBGColor:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Bag/Raw/BagStatic/Frames/img_petBg_png.img_petBg_png'")
      end
    end
    if self.NumText then
      self.NumText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
    end
    if self and self.PlayAnimation then
      self:PlayAnimation(self.change2)
    end
    if self.Panel then
      self.canOpenTips = false
    end
  end
end

function UMG_BagItemTemplate_C:SetSelectedVisible(visible)
  if visible then
    if self.uiData and self.uiData.type ~= _G.Enum.BagItemType.BI_SKILL_MACHINE then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.id)
      self:SetSelectQuality(bagItemConf.item_quality)
      if self.uiData.type == _G.Enum.BagItemType.BI_PET_EGG then
        local Conf
        if bagItemConf.item_behavior[1].ratio[1] and 0 ~= bagItemConf.item_behavior[1].ratio[1] then
          Conf = _G.DataConfigManager:GetPetEggConf(bagItemConf.item_behavior[1].ratio[1])
        elseif bagItemConf.item_behavior[1].ratio2[1] then
          Conf = _G.DataConfigManager:GetPetRandomEggConf(bagItemConf.item_behavior[1].ratio2[1])
        end
        if Conf and Conf.precious_egg_type and Conf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
          self:SetSelectQuality(5)
        elseif self.uiData.egg_data and self.uiData.egg_data.precious_egg_type and self.uiData.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
          self:SetSelectQuality(5)
        end
      end
    end
    self.Selected:SetRenderOpacity(1)
    self.Selected:SetVisibility(UE4.ESlateVisibility.visible)
  else
    self.Selected:SetRenderOpacity(0)
    self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagItemTemplate_C:SetCornerColor()
  if self.uiData == nil then
    return
  end
  if nil == self.uiData.conf then
    return
  end
  local bagItemConf = self.uiData.conf
  local Quality = bagItemConf.item_quality
  local EggConf
  if bagItemConf.item_behavior and bagItemConf.type == Enum.BagItemType.BI_PET_EGG and bagItemConf.item_behavior[1] then
    if bagItemConf.item_behavior[1].ratio and bagItemConf.item_behavior[1].ratio[1] and 0 ~= bagItemConf.item_behavior[1].ratio[1] then
      EggConf = _G.DataConfigManager:GetPetEggConf(bagItemConf.item_behavior[1].ratio[1])
    elseif bagItemConf.item_behavior[1].ratio2 and bagItemConf.item_behavior[1].ratio2[1] and 0 ~= bagItemConf.item_behavior[1].ratio2[1] then
      EggConf = _G.DataConfigManager:GetPetRandomEggConf(bagItemConf.item_behavior[1].ratio2[1])
    end
  end
  if EggConf and EggConf.precious_egg_type and EggConf.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
    Quality = 5
  elseif self.uiData.egg_data and self.uiData.egg_data.precious_egg_type and self.uiData.egg_data.precious_egg_type ~= _G.Enum.PreciousEggType.PET_NONE then
    Quality = 5
  end
  self:SetQuality(Quality)
end

function UMG_BagItemTemplate_C:SetQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.BGColor:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_BagItemTemplate_C:SetSelectQuality(quality)
  if 0 == quality then
  elseif 1 == quality then
    self.SelectBGColor_1:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    self.SelectBGColor_1:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    self.SelectBGColor_1:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    self.SelectBGColor_1:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    self.SelectBGColor_1:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UMG_BagItemTemplate_C:OnAnimationFinished(Animation)
  if Animation == self.change1 then
  elseif Animation == self.change2 then
  elseif Animation == self.open then
    if self.laterPlayChange1 == true then
      self:PlayAnimation(self.change1)
      self:OnClick()
      self.laterPlayChange1 = false
    end
    self:SetClickable(true)
  end
end

function UMG_BagItemTemplate_C:OnNotifySwapEggsChanged(SelectState, ItemGID)
  if SelectState then
    self:SetClickable(false)
    if self.uiData and self.uiData.gid == ItemGID then
      self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SwapEggs_Check:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SwapEggs_Check:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:SetClickable(true)
    self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SwapEggs_Check:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagItemTemplate_C:UpdateVouchGiftInfo(bagItemConf)
  if bagItemConf.expire_time == nil then
    self.Expired:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NearDate:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local BagData = NRCModuleManager:GetModule("BagModule"):GetData()
  if BagData then
    local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
    local expireStatus = BagData:CheckItemExpireStatus(bagItemConf, expireThreshold)
    if expireStatus.isExpired then
      self.Expired:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NearDate:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Expired:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.SwapEggs_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NearDate:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    local normalPath = "PaperSprite'/Game/NewRoco/Modules/System/Bag/Raw/BagStatic/Frames/img_TimeIimit_png.img_TimeIimit_png'"
    local nearPath = "PaperSprite'/Game/NewRoco/Modules/System/Bag/Raw/BagStatic/Frames/img_Countdown_png.img_Countdown_png'"
    self.NearDate:SetPath(normalPath)
    if expireStatus.isNearExpire then
      self.NearDate:SetPath(nearPath)
    end
  end
end

function UMG_BagItemTemplate_C:SetIcon(icon_path)
  if self.uiData and self.uiData.type == _G.Enum.BagItemType.BI_PET_EGG then
    local eggData = self.uiData.egg_data
    if eggData then
      self.IconSwitcher:SetActiveWidgetIndex(1)
      self.PetEggIcon:SetEggIcon(eggData, icon_path)
      return
    end
  end
  self.IconSwitcher:SetActiveWidgetIndex(0)
  self.ItemIcon:SetPath(icon_path)
end

function UMG_BagItemTemplate_C:UpdateCollectMark()
  local isCollect = _G.NRCModuleManager:DoCmd(BagModuleCmd.CheckBallIsCollectOptimization, self.uiData.id)
  if isCollect then
    self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.EquippedIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_BagItemTemplate_C

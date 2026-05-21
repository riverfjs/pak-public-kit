local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_SelectBallEgg_C = Base:Extend("UMG_SelectBallEgg_C")

function UMG_SelectBallEgg_C:OnConstruct()
  Log.Debug("UMG_SelectBallEgg_C:OnConstruct")
  NRCEventCenter:RegisterEvent("UMG_SelectBallEgg_C", self, PetUIModuleEvent.OnHatchingRightPanelScrollViewScrolled, self.OnHatchingRightPanelScrollViewScrolled)
end

function UMG_SelectBallEgg_C:OnTick(InDeltaTime)
  if not self.Pressed or not self.LongPressTimer then
    return
  end
  if not self.StartPressPos then
    return
  end
  if not self.ItemData.bEnableLongClick then
    return
  end
  if self.Dragging then
    return
  end
  self.LongPressTimer = self.LongPressTimer - InDeltaTime
  if self.LongPressTimer <= 0 then
    self.StartPressPos = nil
    self:OnItemBeLongClicked()
  end
end

function UMG_SelectBallEgg_C:OnTouchStarted(MyGeometry, InTouchEvent)
  self.Pressed = true
  self.Dragging = false
  if self.ItemData and self.ItemData.bEnableLongClick then
    local ScreenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InTouchEvent)
    self.StartPressPos = ScreenPosition
    self.LongPressTimer = 0.5
    _G.UpdateManager:Register(self)
  end
  if self.ItemData.parentView then
    self.ItemData.parentView:SetCurMouseTouchItemIndex(self.Index)
  end
  Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_SelectBallEgg_C:OnTouchMoved(MyGeometry, InTouchEvent)
  if self.ItemData.parentView then
    self.ItemData.parentView:SetCurMouseTouchItemIndex(self.Index)
  end
  local ScreenPosition = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InTouchEvent)
  if self.StartPressPos then
    local DiffPostion = ScreenPosition - self.StartPressPos
    if DiffPostion:SizeSquared() >= 10 and self.ItemData and self.ItemData.bEnableLongClick then
      self.Dragging = true
      _G.UpdateManager:UnRegister(self)
    end
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_SelectBallEgg_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local OldPress = self.Pressed
  OldPress = true
  self.Pressed = false
  self.StartPressPos = nil
  if self.ItemData and self.ItemData.bEnableLongClick then
    _G.UpdateManager:UnRegister(self)
  end
  if self.ItemData.parentView then
    self.ItemData.parentView:SetCurMouseTouchItemIndex(self.Index)
  end
  if OldPress then
    return Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_SelectBallEgg_C:OnHatchingRightPanelScrollViewScrolled()
  self.Pressed = false
  self.LongPressTimer = nil
  _G.UpdateManager:UnRegister(self)
  if self.ItemData and self.ItemData.parentView then
    self.ItemData.parentView:SetCurMouseTouchItemIndex(nil)
  end
end

function UMG_SelectBallEgg_C:OnItemBeLongClicked()
  if self and UE4.UObject.IsValid(self) then
    if self.ItemData and self.ItemData.parentView then
      local CurMouseTouchItemIndex = self.ItemData.parentView:GetCurMouseTouchItemIndex()
      if CurMouseTouchItemIndex and CurMouseTouchItemIndex == self.Index then
        local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
        local showErrorTipsWhenNotFound = self.ItemData and self.ItemData.showDefaultIconWhenConfigError
        local showDefaultIconWhenNotFound = self.ItemData and self.ItemData.showDefaultIconWhenConfigError
        if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
          _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ItemData.itemId, _G.Enum.GoodsType.GT_BAGITEM, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
        elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
          _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ItemData.id, _G.Enum.GoodsType.GT_BAGITEM, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound, self.ItemData.gid)
        end
        self.ItemData.parentView:OnItemBeLongClicked()
      end
    end
    self.Pressed = false
    self.LongPressTimer = nil
    _G.UpdateManager:UnRegister(self)
    self.ItemData.parentView:SetCurMouseTouchItemIndex(nil)
  end
end

function UMG_SelectBallEgg_C:OnItemUpdate(Data, Datalist, Index)
  if nil == Data then
    Log.Error("UMG_SelectBallEgg_C:OnItemUpdate: _data is nil")
    return
  end
  if nil == Index then
    Log.Error("UMG_SelectBallEgg_C:OnItemUpdate: index is nil")
    return
  end
  self.ItemData = Data
  self.Index = Index
  self.DisplayMode = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetHatchingRightPanelDisplayMode)
  self.LongPressTimer = nil
  self.Pressed = nil
  self.StartPressPos = nil
  _G.UpdateManager:UnRegister(self)
  self:UpdateItemView()
end

function UMG_SelectBallEgg_C:OnDespawn()
  self.LongPressTimer = nil
  self.Pressed = nil
  self.StartPressPos = nil
  _G.UpdateManager:UnRegister(self)
end

function UMG_SelectBallEgg_C:UpdateItemView()
  if self.ItemData == nil then
    Log.Error("UMG_SelectBallEgg_C:UpdateItemView: self.ItemData is nil")
    return
  end
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.None then
    Log.Error("UMG_SelectBallEgg_C:UpdateItemView: self.DisplayMode is None")
    return
  end
  local ItemData = self.ItemData
  local ItemBagConf = self.ItemData.conf
  self.bSelected = false
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  self:StopAllAnimations()
  if PetUIModule and PetUIModule.data then
    local SelectItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel(self.ItemData)
    if SelectItemData and SelectItemData.gid == ItemData.gid then
      self.bSelected = true
      self:PlayAnimation(self.Select_Loop)
    else
      self.bSelected = false
      self:PlayAnimation(self.Normal_Loop)
    end
  end
  self.Fragment:SetVisibility(UE.ESlateVisibility.Collapsed)
  self.NRCSwitcher_Text:SetActiveWidgetIndex(0)
  self.PetEggMask:SetVisibility(UE.ESlateVisibility.Collapsed)
  self:SetClickable(true)
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
    self.BallEggSwitcher:SetActiveWidgetIndex(1)
    if ItemBagConf.type == _G.Enum.BagItemType.BI_PET_EGG then
      self:SetPetEggItemView(ItemData, ItemBagConf)
    elseif ItemBagConf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
      local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
      self:SetClickable(RequireGlassEggPieceNum <= ItemData.num and true or false)
      self.NRCSwitcher_Text:SetActiveWidgetIndex(RequireGlassEggPieceNum <= ItemData.num and 0 or 1)
      self.PetEggMask:SetVisibility(RequireGlassEggPieceNum <= ItemData.num and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
      self:SetGlassEggPieceItemView(ItemData, ItemBagConf)
    end
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
    self.PatternSwitcher:SetActiveWidgetIndex(0)
    self.BallEggSwitcher:SetActiveWidgetIndex(0)
    self.NumSwitcher:SetActiveWidgetIndex(0 ~= ItemData.itemNum and 0 or 1)
    self.PetBallMask:SetVisibility(0 ~= ItemData.itemNum and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    self:SetClickable(0 ~= ItemData.itemNum and true or false)
    self.PetBallName:SetText(ItemData.conf.name)
    self.PetBallNum:SetText(ItemData.itemNum)
    self.PetBallName:SetRenderOpacity(0 ~= ItemData.itemNum and 1 or 0.35)
    self.BagIcon:SetRenderOpacity(0 ~= ItemData.itemNum and 1 or 0.35)
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    self.NumSwitcher:SetActiveWidgetIndex(0 ~= ItemData.itemNum and 0 or 1)
    self:SetClickable(0 ~= ItemData.itemNum and true or false)
    self.PetBallName:SetText(ItemData.conf.name)
    self.PetBallNum:SetText(ItemData.itemNum)
  end
  self:SetItemIcon()
end

function UMG_SelectBallEgg_C:SetPetEggItemView(ItemData, ItemBagConf)
  local ItemName = ItemBagConf.name
  local isHaveBook = false
  local haveName, des
  if ItemData.egg_data and 0 ~= ItemData.egg_data.conf_id then
    isHaveBook, haveName, des = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, ItemBagConf.id)
    if isHaveBook then
      ItemName = haveName
    end
  end
  self.PatternSwitcher:SetActiveWidgetIndex(0)
  local PetEggConf
  local isRandomEgg = false
  if ItemBagConf.item_behavior[1] and ItemBagConf.item_behavior[1].ratio[1] and 0 ~= ItemBagConf.item_behavior[1].ratio[1] then
    PetEggConf = _G.DataConfigManager:GetPetEggConf(ItemBagConf.item_behavior[1].ratio[1])
  elseif ItemBagConf.item_behavior[1] and ItemBagConf.item_behavior[1].ratio2[1] then
    PetEggConf = _G.DataConfigManager:GetPetRandomEggConf(ItemBagConf.item_behavior[1].ratio2[1])
    isRandomEgg = true
  end
  if PetEggConf and PetEggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_PRECIOUS then
  else
    if ItemData.egg_data and ItemData.egg_data.precious_egg_type == _G.Enum.PreciousEggType.PET_PRECIOUS and not isRandomEgg and not isHaveBook then
      ItemName = LuaText.cifu_precious_petegg
    else
    end
  end
  self.PetEggTypeIconItem:SetItemIcon(ItemData.gid)
  self.PetEggName:SetText(ItemName)
end

function UMG_SelectBallEgg_C:SetGlassEggPieceItemView(ItemData, ItemBagConf)
  if nil == ItemData then
    Log.Error("UMG_SelectBallEgg_C:SetGlassEggPieceItemView: self.ItemData is nil")
    return
  end
  self.PatternSwitcher:SetActiveWidgetIndex(1)
  self.Fragment:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  self.FragmentNumber:SetText(string.format("%d/%d", ItemData.num, RequireGlassEggPieceNum))
  self.FragmentNumber_1:SetText(string.format("%d/%d", ItemData.num, RequireGlassEggPieceNum))
  self.FragmentNumber_2:SetText(string.format("%d/%d", ItemData.num, RequireGlassEggPieceNum))
  local ItemName = ItemBagConf.name
  if ItemData.egg_data and 0 ~= ItemData.egg_data.conf_id then
    local isHaveBook, haveName, des = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, ItemBagConf.id)
    if isHaveBook then
      ItemName = haveName
    end
  end
  self.PetEggTypeIconItem:SetItemIcon(ItemData.gid)
  self.PetEggName:SetText(ItemName)
  self.PetEggName_4:SetText(ItemName)
end

function UMG_SelectBallEgg_C:SetItemIcon()
  if self.ItemData == nil then
    Log.Error("UMG_SelectBallEgg_C:SetItemIcon: self.ItemData is nil")
    return
  end
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.ItemData.id)
  if nil == BagItemConf then
    Log.Error("UMG_SelectBallEgg_C:SetItemIcon: BagItemConf is nil")
    return
  end
  local IconPath = BagItemConf.icon
  if string.IsNilOrEmpty(IconPath) then
    Log.Error("UMG_SelectBallEgg_C:SetItemIcon: IconPath is nil or empty")
    return
  end
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
    if self.ItemData.conf.type == _G.Enum.BagItemType.BI_PET_EGG then
      local eggData = self.ItemData.egg_data
      if eggData then
        self.PetEggItem:SetEggIcon(eggData, IconPath)
      end
    elseif self.ItemData.conf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
      local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
      if RequireGlassEggPieceNum <= self.ItemData.num then
        if self.ItemData.conf.item_behavior[1] and self.ItemData.conf.item_behavior[1].ratio[1] and 0 ~= self.ItemData.conf.item_behavior[1].ratio[1] then
          local CustomGlassEggBagItemConfID = self.ItemData.conf.item_behavior[1].ratio[1]
          local CustomGlassEggBagItemConf = _G.DataConfigManager:GetBagItemConf(CustomGlassEggBagItemConfID)
          if CustomGlassEggBagItemConf and CustomGlassEggBagItemConf.item_behavior[1] and CustomGlassEggBagItemConf.item_behavior[1].ratio[1] and 0 ~= CustomGlassEggBagItemConf.item_behavior[1].ratio[1] then
            local PetEggConfID = CustomGlassEggBagItemConf.item_behavior[1].ratio[1]
            local PetEggConf = _G.DataConfigManager:GetPetEggConf(PetEggConfID)
            if PetEggConf then
              local CustomEggData = {conf_id = PetEggConfID}
              self.PetEggItem:SetEggIcon(CustomEggData, IconPath)
            end
          end
        end
      else
        self.PetEggItem.EggIcon:SetVisibility(UE4.ESlateVisibility.Visible)
        self.PetEggItem.EggIcon:SwitchToSetBrushFromMaterialInstanceMode(false)
        self.PetEggItem.EggIcon:SetPath(IconPath)
        self.PetEggItem.EggIcon:SetRenderOpacity(1)
        self.PetEggItem:ForceLayoutPrepass()
      end
    end
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
    self.PetBallIcon:SetPath(IconPath)
    self.PetBallMask:SetPath(IconPath)
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    self.PetBallIcon:SetPath(IconPath)
  end
end

function UMG_SelectBallEgg_C:OnItemSelected(bSelected)
  if self.bSelected == bSelected then
    return
  end
  self.bSelected = bSelected
  self:StopAnimation(self.Select)
  self:StopAnimation(self.Normal)
  if bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_SelectBallEgg_C:OnItemSelected")
    self:PlayAnimation(self.Select)
    local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
    if PetUIModule and PetUIModule.data then
      PetUIModule.data:SetCurSelectItemDataInHatchingRightPanel(self.ItemData)
    end
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_SelectBallEgg_C:BroadcastOnClicked()
  if self.ItemData and self.ItemData.conf and self.ItemData.conf.type and self.ItemData.conf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
    local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
    if RequireGlassEggPieceNum > self.ItemData.num then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.glass_egg_collect_progress3, RequireGlassEggPieceNum))
    end
  end
end

function UMG_SelectBallEgg_C:PlayItemAnimation(aim)
  self:SetParentViewClickable(false)
  self:PlayAnimation(aim)
end

function UMG_SelectBallEgg_C:OnAnimationFinished(aim)
  self:SetParentViewClickable(true)
end

function UMG_SelectBallEgg_C:SetParentViewClickable(bClickable)
  if self.ItemData.parentView and UE4.UObject.IsValid(self) and self.ItemData.SetViewClickable then
    self.ItemData.parentView:SetViewClickable(bClickable)
  end
end

function UMG_SelectBallEgg_C:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnHatchingRightPanelScrollViewScrolled, self.OnHatchingRightPanelScrollViewScrolled)
end

function UMG_SelectBallEgg_C:OnDeactive()
end

return UMG_SelectBallEgg_C

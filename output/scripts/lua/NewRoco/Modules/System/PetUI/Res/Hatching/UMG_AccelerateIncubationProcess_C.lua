local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_AccelerateIncubationProcess_C = Base:Extend("UMG_AccelerateIncubationProcess_C")

function UMG_AccelerateIncubationProcess_C:OnActive()
end

function UMG_AccelerateIncubationProcess_C:OnDeactive()
end

function UMG_AccelerateIncubationProcess_C:OnAddEventListener()
end

function UMG_AccelerateIncubationProcess_C:OnRemoveEventListener()
end

function UMG_AccelerateIncubationProcess_C:OnItemUpdate(Data, Datalist, Index)
  if nil == Data then
    Log.Error("UMG_AccelerateIncubationProcess_C:OnItemUpdate: _data is nil")
    return
  end
  if nil == Index then
    Log.Error("UMG_AccelerateIncubationProcess_C:OnItemUpdate: index is nil")
    return
  end
  self.ItemData = Data
  self.Index = Index
  self.bSelected = false
  self.DisplayMode = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetHatchingRightPanelDisplayMode)
  self.LongPressTimer = nil
  self.Pressed = nil
  self.StartPressPos = nil
  _G.UpdateManager:UnRegister(self)
  if self.DisplayMode and self.DisplayMode ~= PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    Log.Error("UMG_AccelerateIncubationProcess_C:OnItemUpdate: DisplayMode is not IncubationProgress")
    return
  end
  self:UpdateView()
end

function UMG_AccelerateIncubationProcess_C:UpdateView()
  if self.ItemData == nil then
    Log.Error("UMG_AccelerateIncubationProcess_C:UpdateView: ItemData is nil")
    return
  end
  if nil == self.ItemData.conf then
    Log.Error("UMG_AccelerateIncubationProcess_C:UpdateView: ItemData.conf is nil")
    return
  end
  self.ItemName:SetText(self.ItemData.conf.name)
  self.ItemNum:SetText(self.ItemData.num)
  self.NumSwitcher:SetActiveWidgetIndex(self.ItemData.num > 0 and 0 or 1)
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(self.ItemData.id)
  if nil == BagItemConf then
    Log.Error("UMG_AccelerateIncubationProcess_C:SetItemIcon: BagItemConf is nil")
    return
  end
  local IconPath = BagItemConf.icon
  if string.IsNilOrEmpty(IconPath) then
    Log.Error("UMG_AccelerateIncubationProcess_C:SetItemIcon: IconPath is nil or empty")
    return
  end
  self.PetBallIcon:SetPath(IconPath)
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  self:StopAllAnimations()
  if PetUIModule and PetUIModule.data then
    local SelectItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel(self.ItemData)
    if SelectItemData and SelectItemData.gid == self.ItemData.gid then
      self.bSelected = true
      self:PlayAnimation(self.Select_Loop)
    else
      self.bSelected = false
      self:PlayAnimation(self.Normal_Loop)
    end
  end
end

function UMG_AccelerateIncubationProcess_C:OnItemSelected(bSelected)
  if self.bSelected == bSelected then
    return
  end
  self.bSelected = bSelected
  self:StopAnimation(self.Select)
  self:StopAnimation(self.Normal)
  if bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_AccelerateIncubationProcess_C:OnItemSelected")
    self:PlayAnimation(self.Select)
    local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
    if PetUIModule and PetUIModule.data then
      PetUIModule.data:SetCurSelectItemDataInHatchingRightPanel(self.ItemData)
    end
  else
    self:PlayAnimation(self.Normal)
  end
end

function UMG_AccelerateIncubationProcess_C:OnTick(InDeltaTime)
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

function UMG_AccelerateIncubationProcess_C:OnTouchStarted(MyGeometry, InTouchEvent)
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

function UMG_AccelerateIncubationProcess_C:OnTouchMoved(MyGeometry, InTouchEvent)
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

function UMG_AccelerateIncubationProcess_C:OnTouchEnded(MyGeometry, InTouchEvent)
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

function UMG_AccelerateIncubationProcess_C:OnItemBeLongClicked()
  if self and UE4.UObject.IsValid(self) then
    if self.ItemData and self.ItemData.parentView then
      local CurMouseTouchItemIndex = self.ItemData.parentView:GetCurMouseTouchItemIndex()
      if CurMouseTouchItemIndex and CurMouseTouchItemIndex == self.Index then
        local remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack
        local showErrorTipsWhenNotFound = self.ItemData and self.ItemData.showDefaultIconWhenConfigError
        local showDefaultIconWhenNotFound = self.ItemData and self.ItemData.showDefaultIconWhenConfigError
        _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ItemData.id, _G.Enum.GoodsType.GT_BAGITEM, false, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
        self.ItemData.parentView:OnItemBeLongClicked()
      end
    end
    self.Pressed = false
    self.LongPressTimer = nil
    _G.UpdateManager:UnRegister(self)
    self.ItemData.parentView:SetCurMouseTouchItemIndex(nil)
  end
end

function UMG_AccelerateIncubationProcess_C:OnDespawn()
  self.LongPressTimer = nil
  self.Pressed = nil
  self.StartPressPos = nil
  _G.UpdateManager:UnRegister(self)
end

return UMG_AccelerateIncubationProcess_C

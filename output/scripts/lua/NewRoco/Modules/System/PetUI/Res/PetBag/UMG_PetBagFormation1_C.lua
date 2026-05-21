local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local Delegate = require("Utils.Delegate")
local UMG_PetBagFormation1_C = Base:Extend("UMG_PetBagFormation1_C")
local EnumItemMode = {
  None = 0,
  NormalMode = 1,
  SelectMode = 2,
  Change = 3,
  Reset = 4
}
local INDEX_BASE = 6

function UMG_PetBagFormation1_C:OnConstruct()
  self.IsNilPet = false
  self.hasPet = false
  self.preparedForChange = false
  self.ItemMode = EnumItemMode.None
  self.Change:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Module = NRCModuleManager:GetModule("PetUIModule")
  if self.Module then
    self.Module:RegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  end
  NRCEventCenter:RegisterEvent("UMG_PetBagFormation1_C", self, PetUIModuleEvent.PetBagUIItemUpdateUI, self.UpdatePetLevel)
  NRCEventCenter:RegisterEvent("UMG_PetBagFormation1_C", self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
  self.OnGuidanceLongPress = Delegate()
  self.OnGuidanceReleased = Delegate()
end

function UMG_PetBagFormation1_C:OnDestruct()
  self:CancelAllDelay()
  if self.Module then
    self.Module:UnRegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  end
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetBagUIItemUpdateUI, self.UpdatePetLevel)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
end

function UMG_PetBagFormation1_C:OnDeactive()
end

function UMG_PetBagFormation1_C:OnActive()
end

function UMG_PetBagFormation1_C:OnAddEventListener()
end

function UMG_PetBagFormation1_C:ResetMarkIcon()
  self.CheckIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NrcRedPoint:SetupKey(0)
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation1_C:OnItemUpdate(_data, datalist, index)
  self.IsNilPet = false
  self.isEmptyItem = _data.petInfo.emptyItem
  self.bLock = false
  self.bCanNotPlaySelectedAnim = false
  self.bFiltering = false
  if _data.needToPlayRefreshAnim then
    self:PlayAnimation(self.Refresh)
  end
  self:ResetMarkIcon()
  if self.isEmptyItem then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.IsNilPet = false
    self.uiData = nil
    self.clickable = false
    return
  end
  self._data = _data
  if index then
    self.index = index + INDEX_BASE
    self.ListIndex = index
    self.pos = index - 1
    self.c = index
    self.parent = _data.parent
  end
  if nil == _data.petInfo.base_conf_id then
    self.NilParent = _data.parent
    self.icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NumText:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetRightCornerMark(true)
    self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.hasPet = false
    self.IsNilPet = true
    self.uiData = nil
  else
    self.uiData = _data.petInfo
    if nil == self.uiData.gid then
      self.NrcRedPoint:ShowRedPoint(false)
    end
    self:SetItemData(self.uiData)
  end
  self:InitSelectItem()
end

function UMG_PetBagFormation1_C:InitSelectItem()
  if self:CheckIsSelectedItem() and self.parent ~= nil and UE4.UObject.IsValid(self.parent) and self.ListIndex then
    self.parent:SelectBagItemByIndex(self.ListIndex)
  end
end

function UMG_PetBagFormation1_C:UpdateCollect()
  if self.uiData and self.uiData.petData and self.uiData.petData.partner_mark and self.uiData.petData.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
    self.Star:SetPath(PetUtils.GetPetCollectTagIcon(self.uiData.petData.partner_mark))
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBagFormation1_C:SetItemData(_petInfo, datalistInfo)
  self:ResetItemUI()
  self:SwitchToNormalMode()
  self:SetItemClickable()
  self:UpdateCollect()
  self.TagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NumText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Empty:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.clickable = true
  self.hasPet = true
  if nil == self.uiData.petData then
    return
  end
  self:ShowPetIcon(self.uiData.base_conf_id, self.uiData.gid)
  self:SetRightCornerMark()
  self:UpdateUIInReleaseLifeMode()
end

function UMG_PetBagFormation1_C:ResetItemUI()
  self.CheckIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation1_C:ShowPetIcon(petBaseId, gid)
  local quality, moduleConfId
  if self.uiData.IsTravel or self.uiData.IsInHome or self.uiData.IsInGuard or self:GetSelfIsInFreeList() then
    if self.NrcRedPoint:IsRed() then
      self:SetRedMaskVisibility()
    end
  else
    self:SetRedMaskVisibility()
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.NumText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetItemClickable()
  self:SetLockVisibility()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if petBaseConf then
    moduleConfId = petBaseConf.model_conf
    quality = petBaseConf.quality
  end
  self.NumText:SetText(self.uiData.petData.level)
  self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
  if moduleConfId then
    local petData = self.uiData.petData
    local model_conf = _G.DataConfigManager:GetModelConf(moduleConfId)
    if model_conf then
      self.HeadIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
      self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
      if PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
        self.BlackMask:SetPath(model_conf.shiny_icon)
      else
        self.BlackMask:SetPath(model_conf.icon)
      end
    end
  end
  self.NrcRedPoint:SetupKey(139, {gid})
end

function UMG_PetBagFormation1_C:SetItemQuality(quality)
end

function UMG_PetBagFormation1_C:OnItemSelected(isSelected, IsScrollSelect)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.bLock then
    return
  end
  if self.preparedForChange then
    if isSelected then
      _G.NRCAudioManager:PlaySound2DAuto(1352, "UMG_PetBagFormation1_C:OnItemSelected")
      self:PrepareChangePet()
    end
    return
  end
  if self.uiData and self.uiData.IsTravel then
    return
  end
  if isSelected then
    self:StopTargetAnimations()
    self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
    self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Move_Selected_In)
    if IsScrollSelect then
      return
    end
    if self.sayNothing then
      self.sayNothing = false
    else
      self:HandlePetItemSelected()
    end
  else
    if self.uiData and self.parent and self.parent:IsSelectedPet(self.uiData.gid) then
      self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
    else
    end
    self:StopTargetAnimations()
    self:PlayAnimation(self.Move_Selected_Out)
  end
end

function UMG_PetBagFormation1_C:HandlePetItemSelected()
  local bNeedUpdatePetMiddlePanel = false
  local SelectPetGID = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurSelectPetGIDInPortableBag)
  local SelectItemType = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
  if nil == SelectPetGID and self.uiData and self.uiData.petData then
    bNeedUpdatePetMiddlePanel = true
  elseif self.uiData and self.uiData.petData and SelectPetGID and SelectPetGID ~= self.uiData.petData.gid then
    bNeedUpdatePetMiddlePanel = true
  elseif SelectItemType == PetUIModuleEnum.PortableBagSelectItemType.None and self.uiData and self.uiData.petData then
    bNeedUpdatePetMiddlePanel = true
  end
  self:SetSelectItemData()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ChangeChoosePet, self.index, self.uiData, true, not bNeedUpdatePetMiddlePanel)
  if self.uiData and self.uiData.petData then
    if nil ~= self.parent and nil ~= self.index then
      self.parent:OnPetItemClick(self.index, true, self.uiData.petData, self)
    end
    self:OnItemClickInReleaseLifeMode()
  elseif nil ~= self.parent and nil ~= self.index then
    self.parent:OnPetItemClick(self.index, true, nil, self)
  end
end

function UMG_PetBagFormation1_C:SetSelectItemData()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectItemTypeInPortableBag, PetUIModuleEnum.PortableBagSelectItemType.PageItem)
  local PetGID
  if self.uiData and self.uiData.petData then
    PetGID = self.uiData.petData.gid
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, PetGID)
  local CurShowPageID = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectInfoInPortableBag, CurShowPageID, self.ListIndex)
end

function UMG_PetBagFormation1_C:OnItemClickInReleaseLifeMode(bIgnorePvpOrPveTeam)
  bIgnorePvpOrPveTeam = bIgnorePvpOrPveTeam or false
  if self.uiData == nil then
    return
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    local add = not self:GetSelfIsInFreeList()
    if self.parent:AddOrRemoveItemFromFreeList(self.uiData.petData, add, bIgnorePvpOrPveTeam) then
      self:UpdateUIInReleaseLifeMode()
    end
  end
end

function UMG_PetBagFormation1_C:UpdateUIInReleaseLifeMode()
  self:SetLockVisibility()
  self:SetItemClickable()
  self.CheckIcon:SetVisibility(self:GetSelfIsInFreeList() and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self:SetRightCornerMark()
end

function UMG_PetBagFormation1_C:GetSelfIsInFreeList()
  local bInFreeList = false
  if self.parent and self.uiData and self.uiData.petData then
    bInFreeList = self.parent:CheckIsInFreeList(self.uiData.petData)
  end
  return bInFreeList
end

function UMG_PetBagFormation1_C:SetLockVisibility()
  local IsShow = false
  if self:IsRawGrayInFreeMode() or self:GetSelfIsInFreeList() then
    IsShow = true
  end
  if self.ItemMode == EnumItemMode.SelectMode and not self.IsNilPet then
    IsShow = true
  end
  if self.ItemMode == EnumItemMode.Change then
    IsShow = true
  end
  if self.bLock then
    IsShow = true
  end
  if self.IsNilPet then
    IsShow = false
  end
  self.Lock:SetVisibility(IsShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation1_C:SetRedMaskVisibility()
  if self.uiData == nil then
    self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local IsShow = false
  local IsRed = self.NrcRedPoint:IsRed()
  if (self.uiData.IsInHome or self.uiData.IsInGuard) and IsRed then
    IsShow = false
  end
  if self.ItemMode == EnumItemMode.SelectMode and IsRed then
    IsShow = true
  end
  if self.ItemMode == EnumItemMode.Change and IsRed then
    IsShow = true
  end
  if self.bLock and IsRed then
    IsShow = true
  end
  local IsInFreeMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode)
  if IsInFreeMode then
    IsShow = false
  end
  self.RedMask:SetVisibility(IsShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation1_C:IsRawGrayInFreeMode(bShowTips)
  local IsRawGray = false
  if self.uiData == nil then
    return IsRawGray
  end
  if nil == self.uiData.gid then
    return IsRawGray
  end
  if nil == bShowTips then
    bShowTips = false
  end
  IsRawGray = PetUtils.CheckIsForbidSelectPetInFreeMode(self.uiData.gid, bShowTips)
  return IsRawGray
end

function UMG_PetBagFormation1_C:SwitchToSelectMode(IsChange)
  self.ItemMode = EnumItemMode.SelectMode
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  if IsChange then
  else
  end
end

function UMG_PetBagFormation1_C:LongDragSwitchToSelectMode()
  if self.NrcRedPoint:IsRed() and self.uiData and not self.uiData.IsInHome and not self.uiData.IsInGuard then
    self.RedMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.uiData and self.parent and self.parent:IsDragPet(self.uiData.gid) then
    return
  end
  if self.bCanNotPlaySelectedAnim then
    return
  end
  if not self.IsNilPet then
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:StopTargetAnimations()
  self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_Drag_png.img_Drag_png'")
  self:PlayAnimation(self.Move_Selected_In)
end

function UMG_PetBagFormation1_C:LongDragSwitchToNormalMode()
  if self.isDestruct or self.LongDragSelect then
    return
  end
  self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
  self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.bCanNotPlaySelectedAnim then
    return
  end
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.uiData and self.parent and self.parent:IsSelectedPet(self.uiData.gid) then
    return
  end
  if self.uiData and self.parent and self.parent:IsDragPet(self.uiData.gid) then
    return
  end
  self:StopTargetAnimations()
  self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Move_Selected_Out)
  self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation1_C:SetDragMouseWheelMode()
  self:LongDragSwitchToSelectMode()
end

function UMG_PetBagFormation1_C:SwitchToNormalMode()
  if self.isDestruct then
    return
  end
  self.ItemMode = EnumItemMode.NormalMode
  if self.LongDragSelect then
    self.LongDragSelect = false
    self:LongDragSwitchToNormalMode()
  elseif self.uiData and self.parent and self.parent.exchangeTargetPetInfo and self.parent.exchangeTargetPetInfo.gid == self.uiData.gid then
    self:LongDragSwitchToNormalMode()
  else
    self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
    if not self:CheckIsSelectedItem() then
      self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self.LongDragSelect = false
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
end

function UMG_PetBagFormation1_C:CheckIsSelectedItem()
  local CurSelectItemType = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
  if nil ~= CurSelectItemType and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.PageItem then
    local CurShowPageID = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurShowPageIndexInPortableBag)
    local CurSelectPageID, CurSelectItemIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectInfoInPortableBag)
    if nil ~= CurShowPageID and nil ~= CurSelectPageID and nil ~= CurSelectItemIndex and nil ~= self.ListIndex and CurSelectPageID == CurShowPageID and CurSelectItemIndex == self.ListIndex then
      return true
    end
  end
  return false
end

function UMG_PetBagFormation1_C:SwitchToChange()
  if self.uiData == nil then
    return
  end
  self.ItemMode = EnumItemMode.Change
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_PetBagFormation1_C:SwitchToReset()
  self.ItemMode = EnumItemMode.Reset
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_PetBagFormation1_C:PrepareChangePet()
  if self.parent and self.parent.bIsPendingResPetUpdatePkg then
    Log.Warning("\230\173\163\229\156\168\231\173\137\229\190\133\229\155\158\229\140\133")
    return
  end
  if self.parent == nil and self.IsNilPet then
    local NilData = {gid = "IsNil", isInBackPack = true}
    self.NilParent:SetPetRemoveFromTeam(NilData)
  elseif self.parent then
    self.parent:SetPetRemoveFromTeam(self.uiData)
  end
end

function UMG_PetBagFormation1_C:SetItemClickable(Clickable)
  if nil ~= Clickable then
    self:SetClickable(Clickable)
    return
  end
  self:SetClickable(true)
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) and self:IsRawGrayInFreeMode(false) then
    self:SetClickable(false)
  else
  end
end

function UMG_PetBagFormation1_C:BroadcastOnClicked()
  self:IsRawGrayInFreeMode(true)
end

function UMG_PetBagFormation1_C:OnTouchStarted(_MyGeometry, _TouchEvent)
  Base.OnTouchStarted(self, _MyGeometry, _TouchEvent)
  self:CancelAllDelay()
  if not (not self.IsNilPet and self.hasPet and self.clickable) or self.uiData.IsTravel or self.parent and self.parent.IsBtnToExChange or self.bLock then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if self.parent then
    self.parent:SetDragItemTemp(self)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetBagFormation1_C:OnMouseLeave(_MyGeometry, _TouchEvent)
  self:CancelAllDelay()
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetBagFormation1_C:CancelAllDelay()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
end

function UMG_PetBagFormation1_C:LongPress()
  if self.bLock then
    return
  end
  self.LongDragSelect = true
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, false, self._data, self.pos)
  self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local bPlayInAnim
  if self:IsAnimationPlaying(self.Move_Selected_In) then
    bPlayInAnim = true
  end
  self:StopTargetAnimations()
  if bPlayInAnim then
    self:PlayAnimation(self.Move_Selected_In)
  end
  if self.OnGuidanceLongPress then
    self.OnGuidanceLongPress:Invoke(self)
  end
end

function UMG_PetBagFormation1_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  if self.clickable then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetBagFormation_C:OnTouchEnded")
  end
  self:CancelAllDelay()
  Base.OnTouchEnded(self, _MyGeometry, _TouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetBagFormation1_C:OnAnimationFinished(Animation)
  if Animation == self.Chuxian then
    self:PlayAnimation(self.mask)
  end
  if Animation == self.mask then
    if self.preparedForChange then
      self:PlayAnimation(self.mask)
    else
      self.RedMask:SetVisibility(UE4.ESlateVisibility.Hidden)
      self.Lock:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_PetBagFormation1_C:UpdatePetData(petData)
  if petData.gid ~= self.uiData.gid then
    return
  end
  self.uiData.petData = petData
  self.uiData.base_conf_id = self.uiData.petData.base_conf_id
  self.NumText:SetText(self.uiData.petData.level)
  self.uiData.level = self.uiData.petData.level
  self:ShowPetIcon(self.uiData.base_conf_id, self.uiData.gid)
  self:UpdateCollect()
end

function UMG_PetBagFormation1_C:SetRightCornerMark(bInit)
  if self.uiData == nil then
    return
  end
  if nil == self.uiData.petData then
    return
  end
  if bInit then
    self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") and _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, self.uiData.gid, 4) then
    self.Lock_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local IsInReleaseLifeMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode)
  self.NrcRedPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.NrcRedPoint:IsRed() and self:CheckIsCanShowRedPoint() then
    self.NrcRedPoint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if PetUtils.GetIsInPvpOrPveTeamByGid(self.uiData.petData.gid) and IsInReleaseLifeMode then
    self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State:SetActiveWidgetIndex(3)
  else
    self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.InFormation_1:SetPath(iconPath)
  if self.uiData.IsInHome then
    self.State:SetActiveWidgetIndex(2)
    local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_ruzhu_png.img_ruzhu_png'"
    self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.InFormation_1:SetPath(iconPath)
  elseif self.uiData.IsInGuard then
    self.State:SetActiveWidgetIndex(2)
    local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_Plant_protectionIcon2_png.img_Plant_protectionIcon2_png'"
    self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.InFormation_1:SetPath(iconPath)
  end
  local IsInActivity = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.IsPetInCurTripInfo, self.uiData.petData.gid)
  if IsInActivity then
    self.State:SetActiveWidgetIndex(2)
    local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_youyuan_png.img_youyuan_png'"
    self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.InFormation_1:SetPath(iconPath)
  end
  if self:GetSelfIsInFreeList() then
    self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBagFormation1_C:CheckIsCanShowRedPoint()
  local IsCanShowRedPoint = true
  local IsInReleaseLifeMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode)
  local IsInHome = self.uiData.IsInHome
  local IsInGuard = self.uiData.IsInGuard
  if IsInReleaseLifeMode or IsInHome or IsInGuard then
    IsCanShowRedPoint = false
    return IsCanShowRedPoint
  end
  return IsCanShowRedPoint
end

function UMG_PetBagFormation1_C:OnNewPetBagReleaseLifeModeChanged(isReleaseLifeMode)
  self:UpdateUIInReleaseLifeMode()
end

function UMG_PetBagFormation1_C:OnPetTraceBackSuccessAndRewardPopupClose(changes, gid)
  if self.uiData == nil then
    return
  end
  if nil == gid then
    return
  end
  if gid ~= self.uiData.gid then
    return
  end
  if self.bDragItem then
    return
  end
  local NewPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
  self:UpdatePetData(NewPetData)
  if self.Module then
    self.Module:DispatchEvent(PetUIModuleEvent.OnUpdatePetImage3dData, NewPetData)
  end
  if not self:IsAnimationPlaying(self.TraceBack) then
    self.TimeRewindFxPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.TraceBack)
  end
end

function UMG_PetBagFormation1_C:UpdatePetLevel(petGID)
  if petGID == self.uiData.gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGID)
    self.NumText:SetText(petData.level)
  end
end

function UMG_PetBagFormation1_C:EnterDisableDragState(bEnter)
  if bEnter then
    self.bLock = true
  else
    self.bLock = false
  end
  self:SetLockVisibility()
  self:SetRedMaskVisibility()
end

function UMG_PetBagFormation1_C:ShowExchangeIcon(bShow, bFiltering, bDragTeamPet)
  self.bFiltering = false
  if bFiltering and not bDragTeamPet then
    if bShow then
      self.bFiltering = true
      if self.uiData then
        self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if self.NrcRedPoint:IsRed() then
          self.RedMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    else
      self.bFiltering = false
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.bCanNotPlaySelectedAnim = false
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if bDragTeamPet and self.uiData and (self.uiData.IsInHome or self.uiData.IsInGuard) and bShow then
      self.bCanNotPlaySelectedAnim = true
      self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif self.hasPet then
      self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if not bShow then
        self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if bShow then
        self.Put:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetBagFormation1_C:AsDragItemInitInfo(_data)
  self.Move:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:OnItemUpdate(_data, nil)
  self.bDragItem = true
  self.NrcRedPoint:SetupKey(0)
end

function UMG_PetBagFormation1_C:OnMouseButtonReleased()
  if self.OnGuidanceReleased then
    self.OnGuidanceReleased:Invoke(self)
  end
end

function UMG_PetBagFormation1_C:OnEndGuideTarget(config, bOnDestroy)
  if not config then
    return
  end
  if config:IsCompleteWithButtonReleased() and bOnDestroy then
    Log.Debug("UMG_PetBagFormation1_C:OnEndGuideTarget", config:GetDebugInfo())
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
  end
end

function UMG_PetBagFormation1_C:OnBeginDragStart()
  Log.Debug("UMG_PetBagFormation1_C:OnBeginDragStart", self.pos)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, false, self._data, self.pos)
end

function UMG_PetBagFormation1_C:StopTargetAnimations()
  self:StopAnimation(self.change1)
  self:StopAnimation(self.change2)
  self:StopAnimation(self.mask)
  self:StopAnimation(self.Chuxian)
  self:StopAnimation(self.Move_In)
  self:StopAnimation(self.Move_Loop)
  self:StopAnimation(self.Move_Out)
  self:StopAnimation(self.Move_Selected_In)
  self:StopAnimation(self.Move_Selected_Out)
  self:StopAnimation(self.Move_Selected_Put_In)
  self:StopAnimation(self.Move_Selected_Put_Out)
end

return UMG_PetBagFormation1_C

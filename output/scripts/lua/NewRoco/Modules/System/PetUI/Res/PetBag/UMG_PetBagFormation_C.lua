local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local Delegate = require("Utils.Delegate")
local UMG_PetBagFormation_C = Base:Extend("UMG_PetBagFormation_C")
local EnumItemMode = {
  None = 0,
  NormalMode = 1,
  SelectMode = 2,
  Change = 3,
  Reset = 4,
  NoSelectMode = 5
}
local BASE_INDEX = 6

function UMG_PetBagFormation_C:OnConstruct()
  self.hasPet = false
  self._bSkipUnSelectAnim = false
  self.IsMDT_GLASS = false
  self.preparedForChange = false
  self.ItemMode = EnumItemMode.None
  self.Change:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Module = NRCModuleManager:GetModule("PetUIModule")
  if self.Module then
    self.Module:RegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  end
  NRCEventCenter:RegisterEvent("UMG_PetBagFormation_C", self, PetUIModuleEvent.PetBagUIItemUpdateUI, self.UpdatePetLevel)
  NRCEventCenter:RegisterEvent("UMG_PetBagFormation_C", self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
  self.OnGuidanceLongPress = Delegate()
  self.OnGuidanceReleased = Delegate()
end

function UMG_PetBagFormation_C:OnDestruct()
  if self.Module then
    self.Module:UnRegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  end
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetBagUIItemUpdateUI, self.UpdatePetLevel)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
end

function UMG_PetBagFormation_C:OnDeactive()
end

function UMG_PetBagFormation_C:OnActive()
end

function UMG_PetBagFormation_C:OnAddEventListener()
end

function UMG_PetBagFormation_C:AsDragItemInitInfo(_data)
  self.Move:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:OnItemUpdate(_data, nil, 1)
  self.bDragItem = true
  self.NrcRedPoint:SetupKey(0)
end

function UMG_PetBagFormation_C:ResetMarkIcon()
  self.CheckIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NrcRedPoint:SetupKey(0)
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation_C:OnItemUpdate(_data, datalist, index)
  self._data = _data
  self.index = index
  self.ListIndex = index
  self.parent = _data.parent
  self.RealIndex = index
  self.bLock = false
  self.bCanNotPlaySelectedAnim = false
  self:ResetMarkIcon()
  if _data.petInfo.base_conf_id == nil then
    self.NilParent = _data.parent
    self.icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NumText:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetRightCornerMark(true)
    self.NrcRedPoint:SetupKey(0)
    self.hasPet = false
    self.IsNilPet = true
    self.uiData = nil
  else
    self.IsNilPet = false
    self.uiData = _data.petInfo
    self:SetData(self.uiData)
    if nil == self.uiData.gid then
      self.NrcRedPoint:ShowRedPoint(false)
    end
  end
  self:InitSelectItem()
end

function UMG_PetBagFormation_C:InitSelectItem()
  local CurSelectItemType = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurSelectItemTypeInPortableBag)
  if nil ~= CurSelectItemType and CurSelectItemType == PetUIModuleEnum.PortableBagSelectItemType.TeamItem then
    local CurShowTeamIndex = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurShowTeamIndexInPortableBag)
    local CurSelectTeamIndex, CurSelectItemIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCurSelectInfoInPortableBag)
    if CurSelectItemIndex and CurSelectTeamIndex then
      local realSelectItemIndex = (CurSelectTeamIndex - 1) * BASE_INDEX + CurSelectItemIndex
      if nil ~= CurShowTeamIndex and nil ~= CurSelectTeamIndex and nil ~= realSelectItemIndex and nil ~= self.ListIndex and CurShowTeamIndex == CurSelectTeamIndex and realSelectItemIndex == self.ListIndex and nil ~= self.parent and UE4.UObject.IsValid(self.parent) then
        self.parent:SelectTeamItemByIndex(self.ListIndex)
      end
    end
  end
end

function UMG_PetBagFormation_C:OnSpawn()
  if self.parent and self.parent.petAddToTeam then
    self.preparedForChange = true
    self.canChange = true
    self.clickable = true
    if self.hasPet then
      if self.parent.petAddToTeam.petInfo.gid == self.uiData.gid then
        self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Put:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif self.NilParent and self.NilParent.petAddToTeam then
    self.preparedForChange = true
    self.canChange = true
    self.clickable = true
    if self.hasPet then
      self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Put:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PetBagFormation_C:OnDespawn()
  self:StopAllAnimations()
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetBagFormation_C:UpdateCollect()
  if self.uiData and self.uiData.petData and self.uiData.petData.partner_mark and self.uiData.petData.partner_mark ~= ProtoEnum.PetPartnerMarkType.PPMT_NONE then
    self.Star:SetPath(PetUtils.GetPetCollectTagIcon(self.uiData.petData.partner_mark))
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBagFormation_C:SetData(_petInfo, datalistInfo)
  if not self.uiData or self.IsNilPet then
    return
  end
  self:ResetItemUI()
  self:SetSelectable()
  self:UpdateCollect()
  self:UpdateUIInReleaseLifeMode()
  self.TagIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NumText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Empty:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.clickable = true
  self.hasPet = true
  if self.uiData.indexBase then
    self.index = self.index + self.uiData.indexBase
  end
  if nil == self.uiData.petData then
    return
  end
  self:ShowPetIcon(self.uiData.base_conf_id, self.uiData.gid)
  self:SetRightCornerMark()
end

function UMG_PetBagFormation_C:ResetItemUI()
  self.CheckIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CheckIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetLockVisibility()
end

function UMG_PetBagFormation_C:ShowPetIcon(petBaseId, gid)
  local quality, moduleConfId
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SetSelectable()
  self.NumText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetRedMaskVisibility()
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
  self.NrcRedPoint:SetupKey(181, {gid})
end

function UMG_PetBagFormation_C:SetItemQuality(quality)
end

function UMG_PetBagFormation_C:OnItemSelected(isSelected, IsScrollSelect)
  if self.bLock then
    return
  end
  if self.preparedForChange and not IsScrollSelect then
    if self.canChange then
      if isSelected then
        self.IsPrepareChange = true
        _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetBagFormation_C:OnItemSelected")
        self:PrepareChangePet()
      end
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.legendary_bag)
    end
    return
  end
  if self.uiData and self.uiData.IsTravel then
    return
  end
  if isSelected then
    self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:StopAllAnimations()
    self:PlayAnimation(self.Move_Selected_In)
    if IsScrollSelect then
      if self.IsToChange then
        self:SwitchToChange()
      end
      return
    end
    if self.sayNothing then
      self.sayNothing = false
    else
      self:HandlePetItemSelected()
    end
  elseif IsScrollSelect then
    self:StopAllAnimations()
  elseif self._bSkipUnSelectAnim then
    self:StopAllAnimations()
    if self.parent then
      self.parent:SetSkipItemUnSelectAnim(false)
    end
  else
    if self.uiData and self.parent and self.parent:IsSelectedPet(self.uiData.gid) then
      self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
    end
    if self.Selected then
      self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:StopAllAnimations()
    self:PlayAnimation(self.Move_Selected_Out)
  end
end

function UMG_PetBagFormation_C:HandlePetItemSelected()
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
  local CurShowTeamIndex = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurShowTeamIndexInPortableBag)
  local petIndex = self.RealIndex - (CurShowTeamIndex - 1) * BASE_INDEX
  if self.uiData and self.uiData.petData then
    local isMainTeamIndex, TeamIdx = _G.DataModelMgr.PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(self.uiData.gid)
    if isMainTeamIndex then
      _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, petIndex, self.uiData.petData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, self.uiData.petData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, self.uiData.gid)
    end
    self.IsPrepareChange = false
    if nil ~= self.parent and petIndex then
      self.parent:OnPetItemClick(petIndex, true, self.uiData.petData, self)
    end
    self:OnItemClickInReleaseLifeMode()
  else
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, petIndex, nil)
    if nil ~= self.parent and nil ~= petIndex then
      self.parent:OnPetItemClick(petIndex, true, nil, self)
    end
  end
end

function UMG_PetBagFormation_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if self.clickable then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetBagFormation_C:OnTouchEnded")
  end
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetBagFormation_C:SetSelectItemData()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectItemTypeInPortableBag, PetUIModuleEnum.PortableBagSelectItemType.TeamItem)
  local PetGID
  if self.uiData and self.uiData.petData then
    PetGID = self.uiData.petData.gid
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectPetGIDInPortableBag, PetGID)
  local CurShowTeamIndex = _G.NRCModeManager:DoCmd(PetUIModuleCmd.GetCurShowTeamIndexInPortableBag)
  local petIndex = self.ListIndex - (CurShowTeamIndex - 1) * BASE_INDEX
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetCurSelectInfoInPortableBag, CurShowTeamIndex, petIndex)
end

function UMG_PetBagFormation_C:BroadcastOnClicked()
  self:IsRawGrayInFreeMode(true)
end

function UMG_PetBagFormation_C:OnItemClickInReleaseLifeMode(bIgnorePvpOrPveTeam)
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

function UMG_PetBagFormation_C:UpdateUIInReleaseLifeMode()
  self:SetLockVisibility()
  self:SetItemClickable()
  self.CheckIcon:SetVisibility(self:GetSelfIsInFreeList() and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self:SetRightCornerMark()
end

function UMG_PetBagFormation_C:GetSelfIsInFreeList()
  local bInFreeList = false
  if self.parent and self.uiData and self.uiData.petData then
    bInFreeList = self.parent:CheckIsInFreeList(self.uiData.petData)
  end
  return bInFreeList
end

function UMG_PetBagFormation_C:SetLockVisibility()
  local IsShow = false
  if self:IsRawGrayInFreeMode() or self:GetSelfIsInFreeList() then
    IsShow = true
  end
  if self.ItemMode == EnumItemMode.NoSelectMode then
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

function UMG_PetBagFormation_C:SetRedMaskVisibility()
  if self.uiData == nil then
    self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local IsShow = false
  local IsRed = self.NrcRedPoint:IsRed()
  if self.ItemMode == EnumItemMode.NoSelectMode and IsRed then
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

function UMG_PetBagFormation_C:SetItemClickable(TargetClickable)
  if nil ~= TargetClickable then
    self:SetClickable(TargetClickable)
    return
  end
  local Clickable = true
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) and self:IsRawGrayInFreeMode(false) then
    Clickable = false
    if PetUtils.CheckIsTheLastBigWorldTeamPet(self.uiData.petData.gid) then
      Clickable = true
    else
    end
  end
  self:SetClickable(Clickable)
end

function UMG_PetBagFormation_C:IsRawGrayInFreeMode(bShowTips)
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

function UMG_PetBagFormation_C:SwitchToSelectMode()
  self.ItemMode = EnumItemMode.SelectMode
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.preparedForChange = true
  self.canChange = true
  if self.IsNilPet then
    self.clickable = true
  end
end

function UMG_PetBagFormation_C:SetDragMouseWheelMode()
  if self.bLock then
    return
  end
  self:LongDragSwitchToChange()
end

function UMG_PetBagFormation_C:SwitchToNoSelectMode()
  self.ItemMode = EnumItemMode.NoSelectMode
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
  self.preparedForChange = false
  self.canChange = false
  if self.IsNilPet then
    self.clickable = false
  end
end

function UMG_PetBagFormation_C:SwitchToChange()
  if self.uiData == nil then
    return
  end
  if self.uiData and not self.uiData.gid then
    return
  end
  self.ItemMode = EnumItemMode.Change
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.OnGuidanceLongPress then
    self.OnGuidanceLongPress:Invoke(self)
  end
end

function UMG_PetBagFormation_C:SwitchToReset()
  self.ItemMode = EnumItemMode.Reset
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_PetBagFormation_C:LongDragSwitchToChange()
  self.IsLongDragSelect = true
  if self.NrcRedPoint:IsRed() then
    self.RedMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.uiData and self.parent and self.parent:IsDragPet(self.uiData.gid) then
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return
  end
  if self.bCanNotPlaySelectedAnim then
    return
  end
  if not self.IsNilPet then
    self.Exchange:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:StopAllAnimations()
  self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_Drag_png.img_Drag_png'")
  self:PlayAnimation(self.Move_Selected_In)
  self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_PetBagFormation_C:SwitchToAshSelectMode()
end

function UMG_PetBagFormation_C:OpItem(opType)
  if 1 == opType.type then
    if self and self.uiData then
      self.clickable = true
      if opType.isLegendaryFull then
        if self.uiData.gid ~= opType.currentItemData.petInfo.gid then
          local onePetBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.uiData.base_conf_id)
          if onePetBaseCfg and 1 == onePetBaseCfg.is_pet_legendary then
            self:SwitchToSelectMode()
          else
            self:SwitchToNoSelectMode()
            self.clickable = false
          end
        else
          self:SwitchToChange()
          self.IsToChange = true
          self.clickable = false
        end
      elseif self.uiData.gid ~= opType.currentItemData.petInfo.gid then
        self:SwitchToSelectMode()
      else
        self:SwitchToChange()
        self.IsToChange = true
        self.clickable = false
      end
    elseif self and self.IsNilPet then
      self:SwitchToSelectMode()
    else
      self.clickable = false
    end
  end
end

function UMG_PetBagFormation_C:SwitchToNormalMode()
  if self.isDestruct then
    return
  end
  self.ItemMode = EnumItemMode.NormalMode
  if self.IsLongDragSelect then
    self:LongDragSwitchToNormalMode()
  end
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
  self.preparedForChange = false
  self.canChange = false
end

function UMG_PetBagFormation_C:LongDragSwitchToNormalMode()
  if self.isDestruct or not self.IsLongDragSelect then
    return
  end
  self.Selected:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetBag/Frames/img_xuanzhong1_png.img_xuanzhong1_png'")
  self.IsLongDragSelect = false
  if self.parent and self.uiData and self.uiData.gid and not self.parent:IsDragPet(self.uiData.gid) and not self.bCanNotPlaySelectedAnim then
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.preparedForChange = false
  self.canChange = false
  if self.bCanNotPlaySelectedAnim then
    return
  end
  if self.uiData == nil or self.uiData and self.parent and not self.parent:IsSelectedPet(self.uiData.gid) and not self.parent:IsDragPet(self.uiData.gid) then
    self.Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:StopAllAnimations()
    self:PlayAnimation(self.Move_Selected_Out)
    self.RedMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBagFormation_C:PrepareChangePet()
  if self.parent and self.parent.bIsPendingResPetUpdatePkg then
    Log.Warning("\230\173\163\229\156\168\231\173\137\229\190\133\229\155\158\229\140\133")
    return
  end
  if self.IsNilPet then
    local NilData = {gid = "IsNil"}
    self.IsNilPet = false
    self.NilParent:SetPetRemoveFromTeam(NilData, true)
  elseif self.parent then
    self.parent:SetPetRemoveFromTeam(self.uiData, true)
  end
end

function UMG_PetBagFormation_C:SetNotSelectable()
  self:SetRenderOpacity(0.8)
  self.clickable = false
end

function UMG_PetBagFormation_C:SetSelectable()
  self:SetRenderOpacity(1)
  self.clickable = true
end

function UMG_PetBagFormation_C:OnAnimationFinished(Animation)
end

function UMG_PetBagFormation_C:UpdatePetData(petData)
  if petData.gid ~= self.uiData.gid then
    return
  end
  self.uiData.petData = petData
  self.NumText:SetText(self.uiData.petData.level)
  self.uiData.level = self.uiData.petData.level
  self:ShowPetIcon(self.uiData.base_conf_id, self.uiData.gid)
  self:UpdateCollect()
end

function UMG_PetBagFormation_C:SetIsCanClickHead(IsCanClick)
  if IsCanClick then
    self:SetClickable(true)
  else
    self:SetClickable(false)
  end
end

function UMG_PetBagFormation_C:SetRightCornerMark(bInit)
  if bInit then
    self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.uiData == nil then
    return
  end
  if nil == self.uiData.petData then
    return
  end
  self.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") and _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, self.uiData.petData.gid, 4) then
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

function UMG_PetBagFormation_C:CheckIsCanShowRedPoint()
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

function UMG_PetBagFormation_C:OnNewPetBagReleaseLifeModeChanged(isReleaseLifeMode)
  self:UpdateUIInReleaseLifeMode()
end

function UMG_PetBagFormation_C:OnPetTraceBackSuccessAndRewardPopupClose(changes, gid)
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

function UMG_PetBagFormation_C:UpdatePetLevel(petGID)
  if petGID == self.uiData.gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGID)
    self.NumText:SetText(petData.level)
  end
end

function UMG_PetBagFormation_C:EnterDisableDragState(bEnter)
  if bEnter then
    self.bLock = true
  else
    self.bLock = false
  end
  self:SetRedMaskVisibility()
  self:SetLockVisibility()
end

function UMG_PetBagFormation_C:OnMouseButtonReleased()
  if self.OnGuidanceReleased then
    self.OnGuidanceReleased:Invoke(self)
  end
end

function UMG_PetBagFormation_C:ShowExchangeIcon(bShow, bDragTeamPet, bDragSpecialPet)
  if self.uiData and self.parent and self.parent:IsDragPet(self.uiData.gid) then
    return
  end
  self.Exchange:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bCanNotPlaySelectedAnim = false
  self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not bDragTeamPet and bDragSpecialPet and bShow and self.uiData then
    self.bCanNotPlaySelectedAnim = true
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.hasPet then
    self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif bShow then
    self.Put:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Put:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBagFormation_C:OnEndGuideTarget(config, bOnDestroy)
  if not config then
    return
  end
  if config:IsCompleteWithButtonReleased() and bOnDestroy then
    Log.Debug("UMG_PetBagFormation_C:OnEndGuideTarget", config:GetDebugInfo())
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
  end
end

function UMG_PetBagFormation_C:OnBeginDragStart()
  Log.Debug("UMG_PetBagFormation_C:OnBeginDragStart", self.index)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, false, self._data, self.index - 1)
end

function UMG_PetBagFormation_C:GetGuidanceCustomListIndex()
  local customIndex = self.index
  customIndex = customIndex % BASE_INDEX
  return customIndex
end

return UMG_PetBagFormation_C

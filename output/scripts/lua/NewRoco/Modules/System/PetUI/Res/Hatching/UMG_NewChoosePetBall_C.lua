local UMG_NewChoosePetBall_C = _G.NRCPanelBase:Extend("UMG_NewChoosePetBall_C")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local AT_LEAST_USE_NUM = 1
local EnumAddSubtractBtnPressType = {
  NONE = 0,
  ADD = 1,
  DEL = 2
}
local LONG_PRESS_ADD_SUBTRACT_THRESHOLD = 0.3
local IN_LONG_PRESS_THRESHOLD = 0.6

function UMG_NewChoosePetBall_C:OnConstruct()
  self:StopAllAnimations()
  self:PlayAnimation(self.In)
end

function UMG_NewChoosePetBall_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.HatchEggBtn.btnLevelUp, self.OnClickHatchEggBtn)
  self:AddButtonListener(self.EstablishContractBtn.btnLevelUp, self.OnClickEstablishContractBtn)
  self:AddButtonListener(self.HatchingBtn.btnLevelUp, self.OnClickHatchingBtn)
  self:AddButtonListener(self.IncubationProgressBtn.btnLevelUp, self.OnClickIncubationProgressBtn)
  self.ItemScrollView:SetItemSelectedCallback(self.OnItemSelected, self)
  self.ItemScrollView.OnUserScrolled:Add(self, self.OnItemScrollViewScrolled)
  self.ItemScrollView_1:SetItemSelectedCallback(self.OnItemSelected, self)
end

function UMG_NewChoosePetBall_C:OnActive(DisplayMode, DataList, EggId)
  if not _G.NRCModuleManager:GetModule("PetUIModule"):HasPanel("PetHatchingPanel") then
    self:ClosePanel()
  end
  self.IsClosing = false
  _G.NRCAudioManager:PlaySound2DAuto(40002001, "UMG_PetHatching_C:ClickEggBtn")
  self:OnAddEventListener()
  self.DisplayMode = DisplayMode
  self.DataList = DataList
  self.ParentViewHatchingEggId = EggId
  self.CurSelectBallGid = nil
  self.CurSelectBallItemId = nil
  self.SelectedQuantity = 0
  self.startAddFrame = 0
  self.EndAddFrame = 8
  self.startDelFrame = 0
  self.EndDelFrame = 8
  self.IsAdd = false
  self.IsDelItem = false
  self.IsAddClick = false
  self.IsDelClick = false
  self:UpdateView()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, true, self.DisplayMode, false)
end

function UMG_NewChoosePetBall_C:UpdateView()
  local BagModuleData = _G.NRCModuleManager:GetModule("BagModule"):GetData("BagModuleData")
  if nil == BagModuleData then
    Log.Debug("UMG_NewChoosePetBall_C:UpdateView: BagModuleData is nil")
    return
  end
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
    self.DataList = self:GetSelectEggItemList()
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.BtnSwitcher:SetActiveWidgetIndex(1)
    self.HatchEggBtn:SetBtnText(LuaText.umg_pethatching3)
    self.GrayHatchEggBtn:SetBtnText(LuaText.umg_pethatching3)
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
    self.GrayEstablishContractBtn:SetBtnText(LuaText.umg_pethatching6)
    self.EstablishContractBtn:SetBtnText(LuaText.umg_pethatching6)
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self.BtnSwitcher:SetActiveWidgetIndex(2)
    self.GrayEstablishContractBtn:SetBtnText(LuaText.umg_pethatching6)
    self.EstablishContractBtn:SetBtnText(LuaText.umg_pethatching6)
    self.GrayEstablishContractBtn:SetTitleTextAndIcon(nil, nil, nil, nil, nil, LuaText.choose_ball_tips_1, nil)
    self.GrayEstablishContractBtn:SetShowLockIcon(false)
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectColor then
    self.NRCSwitcher_0:SetActiveWidgetIndex(2)
    self.BtnSwitcher:SetActiveWidgetIndex(7)
    self.HatchingBtnGray:SetBtnText(LuaText.umg_bag_14)
    self.HatchingBtn:SetBtnText(LuaText.umg_bag_14)
    self.HatchingBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.umg_pethatching10, nil, nil)
    self.HatchingBtnGray:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.umg_pethatching10, nil, nil)
    self.HatchingBtnGray:SetShowLockIcon(false)
    self:UpdateSelectColorPanel()
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    self.IncubationProgressBtn:SetBtnText(LuaText.HatchProgressAdd_2)
    self.GrayIncubationProgressBtn:SetBtnText(LuaText.HatchProgressAdd_2)
    self.GrayIncubationProgressBtn:SetTitleTextAndIcon(nil, nil, nil, nil, LuaText.HatchProgressAdd_1, nil, nil)
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.BtnSwitcher:SetActiveWidgetIndex(4)
    self.GrayIncubationProgressBtn:SetShowLockIcon(false)
  end
  self.ItemScrollView:ClearSelection()
  self.DataList = self.DataList or {}
  for i, v in pairs(self.DataList) do
    if v then
      v.parentView = self
      v.DisplayMode = self.DisplayMode
      v.bEnableLongClick = true
    end
  end
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule.data then
    PetUIModule.data:SetCurSelectItemDataInHatchingRightPanel(nil)
  end
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    self.ItemScrollView_1:InitList(self.DataList)
  else
    self.ItemScrollView:InitList(self.DataList)
  end
end

function UMG_NewChoosePetBall_C:SwitchSelectColorPanel()
  self.DisplayMode = PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectColor
  self:UpdateView()
end

function UMG_NewChoosePetBall_C:GetSelectEggItemList()
  local RetList = {}
  local BagModuleData = _G.NRCModuleManager:GetModule("BagModule"):GetData("BagModuleData")
  if nil == BagModuleData then
    return RetList
  end
  local PetEggList = BagModuleData:SortItemListByLableType(_G.Enum.ItemLableType.ILT_PET_EGG, _G.Enum.Sequence.SEQUENCE_QUALITY_DOWN)
  local FullGlassEggPieceList = {}
  local NotFullGlassEggPieceList = {}
  local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  local PreciousItemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByLableType, _G.Enum.ItemLableType.ILT_PRECIOUS)
  for _, item in pairs(PreciousItemList) do
    if item and item.conf and item.conf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE and item.num and item.num > 0 then
      if RequireGlassEggPieceNum <= item.num then
        table.insert(FullGlassEggPieceList, item)
      else
        table.insert(NotFullGlassEggPieceList, item)
      end
    end
  end
  table.sort(FullGlassEggPieceList, function(a, b)
    if a.num == b.num then
      return a.conf.sort_id < b.conf.sort_id
    else
      return a.num > b.num
    end
  end)
  table.sort(NotFullGlassEggPieceList, function(a, b)
    if a.num == b.num then
      return a.conf.sort_id < b.conf.sort_id
    else
      return a.num > b.num
    end
  end)
  table.move(FullGlassEggPieceList, 1, #FullGlassEggPieceList, #RetList + 1, RetList)
  table.move(PetEggList, 1, #PetEggList, #RetList + 1, RetList)
  table.move(NotFullGlassEggPieceList, 1, #NotFullGlassEggPieceList, #RetList + 1, RetList)
  return RetList
end

function UMG_NewChoosePetBall_C:OnGlassParticlesItemSelected()
  self:UpdateSelectColorPanel()
  self:UpdateHatchBtn()
end

function UMG_NewChoosePetBall_C:OnGlassColorItemSelected()
  self:UpdateHatchBtn()
end

function UMG_NewChoosePetBall_C:GetCurSelectParticleIconConf()
  if self.GlassParticlesConfList then
    return self.GlassParticlesConfList[self.CurSelectParticleIconItemIndex]
  end
end

function UMG_NewChoosePetBall_C:GetCurSelectColorConf()
  if self.GlassColorConfList then
    return self.GlassColorConfList[self.CurSelectColorItemIndex]
  end
end

function UMG_NewChoosePetBall_C:UpdateHatchBtn()
  if self:GetCurSelectParticleIconConf() and self:GetCurSelectColorConf() then
    self.BtnSwitcher:SetActiveWidgetIndex(6)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(7)
  end
end

function UMG_NewChoosePetBall_C:UpdateSelectColorPanel()
  Log.Debug("UMG_NewChoosePetBall_C:UpdateSelectColorPanel")
  if self.GlassParticlesConfList == nil then
    self.GlassParticlesConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PARTICLE_RANDOM_CONF):GetAllDatas()
    table.sort(self.GlassParticlesConfList, function(a, b)
      return a.sort_id < b.sort_id
    end)
  end
  if self.GlassParticlesConfList then
    local GlassParticlesDataList = {}
    for i = 1, #self.GlassParticlesConfList do
      local DataItem = {
        conf = self.GlassParticlesConfList[i],
        parentView = self
      }
      table.insert(GlassParticlesDataList, DataItem)
    end
    self.HorizontalTab1:InitGridView(GlassParticlesDataList)
    if nil == self.CurSelectParticleIconItemIndex then
      self.HorizontalTab1:SelectItemByIndex(0)
    end
  end
  if nil == self.GlassColorConfList then
    self.GlassColorConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.COLOR_RANDOM_CONF):GetAllDatas()
  end
  if self.GlassColorConfList then
    local GlassColorDataList = {}
    for _, v in pairs(self.GlassColorConfList) do
      local DataItem = {conf = v, parentView = self}
      table.insert(GlassColorDataList, DataItem)
    end
    self.ItemScrollView_2:InitList(GlassColorDataList)
    if self.CurSelectColorItemIndex then
      self.ItemScrollView_2:SelectItemByIndex(self.CurSelectColorItemIndex - 1)
    end
  end
end

function UMG_NewChoosePetBall_C:AutoSelectFirstItem()
  self.ItemScrollView:SelectItemByIndex(0)
end

function UMG_NewChoosePetBall_C:OnItemSelected(item, rawIndex, userClick)
  if nil == item then
    Log.Error("UMG_NewChoosePetBall_C:OnItemSelected: item is nil")
    return
  end
  if nil == item.ItemData then
    Log.Error("UMG_NewChoosePetBall_C:OnItemSelected: item.ItemData is nil")
    return
  end
  if 0 == item.ItemData.num then
    Log.Error("UMG_NewChoosePetBall_C:OnItemSelected: item.ItemData.num is 0")
    return
  end
  if self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
    self.BtnSwitcher:SetActiveWidgetIndex(0)
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(item.ItemData.id)
    if BagItemConf then
      self.HatchEggBtn:SetBtnText(BagItemConf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE and LuaText.umg_pethatching12 or LuaText.umg_pethatching3)
      self.GrayHatchEggBtn:SetBtnText(BagItemConf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE and LuaText.umg_pethatching12 or LuaText.umg_pethatching3)
    end
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
    if item.ItemData.gid then
      self.CurSelectBallGid = item.ItemData.gid
    end
    if item.ItemData.itemId then
      self.CurSelectBallItemId = item.ItemData.itemId
    end
    self.BtnSwitcher:SetActiveWidgetIndex(3)
    local PetBallSelectTips = self:GetPetBallSelectTips()
    self.EstablishContractBtn:SetTitleTextAndIcon(nil, nil, nil, nil, nil, PetBallSelectTips, nil)
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectColor then
  elseif self.DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
    self.BtnSwitcher:SetActiveWidgetIndex(5)
    if 0 == self.SelectedQuantity then
      self.SelectedQuantity = 1
    end
    local MaxNum = self:GetCanCostItemMaxNum()
    if MaxNum < self.SelectedQuantity then
      self.SelectedQuantity = MaxNum
    end
    self:SetCommonAddSubtractPanel()
  end
end

function UMG_NewChoosePetBall_C:OnItemScrollViewScrolled()
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnHatchingRightPanelScrollViewScrolled)
end

function UMG_NewChoosePetBall_C:SetCurMouseTouchItemIndex(index)
  self.CurMouseTouchItemIndex = index
end

function UMG_NewChoosePetBall_C:GetCurMouseTouchItemIndex()
  return self.CurMouseTouchItemIndex
end

function UMG_NewChoosePetBall_C:OnItemBeLongClicked()
  self.ItemScrollView:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.DelayManager:DelayFrames(10, function()
    self.ItemScrollView:SetVisibility(UE4.ESlateVisibility.Visible)
  end)
end

function UMG_NewChoosePetBall_C:GetPetBallSelectTips()
  local Desc = ""
  if self.CurSelectBallItemId == nil then
    return Desc
  end
  local petBallConf = _G.DataConfigManager:GetBallConf(self.CurSelectBallItemId)
  local ballType = petBallConf.ball_effect_type
  local ballName = string.format("<Orange>%s</>", petBallConf.editor_name)
  local DescBase = ""
  if ballType == _G.Enum.BallEffectType.BET_NORMAL then
    DescBase = LuaText.choose_ball_tips_2
  elseif ballType == _G.Enum.BallEffectType.BET_CHANGE_PET_ATTRIBUTE then
    DescBase = LuaText.choose_ball_tips_6
  elseif ballType == _G.Enum.BallEffectType.BET_CHANGE_PET_MUTATION then
    DescBase = LuaText.choose_ball_tips_3
  end
  Desc = string.format(DescBase, ballName)
  return Desc
end

function UMG_NewChoosePetBall_C:SetViewClickable(bClickable)
  if self.ItemScrollView then
    self.ItemScrollView:SetClickable(bClickable)
  end
end

function UMG_NewChoosePetBall_C:GetDisplayMode()
  return self.DisplayMode
end

function UMG_NewChoosePetBall_C:OnClickHatchEggBtn()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
  isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_START, true)
  if isBan then
    Log.Debug("UMG_NewChoosePetBall_C:OnClickHatchEggBtn: isBan1")
    return
  end
  if self.IsClosing then
    Log.Debug("UMG_NewChoosePetBall_C:OnClickHatchEggBtn IsClosing=[true] return")
    return
  end
  local CurSelectedItemData
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule.data then
    CurSelectedItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel()
  end
  if nil == CurSelectedItemData then
    Log.Error("UMG_NewChoosePetBall_C:OnClickHatchEggBtn: CurSelectedItemData is nil")
    return
  end
  if not self.ClickHatchEggBtnTime then
    self.ClickHatchEggBtnTime = os.time()
  elseif os.time() - self.ClickHatchEggBtnTime <= 1 then
    return
  else
    self.ClickHatchEggBtnTime = os.time()
  end
  if CurSelectedItemData.conf and CurSelectedItemData.conf.type then
    if CurSelectedItemData.conf.type == _G.Enum.BagItemType.BI_PET_EGG then
      _G.NRCModuleManager:DoCmd(BagModuleCmd.SetCurSelectEggItemData, CurSelectedItemData)
      _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItemData.gid, CurSelectedItemData.id, 1)
    elseif CurSelectedItemData.conf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
      local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
      Log.Debug("UMG_NewChoosePetBall_C:OnClickHatchEggBtn gid=[", CurSelectedItemData.gid, "], id=[", CurSelectedItemData.id, "], num=[", RequireGlassEggPieceNum, "]")
      _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItemData.gid, CurSelectedItemData.id, RequireGlassEggPieceNum)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(1220002037, "UMG_NewChoosePetBall_C:OnClickHatchEggBtn")
end

function UMG_NewChoosePetBall_C:OnClickHatchingBtn()
  self:TryToHatchCustomizableGlassEgg()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_NewChoosePetBall_C:OnClickHatchingBtn")
end

function UMG_NewChoosePetBall_C:OnClickEstablishContractBtn()
  if self.ParentViewHatchingEggId == nil then
    Log.Error("UMG_NewChoosePetBall_C:OnClickEstablishContractBtn: ParentViewHatchingEggId is nil")
    return
  end
  if nil == self.CurSelectBallItemId then
    Log.Error("UMG_NewChoosePetBall_C:OnClickEstablishContractBtn: CurSelectBallItemId is nil")
    return
  end
  if nil == self.CurSelectBallGid then
    Log.Error("UMG_NewChoosePetBall_C:OnClickEstablishContractBtn: CurSelectBallGid is nil")
    return
  end
  local PetEggConfigType = PetUtils.GetPetEggConfigTypeByGID(self.ParentViewHatchingEggId)
  if PetEggConfigType and PetEggConfigType == PetUIModuleEnum.PetEggConfigType.BlessingEgg then
    local petBallConf = _G.DataConfigManager:GetBallConf(self.CurSelectBallItemId)
    local ballType = petBallConf.ball_effect_type
    if ballType == _G.Enum.BallEffectType.BET_CHANGE_PET_ATTRIBUTE or ballType == _G.Enum.BallEffectType.BET_CHANGE_PET_MUTATION then
      local BagEggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self.ParentViewHatchingEggId)
      if BagEggItem and BagEggItem.egg_data then
        local EggData = BagEggItem.egg_data
        if nil ~= EggData.talent_rank and EggData.talent_rank < _G.Enum.PetTalentRate.PTR_PERFECT then
          local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
          local title = LuaText.umg_pethatching13
          local des = string.format(LuaText.umg_pethatching14, petBallConf.editor_name)
          local leftText = LuaText.umg_pet_attribute_3
          local rightText = LuaText.umg_pet_attribute_4
          local Context = DialogContext()
          Context:SetTitle(title):SetContent(des):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.RequsetEstablishContract):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
          return
        end
      end
    end
  end
  self:RequsetEstablishContract(true)
end

function UMG_NewChoosePetBall_C:RequsetEstablishContract(IsSure)
  Log.Debug("UMG_NewChoosePetBall_C:RequsetEstablishContract")
  if not IsSure then
    return
  end
  if self.IsClosing then
    Log.Debug("UMG_NewChoosePetBall_C:RequsetEstablishContract IsClosing=[true] return")
    return
  end
  if self.ParentViewHatchingEggId == nil then
    Log.Error("UMG_NewChoosePetBall_C:RequsetEstablishContract: ParentViewHatchingEggId is nil")
    return
  end
  local CurEggGid = self.ParentViewHatchingEggId
  local CurSelectBallId = self.CurSelectBallGid
  local PetBallItemId = self.CurSelectBallItemId
  if nil == CurEggGid then
    return
  end
  if nil == CurSelectBallId then
    return
  end
  if nil == PetBallItemId then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
  isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_GET_BACK, true)
  if isBan then
    return
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ZoneCrackEggReq, CurEggGid, CurSelectBallId, PetBallItemId)
end

function UMG_NewChoosePetBall_C:TryToHatchCustomizableGlassEgg()
  Log.Debug("UMG_NewChoosePetBall_C:TryToHatchCustomizableGlassEgg")
  if self.IsClosing then
    Log.Debug("UMG_NewChoosePetBall_C:TryToHatchCustomizableGlassEgg IsClosing=[true] return")
    return
  end
  if self.ParentViewHatchingEggId == nil then
    Log.Error("UMG_NewChoosePetBall_C:TryToHatchCustomizableGlassEgg: ParentViewHatchingEggId is nil")
    return
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenColorfulMatchingTips, self.ParentViewHatchingEggId, self:GetCurSelectParticleIconConf(), self:GetCurSelectColorConf())
end

function UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn()
  Log.Debug("UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn")
  if self.IsClosing then
    Log.Debug("UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn IsClosing=[true] return")
    return
  end
  if self.ParentViewHatchingEggId == nil then
    Log.Error("UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn: ParentViewHatchingEggId is nil")
    return
  end
  if nil == self.SelectedQuantity then
    Log.Error("UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn: SelectedQuantity is nil")
    return
  end
  local CurSelectedItemData
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule.data then
    CurSelectedItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel()
  end
  if nil == CurSelectedItemData then
    Log.Error("UMG_NewChoosePetBall_C:OnClickIncubationProgressBtn: CurSelectedItemData is nil")
    return
  end
  _G.NRCModuleManager:DoCmd(BagModuleCmd.UseBagItem, CurSelectedItemData.gid, CurSelectedItemData.id, self.SelectedQuantity, self.ParentViewHatchingEggId)
end

function UMG_NewChoosePetBall_C:SetCurSelectParticleIconItemIndex(index)
  self.CurSelectParticleIconItemIndex = index
end

function UMG_NewChoosePetBall_C:GetCurSelectParticleIconItemIndex()
  return self.CurSelectParticleIconItemIndex
end

function UMG_NewChoosePetBall_C:SetCurSelectColorItemIndex(index)
  self.CurSelectColorItemIndex = index
end

function UMG_NewChoosePetBall_C:GetCurSelectColorItemIndex()
  return self.CurSelectColorItemIndex
end

function UMG_NewChoosePetBall_C:SetCommonAddSubtractPanel()
  self.AddSubtractBtnPressType = EnumAddSubtractBtnPressType.NONE
  self.AddSubtractBtnPressTimer = IN_LONG_PRESS_THRESHOLD
  self:SetCommonAddSubtractInfo()
  self:UpdateCommonAddSubtractPanel()
end

function UMG_NewChoosePetBall_C:SetCommonAddSubtractInfo()
  local SliderInfo = {
    num1 = AT_LEAST_USE_NUM,
    num2 = self:GetCanCostItemMaxNum()
  }
  local ProgressBarInfo = {
    num1 = AT_LEAST_USE_NUM,
    num2 = self:GetCanCostItemMaxNum()
  }
  local CommonAddSubtractData = _G.NRCCommonAddSubtractData()
  CommonAddSubtractData.SliderInfo = SliderInfo
  CommonAddSubtractData.ProgressBarInfo = ProgressBarInfo
  CommonAddSubtractData.AddBtnPressedHandler = self.OnBtnAddPressed
  CommonAddSubtractData.AddBtnReleasedHandler = self.OnBtnAddReleased
  CommonAddSubtractData.SubtractBtnPressedHandler = self.OnBtnDelPressed
  CommonAddSubtractData.SubtractBtnReleasedHandler = self.OnBtnDelReleased
  CommonAddSubtractData.MaxBtnHandler = self.OnBtnMaxClicked
  CommonAddSubtractData.SliderHandler = self.OnSliderValueChanged
  CommonAddSubtractData.Call = self
  self.UMG_AddSubtract:SetPanelInfo(CommonAddSubtractData)
  self.UMG_AddSubtract:SetSliderStepSize(1)
end

function UMG_NewChoosePetBall_C:UpdateCommonAddSubtractPanel(UpdateReasonType)
  if self.IsClosing then
    return
  end
  local MaxNum = self:GetCanCostItemMaxNum()
  if MaxNum < self.SelectedQuantity then
    self.SelectedQuantity = MaxNum
  end
  self.SelectionQuantityText:SetText(string.format(LuaText.HatchProgressAdd_3, self.SelectedQuantity))
  if 0 == MaxNum then
    self.UMG_AddSubtract:SetProgressBarPercent(1)
  else
    self.UMG_AddSubtract:SetProgressBarPercent((self.SelectedQuantity - AT_LEAST_USE_NUM) / (MaxNum - AT_LEAST_USE_NUM))
  end
  self.UMG_AddSubtract:SetSliderStepSize(1)
  self.UMG_AddSubtract:SetSliderMinValue(AT_LEAST_USE_NUM)
  self.UMG_AddSubtract:SetSliderMaxValue(MaxNum)
  self.UMG_AddSubtract:SetSliderValue(self.SelectedQuantity)
  self.UMG_AddSubtract:SetSelectNumText(MaxNum)
  self:CheckAddSubtractDisable()
  self:UpdateGreenProgressBar(UpdateReasonType)
end

function UMG_NewChoosePetBall_C:CheckAddSubtractDisable()
  if self.SelectedQuantity <= self.UMG_AddSubtract:GetSliderMinValue() then
    self.UMG_AddSubtract:SetSubtractBtnIsEnabledNewStyle(false)
  else
    self.UMG_AddSubtract:SetSubtractBtnIsEnabledNewStyle(true)
  end
  if self.SelectedQuantity >= self.UMG_AddSubtract:GetSliderMaxValue() then
    self.UMG_AddSubtract:SetAddBtnIsEnabledNewStyle(false)
  else
    self.UMG_AddSubtract:SetAddBtnIsEnabledNewStyle(true)
  end
end

function UMG_NewChoosePetBall_C:OnTick(InDeltaTime)
  if self.AddSubtractBtnPressTimer == nil then
    return
  end
  if self.AddSubtractBtnPressType == EnumAddSubtractBtnPressType.NONE then
    return
  end
  self.AddSubtractBtnPressTimer = self.AddSubtractBtnPressTimer - InDeltaTime
  if self.AddSubtractBtnPressTimer <= 0 then
    if self.AddSubtractBtnPressType == EnumAddSubtractBtnPressType.ADD then
      self:OnBtnAddItemClick()
    elseif self.AddSubtractBtnPressType == EnumAddSubtractBtnPressType.DEL then
      self:OnBtnDelItemClick()
    end
    self.AddSubtractBtnPressTimer = LONG_PRESS_ADD_SUBTRACT_THRESHOLD
  end
end

function UMG_NewChoosePetBall_C:OnBtnAddPressed()
  self.AddSubtractBtnPressType = EnumAddSubtractBtnPressType.ADD
  _G.UpdateManager:Register(self)
end

function UMG_NewChoosePetBall_C:OnBtnAddReleased()
  self.AddSubtractBtnPressType = EnumAddSubtractBtnPressType.NONE
  self.AddSubtractBtnPressTimer = IN_LONG_PRESS_THRESHOLD
  _G.UpdateManager:UnRegister(self)
  self:OnBtnAddItemClick()
end

function UMG_NewChoosePetBall_C:OnBtnAddItemClick()
  local MaxNum = self:GetCanCostItemMaxNum()
  if MaxNum >= self.SelectedQuantity + 1 then
    self.SelectedQuantity = self.SelectedQuantity + 1
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_NewChoosePetBall_C:OnBtnAddItemClick")
  self:UpdateCommonAddSubtractPanel()
end

function UMG_NewChoosePetBall_C:OnBtnDelPressed()
  self.AddSubtractBtnPressType = EnumAddSubtractBtnPressType.DEL
  self.IsDelClick = true
  self.IsDelItem = true
  _G.UpdateManager:Register(self)
end

function UMG_NewChoosePetBall_C:OnBtnDelReleased()
  self.AddSubtractBtnPressType = EnumAddSubtractBtnPressType.NONE
  self.AddSubtractBtnPressTimer = IN_LONG_PRESS_THRESHOLD
  _G.UpdateManager:UnRegister(self)
  self:OnBtnDelItemClick()
end

function UMG_NewChoosePetBall_C:OnBtnDelItemClick()
  local MaxNum = self:GetCanCostItemMaxNum()
  if self.SelectedQuantity - 1 >= AT_LEAST_USE_NUM then
    self.SelectedQuantity = self.SelectedQuantity - 1
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_NewChoosePetBall_C:OnBtnDelItemClick")
  self:UpdateCommonAddSubtractPanel()
end

function UMG_NewChoosePetBall_C:OnBtnMaxClicked()
  local MaxNum = self:GetCanCostItemMaxNum()
  if self.SelectedQuantity ~= MaxNum then
    self.SelectedQuantity = MaxNum
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401008, "UMG_NewChoosePetBall_C:OnBtnMaxClicked")
    self:UpdateCommonAddSubtractPanel()
  end
end

function UMG_NewChoosePetBall_C:OnSliderValueChanged(value)
  local RealValue = math.floor(value)
  local MaxNum = self:GetCanCostItemMaxNum()
  if RealValue > MaxNum then
    RealValue = MaxNum
  end
  if RealValue < AT_LEAST_USE_NUM then
    RealValue = AT_LEAST_USE_NUM
  end
  if self.SelectedQuantity ~= RealValue then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40007002, "UMG_NewChoosePetBall_C:OnSliderValueChanged")
  end
  self.SelectedQuantity = RealValue
  self:UpdateCommonAddSubtractPanel()
end

function UMG_NewChoosePetBall_C:UpdateGreenProgressBar(UpdateReasonType)
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule:HasPanel("PetHatchingPanel") then
    local PetHatchingPanel = PetUIModule:GetPanel("PetHatchingPanel")
    if PetHatchingPanel and PetHatchingPanel.UpdateGreenProgressBar and PetUIModule.data then
      PetHatchingPanel:UpdateGreenProgressBar(self.SelectedQuantity, UpdateReasonType)
    end
  end
end

function UMG_NewChoosePetBall_C:GetCanCostItemMaxNum()
  local CanCostItemMaxNum = 0
  local CurSelectedItemData
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule.data then
    CurSelectedItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel()
  end
  if nil == CurSelectedItemData then
    Log.Error("UMG_NewChoosePetBall_C:GetCanCostItemMaxNum CurSelectedItemData is nil")
    return CanCostItemMaxNum
  end
  local BgaItemNum = CurSelectedItemData.num
  local ItemAddProgressPercent
  if CurSelectedItemData.conf.item_behavior[1] and CurSelectedItemData.conf.item_behavior[1].use_action and CurSelectedItemData.conf.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_PET_HATCH_PROCESS_ADD and CurSelectedItemData.conf.item_behavior[1].ratio and CurSelectedItemData.conf.item_behavior[1].ratio[1] and CurSelectedItemData.conf.item_behavior[1].ratio[1] > 0 then
    ItemAddProgressPercent = CurSelectedItemData.conf.item_behavior[1].ratio[1]
  end
  if nil == ItemAddProgressPercent then
    Log.Error("UMG_NewChoosePetBall_C:GetCanCostItemMaxNum ItemAddProgressPercent is nil")
    return CanCostItemMaxNum
  end
  local CurEggHatchingProgress
  if PetUIModule and PetUIModule:HasPanel("PetHatchingPanel") then
    local PetHatchingPanel = PetUIModule:GetPanel("PetHatchingPanel")
    if PetHatchingPanel then
      CurEggHatchingProgress = PetHatchingPanel:GetCurEggHatchingProgress()
    end
  end
  if nil == CurEggHatchingProgress then
    Log.Error("UMG_NewChoosePetBall_C:GetCanCostItemMaxNum CurEggHatchingProgress is nil")
    return CanCostItemMaxNum
  end
  CanCostItemMaxNum = math.ceil((100 - CurEggHatchingProgress) / ItemAddProgressPercent)
  if BgaItemNum < CanCostItemMaxNum then
    CanCostItemMaxNum = BgaItemNum
  end
  return CanCostItemMaxNum
end

function UMG_NewChoosePetBall_C:OnAnimationFinished(anim)
  if anim == self.Out then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, false, self.DisplayMode, true)
    self:DoClose()
  elseif anim == self.In then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, true, self.DisplayMode, true)
  end
end

function UMG_NewChoosePetBall_C:OnClickCloseBtn()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
end

function UMG_NewChoosePetBall_C:ClosePanel(CloseReasonType)
  Log.Debug("UMG_NewChoosePetBall_C:ClosePanel")
  CloseReasonType = CloseReasonType or PetUIModuleEnum.PetHatchingRightPanelCloseReasonType.None
  self.IsClosing = true
  self:StopAllAnimations()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, false, self.DisplayMode, false, CloseReasonType)
  self:PlayAnimation(self.Out)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002002, "UMG_NewChoosePetBall_C:ClosePanel")
end

function UMG_NewChoosePetBall_C:OnDeactive()
end

function UMG_NewChoosePetBall_C:OnDestruct()
end

return UMG_NewChoosePetBall_C

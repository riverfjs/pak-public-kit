local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetHatching_C = _G.NRCPanelBase:Extend("UMG_PetHatching_C")
local EnumCurHatchingEggType = {
  None = 0,
  Normal = 1,
  RandomEgg = 2,
  CustomGlassEgg = 3
}
local EnumRefreshUpdateHatchSecsReasonType = {
  None = 0,
  HatchSecsUpdate = 1,
  UsedIncubationProgressItem = 2
}

function UMG_PetHatching_C:OnActive(gid)
  self:OnAddEventListener()
  self:SetCommonTitle()
  self:OnUpdateData(gid)
end

function UMG_PetHatching_C:OnUpdateData(gid)
  self.SelectGid = gid
  self.IsFinishEggSwitch = false
  self.isFirstOpen = true
  self.bHaveHatchingEgg = false
  self:SetIsClicking(false)
  self:UpdatePanel(true)
  self.lastTargetTime = 0
  self:ResetProgressPlayQueue()
end

function UMG_PetHatching_C:UpdatePanel(isRemove)
  local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
  for i = 1, #backpackEggList do
    if backpackEggList[i].eggData and backpackEggList[i].eggData.start_hatch_time then
    else
      backpackEggList[i].eggData.start_hatch_time = 0
    end
  end
  table.sort(backpackEggList, function(a, b)
    return a.eggData.start_hatch_time < b.eggData.start_hatch_time
  end)
  local selectIndex = 0
  local dataList = {}
  self.bHaveHatchingEgg = #backpackEggList > 0
  self.Egg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetActiveWidgetIndex(self.bHaveHatchingEgg and 0 or 1)
  if not self.bHaveHatchingEgg then
    self:PlayAnimation(self.Empty_In)
  end
  for i = 1, 3 do
    if i > #backpackEggList then
      table.insert(dataList, {data = nil, positionIndex = i})
    else
      if self.SelectGid and self.SelectGid == backpackEggList[i].gid then
        selectIndex = i - 1
        self.SelectGid = nil
      end
      table.insert(dataList, {
        data = backpackEggList[i],
        positionIndex = i
      })
    end
  end
  self.petHeadList:InitGridView(dataList)
  if self.bHaveHatchingEgg == false then
    if self:IsBagHaveEggItem() then
      self.WidgetSwitcher_Btn:SetActiveWidgetIndex(1)
      self.UMG_Btn2:SetBtnText(LuaText.umg_pethatching3)
    else
      self.WidgetSwitcher_Btn:SetActiveWidgetIndex(0)
      self.UMG_Btn2Grey:SetBtnText(LuaText.umg_pethatching3)
    end
  else
    self.WidgetSwitcher_Btn:SetActiveWidgetIndex(1)
    self.UMG_Btn2:SetBtnText(LuaText.umg_pet_attribute_2)
  end
  if isRemove then
    local item = self.petHeadList:GetItemByIndex(selectIndex)
    item:RemoveSelect()
  end
  self.petHeadList:SetItemClickAble(true)
  self.petHeadList:SelectItemByIndex(selectIndex)
  if self.isFirstOpen then
    self.isFirstOpen = false
    for i = 1, 3 do
      local item = self.petHeadList:GetItemByIndex(i - 1)
      item:PlayInAnimation()
    end
  end
end

function UMG_PetHatching_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_PetHatching_C:ResetProgressPlayQueue()
  self.ProgressPlayQueue = {}
  self.bPlayingProgressAddAnim = false
  self.bPlayAddAnimFullPercent = false
end

function UMG_PetHatching_C:CreateProgressPlayNodeAndAddQueue(Progress, hatchProgressUpdateReasonType)
  local ProgressPlayNode = {TargetProgress = Progress, HatchProgressUpdateReasonType = hatchProgressUpdateReasonType}
  table.insert(self.ProgressPlayQueue, ProgressPlayNode)
  if not self.bPlayingProgressAddAnim then
    self:PlayNextProgressPlayNode()
  end
end

function UMG_PetHatching_C:PlayNextProgressPlayNode()
  if 0 == #self.ProgressPlayQueue then
    return
  end
  local ProgressPlayNode = table.remove(self.ProgressPlayQueue, 1)
  local HatchProgressUpdateReasonType = ProgressPlayNode.HatchProgressUpdateReasonType
  HatchProgressUpdateReasonType = HatchProgressUpdateReasonType or EnumRefreshUpdateHatchSecsReasonType.None
  if PetUtils.CheckPetEggIsHatchSecsMax(self.curEggGid) and HatchProgressUpdateReasonType == EnumRefreshUpdateHatchSecsReasonType.None then
    self:PlayNextProgressPlayNode()
    return
  end
  if self.bPlayAddAnimFullPercent then
    self:PlayNextProgressPlayNode()
    return
  end
  if not self.bPlayAddAnimFullPercent then
    self:LoadingProgress(ProgressPlayNode.TargetProgress)
  end
end

function UMG_PetHatching_C:LoadingProgress(progress)
  self.progress = progress
  if not self.IsFinishEggSwitch then
    return
  end
  local endTime = self.Add:GetEndTime()
  local targetTime = endTime / 100 * progress
  if 0 == targetTime then
    targetTime = 0.001
    self.lastTargetTime = 0
  elseif targetTime <= self.lastTargetTime then
    self.lastTargetTime = targetTime - 0.1
  end
  self.Egg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:UpdateIncubationProgressBtn()
  progress = math.floor(progress)
  self.NRCText_132:SetText(string.format("%.0f", progress))
  self:PlayAnimationTimeRange(self.Add, self.lastTargetTime, targetTime)
  self.bPlayingProgressAddAnim = true
  local DelayTime = targetTime - self.lastTargetTime
  self.lastTargetTime = targetTime
  if progress >= 100 then
    self:UpdateEstablishContractBtn()
    self.bPlayAddAnimFullPercent = true
    self:DelaySeconds(DelayTime + 0.3, function()
      self.Egg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end)
  end
end

function UMG_PetHatching_C:ClearGreenProgressBar()
  self:StopAnimation(self.Add_Green)
  self:SetGreenProgressBarVisible(false)
  if self.selectIndex then
    local PetHatchingItem = self.petHeadList:GetItemByIndex(self.selectIndex - 1)
    if PetHatchingItem then
      PetHatchingItem:ClearGreenProgressBar()
    end
  end
end

function UMG_PetHatching_C:SetGreenProgressBarVisible(bVisible)
  self.EggProgressBar_1:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.GreenBox:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.GreenDot:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetHatching_C:UpdateGreenProgressBar(InSelectedQuantity, UpdateReasonType)
  Log.Debug("UMG_PetHatching_C:UpdateGreenProgressBar")
  local PetUIModule = NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule and PetUIModule.data then
    local CurSelectedItemData = PetUIModule.data:GetCurSelectItemDataInHatchingRightPanel()
    if CurSelectedItemData and CurSelectedItemData.conf.item_behavior[1] and CurSelectedItemData.conf.item_behavior[1].use_action and CurSelectedItemData.conf.item_behavior[1].use_action == _G.Enum.ItemBehavior.IB_PET_HATCH_PROCESS_ADD and CurSelectedItemData.conf.item_behavior[1].ratio and CurSelectedItemData.conf.item_behavior[1].ratio[1] and CurSelectedItemData.conf.item_behavior[1].ratio[1] > 0 then
      local ItemAddProgressPercent = CurSelectedItemData.conf.item_behavior[1].ratio[1]
      local FinalPreviewProgress = ItemAddProgressPercent * InSelectedQuantity
      if self.FinalPreviewProgress ~= nil and FinalPreviewProgress == self.FinalPreviewProgress and UpdateReasonType ~= PetUIModuleEnum.HatchingPanelCommonAddSubtractPanelUpdateReasonType.HatchSecsUpdate then
        return
      end
      self.FinalPreviewProgress = FinalPreviewProgress
      local AnimEndTime = self.Add_Green:GetEndTime()
      local TargetPlayTime = AnimEndTime / 100 * FinalPreviewProgress
      if 0 == TargetPlayTime then
        TargetPlayTime = 0.001
      end
      if nil == self.LastGreenAnimPlayEndTime then
        self.LastGreenAnimPlayEndTime = self.lastTargetTime or 0
      end
      local TargetPlayEndTime = TargetPlayTime + self.lastTargetTime
      if AnimEndTime < TargetPlayEndTime then
        TargetPlayEndTime = AnimEndTime
      end
      self:SetGreenProgressBarVisible(true)
      self:StopAnimation(self.Add_Green)
      if TargetPlayEndTime > self.LastGreenAnimPlayEndTime then
        self:PlayAnimationTimeRange(self.Add_Green, self.LastGreenAnimPlayEndTime, TargetPlayEndTime, 1, UE4.EUMGSequencePlayMode.FORWARD)
      else
        self:PlayAnimationTimeRange(self.Add_Green, AnimEndTime - self.LastGreenAnimPlayEndTime, TargetPlayEndTime, 1, UE4.EUMGSequencePlayMode.REVERSE, 1, false)
      end
      self.LastGreenAnimPlayEndTime = TargetPlayEndTime
      if self.selectIndex then
        local PetHatchingItem = self.petHeadList:GetItemByIndex(self.selectIndex - 1)
        if PetHatchingItem then
          PetHatchingItem:UpdateGreenProgressBar(FinalPreviewProgress)
        end
      end
    end
  end
end

function UMG_PetHatching_C:OnConstruct()
  self:RegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.OnSelectPetEgg)
  _G.NRCEventCenter:RegisterEvent(self.name, self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
  _G.NRCEventCenter:RegisterEvent("UMG_PetHatching_C", self, PetUIModuleEvent.OnUsedIncubationProgressItemSuccess, self.OnUsedIncubationProgressItemSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.OnStopHatchEgg, self.OnStopHatchEgg)
  self:RegisterEvent(self, PetUIModuleEvent.OnClickPetImage3d, self.OnPetPerform)
  self:RegisterEvent(self, PetUIModuleEvent.FinshEggSwitch, self.OnFinishEggSwitch)
  self:RegisterEvent(self, PetUIModuleEvent.UpdateEggSpeedIcon, self.UpdateEggSpeedIcon)
  self:RegisterEvent(self, PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, self.OnShowOrClosePetEggBallChoosePanel)
  self:BindInputAction()
end

function UMG_PetHatching_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnUsedIncubationProgressItemSuccess, self.OnUsedIncubationProgressItemSuccess)
  self:UnRegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.OnSelectPetEgg)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnStopHatchEgg, self.OnStopHatchEgg)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnClickPetImage3d, self.OnPetPerform)
  self:UnRegisterEvent(self, PetUIModuleEvent.FinshEggSwitch, self.OnFinishEggSwitch)
  self:UnRegisterEvent(self, PetUIModuleEvent.UpdateEggSpeedIcon, self.UpdateEggSpeedIcon)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, self.OnShowOrClosePetEggBallChoosePanel)
  self:UnBindInputAction()
  if self.module then
    self.module.isHatchingPanel = false
  end
end

function UMG_PetHatching_C:BindInputAction()
end

function UMG_PetHatching_C:UnBindInputAction()
end

function UMG_PetHatching_C:OnPcClose()
  if self.btnCloseSubPanel2:IsVisible() then
    self:ClosePanel1()
  else
    self:ClosePanel()
  end
end

function UMG_PetHatching_C:OnDisable()
  self:CancelDelay()
end

function UMG_PetHatching_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseSubPanel2.btnClose, self.ClosePanel1)
  self:AddButtonListener(self.btn, self.ClosePanel)
  self:AddButtonListener(self.ClickBtn, self.OnClickIncubationProgressBtn)
  self:AddButtonListener(self.UMG_Btn2Grey.btnLevelUp, self.ClickEggBtn)
  self:AddButtonListener(self.UMG_Btn2.btnLevelUp, self.ClickEggBtn)
  self:AddButtonListener(self.RetrieveBtn.btnLevelUp, self.ClickEggBtn)
  self:AddButtonListener(self.EstablishContract.btnLevelUp, self.OnClickEstablishContract)
end

function UMG_PetHatching_C:SetIsClicking(bClicking)
  self.IsClicking = bClicking
end

function UMG_PetHatching_C:GetIsClicking()
  return self.IsClicking
end

function UMG_PetHatching_C:OnFinishEggSwitch(isFinish)
  self.IsFinishEggSwitch = isFinish
  self:CancelDelay()
  if isFinish then
    if self.isFinishHatching then
      self.Egg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:PlayAnimation(self.Change)
    else
      if self.isFirstOpen then
        self:PlayAnimation(self.In)
      else
        self:PlayAnimation(self.Change)
      end
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002031, "UMG_PetHatching_C:OnFinishEggSwitch")
      self.CanvasPanel_77:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.EggProgressBar:SetPercent(0)
      if self.progress then
        self.NRCText_132:SetText(string.format("%.0f", math.floor(self.progress)))
      end
      self:DelaySeconds(0.4, function()
        self.CanvasPanel_77:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:CreateProgressPlayNodeAndAddQueue(self.progress)
      end)
      self:DelaySeconds(0.15, function()
        self:UpdateIncubationProgressBtn()
      end)
    end
    self:SetIsClicking(false)
    self:DelaySeconds(0.15, function()
      self.NRCText:SetVisibility(self.eggInfo == nil and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCImage_5:SetVisibility(self.eggInfo == nil and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
    end, self)
    self.NRCSwitcher_BottomPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Egg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_BottomPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:CancelDelay()
  end
end

function UMG_PetHatching_C:OnShowOrClosePetEggBallChoosePanel(IsShow, DisplayMode, IsAnimFinished, CloseReasonType)
  if IsShow then
    if not IsAnimFinished then
      self:ClearGreenProgressBar()
      if DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
      elseif DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
        self.HorizontalBox_Tips:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
        self.HorizontalBox_Tips:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.FinalPreviewProgress = nil
        self.LastGreenAnimPlayEndTime = nil
      end
      self:StopAnimation(self.Empty_MoveLeft)
      self:StopAnimation(self.Empty_MoveRight)
      self:PlayAnimation(self.Empty_MoveLeft)
    else
      self:SetIsClicking(false)
    end
  else
    if not IsAnimFinished then
      if DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall then
      elseif DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg then
      elseif DisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
        self.HorizontalBox_Tips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if CloseReasonType ~= PetUIModuleEnum.PetHatchingRightPanelCloseReasonType.UsedIncubationProgressItem then
          self:ClearGreenProgressBar()
        end
        self.FinalPreviewProgress = nil
        self.LastGreenAnimPlayEndTime = nil
      end
      self:StopAnimation(self.Empty_MoveLeft)
      self:StopAnimation(self.Empty_MoveRight)
      self:PlayAnimation(self.Empty_MoveRight)
    end
    self:SetIsClicking(false)
  end
end

function UMG_PetHatching_C:OnUpdateHatchSecs(rsp)
  if nil == rsp then
    Log.Error("UMG_PetHatching_C:OnUpdateHatchSecs rsp is nil")
    return
  end
  Log.Debug("UMG_PetHatching_C:OnUpdateHatchSecs")
  Log.Dump(rsp, 3, "UMG_PetHatching_C:OnUpdateHatchSecs rsp:")
  local index
  for i = 1, #rsp.egg_gid do
    if rsp.egg_gid[i] == self.curEggGid then
      index = i
    end
  end
  local secs = 0
  if index and rsp.hatched_secs[index] then
    secs = rsp.hatched_secs[index]
  end
  local eggData = self.eggInfo.bagItem.egg_data
  self.isFinishHatching = false
  local eggMaxSeces
  if eggData and 0 == eggData.conf_id then
    eggMaxSeces = eggData.max_hatched_secs
    self.isFinishHatching = secs / eggMaxSeces >= 1
  elseif eggData and 0 ~= eggData.conf_id then
    local eggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
    eggMaxSeces = eggConf.hatch_data
    self.isFinishHatching = secs / eggMaxSeces >= 1
  end
  self.NRCSwitcher_BottomPanel:SetActiveWidgetIndex(self.isFinishHatching and 1 or 0)
  local bAlreadyHatched = false
  if eggData and eggData.hatched_secs and eggMaxSeces <= eggData.hatched_secs then
    bAlreadyHatched = true
  end
  for i, eggInfo in pairs(_G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()) do
    for j = 1, #rsp.egg_gid do
      if rsp.egg_gid[j] == eggInfo.gid and rsp.hatched_secs[j] then
        eggInfo.eggData.hatched_secs = rsp.hatched_secs[j]
      end
    end
  end
  if eggMaxSeces and not bAlreadyHatched then
    self:CreateProgressPlayNodeAndAddQueue(math.clamp(secs / eggMaxSeces * 100, 0, 100), EnumRefreshUpdateHatchSecsReasonType.HatchSecsUpdate)
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.UpdateHatchingRightPanelCommonAddSubtractPanel, PetUIModuleEnum.HatchingPanelCommonAddSubtractPanelUpdateReasonType.HatchSecsUpdate)
  if self.isFinishHatching then
    self:UpdateEstablishContractBtn()
    local RightPanelDisplayMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetHatchingRightPanelDisplayMode)
    if RightPanelDisplayMode == PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
    end
  end
end

function UMG_PetHatching_C:RefreshUpdateHatchSecs(EggGid, NewHatchSecs, UpdateReasonType)
  if nil == EggGid then
    Log.Error("UMG_PetHatching_C:RefreshUpdateHatchSecs EggGid is nil")
    return
  end
  if nil == NewHatchSecs then
    Log.Error("UMG_PetHatching_C:RefreshUpdateHatchSecs NewHatchSecs is nil")
    return
  end
  local secs = NewHatchSecs
  local eggData = self.eggInfo.bagItem.egg_data
  local LastHatchSecs = self.eggInfo.eggData.hatched_secs
  self.isFinishHatching = false
  local eggMaxSeces
  if eggData and 0 == eggData.conf_id then
    eggMaxSeces = eggData.max_hatched_secs
    self.isFinishHatching = secs / eggMaxSeces >= 1
  elseif eggData and 0 ~= eggData.conf_id then
    local eggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
    eggMaxSeces = eggConf.hatch_data
    self.isFinishHatching = secs / eggMaxSeces >= 1
  end
  self.NRCSwitcher_BottomPanel:SetActiveWidgetIndex(self.isFinishHatching and 1 or 0)
  for _, eggInfo in pairs(_G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()) do
    if EggGid == eggInfo.gid then
      eggInfo.eggData.hatched_secs = NewHatchSecs
    end
  end
  if eggMaxSeces then
    self:CreateProgressPlayNodeAndAddQueue(math.clamp(secs / eggMaxSeces * 100, 0, 100), UpdateReasonType)
  end
end

function UMG_PetHatching_C:OnUsedIncubationProgressItemSuccess(EggGid, NewHatchSecs)
  if self.selectIndex then
    local PetHatchingItem = self.petHeadList:GetItemByIndex(self.selectIndex - 1)
    if PetHatchingItem and PetHatchingItem.itemInfo and PetHatchingItem.itemInfo.gid and PetHatchingItem.itemInfo.gid == EggGid then
      PetHatchingItem:RefreshUpdateHatchSecs(NewHatchSecs)
      self:RefreshUpdateHatchSecs(EggGid, NewHatchSecs, EnumRefreshUpdateHatchSecsReasonType.UsedIncubationProgressItem)
    end
  end
end

function UMG_PetHatching_C:UpdateIncubationProgressBtn()
  local bShow = false
  local bHaveEggItem = false
  if self.curEggGid then
    local EggItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, self.curEggGid)
    if EggItem then
      bHaveEggItem = true
    end
  end
  local ItemList = PetUtils.GetIncubationProgressItemList()
  if ItemList and #ItemList > 0 and not self.isFinishHatching and bHaveEggItem then
    bShow = true
  end
  self.ClickBtn:SetVisibility(bShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetHatching_C:UpdateEstablishContractBtn()
  local eggData = self.eggInfo.bagItem.egg_data
  if eggData and eggData.ball_id and 0 ~= eggData.ball_id then
    self.Switcher_Btn:SetActiveWidgetIndex(1)
    self.EstablishContract:SetBtnText(LuaText.umg_bag_14)
    return
  end
  if self.eggInfo and self.eggInfo.eggData and self.eggInfo.eggData.conf_id then
    local PetEggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.eggData.conf_id)
    if PetEggConf and PetEggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
      self.Switcher_Btn:SetActiveWidgetIndex(1)
      self.EstablishContract:SetBtnText(LuaText.umg_bag_14)
      return
    end
  end
  local VaildPetBallItemList = self:GetVaildPetBallItemList()
  local VaildPetBallItemNum = 0
  for _, PetBallItem in pairs(VaildPetBallItemList or {}) do
    VaildPetBallItemNum = VaildPetBallItemNum + PetBallItem.itemNum
  end
  if VaildPetBallItemNum > 0 then
    self.Switcher_Btn:SetActiveWidgetIndex(1)
    self.EstablishContract:SetBtnText(LuaText.umg_pethatching6)
  else
    self.Switcher_Btn:SetActiveWidgetIndex(0)
    self.ProhibitedBtn:SetShowLockIcon(false)
    self.ProhibitedBtn:SetOnlyShowTipText(LuaText.umg_pethatching7)
  end
end

function UMG_PetHatching_C:GetVaildPetBallItemList()
  if self.curEggGid == nil then
    return {}
  end
  return _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetVaildPetBallItemList, self.curEggGid)
end

function UMG_PetHatching_C:OnClickEstablishContract()
  Log.Debug("UMG_PetHatching_C:OnClickEstablishContract")
  if self:GetIsClicking() then
    Log.Debug("UMG_PetHatching_C:OnClickEstablishContract IsClicking=[true] return")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetHatching_C:OnClickEstablishContract")
  local eggData = self.eggInfo.bagItem.egg_data
  if eggData and eggData.ball_id and 0 ~= eggData.ball_id then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
    isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_GET_BACK, true)
    if isBan then
      return
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ZoneCrackEggReq, self.curEggGid, nil, nil)
    self:SetIsClicking(true)
    return
  end
  local CurHatchingEggType = self:GetCurHatchingEggType()
  if CurHatchingEggType == EnumCurHatchingEggType.CustomGlassEgg then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenHatchingRightPanel, PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectColor, nil, self.curEggGid)
  else
    local vaildPetBallItemList = self:GetVaildPetBallItemList()
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenHatchingRightPanel, PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectPetBall, vaildPetBallItemList, self.curEggGid)
  end
  self:SetIsClicking(true)
end

function UMG_PetHatching_C:GetCurHatchingEggType()
  local CurHatchingEggType = EnumCurHatchingEggType.None
  if self.eggInfo and self.eggInfo.eggData then
    CurHatchingEggType = EnumCurHatchingEggType.Normal
  end
  if self.eggInfo and self.eggInfo.eggData and self.eggInfo.eggData.conf_id then
    local PetEggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.eggData.conf_id)
    if PetEggConf and PetEggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
      CurHatchingEggType = EnumCurHatchingEggType.CustomGlassEgg
    end
  end
  return CurHatchingEggType
end

function UMG_PetHatching_C:UpdateEggSpeedIcon(redpointDatas)
  for i = 1, 3 do
    local item = self.petHeadList:GetItemByIndex(i - 1)
    item:UpdateIncubating(redpointDatas)
  end
end

function UMG_PetHatching_C:OnSelectPetEgg(eggInfo, selectIndex)
  if nil == selectIndex then
    Log.Error("UMG_PetHatching_C:OnSelectPetEgg selectIndex is nil")
    return
  end
  Log.Debug("UMG_PetHatching_C:OnSelectPetEgg selectIndex=[", selectIndex, "]")
  self:SetIsClicking(true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
  if self.selectIndex == selectIndex then
    local oldGid = self.eggInfo and self.eggInfo.bagItem.gid or -1
    local newGid = eggInfo and eggInfo.bagItem.gid or -1
    if oldGid == newGid then
      self:SetIsClicking(false)
      return
    end
  end
  self:StopTargetAnimations()
  self:ClearGreenProgressBar()
  self:ResetProgressPlayQueue()
  self.selectIndex = selectIndex
  if self.isFirstOpen == false then
    self.button_close:SetRenderOpacity(1)
    self.btn:SetRenderOpacity(1)
  end
  self:CancelDelay()
  if nil == eggInfo then
    self.bHaveHatchingEgg = false
    self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSwitcher_BottomPanel:SetActiveWidgetIndex(0)
    self.NRCSwitcher_BottomPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_BottomPanel:SetRenderOpacity(1)
    if self:IsBagHaveEggItem() then
      self.WidgetSwitcher_Btn:SetActiveWidgetIndex(1)
      self.UMG_Btn2:SetBtnText(LuaText.umg_pethatching3)
    else
      self.WidgetSwitcher_Btn:SetActiveWidgetIndex(0)
      self.UMG_Btn2Grey:SetBtnText(LuaText.umg_pethatching3)
    end
    self.Switcher:SetActiveWidgetIndex(1)
    if not self.bHaveHatchingEgg then
      self:PlayAnimation(self.Empty_In)
    end
    return
  end
  if false == self.bHaveHatchingEgg then
    self.bHaveHatchingEgg = true
    self:PlayAnimation(self.Empty_Out)
  end
  self.NRCSwitcher_BottomPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.WidgetSwitcher_Btn:SetActiveWidgetIndex(1)
  self.UMG_Btn2:SetBtnText(LuaText.umg_pet_attribute_2)
  self.Egg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetActiveWidgetIndex(0)
  self.eggInfo = eggInfo
  self.curEggGid = eggInfo.gid
  local eggData = self.eggInfo.bagItem.egg_data
  local targetProgerss = 0
  if 0 == eggData.conf_id and eggData.random_egg_conf then
    local eggMaxSeces = eggData.max_hatched_secs
    local eggSeces = eggInfo.eggData.hatched_secs
    targetProgerss = math.clamp(eggSeces / eggMaxSeces * 100, 0, 100)
  else
    local eggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
    local eggMaxSeces = eggConf.hatch_data
    local eggSeces = eggInfo.eggData.hatched_secs
    targetProgerss = math.clamp(eggSeces / eggMaxSeces * 100, 0, 100)
  end
  targetProgerss = math.floor(targetProgerss)
  self.NRCText_132:SetText(string.format("%.0f", targetProgerss))
  self.progress = targetProgerss
  self.lastTargetTime = 0
  self.IsFinishEggSwitch = false
end

function UMG_PetHatching_C:StopTargetAnimations()
  self:StopAnimation(self.Empty_In)
  self:StopAnimation(self.Empty_Out)
  self:StopAnimation(self.Out)
  self:StopAnimation(self.In)
  self:StopAnimation(self.Add)
  self:StopAnimation(self.Change)
end

function UMG_PetHatching_C:OnStopHatchEgg()
  self:UpdatePanel(true)
end

function UMG_PetHatching_C:OnPetPerform()
  if not self.progress or self.progress >= 99.99 then
  end
end

function UMG_PetHatching_C:GetCurEggHatchingProgress()
  return self.progress
end

function UMG_PetHatching_C:ClosePanel()
  Log.Debug("UMG_PetHatching_C:ClosePanel")
  if self:CheckIsSelectBtn() then
    return
  end
  if self.module and self.module:GetIsCrackEggIng() then
    Log.Debug("UMG_PetHatching_C:ClosePanel IsCrackEggIng=[true] return")
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGBTN
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
  self:SetPetItemClickAble(false)
  self:SetIsClicking(true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002002, "UMG_PetLeftPanel_C:OnBtnSetMainFightClick")
  self:PlayAnimation(self.Out)
  self.module:OnClosePetHatchingPanel()
end

function UMG_PetHatching_C:ClosePanel1()
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").BACKBTN
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
  self:SetPetItemClickAble(false)
  self:SetIsClicking(true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseHatchingRightPanel)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_PetLeftPanel_C:OnBtnSetMainFightClick")
  self:PlayAnimation(self.Out)
  self.module:OnClosePetHatchingPanel()
end

function UMG_PetHatching_C:OnClickEgg()
  self:OnPetPerform()
end

function UMG_PetHatching_C:IsRemoveEggItem(item)
  if item.type == _G.ProtoEnum.BagItemType.BI_PET_EGG then
    local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
    for k = 1, #backpackEggList do
      local eggInfo = backpackEggList[k]
      if eggInfo.gid == item.gid then
        return true
      end
    end
  end
  return false
end

function UMG_PetHatching_C:IsBagHaveEggItem()
  local bagItems = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByType, _G.ProtoEnum.BagItemType.BI_PET_EGG)
  local bHave = false
  if nil ~= bagItems then
    for i = 1, #bagItems do
      local item = bagItems[i]
      if self:IsRemoveEggItem(item) == false then
        bHave = true
        break
      end
    end
  end
  local PreciousItemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByLableType, _G.Enum.ItemLableType.ILT_PRECIOUS)
  for _, item in pairs(PreciousItemList or {}) do
    if item and item.conf and item.conf.type == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE and item.num and item.num > 0 then
      bHave = true
    end
  end
  return bHave
end

function UMG_PetHatching_C:OnClickIncubationProgressBtn()
  Log.Debug("UMG_PetHatching_C:OnClickIncubationProgressBtn")
  if self:GetIsClicking() then
    Log.Debug("UMG_PetHatching_C:OnClickIncubationProgressBtn IsClicking=[true] return")
    return
  end
  local IncubationProgressItemList = PetUtils.GetIncubationProgressItemList()
  if nil ~= IncubationProgressItemList and #IncubationProgressItemList > 0 then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenHatchingRightPanel, PetUIModuleEnum.PetHatchingRightPanelDisplayMode.IncubationProgress, IncubationProgressItemList, self.curEggGid)
  end
end

function UMG_PetHatching_C:ClickEggBtn()
  Log.Debug("UMG_PetHatching_C:ClickEggBtn")
  if self:GetIsClicking() then
    Log.Debug("UMG_PetHatching_C:ClickEggBtn IsClicking=[true] return")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetHatching_C:ClickEggBtn")
  if self.bHaveHatchingEgg == false then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
    isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_START, true)
    if isBan then
      return
    end
    if self:IsBagHaveEggItem() then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenHatchingRightPanel, PetUIModuleEnum.PetHatchingRightPanelDisplayMode.SelectEgg, {}, nil)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_pethatching4)
    end
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGOUT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
  self:SetPetItemClickAble(false)
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Pet_Attribute_C:onClickRemoveEgg")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local conf = _G.DataConfigManager:GetPetGlobalConfig("hatch_interrupt_text")
  local title = LuaText.umg_pet_attribute_1
  local des = conf and conf.str or LuaText.umg_pet_attribute_2
  if self:GetCurHatchingEggType() == EnumCurHatchingEggType.CustomGlassEgg then
    des = self:GetCustomGlassEggRemoveTipsContent()
  end
  local leftText = LuaText.umg_pet_attribute_3
  local rightText = LuaText.umg_pet_attribute_4
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.RemoveEggCallblack):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_PetHatching_C:GetCustomGlassEggRemoveTipsContent()
  local BaseContent = LuaText.umg_pethatching9
  local RequireGlassEggPieceNum = _G.DataConfigManager:GetGlobalConfigByKeyType("require_glass_egg_piece_num", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  local EggPieceItemName
  if self.eggInfo and self.eggInfo.eggData and self.eggInfo.eggData.egg_piece_id then
    local EggPieceBagItemConf = _G.DataConfigManager:GetBagItemConf(self.eggInfo.eggData.egg_piece_id)
    if EggPieceBagItemConf then
      EggPieceItemName = EggPieceBagItemConf.name
    end
  end
  return string.format(BaseContent or "", RequireGlassEggPieceNum or 0, EggPieceItemName or "")
end

function UMG_PetHatching_C:RemoveEggCallblack(isOk)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGOUT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
  self:SetPetItemClickAble(true)
  if isOk then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, true)
    isBan = isBan or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG_GET_BACK, true)
    if isBan then
      return
    end
    if self.eggInfo then
      local gid = self.eggInfo.gid
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ZoneStopHatchReq, gid)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(1220002039, "UMG_Pet_Attribute_C:RemoveEggCallblack")
end

function UMG_PetHatching_C:OnAnimationFinished(aim)
  if aim == self.Out then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.OnCloseEggPanel, false)
    local touchReasonType1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGBTN
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType1)
    local touchReasonType2 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").BACKBTN
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType2)
    self:SetPetItemClickAble(true)
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainShareBtnVisibility, true)
    self:SetIsClicking(false)
    self:DoClose()
  elseif aim == self.In then
    self:SetPetItemClickAble(true)
  elseif aim == self.Change then
    self:SetPetItemClickAble(true)
  elseif aim == self.Empty_In then
    self.NRCSwitcher_BottomPanel:SetActiveWidgetIndex(0)
    self.NRCSwitcher_BottomPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Btn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_Btn2:SetRenderOpacity(1)
    self:SetIsClicking(false)
  elseif aim == self.Add then
    self.bPlayingProgressAddAnim = false
    self:PlayNextProgressPlayNode()
  end
end

function UMG_PetHatching_C:SetPetItemClickAble(clickable)
  if self and UE4.UObject.IsValid(self) and self.petHeadList then
    self.petHeadList:SetItemClickAble(clickable)
  end
end

function UMG_PetHatching_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetHatchingPanel")
end

return UMG_PetHatching_C

local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ActivityProfilerLog = require("NewRoco.Modules.System.Activity.ActivityProfilerLog")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local JsonUtils = require("Common.JsonUtils")
local UMG_ActivityMainPanel_C = _G.NRCPanelBase:Extend("UMG_ActivityMainPanel_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local CompositedActivityObject = require("NewRoco.Modules.System.Activity.ActivityObject.CompositedActivityObject")
local MaxViewNum = 0
local FunctionEntranceMain = Enum.FunctionEntrance.FE_ACTIVITY

function UMG_ActivityMainPanel_C:OnConstruct()
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ACTIVITY)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ACTIVITY)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self.displayActivities = {}
  self.displayActivitiesClassified = {}
  self.returnActivitiesList = {}
  self.activityViews = _G.MakeWeakTable()
  self.loadingActivityViews = _G.MakeWeakTable()
  self.activityViewOpenOrder = {}
  self.compositedActivities = {}
  self.waitingActiveActivity = nil
  self.curActiveActivity = nil
  self.OpenType = nil
  self.OpenId = nil
  self.activitySelectCounter = 0
  self.curShowTabId = nil
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnClosePanel)
  self:AddButtonListener(self.LianXiButton.btnLevelUp, self.OnClicked)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClick)
  self:AddButtonListener(self.BtnBackflow.btnLevelUp, self.OpenReturnActivities)
  self:AddButtonListener(self.CloseBtn_1.btnClose, self.CloseRecallGuide)
  self:RegisterEvent(self, ActivityModuleEvent.FilterActivityMainTab, self.OnFilterActivityMainTab)
  self:RegisterEvent(self, ActivityModuleEvent.LoadActivityView, self.OnLoadActivityView)
  self:RegisterEvent(self, ActivityModuleEvent.DisplayingActivitiesChange, self.OnDisplayingActivitiesChange)
  self:RegisterEvent(self, ActivityModuleEvent.ShowActivityMainPanelCloseBtn, self.OnShowActivityMainPanelCloseBtn)
  self:RegisterEvent(self, ActivityModuleEvent.ActivitySvrBlockedStateChange, self.OnActivitySvrBlockedStateChange)
  self:RegisterEvent(self, ActivityModuleEvent.OnRecallActivityFinish, self.OnRecallActivityFinish)
  self:BindInputAction()
  self:SetCommonTitle()
  if self.InvalidationBox_86 then
    self.InvalidationBox_86:SetCanCache(false)
  end
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    self.functionBanUIController = FunctionBanUIController()
    local functionBanUIController = self.functionBanUIController
    functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnActivitySvrBlockedStateChange, self)
    functionBanUIController:Activate()
  end
end

function UMG_ActivityMainPanel_C:OnDestruct()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ACTIVITY)
  self:RemoveButtonListener(self.LianXiButton.btnLevelUp)
  self:RemoveButtonListener(self.BtnBackflow.btnLevelUp)
  self:RemoveButtonListener(self.CloseBtn_1.btnClose)
  self:UnRegisterEvent(self, ActivityModuleEvent.FilterActivityMainTab)
  self:UnRegisterEvent(self, ActivityModuleEvent.LoadActivityView)
  self:UnRegisterEvent(self, ActivityModuleEvent.DisplayingActivitiesChange)
  self:UnRegisterEvent(self, ActivityModuleEvent.ShowActivityMainPanelCloseBtn)
  self:UnRegisterEvent(self, ActivityModuleEvent.OnRecallActivityFinish)
  for _activityInst, _activityView in pairs(self.activityViews) do
    if _activityInst then
      _activityInst:DetachView()
    end
  end
  if self.functionBanUIController then
    self.functionBanUIController:Deactivate()
  end
end

function UMG_ActivityMainPanel_C:OnActive(_activityType, _activityId, _openSource)
  if _activityType then
    self.OpenType = _activityType
  end
  if _activityId then
    self.OpenId = _activityId
  end
  if GlobalConfig.DebugOpenUI == true then
    self:LoadPanelByUITest(_activityType)
    return
  end
  self.openSource = _openSource
  local displayActivities = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetDisplayActivities, true)
  self:LocateActivityByTypeOrId(true, displayActivities, _activityType, _activityId)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").ACTIVITY
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
end

function UMG_ActivityMainPanel_C:OnEnable()
  self:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_ActivityMainPanel_C:OnDisable()
  if not self.activityViews then
    return
  end
  for _, _activityView in pairs(self.activityViews) do
    if _activityView and _activityView.OnDisable then
      _activityView:OnDisable()
    end
  end
end

function UMG_ActivityMainPanel_C:OnBringToFront(_activityType, _activityId)
  self:LocateActivityByTypeOrId(false, self.displayActivities, _activityType, _activityId)
end

function UMG_ActivityMainPanel_C:LocateActivityByTypeOrId(_refreshDisplay, _displayActivities, _activityType, _activityId)
  if not _displayActivities then
    return
  end
  local findActivity
  if _activityId then
    for _, _activityInst in ipairs(_displayActivities) do
      if _activityInst:GetActivityId() == _activityId then
        findActivity = _activityInst
        break
      end
    end
  end
  if _activityType and not findActivity then
    for _, _activityInst in ipairs(_displayActivities) do
      if _activityInst:GetActivityType() == _activityType then
        findActivity = _activityInst
        break
      end
    end
  end
  if _refreshDisplay then
    if findActivity then
      self.waitingActiveActivity = findActivity
    end
    self:RefreshDisplayActivities(_displayActivities)
  elseif findActivity then
    if findActivity ~= self.curActiveActivity then
      local itemIndex = self.TabList1:GetIndexByData(findActivity:GetActivityMainTabId(), function(_data, _valueInList)
        return _valueInList and _valueInList.mainTabId == _data
      end)
      if itemIndex > 0 then
        self.waitingActiveActivity = findActivity
        if self.TabList1:IsItemIndexSelected(itemIndex) then
          local displayActivities = self.displayActivitiesClassified[findActivity:GetActivityMainTabId()] or {}
          local selectIndex = 0
          if self.waitingActiveActivity then
            for _index, _activityInst in ipairs(displayActivities) do
              if self.waitingActiveActivity == _activityInst then
                selectIndex = _index - 1
                break
              end
            end
          end
          self.TabList:SelectItemByIndex(selectIndex)
        else
          self.TabList1:SelectItemByIndex(itemIndex - 1)
        end
      end
    end
  elseif _activityType or _activityId then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_unopen_track_tips)
  end
end

function UMG_ActivityMainPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_ActivityUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseActivityUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseActivityQuick", self, "OnPcClose")
  end
end

function UMG_ActivityMainPanel_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnBtnClosePanel()
end

function UMG_ActivityMainPanel_C:RefreshDisplayActivities(displayActivities)
  self.displayActivities = displayActivities
  self.curShowTabId = nil
  local validCompositedKeys = {}
  for _compositedKey, _ in pairs(self.compositedActivities) do
    validCompositedKeys[_compositedKey] = false
  end
  local activityTabData = {}
  local returnActivityData = {}
  local mainTabIds = {}
  for _, _activityInst in ipairs(displayActivities) do
    local mainTabId = _activityInst:GetActivityMainTabId()
    if _activityInst:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY and not _activityInst.activityConf.if_hide then
      table.insert(returnActivityData, _activityInst)
    else
      local cacheActivities = activityTabData[mainTabId]
      if not cacheActivities then
        cacheActivities = {}
        activityTabData[mainTabId] = cacheActivities
        table.insert(mainTabIds, mainTabId)
      end
      local compositedKey = _activityInst:GetActivityCompositedKey()
      if compositedKey then
        validCompositedKeys[compositedKey] = true
        local compositedInst = self.compositedActivities[compositedKey]
        if compositedInst then
          compositedInst:AddActivity(_activityInst)
        else
          compositedInst = CompositedActivityObject({_activityInst})
          self.compositedActivities[compositedKey] = compositedInst
          table.insert(cacheActivities, compositedInst)
        end
      else
        table.insert(cacheActivities, _activityInst)
      end
    end
  end
  if 0 == #returnActivityData then
    self.BtnBackflow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BtnBackflow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BtnBackflow:SetRedDot(489)
    table.sort(returnActivityData, function(a, b)
      return a:GetActivityId() < b:GetActivityId()
    end)
    if self.openSource ~= ActivityEnum.MainPanelOpenSource.RecallActivity then
      local recordTable = JsonUtils.LoadSaved("RecallPanelOpenRecord", {})
      if not next(recordTable) then
        self.CanvasPanel_Aperture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.CanvasInstruction:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        _G.NRCAudioManager:PlaySound2DAuto(40009005, "UMG_ActivityMainPanel_C:RefreshDisplayActivities")
        self:PlayAnimation(self.Guide_BtnBackflow)
        self.bPlayGuide = true
        JsonUtils.DumpSaved("RecallPanelOpenRecord", {1})
      end
    end
  end
  self.displayActivitiesClassified = activityTabData
  self.returnActivitiesList = returnActivityData
  for _compositedKey, _valid in pairs(validCompositedKeys) do
    if not _valid then
      self.compositedActivities[_compositedKey] = nil
    end
  end
  local tabList = {}
  table.sort(mainTabIds, function(a, b)
    return a < b
  end)
  for _, _tabId in ipairs(mainTabIds) do
    local tabItem = {}
    tabItem.mainTabId = _tabId
    tabItem.extraKeyList = {}
    local activities = activityTabData[_tabId]
    if activities and #activities > 0 then
      for _, _activityInst in ipairs(activities) do
        local _activityExtraKeyTable = _activityInst:GetTabRedPointExtraKeyList()
        for _, _extraKey in ipairs(_activityExtraKeyTable) do
          table.insert(tabItem.extraKeyList, _extraKey)
        end
      end
    end
    table.insert(tabList, tabItem)
  end
  local tabListNum = #tabList
  local tabItemWidthConf = {
    387,
    194,
    129
  }
  if tabListNum > 0 then
    self.TabList1:SetCustomSize(tabItemWidthConf[math.min(tabListNum, 3)], 53)
  end
  self.TabList1:InitGridView(tabList)
  local selectMainTabId = 0
  local waitingActiveActivity = self.waitingActiveActivity
  if waitingActiveActivity then
    local waitingActiveTabId = waitingActiveActivity:GetActivityMainTabId()
    for _index, _tabId in ipairs(mainTabIds) do
      if waitingActiveTabId == _tabId then
        selectMainTabId = _index - 1
        break
      end
    end
  else
    for _index, _ in ipairs(tabList) do
      local hasRedPoint = self.TabList1:OpItemByIndex(_index, ActivityEnum.ActivityTabOpType.GetHasRedPoint)
      if hasRedPoint then
        selectMainTabId = _index - 1
        break
      end
    end
  end
  if self.openSource == ActivityEnum.MainPanelOpenSource.RecallActivity and #returnActivityData > 0 then
    self:OpenReturnActivities()
  else
    self.TabList1:SelectItemByIndex(selectMainTabId)
  end
end

function UMG_ActivityMainPanel_C:RefreshCommonTitle(index)
  if 1 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif 3 == index and self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
  end
end

function UMG_ActivityMainPanel_C:OnFilterActivityMainTab(_mainTabId)
  local displayActivities = self.displayActivitiesClassified[_mainTabId]
  for _index, _activityInst in ipairs(displayActivities) do
    _activityInst:SendTLogActivityInteraction(ActivityEnum.TLogInteractionType.Show)
  end
  local selectMainTabId
  local selectMainTabIndex = self.TabList1:GetSelectedIndex()
  if selectMainTabIndex then
    local selectData = self.TabList1:GetDataByIndex(selectMainTabIndex + 1)
    if selectData then
      selectMainTabId = selectData.mainTabId
    end
  end
  if selectMainTabId then
    if self.activitySelectCounter < 1 then
      self:DelayFrames(1, function()
        self:ShowTabList(selectMainTabId)
      end)
    else
      self:ShowTabList(selectMainTabId)
    end
  end
end

function UMG_ActivityMainPanel_C:ShowTabList(_mainTabId)
  local displayActivities = self.displayActivitiesClassified[_mainTabId] or {}
  self.TabList:InitList(displayActivities)
  local selectIndex = 0
  if self.curShowTabId ~= _mainTabId then
    local waitingActiveActivity = self.waitingActiveActivity
    if waitingActiveActivity then
      for _index, _activityInst in ipairs(displayActivities) do
        if waitingActiveActivity == _activityInst then
          selectIndex = _index - 1
          break
        end
      end
    else
      for _index, _ in ipairs(displayActivities) do
        local hasRedPoint = self.TabList:OpItemByIndex(_index, ActivityEnum.ActivityTabOpType.GetHasRedPoint)
        if hasRedPoint then
          selectIndex = _index - 1
          break
        end
      end
    end
  else
    selectIndex = self.TabList:GetSelectedIndex()
    if selectIndex and selectIndex > 0 then
      selectIndex = selectIndex - 1
    end
  end
  self.curShowTabId = _mainTabId
  self.TabList:SelectItemByIndex(selectIndex or 0)
  self:RefreshCommonTitle(_mainTabId)
end

function UMG_ActivityMainPanel_C:OnLoadActivityView(_activityInst)
  if self.curActiveActivity == _activityInst and self.activityViews[_activityInst] then
    return
  end
  self.activitySelectCounter = self.activitySelectCounter + 1
  ActivityProfilerLog.ProfilerOpen(_activityInst, true)
  local oldActivityView = self.curActiveActivity and self.activityViews[self.curActiveActivity]
  if oldActivityView then
    oldActivityView:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if oldActivityView.OnDisable then
      oldActivityView:OnDisable()
    end
  end
  self.curActiveActivity = _activityInst
  if _activityInst then
    local newActivityView = self.activityViews[_activityInst]
    if not newActivityView then
      if not self.loadingActivityViews[_activityInst] then
        local successExecuteLoad = false
        self.loadingActivityViews[_activityInst] = true
        _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.FullSpeed, _activityInst:GetUmgName())
        ActivityProfilerLog.ProfilerLoad(_activityInst, true)
        local umgPath = _activityInst:GetUmgPath()
        if not string.IsNilOrEmpty(umgPath) then
          if string.EndsWith(umgPath, "_C'") then
            local resRequest = self:LoadPanelRes(umgPath, 255, self.OnDefaultViewClassLoaded)
            if resRequest then
              resRequest.activityInst = _activityInst
              successExecuteLoad = true
            end
          else
            self:LogError("invalid umg path in activity: ", _activityInst:GetActivityId(), umgPath)
          end
        else
          successExecuteLoad = _activityInst:LoadViewClass(self, self.OnCustomViewClassLoaded)
          if not successExecuteLoad then
            self:LogError("empty umg path and invalid LoadViewClass function in activity: ", _activityInst:GetActivityId())
          end
        end
        if not successExecuteLoad then
          self:InstantiateActivityViewClass(_activityInst, nil)
        end
      end
    else
      newActivityView:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:OnActivityViewChanged(newActivityView, _activityInst, false)
    end
    _activityInst:ReqGetPlayerActivityData()
    _activityInst:SendTLogActivityInteraction(ActivityEnum.TLogInteractionType.Click)
  end
end

function UMG_ActivityMainPanel_C:OnDefaultViewClassLoaded(resRequest, viewClass)
  self:InstantiateActivityViewClass(resRequest and resRequest.activityInst, viewClass)
end

function UMG_ActivityMainPanel_C:OnCustomViewClassLoaded(viewClass, activityInst)
  self:InstantiateActivityViewClass(activityInst, viewClass)
end

function UMG_ActivityMainPanel_C:InstantiateActivityViewClass(_activityInst, viewClass)
  if not _activityInst then
    return
  end
  self.loadingActivityViews[_activityInst] = nil
  _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, _activityInst:GetUmgName())
  ActivityProfilerLog.ProfilerLoad(_activityInst, false)
  if viewClass and self.curActiveActivity == _activityInst then
    ActivityProfilerLog.ProfilerCreate(_activityInst, true)
    local newActivityView = UE4.UWidgetBlueprintLibrary.Create(UE4Helper.GetCurrentWorld(), viewClass)
    ActivityProfilerLog.ProfilerCreate(_activityInst, false)
    newActivityView.activityInst = _activityInst
    newActivityView.panelName = _activityInst:GetUmgName()
    self:DynamicAddChildView(newActivityView)
    _activityInst:AttachView(newActivityView)
    self.activityViews[_activityInst] = newActivityView
    ActivityProfilerLog.ProfilerAddToViewport(_activityInst, true)
    local contentSlot = self.Content:AddChild(newActivityView)
    ActivityProfilerLog.ProfilerAddToViewport(_activityInst, false)
    if contentSlot then
      local anchors = UE4.FAnchors()
      anchors.Minimum = UE4.FVector2D(0, 0)
      anchors.Maximum = UE4.FVector2D(1, 1)
      contentSlot:SetAnchors(anchors)
      contentSlot:SetOffsets(UE4.FMargin())
      contentSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
    end
    if newActivityView.OnOpenView then
      newActivityView:OnOpenView()
    end
    self:OnActivityViewChanged(newActivityView, _activityInst, true)
  end
end

function UMG_ActivityMainPanel_C:OnActivityViewClassLoadedByUITest(resRequest, viewClass)
  if GlobalConfig.DebugOpenUI == true then
    local newActivityView = UE4.UWidgetBlueprintLibrary.Create(UE4Helper.GetCurrentWorld(), viewClass)
    
    function newActivityView.OnConstruct()
    end
    
    self:DynamicAddChildView(newActivityView)
    local contentSlot = self.Content:AddChild(newActivityView)
    if contentSlot then
      local anchors = UE4.FAnchors()
      anchors.Minimum = UE4.FVector2D(0, 0)
      anchors.Maximum = UE4.FVector2D(1, 1)
      contentSlot:SetAnchors(anchors)
      contentSlot:SetOffsets(UE4.FMargin())
      contentSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
    end
    if newActivityView.OnOpenView then
      newActivityView:OnOpenView()
    end
  end
end

function UMG_ActivityMainPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_ActivityMainPanel_C:OnActivityViewChanged(newActivityView, activityInst, firstLoad)
  if newActivityView and newActivityView.OnEnable then
    newActivityView:OnEnable(firstLoad)
  end
  if MaxViewNum and MaxViewNum > 0 then
    table.removeValue(self.activityViewOpenOrder, activityInst)
    table.insert(self.activityViewOpenOrder, activityInst)
    if #self.activityViewOpenOrder > MaxViewNum then
      local removeInst = table.remove(self.activityViewOpenOrder, 1)
      if removeInst then
        removeInst:DetachView()
        local removeView = self.activityViews[removeInst]
        if removeView then
          self.activityViews[removeInst] = nil
          self.Content:RemoveChild(removeView)
        end
      end
    end
  end
  self:OnActivitySvrBlockedStateChange()
  ActivityProfilerLog.ProfilerOpen(activityInst, false)
end

function UMG_ActivityMainPanel_C:OnDisplayingActivitiesChange(_newDisplayActivities)
  if not _newDisplayActivities or #_newDisplayActivities <= 0 then
    return
  end
  local _newActivities = {}
  for _, _activityInst in ipairs(_newDisplayActivities) do
    _newActivities[_activityInst:GetActivityId()] = true
  end
  local tabChangeFlag = ActivityUtils.RemoveElements(self.displayActivities, function(_activityInst)
    local _id = _activityInst:GetActivityId()
    if not _newActivities[_id] then
      local _viewBindInst = _activityInst
      local _compositedKey = _activityInst:GetActivityCompositedKey()
      if _compositedKey then
        _viewBindInst = self.compositedActivities[compositedKey] or _activityInst
      end
      if not self.activityViews[_viewBindInst] then
        return true
      end
    else
      _newActivities[_id] = nil
    end
  end)
  for _index, _activityInst in ipairs(_newDisplayActivities) do
    local _id = _activityInst:GetActivityId()
    if _newActivities[_id] then
      tabChangeFlag = true
      if _index < #self.displayActivities then
        table.insert(self.displayActivities, _index, _activityInst)
      else
        table.insert(self.displayActivities, _activityInst)
      end
    end
  end
  if tabChangeFlag then
    local locateActivityType, locateActivityId
    if self.activitySelectCounter <= 1 then
      locateActivityType = self.OpenType
      locateActivityId = self.OpenId
    end
    if not locateActivityType and not locateActivityId then
      local curActiveActivity = self.curActiveActivity
      if curActiveActivity then
        locateActivityType = curActiveActivity:GetActivityType()
        locateActivityId = curActiveActivity:GetActivityId()
      end
    end
    self:LocateActivityByTypeOrId(true, self.displayActivities, locateActivityType, locateActivityId)
  end
end

function UMG_ActivityMainPanel_C:OnShowActivityMainPanelCloseBtn(_show)
  self.CloseBtn:SetVisibility(_show and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_ActivityMainPanel_C:OnActivitySvrBlockedStateChange()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain)
  local activityInst = self.curActiveActivity
  if isBan or activityInst and activityInst:GetShieldingStatus() then
    self.blockBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.blockBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ActivityMainPanel_C:OnBtnClosePanel()
  if self.bReturnOpen then
    self.bReturnOpen = false
    self.TabListPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Title1:Set_MainTitle(self.titleConf.title)
    if self.openSource == ActivityEnum.MainPanelOpenSource.RecallActivity then
      _G.NRCAudioManager:PlaySound2DAuto(40009005, "UMG_ActivityMainPanel_C:RefreshDisplayActivities")
      self.CanvasPanel_Aperture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasInstruction:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Guide_BtnBackflow)
      self.bPlayGuide = true
      JsonUtils.DumpSaved("RecallPanelOpenRecord", {1})
      self.openSource = nil
    end
    self.BtnBackflow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TabList1:SelectItemByIndex(0)
  else
    local mappingContext = self:GetInputMappingContext("IMC_ActivityUI")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseActivityUI")
      mappingContext:UnBindAction("IA_CloseActivityQuick")
    end
    _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_ActivityMainPanel_C:OnBtnClosePanel")
    local _curActivityView = self.curActiveActivity and self.activityViews[self.curActiveActivity]
    if _curActivityView and _curActivityView.OnCloseView then
      _curActivityView:OnCloseView()
    end
    self:OnClose()
  end
end

function UMG_ActivityMainPanel_C:DoClose()
  if self.openSource == ActivityEnum.MainPanelOpenSource.LobbyMainInner then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  end
  _G.NRCPanelBase.DoClose(self)
end

function UMG_ActivityMainPanel_C:OnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1011, "UMG_ActivityMainPanel_C:OnClicked")
  self:DelaySeconds(0.2, function()
    _G.NRCSDKManager:CustomerService(4)
  end)
end

function UMG_ActivityMainPanel_C:OnBlockBtnClick()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.onlinemodule_13)
end

function UMG_ActivityMainPanel_C:LoadPanelByUITest(umgPath)
  self:LoadPanelRes(umgPath, 255, self.OnActivityViewClassLoadedByUITest)
end

function UMG_ActivityMainPanel_C:OpenReturnActivities()
  self.bReturnOpen = true
  self.TabListPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local titleConf = _G.DataConfigManager:GetTitleConf("RecallTheme")
  self.Title1:SetBaseInfo(titleConf.head_icon, titleConf.subtitle[1].subtitle, titleConf.title)
  local returnActivities = self.returnActivitiesList
  self.TabList:InitList(returnActivities)
  local selectIndex = 0
  for _index, _ in ipairs(returnActivities) do
    local hasRedPoint = self.TabList:OpItemByIndex(_index, ActivityEnum.ActivityTabOpType.GetHasRedPoint)
    if hasRedPoint then
      selectIndex = _index - 1
      break
    end
  end
  self.TabList:SelectItemByIndex(selectIndex)
  self.BtnBackflow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.bPlayGuide then
    self:CloseRecallGuide()
    self.bPlayGuide = nil
  end
end

function UMG_ActivityMainPanel_C:OnRecallActivityFinish()
  if self.bReturnOpen then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
    self:OnBtnClosePanel()
  end
  self:StopAllAnimations()
  self.BtnBackflow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_Aperture:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasInstruction:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ActivityMainPanel_C:CloseRecallGuide()
  self:StopAllAnimations()
  self.CanvasInstruction:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_Aperture:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ActivityMainPanel_C:OnAnimFinished(Anim)
  if Anim == self.Guide_BtnBackflow then
    self:PlayAnimation(self.Guide_BtnBackflow_Loop, nil, 0)
  end
end

return UMG_ActivityMainPanel_C

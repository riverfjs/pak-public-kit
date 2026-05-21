local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local LoadingUIModuleEvent = reload("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local LoadingUIModule = NRCModuleBase:Extend("LoadingUIModule")

function LoadingUIModule:OnConstruct()
  self.data = self:SetData("LoadingUIModuleData", "NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleData")
  self._cacheResReqList = nil
  local LoadingUIPanelData = _G.NRCPanelRegisterData()
  LoadingUIPanelData.panelName = "UMG_LoadingUI"
  LoadingUIPanelData.panelPath = "/Game/NewRoco/Modules/System/LoadingUIModule/Res/UMG_LoadingUI"
  LoadingUIPanelData.panelLayer = Enum.UILayerType.UI_LAYER_LEVEL_LOADING
  LoadingUIPanelData.panelCacheType = _G.NRCPanelRegisterData.PanelCacheType.DonntCache
  LoadingUIPanelData.enablePcEsc = false
  self:RegisterPanel(LoadingUIPanelData)
  local FastLoadingUIPanelData = _G.NRCPanelRegisterData()
  FastLoadingUIPanelData.panelName = "UMG_FastLoadingUI"
  FastLoadingUIPanelData.panelPath = "/Game/NewRoco/Modules/System/LoadingUIModule/Res/UMG_FastLoadingUI"
  FastLoadingUIPanelData.panelLayer = Enum.UILayerType.UI_LAYER_LEVEL_LOADING
  FastLoadingUIPanelData.panelCacheType = _G.NRCPanelRegisterData.PanelCacheType.PreCache
  FastLoadingUIPanelData.enablePcEsc = false
  self:RegisterPanel(FastLoadingUIPanelData)
  local WaitingUIPanelData = _G.NRCPanelRegisterData()
  WaitingUIPanelData.panelName = "UMG_WaitingUI"
  WaitingUIPanelData.panelPath = "/Game/NewRoco/Modules/System/LoadingUIModule/Res/UMG_WaitingUI"
  WaitingUIPanelData.panelLayer = Enum.UILayerType.UI_LAYER_TOP_WAITTING
  WaitingUIPanelData.enablePcEsc = false
  self:RegisterPanel(WaitingUIPanelData)
  local CreatePlayerUIPanelData = _G.NRCPanelRegisterData()
  CreatePlayerUIPanelData.panelName = "UMG_LoadingPanel"
  CreatePlayerUIPanelData.panelPath = "/Game/NewRoco/Modules/System/LoadingUIModule/Res/UMG_LoadingPanel"
  CreatePlayerUIPanelData.panelLayer = Enum.UILayerType.UI_LAYER_LEVEL_LOADING
  CreatePlayerUIPanelData.openAnimName = "FadeIn"
  CreatePlayerUIPanelData.closeAnimName = "FadeOut"
  CreatePlayerUIPanelData.enablePcEsc = false
  self:RegisterPanel(CreatePlayerUIPanelData)
end

function LoadingUIModule:OnDestruct()
  self._cacheResReqList = nil
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
end

function LoadingUIModule:OnShutdown()
  local LivingPanel = self:GetLivingPanelName()
  if LivingPanel then
    local findLoadingPanel = false
    for i = #LivingPanel, 1, -1 do
      local panelName = LivingPanel[i]
      if not findLoadingPanel and "UMG_FastLoadingUI" == panelName then
        findLoadingPanel = true
        local panelInst = self:GetPanel(panelName)
        UE4.UNRCPlatformGameInstance.GetInstance():SetBackToLoginLoadingUMG(panelInst)
      else
        self:ClosePanel(panelName)
      end
    end
  end
end

function LoadingUIModule:OpenLoadingUI(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, needForceShow, teleport_rule_id)
  self:Log("_G.DataModelMgr.PlayerDataModel:IsFirstLogin()", _G.DataModelMgr.PlayerDataModel:IsFirstLogin())
  if _G.DataModelMgr.PlayerDataModel:IsFirstLogin() then
    self:OnOpenLoadingUI(content, process, tips, liveTime)
  else
    self:OnOpenFastLoadingUI(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, needForceShow, teleport_rule_id)
  end
end

function LoadingUIModule:CloseLoadingUI(delayTime, bForceUseFirstLoginUI, bForceSetDelayTime)
  self:Log("CloseLoadingUI firstLogin, delayTime , forceUseFirstLogintUI , forceSetDelayTime ", _G.DataModelMgr.PlayerDataModel:IsFirstLogin() and "true" or "false", delayTime, bForceUseFirstLoginUI and "true" or "false", bForceSetDelayTime and "true" or "false")
  if _G.DataModelMgr.PlayerDataModel:IsFirstLogin() or bForceUseFirstLoginUI then
    self:OnCloseLoadingUI(delayTime, bForceSetDelayTime)
  else
    self:OnCloseFastLoadingUI(delayTime, bForceSetDelayTime)
  end
end

function LoadingUIModule:OnOpenLoadingUI(content, process, tips, liveTime)
  if nil == process then
    process = 0
  end
  local isOpened, _ = self:HasPanel("UMG_LoadingUI")
  if isOpened then
    local loadingUI = self:GetPanel("UMG_LoadingUI")
    if loadingUI then
      self:EnablePanel("UMG_LoadingUI")
      loadingUI:SetData(content, process, tips, liveTime)
    end
  else
    self:OpenPanel("UMG_LoadingUI", content, process, tips, liveTime)
  end
  NRCGCManager:TryGC(true)
end

function LoadingUIModule:OnCloseLoadingUI(delayTime, bForceClose)
  self:Log("OnCloseLoadingUI", delayTime, bForceClose)
  delayTime = delayTime or 0
  local isOpened, _ = self:HasPanel("UMG_LoadingUI")
  if isOpened then
    local loadingUI = self:GetPanel("UMG_LoadingUI")
    if loadingUI and not bForceClose then
      loadingUI:DelayClose(delayTime)
    else
      self:ClosePanel("UMG_LoadingUI")
    end
  else
    self:ClosePanel("UMG_LoadingUI")
  end
  NRCGCManager:TryGC(true)
end

function LoadingUIModule:OnOpenFastLoadingUI(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, needForceShow, teleport_rule_id)
  self:Log("[OnOpenFastLoadingUI]", content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, needForceShow)
  if nil == process then
    process = 0
  end
  local isOpened, _ = self:HasPanel("UMG_FastLoadingUI")
  if isOpened then
    local loadingUI = self:GetPanel("UMG_FastLoadingUI")
    if loadingUI then
      if loadingUI._showingLoadingUI then
        loadingUI._showingLoadingUI.NeedForceShow = needForceShow
      end
      if loadingUI:IsOutAnimationPlayed() then
        self:OnCloseFastLoadingUI(0, true)
      end
      self:EnablePanel("UMG_FastLoadingUI")
      loadingUI:SetData(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, teleport_rule_id)
    end
  else
    self:OpenPanel("UMG_FastLoadingUI", content, process, tips, liveTime, switch_reason, teleport_id, teleport_rule_id)
  end
  NRCGCManager:TryGC(true)
end

function LoadingUIModule:OnCloseFastLoadingUI(delayTime, bForceClose)
  self:Log("OnCloseFastLoadingUI", delayTime, bForceClose)
  delayTime = delayTime or 0
  local isOpened, _ = self:HasPanel("UMG_FastLoadingUI")
  if isOpened then
    local loadingUI = self:GetPanel("UMG_FastLoadingUI")
    if loadingUI and not bForceClose then
      loadingUI:DelayClose(delayTime)
    else
      self:DisablePanel("UMG_FastLoadingUI")
      if bForceClose then
        UE4Helper.SetEnableWorldRendering(nil, false, "UMG_FastLoading_C")
      end
    end
  else
    self:DisablePanel("UMG_FastLoadingUI")
  end
  NRCGCManager:TryGC(true)
end

function LoadingUIModule:OnOpenWaitingUI(content, delayTime)
  local isOpened, _ = self:HasPanel("UMG_WaitingUI")
  if isOpened then
    local waitingUI = self:GetPanel("UMG_WaitingUI")
    if waitingUI then
      self:EnablePanel("UMG_WaitingUI")
      waitingUI:SetData(content, delayTime)
    end
  else
    self:OpenPanel("UMG_WaitingUI", content, delayTime)
  end
end

function LoadingUIModule:OnCloseWaitingUI(arg)
  self:DisablePanel("UMG_WaitingUI")
end

function LoadingUIModule:OnUpdateWaitingUIText(newContent)
  if not self.GetPanel or not self.HasPanel then
    return false
  end
  local isOpened, _ = self:HasPanel("UMG_WaitingUI")
  if isOpened then
    local waitingUI = self:GetPanel("UMG_WaitingUI")
    if waitingUI then
      waitingUI:UpdateText(newContent)
    end
  end
end

function LoadingUIModule:IsWaitingUIEnabled()
  if not self.GetPanel or not self.HasPanel then
    return false
  end
  local isOpened, _ = self:HasPanel("UMG_WaitingUI")
  if isOpened then
    local waitingUI = self:GetPanel("UMG_WaitingUI")
    if waitingUI then
      return waitingUI.enableView
    else
      return false
    end
  else
    return false
  end
end

function LoadingUIModule:IsWaitingUIOpening()
  if not self.IsPanelInOpening then
    return false
  end
  return self:IsPanelInOpening("UMG_WaitingUI")
end

function LoadingUIModule:HasLoadingUI(Name)
  local isOpened, _ = self:HasPanel(Name)
  if not isOpened then
    return false
  end
  local Panel = self:GetPanel(Name)
  if not Panel then
    return false
  end
  return Panel.enableView
end

function LoadingUIModule:HasAnyLoadingUI()
  if self:HasLoadingUI("UMG_LoadingUI") then
    return true
  end
  if self:HasLoadingUI("UMG_FastLoadingUI") then
    return true
  end
  return false
end

function LoadingUIModule:OnActive()
  _G.NRCEventCenter:RegisterEvent("LoadingUIModule", self, SceneEvent.LoadMapFinish, self.OnLoadMapFinish)
end

function LoadingUIModule:OnDeactive()
  self:UnRegisterAllCmd()
  self:ClearAllData()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnLoadMapFinish)
end

function LoadingUIModule:OpenCreatePlayerLoadingUI(withoutUI)
  if not self:HasPanel("UMG_LoadingPanel") then
    self:OpenPanel("UMG_LoadingPanel", withoutUI)
  else
    local panel = self:GetPanel("UMG_LoadingPanel")
    if withoutUI then
      panel:ShowWithoutAnim()
    end
  end
end

function LoadingUIModule:CloseCreatePlayerLoadingUI(isDelay, closeDirectly)
  if not self:HasPanel("UMG_LoadingPanel") then
    return
  end
  local panel = self:GetPanel("UMG_LoadingPanel")
  if closeDirectly then
    self:ClosePanel("UMG_LoadingPanel")
  end
  if panel:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  if isDelay then
    self.delayID = DelayManager:DelaySeconds(0.5, function()
      if panel and UE4.UObject.IsValid(panel) then
        panel:PlayFadeOutAnim()
      end
    end)
  elseif panel and UE4.UObject.IsValid(panel) then
    panel:PlayFadeOutAnim()
  end
end

local function ConverToWidgetClsPath(res_path)
  local rt = string.gsub(res_path, "WidgetBlueprint'(.*)'", function(s)
    print(s)
    if not string.EndsWith(s, "_C") then
      s = s .. "_C"
    end
    return s
  end)
  return rt
end

function LoadingUIModule:OnLoadMapFinish()
  self:Log("[[OnLoadMapFinish]]")
  if self._cacheResReqList then
    for i, v in ipairs(self._cacheResReqList) do
      local resReq = v
      if not resReq then
        NRCResourceManager:UnLoadRes(resReq)
      end
    end
  end
  local sceneModule = NRCModuleManager:GetModule("SceneModule")
  if sceneModule then
    local curSceneResId = sceneModule:GetCurrentMapResId()
    local preCacheUmgLsit = {}
    local allData = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.TELEPORT_LOADING_CONF)
    for i, v in ipairs(allData) do
      if v.loading_begin == curSceneResId then
        table.insert(preCacheUmgLsit, v.res_path)
      end
    end
    local preCacheLoadReq = {}
    for i, v in ipairs(preCacheUmgLsit) do
      local widgetClsPath = ConverToWidgetClsPath(v)
      local resReq = NRCResourceManager:LoadResAsync(self, widgetClsPath, PriorityEnum.Passive_UI_Default, -1, function(caller, resRequest, asset)
        caller:Log("PreloadLoadingRes Success", resRequest.assetPath)
      end, nil, nil)
      table.insert(preCacheLoadReq, resReq)
    end
    self._cacheResReqList = preCacheLoadReq
  end
end

function LoadingUIModule:FindLoadingUIUMGWidgetClass(cur_scene_res_id, next_scene_res_id)
  self:Log("[FindLoadingUIUMGWidgetClass]", cur_scene_res_id, next_scene_res_id)
  local allData = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.TELEPORT_LOADING_CONF)
  for i, v in ipairs(allData) do
    if v.loading_begin == cur_scene_res_id and v.loading_end == next_scene_res_id then
      local res_path = ConverToWidgetClsPath(v.res_path)
      return res_path
    end
  end
  return nil
end

function LoadingUIModule:CreatePlayerFinalLoading()
  local panel = self:GetPanel("UMG_LoadingPanel")
  if panel then
    panel:PlayFinalLoading()
  end
end

function LoadingUIModule:SetFastLoadingUIHeadLineText(headLineText)
  local isOpened, _ = self:HasPanel("UMG_FastLoadingUI")
  if isOpened then
    local loadingUI = self:GetPanel("UMG_FastLoadingUI")
    if loadingUI and loadingUI.SetHeadLineText then
      loadingUI:SetHeadLineText(headLineText)
    end
  end
end

return LoadingUIModule

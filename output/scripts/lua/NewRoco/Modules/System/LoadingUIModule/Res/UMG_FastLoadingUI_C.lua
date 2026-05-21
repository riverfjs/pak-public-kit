local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local UMG_FastLoadingUI_C = _G.NRCPanelBase:Extend("UMG_FastLoadingUI_C")
local ELoadingUI = {CommonLoadingUI = 0, LoadedUI = 1}

function UMG_FastLoadingUI_C:OnConstruct()
  self:SetChildViews(self.CommonLoadingUI)
  self.liveTime = 0
  self.IsClosing = false
  self.curProcess = 0
  self.targetProcess = 0
  self._param = {}
  self._param.content = nil
  self._param.process = 0
  self._param.tips = nil
  self._param.switch_reason = 0
  self._param.liveTime = nil
  self._param.cur_map_id = nil
  self._param.next_map_id = nil
  self._isWidgetInited = nil
  self._isOutAnimationPlayed = nil
  self.CommonLoadingUI:OnConstruct()
  self.NRCWidgetLoader_238.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadPanelCallback)
  self.NRCWidgetLoader_238.OnUnLoadPanelCallbackDelegate:Add(self, self.OnUnLoadPanelCallback)
  self._showingLoadingUI = self.CommonLoadingUI
  self._eCurLoadingUI = ELoadingUI.CommonLoadingUI
  self.NRCSwitcher_33:SetActiveWidgetIndex(0)
end

function UMG_FastLoadingUI_C:OnLoadPanelCallback(bResult, umgWidget)
  self:Log("[OnLoadPanelCallback]", bResult)
end

function UMG_FastLoadingUI_C:OnUnLoadPanelCallback(bResult)
  self:Log("[OnUnLoadPanelCallback]", bResult)
end

function UMG_FastLoadingUI_C:OnDestruct()
  self._showingLoadingUI:OnDestruct()
  self.NRCWidgetLoader_238.OnLoadPanelCallbackDelegate:Remove(self, self.OnLoadPanelCallback)
  self.NRCWidgetLoader_238.OnUnLoadPanelCallbackDelegate:Remove(self, self.OnUnLoadPanelCallback)
  self._isWidgetInited = false
end

function UMG_FastLoadingUI_C:OnActive(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, teleport_rule_id)
  self:Log("[OnActive]", content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, teleport_rule_id)
  self._param = {}
  self._param.content = content
  self._param.process = process
  self._param.tips = tips
  self._param.switch_reason = switch_reason
  self._param.liveTime = liveTime
  self._param.cur_scene_res_id = cur_scene_res_id
  self._param.next_scene_res_id = next_scene_res_id
  self._param.teleport_rule_id = teleport_rule_id
  self.IsClosing = false
  self.targetProcess = process * 100
  self.curProcess = 0
  self._curLoadedWidgetCls = nil
  self._isOutAnimationPlayed = nil
  self:LoadLoadingWidget()
  self._showingLoadingUI:OnActive(content, tips, switch_reason)
  if self._param.liveTime ~= nil then
    self:DelayClose(self._param.liveTime)
  else
    self:StopOutAnimation()
  end
end

function UMG_FastLoadingUI_C:OnDeactive()
  self:Log("OnDeactive")
  self._showingLoadingUI:OnDeactive()
  self._isWidgetInited = false
  self._isOutAnimationPlayed = nil
end

function UMG_FastLoadingUI_C:OnEnable()
  self:Log("OnEnable")
  self.liveTime = 0
  self._showingLoadingUI:OnEnable()
  self.IsClosing = false
  self.curProcess = 0
  self._isOutAnimationPlayed = nil
  _G.NRCAudioManager:SetStateByName("WaitLoading", "Loading")
end

function UMG_FastLoadingUI_C:OnDisable()
  self:Log("OnDisable")
  self._showingLoadingUI:OnDisable()
  if self._eCurLoadingUI == ELoadingUI.LoadedUI then
    self._showingLoadingUI = self.CommonLoadingUI
    self._eCurLoadingUI = ELoadingUI.CommonLoadingUI
    self.NRCWidgetLoader_238:UnLoadPanel(true)
    self.NRCSwitcher_33:SetActiveWidgetIndex(0)
  end
  self._curLoadedWidgetCls = nil
  self._isWidgetInited = false
  self._isOutAnimationPlayed = nil
  _G.NRCAudioManager:SetStateByName("WaitLoading", "None")
end

function UMG_FastLoadingUI_C:DelayClose(delayTime)
  Log.Debug("[UMG_FastLoadingUI_C]  DelayClose", delayTime, self.liveTime)
  delayTime = delayTime or 0
  if not self.IsClosing then
    if delayTime <= 0 then
      delayTime = 0
    else
      self:StopOutAnimation()
    end
    self.liveTime = delayTime
    self.IsClosing = true
  end
  self.targetProcess = 100
end

function UMG_FastLoadingUI_C:OnTick(deltaTime)
  if self.enableView then
    if deltaTime > 0.1 then
      deltaTime = 0.1
    end
    if self.targetProcess > self.curProcess then
      local delta = (self.targetProcess - self.curProcess) * deltaTime * 0.5
      if self.liveTime < 3 then
        delta = 1
      end
      if delta < 1 then
        delta = 1
      end
      self.curProcess = self.curProcess + delta
      if self.curProcess > self.targetProcess then
        self.curProcess = self.targetProcess
      end
    else
      self.curProcess = self.targetProcess
    end
    self._showingLoadingUI:OnViewTick(deltaTime)
    if self.IsClosing and self._showingLoadingUI.FxFinished then
      if not self._isOutAnimationPlayed then
        self:StopInAnimation()
        self:PlayOutAnimation()
        self._isOutAnimationPlayed = true
        UE4Helper.SetEnableWorldRendering(nil, false, "UMG_FastLoading_C")
        _G.GEMPostManager:GEMPostStepEvent("CommonLoadingEnd")
        _G.GEMPostManager:GEMPostStepEvent("EnterBigWorld")
        if not self._showingLoadingUI.bOutAnimationPlayed then
          self.liveTime = math.max(self._showingLoadingUI.OutDuration or 0.5, self.liveTime)
        else
          self.liveTime = -1
        end
      elseif self.liveTime < 0 then
        self:Log("StopAllAnimations")
        self.module:DisablePanel("UMG_FastLoadingUI")
      else
        self.liveTime = self.liveTime - deltaTime
      end
    end
  end
end

function UMG_FastLoadingUI_C:PlayOutAnimation()
  self._showingLoadingUI:PlayOutAnimation()
end

function UMG_FastLoadingUI_C:StopOutAnimation()
  self._showingLoadingUI:StopOutAnimation()
end

function UMG_FastLoadingUI_C:StopInAnimation()
  self._showingLoadingUI:StopInAnimation()
end

function UMG_FastLoadingUI_C:MapLoaded()
  self.mapLoaded = true
end

function UMG_FastLoadingUI_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if _G.GlobalConfig.DebugOpenUI then
    UE4Helper.SetEnableWorldRendering(nil, false, "UMG_FastLoading_C")
    self:DoClose()
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_FastLoadingUI_C:LoadLoadingWidget()
  local umgWidgetClassPath = self._param.cur_scene_res_id and self._param.next_scene_res_id and NRCModuleManager:DoCmd(LoadingUIModuleCmd.FindLoadingUIUMGWidgetClass, self._param.cur_scene_res_id, self._param.next_scene_res_id)
  if self._curLoadedWidgetCls ~= nil and self._curLoadedWidgetCls == umgWidgetClassPath then
    return
  elseif self._curLoadedWidgetCls == nil and nil == umgWidgetClassPath and nil ~= self._showingLoadingUI then
    return
  end
  if self._showingLoadingUI then
    self._showingLoadingUI:OnDisable()
  end
  self._showingLoadingUI = nil
  if umgWidgetClassPath then
    local softClsPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(tostring(umgWidgetClassPath))
    self.NRCWidgetLoader_238:SetWidgetClass(softClsPath)
    self.NRCWidgetLoader_238:LoadPanelSync(self)
    self._showingLoadingUI = self.NRCWidgetLoader_238:GetPanel()
    self._eCurLoadingUI = ELoadingUI.LoadedUI
    self.NRCSwitcher_33:SetActiveWidgetIndex(1)
    self._curLoadedWidgetCls = umgWidgetClassPath
  end
  if not self._showingLoadingUI then
    self._showingLoadingUI = self.CommonLoadingUI
    self._eCurLoadingUI = self.CommonLoadingUI
    self.NRCSwitcher_33:SetActiveWidgetIndex(0)
    self._curLoadedWidgetCls = nil
    self._showingLoadingUI:OnEnable()
  end
end

function UMG_FastLoadingUI_C:SetData(content, process, tips, liveTime, switch_reason, teleport_id, cur_scene_res_id, next_scene_res_id, teleport_rule_id)
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self._param = {}
  self._param.content = content
  self._param.process = process
  self._param.tips = tips
  self._param.switch_reason = switch_reason
  self._param.liveTime = liveTime
  self._param.teleport_id = teleport_id
  self._param.teleport_rule_id = teleport_rule_id
  if not self._isWidgetInited then
    self._param.cur_scene_res_id = cur_scene_res_id
    self._param.next_scene_res_id = next_scene_res_id
    self:LoadLoadingWidget()
    self._isWidgetInited = true
  end
  self._showingLoadingUI:SetData(content, tips, switch_reason, teleport_id, teleport_rule_id)
  self.targetProcess = process * 100
  self.IsClosing = false
  if nil ~= liveTime then
    self:DelayClose(liveTime)
  else
    self:StopOutAnimation()
  end
end

function UMG_FastLoadingUI_C:IsOutAnimationPlayed()
  return self._isOutAnimationPlayed
end

function UMG_FastLoadingUI_C:CheckFxPlayedFlag()
  self:Log("CheckFxPlayedFlag ", self._showingLoadingUI.FxPlayed)
  return self._showingLoadingUI.FxPlayed
end

function UMG_FastLoadingUI_C:SetHeadLineText(headLineText)
  if self._showingLoadingUI and self._showingLoadingUI.SetHeadLineText then
    self._showingLoadingUI:SetHeadLineText(headLineText)
  end
end

return UMG_FastLoadingUI_C

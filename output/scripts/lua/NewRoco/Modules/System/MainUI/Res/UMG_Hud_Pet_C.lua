local Base = require("NewRoco.Modules.System.MainUI.Res.UMG_Hud_Base")
local SceneEnum = require("NewRoco.Modules.Core.Scene.Common.SceneEnum")
local RealtimeDialogModuleCmd = require("NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleCmd")
local DeviceUtils = require("NewRoco.Modules.Core.App.DeviceUtils")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local UMG_Hud_Pet_C = Base:Extend("UMG_Hud_Pet_C")
local SubPanel = {
  MainPanel = "UMG_Hud_Main",
  TrackPanel = "UMG_Hud_Track",
  PerceptionPanel = "UMG_Hud_Perception",
  DialogPanel = "UMG_Hud_OpenDialogue",
  HomeOutPutPanel = "UMG_Home_Output",
  PlantStatusPanel = "UMG_Hud_HomePlantingStatus",
  CountdownExpansion = "UMG_UnderExpansion",
  FeedHud = "UMG_Hud_Feed",
  VeryIntimate = "UMG_Pet_VeryIntimate"
}
local NameLabelDrawSize = {
  MainPanel = UE4.FIntPoint(300, 50),
  TrackPanel = UE4.FIntPoint(700, 220),
  PerceptionPanel = UE4.FIntPoint(700, 220),
  DialogPanel = UE4.FIntPoint(700, 220),
  HomeOutPutPanel = UE4.FIntPoint(700, 700),
  PlantStatusPanel = UE4.FIntPoint(100, 100),
  TraceNamePanel = UE4.FIntPoint(200, 300),
  VeryIntimate = UE4.FIntPoint(128, 128),
  Default = UE4.FIntPoint(700, 220)
}

function UMG_Hud_Pet_C:OnInitialized()
  self:ResetData()
  self.UmgLoaders = {
    [SubPanel.MainPanel] = self.MainLoader,
    [SubPanel.TrackPanel] = self.TrackLoader,
    [SubPanel.PerceptionPanel] = self.PerceptionLoader,
    [SubPanel.DialogPanel] = self.OpenDialogue,
    [SubPanel.HomeOutPutPanel] = self.HomeOutputLoader,
    [SubPanel.PlantStatusPanel] = self.HomePlantState,
    [SubPanel.CountdownExpansion] = self.CountdownExpansion,
    [SubPanel.FeedHud] = self.FeedHud,
    [SubPanel.VeryIntimate] = self.VeryIntimate
  }
  if _G.GlobalConfig.EnableSubHudPool then
    for _subPanel, _umgLoader in pairs(self.UmgLoaders) do
      local _umgPool = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetOrCreateSubHudPool, _subPanel)
      if _umgPool then
        _umgLoader:SetPool(_umgPool)
      end
    end
  end
end

function UMG_Hud_Pet_C:OnConstruct()
  self.mainUIModule = NRCModuleManager:GetModule("MainUIModule")
  if self.mainUIModule then
    self.mainUIModule:RegisterEvent(self, MainUIModuleEvent.OnGlobalPetHUDEnabledChanged, self.RefreshPetHUDByGlobal)
  end
  self.bIsPetBondVisible = nil
  self.bIsPetBondActive = nil
  self:RefreshPetHUDByGlobal()
end

function UMG_Hud_Pet_C:OnDestruct()
  self:CancelAllDelayProcess()
  self:UnloadAllSubPanel(false)
  if self.mainUIModule then
    self.mainUIModule:UnRegisterEvent(self, MainUIModuleEvent.OnGlobalPetHUDEnabledChanged)
  end
  _G.UpdateManager:UnRegister(self)
  self.delayHiddenFrame = nil
end

function UMG_Hud_Pet_C:SetVisible(visible)
  self:SetVisibility(visible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.bIsVisible = visible
  if not visible then
    if self.bOpenDialogueVisible then
      _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.FinishDialogOption, self.RealtimeDialogOptionID, self.RealtimeDialogDialogConf)
    end
    self:UnloadAllSubPanel(false)
    self:ClearData()
  end
end

function UMG_Hud_Pet_C:ResetData()
  self.ParentHeadWidget = nil
  self.CurPerceptionType = nil
  self.MainConfData = {}
  self.RealtimeDialogDialogKey = nil
  self.bTrackVisible = false
  self.bPerceptionVisible = false
  self.bOpenDialogueVisible = false
  self.bHomeOutputVisible = false
  self.bPlantStatusVisible = false
  self.bRoomExpanding = false
  self.bMessageStatusVisible = false
end

function UMG_Hud_Pet_C:ClearData()
  self.bTrackVisible = false
end

function UMG_Hud_Pet_C:CancelAllDelayProcess()
  if self.HudMainDelayRefreshId then
    _G.DelayManager:CancelDelayById(self.HudMainDelayRefreshId)
    self.HudMainDelayRefreshId = nil
  end
end

function UMG_Hud_Pet_C:UnloadAllSubPanel(_forceUnload)
  if self.UmgLoaders then
    for _, _UmgLoader in pairs(self.UmgLoaders) do
      _UmgLoader:UnLoadPanel(_forceUnload)
    end
  end
end

function UMG_Hud_Pet_C:ReturnToPool()
  self:CancelAllDelayProcess()
  self:UnloadAllSubPanel(true)
end

function UMG_Hud_Pet_C:AwakeFromPool()
  self:ResetData()
end

function UMG_Hud_Pet_C:LoadSubPanel(_SubPanel, ...)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    UmgLoader:SetPriority(PriorityEnum.UI_Hud_Pet)
    UmgLoader:LoadPanel(nil, ...)
  end
end

function UMG_Hud_Pet_C:UnLoadSubPanel(_SubPanel, _forceUnload)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    return UmgLoader:UnLoadPanel(_forceUnload)
  end
end

function UMG_Hud_Pet_C:GetSubPanel(_SubPanel)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    return UmgLoader:GetPanel()
  end
end

function UMG_Hud_Pet_C:DoRefreshHudMainStatus()
  self.HudMainDelayRefreshId = nil
  local _conf = self.MainConfData
  local visible = false
  if _conf then
    local showName = _conf.nameVisible and not string.IsNilOrEmpty(_conf.name)
    visible = showName or _conf.focusVisible or _conf.autoLockIconVisible or _conf.fightingVisible or not string.IsNilOrEmpty(_conf.petTypeIconPath) or _conf.titleVisible or _conf.MagicMessageVisible or _conf.traceNameVisible or not string.IsNilOrEmpty(_conf.ownerName)
  end
  self.bHudMainVisible = visible
  if visible then
    if _conf.onlyShowTitleIcon then
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:LoadSubPanel(SubPanel.MainPanel, _conf, self)
    self:SubmitChange()
  else
    local hudMain = self:GetSubPanel(SubPanel.MainPanel)
    if UE4.UObject.IsValid(hudMain) then
      hudMain:SetConfData(_conf)
      self:SubmitChange()
    end
  end
  self:CheckShouldHideInGame()
end

function UMG_Hud_Pet_C:RefreshHudMainStatus(_conf)
  if self.HudMainDelayRefreshId then
    return
  end
  self.HudMainDelayRefreshId = _G.DelayManager:DelayFrames(1, self.DoRefreshHudMainStatus, self)
end

function UMG_Hud_Pet_C:SetName(showName)
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self.MainConfData.name = showName
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetNameVisible(visible)
  self.MainConfData.nameVisible = visible
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetNameColor(color)
  self.MainConfData.nameColor = color
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:ShowAutoLockIcon(visible)
  self.MainConfData.autoLockIconVisible = visible
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetFocusVisible(visible)
  self.MainConfData.focusVisible = visible
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:ShowCatchPetType(petBaseConf, visible)
  if visible then
    local petType = petBaseConf and petBaseConf.unit_type[1]
    if petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType)
      if typeDic then
        self.MainConfData.petTypeIconPath = typeDic.type_icon
      end
    end
  else
    self.MainConfData.petTypeIconPath = nil
  end
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetFightingVisible(visible)
  if self.MainConfData.fightingVisible == visible then
    return
  end
  self.MainConfData.fightingVisible = visible
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetRoomExpandStatus(bRoomExpanding, bExpandFinish)
  self.bRoomExpanding = bRoomExpanding
  self:CheckPanelSize()
  if bRoomExpanding then
    self:LoadSubPanel(SubPanel.CountdownExpansion, self.ParentHeadWidget)
  else
    self:UnLoadSubPanel(SubPanel.CountdownExpansion)
  end
  if bExpandFinish then
    local Path = self.wait_expansion_icon and self.wait_expansion_icon.AssetPathName
    if Path and not self.MainConfData.titleIconExpand then
      self.MainConfData.titleIconExpand = self.MainConfData.titleIcon
    end
    self.MainConfData.titleIcon = Path
  elseif self.MainConfData.titleIconExpand then
    self.MainConfData.titleIcon = self.MainConfData.titleIconExpand
    self.MainConfData.titleIconExpand = nil
  end
  self.MainConfData.titleIconNoDraw = bRoomExpanding and not bExpandFinish
  self:SubmitChange()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetTitleInfo(title, titleIcon)
  self.MainConfData.title = title
  self.MainConfData.titleIcon = titleIcon
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetMagicMessageVisible(bVisible)
  self.MainConfData.name = ""
  self.MainConfData.MagicMessageVisible = bVisible
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetTitleVisible(bVisible)
  self.MainConfData.titleVisible = bVisible
  if bVisible and not self.MainConfData.nameVisible then
    self.MainConfData.onlyShowTitleIcon = true
  else
    self.MainConfData.onlyShowTitleIcon = false
  end
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:SetOwnerName(ownerName)
  if not self.MainConfData.ownerName or ownerName ~= self.MainConfData.ownerName then
    self.MainConfData.ownerName = ownerName
    self:CheckManuallyRedraw()
    self:CheckPanelSize()
    self:RefreshHudMainStatus(self.MainConfData)
  end
end

function UMG_Hud_Pet_C:SetTraceNameVisible(bVisible)
  self.MainConfData.name = ""
  self.MainConfData.traceNameVisible = bVisible
  self:CheckPanelSize()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:ShowTrackIcon(TaskID, bTurnOn)
  if self.bIsVisible then
    if self.bTrackVisible == bTurnOn then
      return
    end
    self.bTrackVisible = bTurnOn
    self:CheckManuallyRedraw()
    self:CheckPanelSize()
    if bTurnOn then
      self:LoadSubPanel(SubPanel.TrackPanel, TaskID)
    else
      self:UnLoadSubPanel(SubPanel.TrackPanel)
    end
    self:SubmitChange()
    self:DelayCheckShouldHideInGame()
  end
end

function UMG_Hud_Pet_C:ShowTrackingEnd()
  local TrackPanel = self:GetSubPanel(SubPanel.TrackPanel)
  if TrackPanel then
    TrackPanel:ShowTrackingEnd()
  end
end

function UMG_Hud_Pet_C:ShowProduction(bShow, ...)
  self.bHomeOutputVisible = bShow
  if bShow then
    local function temp(...)
      self:ChildNeedRefresh(...)
    end
    
    self:LoadSubPanel(SubPanel.HomeOutPutPanel, temp, ...)
  else
    self:UnLoadSubPanel(SubPanel.HomeOutPutPanel)
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
  self:RefreshHudMainStatus(self.MainConfData)
end

function UMG_Hud_Pet_C:ShowTopMessage(bShow, npc)
  self.bMessageStatusVisible = bShow
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  if bShow then
    self:LoadSubPanel(SubPanel.FeedHud, npc, self)
  else
    self:UnLoadSubPanel(SubPanel.FeedHud)
  end
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:UpdateHomeOutput(bInProduce, furnitureCoin)
  local outputPanel = self:GetSubPanel(SubPanel.HomeOutPutPanel)
  if outputPanel then
    outputPanel:UpdateStatus(bInProduce, furnitureCoin)
  end
end

function UMG_Hud_Pet_C:HighlightHomePetHud(bHighlight)
  local outputPanel = self:GetSubPanel(SubPanel.HomeOutPutPanel)
  if outputPanel then
    outputPanel:HighlightHomePetHud(bHighlight)
  end
end

function UMG_Hud_Pet_C:ShowPerceptionHead(npc, type, target)
  if self.CurPerceptionType == type then
    return
  end
  self.CurPerceptionType = type
  if self:IsShowPerceptionHead() then
    if type == SceneEnum.PerceptionHudType.GroupTarget then
      type = SceneEnum.PerceptionHudType.Perceive
    end
    self:SetPerceptionHeadVisible(true, true, npc, type, self, target)
  else
    self:SetPerceptionHeadVisible(false)
  end
end

function UMG_Hud_Pet_C:RemoveNpc()
  self:SetPerceptionHeadVisible(false)
end

function UMG_Hud_Pet_C:SetPerceptionHeadVisible(visible, ...)
  self.bPerceptionVisible = visible
  if visible then
    self:LoadSubPanel(SubPanel.PerceptionPanel, ...)
  else
    self:UnLoadSubPanel(SubPanel.PerceptionPanel)
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:IsShowPerceptionHead()
  return self.CurPerceptionType == SceneEnum.PerceptionHudType.Perceive or self.CurPerceptionType == SceneEnum.PerceptionHudType.TackAction or self.CurPerceptionType == SceneEnum.PerceptionHudType.HardAction or self.CurPerceptionType == SceneEnum.PerceptionHudType.GroupTarget
end

function UMG_Hud_Pet_C:SetDialogPanelVisible(bVisible, ...)
  self.bOpenDialogueVisible = bVisible
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  if bVisible then
    self:LoadSubPanel(SubPanel.DialogPanel, ...)
    if self.RealtimeDialogDialogKey then
      _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.UpdateDialogList, self.RealtimeDialogDialogKey, self.RealtimeDialogOptionID, true)
    end
  else
    if self.RealtimeDialogDialogKey then
      _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.UpdateDialogList, self.RealtimeDialogDialogKey, self.RealtimeDialogOptionID, false, self.RealtimeDialogDialogConf)
      self.RealtimeDialogDialogKey = nil
    end
    self:UnLoadSubPanel(SubPanel.DialogPanel)
  end
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:SetDialogPanelInfo(DialogKey, DialogConf, Actor, OptionID)
  local TrackPanel = self:GetSubPanel(SubPanel.TrackPanel)
  if TrackPanel then
    return
  end
  self.RealtimeDialogDialogKey = DialogKey
  self.RealtimeDialogDialogConf = DialogConf
  self.RealtimeDialogOptionID = OptionID
  self:SubmitChange()
  self:SetDialogPanelVisible(true, true, DialogKey, DialogConf, Actor, OptionID)
end

function UMG_Hud_Pet_C:OnRefreshPlantStatusPanel(visible, ...)
  self.bPlantStatusVisible = visible
  if visible then
    self:LoadSubPanel(SubPanel.PlantStatusPanel, ...)
  else
    self:UnLoadSubPanel(SubPanel.PlantStatusPanel)
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:SetPlantStatusVisible(visible, ...)
  self:OnRefreshPlantStatusPanel(visible, ...)
end

function UMG_Hud_Pet_C:OnRefreshFarmNpcStatus(...)
  local PlantStatusPanel = self:GetSubPanel(SubPanel.PlantStatusPanel)
  if PlantStatusPanel then
    PlantStatusPanel:OnRefreshStatus(self, ...)
  end
end

function UMG_Hud_Pet_C:SetVeryIntimateVisible(visible, active, ...)
  if self.bIsPetBondVisible == visible then
    return
  end
  Log.Debug("UMG_Hud_Pet_C:SetVeryIntimateVisible", visible)
  self.bIsPetBondVisible = visible
  if visible then
    self.bIsPetBondActive = active
    self:LoadSubPanel(SubPanel.VeryIntimate, self, ...)
    self:SetPlayingAnim(true, "PetBond")
  else
    self:UnLoadSubPanel(SubPanel.VeryIntimate)
    self:SetPlayingAnim(false, "PetBond")
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:SetPetBondActive(active, ...)
  if self.bIsPetBondActive == active then
    return
  end
  Log.Debug("UMG_Hud_Pet_C:SetPetBondActive", active)
  self.bIsPetBondActive = active
  local VeryIntimatePanel = self:GetSubPanel(SubPanel.VeryIntimate)
  if VeryIntimatePanel then
    VeryIntimatePanel:SetPetBondActive(active)
  end
end

function UMG_Hud_Pet_C:SetParentHUD(ParentHUD)
  self.ParentHeadWidget = ParentHUD
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
end

function UMG_Hud_Pet_C:SubmitChange()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    self.ParentHeadWidget:RequestRedraw()
  end
end

function UMG_Hud_Pet_C:SetPlayingAnim(bPlaying, flag)
  if not flag then
    Log.Error("SetPlayingAnim: should set flag!")
    return
  end
  local inPlayingAnim = self.inPlayingAnim
  if not inPlayingAnim then
    inPlayingAnim = {}
    self.inPlayingAnim = inPlayingAnim
  end
  if bPlaying then
    inPlayingAnim[flag] = true
  else
    inPlayingAnim[flag] = nil
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:CheckShouldHideInGame()
end

function UMG_Hud_Pet_C:IsPlayingAnim()
  local inPlayingAnim = self.inPlayingAnim
  return inPlayingAnim and next(inPlayingAnim) ~= nil
end

function UMG_Hud_Pet_C:ChildNeedRefresh(caller, name)
  if not (caller and name) or not self:GetSubPanel(name) then
    return
  end
  self:CheckManuallyRedraw()
  self:CheckPanelSize()
  self:SubmitChange()
  self:DelayCheckShouldHideInGame()
end

function UMG_Hud_Pet_C:CheckManuallyRedraw()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    local result = not self:IsPlayingAnim() and not self.bOpenDialogueVisible and not self.bPerceptionVisible and not self.bMessageStatusVisible and not self.bTrackVisible and not self.bPlantStatusVisible or DeviceUtils.OptimizeNameLabel()
    self.ParentHeadWidget:SetManuallyRedraw(result)
    return result
  end
  return false
end

function UMG_Hud_Pet_C:CheckPanelSize()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    local MainConfData = self.MainConfData
    local result = not self:IsPlayingAnim() and not self.bOpenDialogueVisible and not self.bPerceptionVisible and not self.bTrackVisible and not self.bHomeOutputVisible and not self.bPlantStatusVisible and not self.bRoomExpanding and not self.bMessageStatusVisible and MainConfData and not MainConfData.autoLockIconVisible and not MainConfData.focusVisible and not MainConfData.titleVisible and not MainConfData.fightingVisible and string.IsNilOrEmpty(MainConfData.ownerName)
    self.bNameOnly = result
    local desiredDrawSize = self:GetDynamicPanelDesiredDrawSize()
    if self.ParentHeadWidget.DrawSize ~= desiredDrawSize then
      self.ParentHeadWidget.DrawSize = desiredDrawSize
    end
  end
end

function UMG_Hud_Pet_C:GetDynamicPanelDesiredDrawSize()
  if self.bNameOnly then
    return NameLabelDrawSize.MainPanel
  elseif self:CheckPanelSizePlantStatus() then
    return NameLabelDrawSize.PlantStatusPanel
  elseif self:CheckPanelSizeTraceName() then
    return NameLabelDrawSize.TraceNamePanel
  elseif self:CheckPanelSizePenTraceName() then
    return NameLabelDrawSize.TraceNamePanel
  else
    return NameLabelDrawSize.Default
  end
end

function UMG_Hud_Pet_C:CheckPanelSizePlantStatus()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    return not self.bOpenDialogueVisible and self.bPlantStatusVisible
  end
end

function UMG_Hud_Pet_C:CheckPanelSizeTraceName()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    return self.MainConfData.traceNameVisible
  end
end

function UMG_Hud_Pet_C:CheckPanelSizePenTraceName()
  if UE.UObject.IsValid(self.ParentHeadWidget) then
    return self.MainConfData.MagicMessageVisible
  end
end

function UMG_Hud_Pet_C:DelayCheckShouldHideInGame()
  if not self.delayHiddenFrame then
    _G.UpdateManager:Register(self)
  end
  self.delayHiddenFrame = 2
end

function UMG_Hud_Pet_C:CheckShouldHideInGame()
  local headWidget = self.ParentHeadWidget
  if headWidget and UE.UObject.IsValid(headWidget) then
    local hasAnyVisibleHud = self:IsPlayingAnim() or self.bHudMainVisible or self.bPerceptionVisible or self.bOpenDialogueVisible or self.bTrackVisible or self.bPlantStatusVisible or self.bRoomExpanding or self.bHomeOutputVisible
    headWidget:SetRenderStatus(hasAnyVisibleHud, MainUIModuleEnum.DisableHudOpSource.EmptyHudEle)
    headWidget:SetRenderStatus(self.bGlobalPetHUDEnabled, MainUIModuleEnum.DisableHudOpSource.GlobalForbid)
  end
end

function UMG_Hud_Pet_C:OnTick()
  if not self.delayHiddenFrame then
    _G.UpdateManager:UnRegister(self)
    Log.Error("zgx delayHiddenFrame is nil")
    return
  end
  if self.delayHiddenFrame > 0 then
    self.delayHiddenFrame = self.delayHiddenFrame - 1
    return
  end
  self:CheckShouldHideInGame()
  _G.UpdateManager:UnRegister(self)
  self.delayHiddenFrame = nil
end

function UMG_Hud_Pet_C:RefreshPetHUDByGlobal()
  self.bGlobalPetHUDEnabled = not self.mainUIModule or self.mainUIModule.bGlobalPetHUDEnabled
  self:CheckShouldHideInGame()
end

return UMG_Hud_Pet_C

local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local BigMapModuleEnum = require("NewRoco.Modules.System.BigMap.BigMapModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local UMG_MapRightPanel_C = _G.NRCPanelBase:Extend("UMG_MapRightPanel_C")

function UMG_MapRightPanel_C:Initialize(Initializer)
  self.playAniEffect = true
  self.curSubPanelIndex = -1
end

function UMG_MapRightPanel_C:OnConstruct()
  self:SetChildViews(self.npcInfo, self.MarkerInfo, self.MarkerPanel_New)
  self:OnAddEventListener()
  self.WorkingContext = {}
end

function UMG_MapRightPanel_C:OnDestruct()
  self.module:SetMapPanelCanTouchMove(true)
end

function UMG_MapRightPanel_C:OnEnable()
end

function UMG_MapRightPanel_C:OnDisable()
end

function UMG_MapRightPanel_C:OnActive(Type, _info, worldMapCfg, rspInfo)
  if _G.GlobalConfig.DebugOpenUI then
    if self.npcInfo.NPCTypeSwitcher then
      self.npcInfo.NPCTypeSwitcher:SetActiveWidgetIndex(3)
    end
    return
  end
  self.map_show_tip_type = worldMapCfg and worldMapCfg.map_tips_show_type
  self.npc_refresh_id = _info and _info.npc_refresh_id
  self:ShowPanel(Type, _info, worldMapCfg, rspInfo)
end

function UMG_MapRightPanel_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseButtonClicked)
end

function UMG_MapRightPanel_C:OnTick(InDeltaTime)
  if self.npcInfo and self.npcInfo.RefreshTeamBattleTimeText and not BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
    self.npcInfo:RefreshTeamBattleTimeText()
  end
end

function UMG_MapRightPanel_C:OnRemoveEventListener()
end

function UMG_MapRightPanel_C:OnCloseButtonClicked()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  self:DispatchEvent(BigMapModuleEvent.ShowMapHint, true)
  self:DispatchEvent(BigMapModuleEvent.ShowSanctuary, true)
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.HideOwlTips)
  Log.Debug("[TxTest]UMG_MapRightPanel_C:OnCloseButtonClicked", self.playAniEffect)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008020, "UMG_MapRightPanel_C:OnCloseButtonClicked")
  if self.playAniEffect then
    self:PlayAnimation(self.Out)
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.CloseOwlTips)
    if self.curSubPanelIndex and self.curSubPanelIndex >= 0 then
      local subPanel = self.switcherPanels:GetWidgetAtIndex(self.curSubPanelIndex)
      if subPanel then
        subPanel:OnPanelShow(false)
      end
    end
  else
    self:DispatchEvent(BigMapModuleEvent.MainMapRightPanelHide, self.map_show_tip_type, self.npc_refresh_id)
  end
  self.WorkingContext = {}
end

function UMG_MapRightPanel_C:HiddenPanel()
  self:OnCloseButtonClicked()
end

function UMG_MapRightPanel_C:ShowPanel(_subIndex, _data, worldMap, dungeonInfo)
  Log.Debug("[TxTest]UMG_MapRightPanel_C:ShowPanel", _subIndex)
  local count = self.switcherPanels:GetNumWidgets()
  if _subIndex and _subIndex >= 0 and _subIndex < count then
    if 0 == _subIndex then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008019, "UMG_MapRightPanel_C:ShowPanel")
    elseif 1 == _subIndex then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008019, "UMG_MapRightPanel_C:ShowPanel")
    end
    self.switcherPanels:SetActiveWidgetIndex(_subIndex)
    local subPanel = self.switcherPanels:GetWidgetAtIndex(_subIndex)
    local bSameContext = self:IsSameWorkingContext(_subIndex, _data, worldMap)
    if subPanel.InitPanelData then
      subPanel:InitPanelData(_data, worldMap, dungeonInfo, not bSameContext)
    end
    self.curSubPanelIndex = _subIndex
    if self.playAniEffect and not bSameContext then
      _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
      self:PlayAnimation(self.Open)
      if 0 ~= _subIndex then
        subPanel:OnPanelShow(true)
      else
      end
    end
  end
end

function UMG_MapRightPanel_C:OnAnimationFinished(Animation)
  if Animation == self.Open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  elseif Animation == self.Out then
    self:DispatchEvent(BigMapModuleEvent.MainMapRightPanelHide, self.map_show_tip_type, self.npc_refresh_id)
    self:DoClose()
  end
end

function UMG_MapRightPanel_C:IsSameWorkingContext(...)
  local newWorkingContext = {
    ...
  }
  if self.WorkingContext == nil then
    self.WorkingContext = newWorkingContext
    return false
  elseif type(self.WorkingContext) == "table" then
    local bNewDifference = false
    local bEmptyTable = true
    local prevSubIndex = self.WorkingContext[1]
    local newSubIndex = newWorkingContext[1]
    if prevSubIndex ~= newSubIndex then
      bNewDifference = true
    else
      if 3 == newSubIndex then
        bNewDifference = true
      end
      for k, v in ipairs(self.WorkingContext) do
        bEmptyTable = false
        if 3 == newSubIndex then
          if 2 == k and v and newWorkingContext[k] and v.MarkerData == newWorkingContext[k].MarkerData then
            bNewDifference = false
            break
          end
        elseif newWorkingContext[k] ~= v then
          bNewDifference = true
          break
        end
      end
    end
    bNewDifference = bEmptyTable or bNewDifference
    if bNewDifference then
      self.WorkingContext = newWorkingContext
    end
    return not bNewDifference
  end
  return false
end

return UMG_MapRightPanel_C

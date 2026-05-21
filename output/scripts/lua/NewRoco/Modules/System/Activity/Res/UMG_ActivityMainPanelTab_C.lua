local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_ActivityMainPanelTab_C = Base:Extend("UMG_ActivityMainPanelTab_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_ActivityMainPanelTab_C:OnConstruct()
  if self.InvalidationBox_0 then
    self.InvalidationBox_0:SetCanCache(false)
  end
end

function UMG_ActivityMainPanelTab_C:OnDestruct()
  self.updatedFlag = false
  self:CancelPlayLoopAnim()
  local _activityInst = self.activityInst
  if _activityInst then
    _activityInst:RemoveEventListener(self, ActivityModuleEvent.CompositedActivitySelectChange, self.OnRefreshView)
  end
end

function UMG_ActivityMainPanelTab_C:OnItemUpdate(_data, datalist, index)
  self.activityInst = _data
  self.index = index
  self.bSelected = false
  local _activityInst = self.activityInst
  if _activityInst then
    self:OnRefreshView()
    _activityInst:RemoveEventListener(self, ActivityModuleEvent.CompositedActivitySelectChange, self.OnRefreshView)
    _activityInst:AddEventListener(self, ActivityModuleEvent.CompositedActivitySelectChange, self.OnRefreshView)
    local mainTabId = _activityInst:GetActivityMainTabId()
    local redPointId
    if _activityInst:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY then
      redPointId = 487
    else
      redPointId = ActivityUtils.GetTabRedPoint(mainTabId)
    end
    if redPointId then
      local extraKeyList = _activityInst:GetTabRedPointExtraKeyList()
      self.redPointSpecial:EnableAnimation()
      self.redPointSpecial:SetupKey(redPointId, nil, extraKeyList)
      self.redPointSpecial:SetRedStatusChangeListener(self, self.OnRedPointSpecialStatusChange)
    else
      self.redPointSpecial:SetupKey(0)
    end
  end
  self:OnRedPointSpecialStatusChange(self.redPointSpecial, self.redPointSpecial:IsRed())
  if not self.updatedFlag then
    self.updatedFlag = true
    self:StopAllAnimations()
    self:PlayAnimation(self.normal)
  end
end

function UMG_ActivityMainPanelTab_C:OnRedPointSpecialStatusChange(redPoint, isRed)
  local activityInst = self.activityInst
  if isRed or not activityInst then
    self.redPointNew:SetupKey(0)
  else
    local newRedKey
    if activityInst:GetActivityBelongSystem() == _G.Enum.BelongSystem.BS_RECALL_ACTIVITY then
      newRedKey = 488
    else
      newRedKey = ActivityEnum.RedPointKey.NewActivity
    end
    self.redPointNew:SetupKey(newRedKey, {
      tostring(activityInst:GetActivityId())
    })
    if self.bSelected and self.redPointNew:IsRed() then
      self.activityInst:EraseNewActivityRedPoint()
    end
  end
end

function UMG_ActivityMainPanelTab_C:OnDespawn()
  if self._parent and self._parent._selectedItemIndex == self.index then
    self.updatedFlag = false
    self:CancelPlayLoopAnim()
  end
end

function UMG_ActivityMainPanelTab_C:OnRefreshView()
  local _activityInst = self.activityInst
  if _activityInst then
    self.Title:SetText(_activityInst:GetActivityName())
    local iconSelect, iconNormal = _activityInst:GetActivityIcon()
    if iconSelect then
      self.selectImg:SetPath(iconSelect)
    end
    if iconNormal then
      self.icon:SetPath(iconNormal)
    end
  end
end

function UMG_ActivityMainPanelTab_C:OnItemSelected(_bSelected)
  self.bSelected = _bSelected
  self:StopAllAnimations()
  self:CancelPlayLoopAnim()
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_ActivityMainPanelTab_C:OnItemSelected")
    local _activityInst = self.activityInst
    if _activityInst then
      _activityInst:SendEvent(ActivityModuleEvent.LoadActivityView, _activityInst)
      _G.GEMPostManager:SendActivityTLog(_activityInst:GetActivityId())
      _activityInst:EraseNewActivityRedPoint()
      if _activityInst:GetActivityType() == ActivityEnum.ActivityTypeSpecial.UnknownActivity then
        _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.unupdated_activity_tip)
      end
    end
    self:PlayAnimation(self.change1)
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_ActivityMainPanelTab_C:OpItem(opType)
  if opType == ActivityEnum.ActivityTabOpType.GetHasRedPoint then
    return self.redPointSpecial:IsRed() or self.redPointNew:IsRed()
  end
end

function UMG_ActivityMainPanelTab_C:OnAnimationFinished(anim)
  if self.bSelected then
    if anim == self.change1 then
      self:StartPlayLoopAnim()
    elseif anim == self.select_loop then
      self:CancelPlayLoopAnim()
      self.playLoopDelayId = _G.DelayManager:DelaySeconds(3, self.OnDelayPlayLoopAnim, self)
    end
  end
end

function UMG_ActivityMainPanelTab_C:StartPlayLoopAnim()
  if self and UE4.UObject.IsValid(self) then
    self:PlayAnimation(self.select_loop)
  end
end

function UMG_ActivityMainPanelTab_C:OnDelayPlayLoopAnim()
  self.playLoopDelayId = nil
  self:StartPlayLoopAnim()
end

function UMG_ActivityMainPanelTab_C:CancelPlayLoopAnim()
  if self.playLoopDelayId then
    _G.DelayManager:CancelDelayById(self.playLoopDelayId)
    self.playLoopDelayId = nil
  end
end

return UMG_ActivityMainPanelTab_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_Tab_C = Base:Extend("UMG_ActivityMainPanelTab_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_Tab_C:OnConstruct()
end

function UMG_Activity_Tab_C:OnDestruct()
  self:CancelPlayLoopAnim()
end

function UMG_Activity_Tab_C:OnItemUpdate(_data, datalist, index)
  self.mainTabId = _data.mainTabId
  self.index = index
  self.bSelected = false
  local mainTabConf = _G.DataConfigManager:GetActivityMaintabConf(self.mainTabId)
  if mainTabConf then
    self.selectImg:SetPath(mainTabConf.maintab_icon_select)
    self.icon:SetPath(mainTabConf.maintab_icon)
    local redPointIds = {
      304,
      305,
      306
    }
    local mainTabId = mainTabConf.id
    if mainTabId > 0 and mainTabId <= #redPointIds then
      if 3 == mainTabId then
        self.RedDot:ClearIgnoreRedPointDataList()
        self.RedDot:SetIgnoreRedPointDataList(Enum.RedPointReason.RPR_ACTIVITY_TAB_NOTIFY, {300006})
      end
      self.RedDot:SetupKey(redPointIds[mainTabId], nil, _data.extraKeyList)
    else
      Log.ErrorFormat("\229\136\134\233\161\181[%d]\231\188\186\229\176\145\231\186\162\231\130\185\233\133\141\231\189\174!", mainTabId)
    end
  end
  self:PlayAnimation(self.change2)
end

function UMG_Activity_Tab_C:OnItemSelected(_bSelected)
  self.bSelected = _bSelected
  self:StopAllAnimations()
  self:CancelPlayLoopAnim()
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_Activity_Tab_C:OnItemSelected")
    ActivityUtils.DispatchEvent(ActivityModuleEvent.FilterActivityMainTab, self.mainTabId)
    self:PlayAnimation(self.change1)
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_Activity_Tab_C:OpItem(opType)
  if opType == ActivityEnum.ActivityTabOpType.GetHasRedPoint then
    return self.RedDot:IsRed()
  end
end

function UMG_Activity_Tab_C:OnAnimationFinished(anim)
  if self.bSelected then
    if anim == self.change1 then
      self:StartPlayLoopAnim()
    elseif anim == self.select_loop then
      self:CancelPlayLoopAnim()
      self.playLoopDelayId = _G.DelayManager:DelaySeconds(3, self.StartPlayLoopAnim, self)
    end
  end
end

function UMG_Activity_Tab_C:StartPlayLoopAnim()
  if UE4.UObject.IsValid(self) then
    self.playLoopDelayId = nil
    self:PlayAnimation(self.select_loop)
  end
end

function UMG_Activity_Tab_C:CancelPlayLoopAnim()
  if self.playLoopDelayId then
    _G.DelayManager:CancelDelayById(self.playLoopDelayId)
    self.playLoopDelayId = nil
  end
end

return UMG_Activity_Tab_C

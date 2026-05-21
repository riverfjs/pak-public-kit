local UMG_PeerTask_C = _G.NRCPanelBase:Extend("UMG_PeerTask_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_PeerTask_C:OnConstruct()
  self:SetChildViews(self.PopUp)
  self:SetCommonPopUpInfo()
  self:RegisterEvent(self, ActivityModuleEvent.RefreshLimitTimeAppearActivityData, self.OnRefreshLimitTimeAppearActivityData)
end

function UMG_PeerTask_C:OnDestruct()
  self:RemoveAllButtonListener()
  self:RemoveAllDelegateListener()
end

function UMG_PeerTask_C:OnActive(param)
  self:LoadAnimation(0)
  if not param then
    Log.Error("param is nil")
    return
  end
  self.activityInst = param
  self.priorityOrder = {
    [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT] = 1,
    [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN] = 2,
    [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH] = 3,
    [ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE] = 4
  }
  local conf = self.activityInst:GetActivityConf()
  if conf then
    self.PopUp:SetTitleTextInfo(conf.option_txt2)
  end
  self:RefreshView()
end

function UMG_PeerTask_C:RefreshView()
  local listData = {}
  local conditionIds = self.activityInst:GetConditionIds()
  if conditionIds and #conditionIds > 0 then
    for i, v in ipairs(conditionIds) do
      local state = self.activityInst:GetConditionState(v) or ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
      local curProgress, totalProgress, RequiredType = self.activityInst:GetConditionProgress(v)
      table.insert(listData, {
        conditionId = v,
        state = state,
        curProgress = curProgress,
        totalProgress = totalProgress
      })
    end
  end
  if #listData > 1 then
    table.sort(listData, function(a, b)
      return self.priorityOrder[a.state] < self.priorityOrder[b.state]
    end)
  end
  self.List:SetCustomData({
    activityInst = self.activityInst
  })
  self.List:InitList(listData)
end

function UMG_PeerTask_C:OnRefreshLimitTimeAppearActivityData(_activityId, _partData)
  if self.activityInst and _activityId == self.activityInst:GetActivityId() then
    if self.activityInst:IsActivityInactive() then
      ActivityUtils.ShowActivityExpiredTips()
      self:OnClose()
      return
    end
    self:RefreshView()
  end
end

function UMG_PeerTask_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_PeerTask_C:OnPcClose()
  self:OnClose()
end

function UMG_PeerTask_C:OnClose()
  self:LoadAnimation(2)
  self:DoClose()
end

function UMG_PeerTask_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_PeerTask_C

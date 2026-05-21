local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local UMG_Activity_Kitten_C = Base:Extend("UMG_Activity_Kitten_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_Activity_Kitten_C:BindUIElements()
  local uiElements = {}
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.titleLabelText = self.NRCText_61
  uiElements.titleLabelIcon = self.Label
  uiElements.bgImage = self.BG
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_Kitten_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
  self:RefreshView()
  self:CheckShowTraceBtn()
end

function UMG_Activity_Kitten_C:OnDestruct()
  Base.OnDestruct(self)
  self:RemoveAllButtonListener()
  self:RemoveAllDelegateListener()
end

function UMG_Activity_Kitten_C:OnAddEventListener()
  self:AddButtonListener(self.ExamineBtn, self.OpenPetPanel)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTraceBtnClick)
  self:AddButtonListener(self.PeerTaskBtn.btnLevelUp, self.OnPeerTaskBtnClick)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshLimitTimeAppearActivityData, self.OnRefreshLimitTimeAppearActivityData)
end

function UMG_Activity_Kitten_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  if self.activityInst then
    self.activityInst:RefreshAllConditionProgress()
  end
end

function UMG_Activity_Kitten_C:OnRefreshLimitTimeAppearActivityData(_activityId, _partData)
  if self.activityInst and _activityId == self.activityInst:GetActivityId() then
    self:RefreshView()
  end
end

function UMG_Activity_Kitten_C:RefreshView()
  local petBaseId = self.activityInst:GetPetBaseId()
  if petBaseId and 0 ~= petBaseId then
    local petBaseData = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextName:SetText(petBaseData and petBaseData.name or "")
    self.Attr:InitGridView(ActivityUtils.CreatePetCommonAttrListData(petBaseData and petBaseData.unit_type, nil, nil, PetUtils.CreateFakePetData(petBaseId)))
  else
    self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.PeerTaskBtn.RedDot:SetRedPointUIType(Enum.RedPointType.RPT_AWARD, self.activityInst:CanGetReward())
  local conf = self.activityInst:GetActivityConf()
  if conf then
    self.TraceBtn:SetBtnText(conf.option_txt1)
    self.PeerTaskBtn:SetBtnText(conf.option_txt2)
    if conf.condition_id and #conf.condition_id > 0 and not self.activityInst:IsActivityInactive() then
      self.PeerTaskBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.PeerTaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if self.PetImage then
    self.PetImage:SetPath(conf and conf.pet_img1 or "")
    if conf and conf.pet_img1_zoom then
      self.PetImage:SetRenderScale(UE4.FVector2D(conf.pet_img1_zoom, conf.pet_img1_zoom))
    end
  end
  if self.CartoonImage then
    self.CartoonImage:SetPath(conf and conf.pet_img2 or "")
  end
end

function UMG_Activity_Kitten_C:OpenPetPanel()
  local petBaseId = self.activityInst:GetPetBaseId()
  if petBaseId and 0 ~= petBaseId then
    _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_Kitten_C:OpenPetPanel")
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petBaseId, true)
  end
end

function UMG_Activity_Kitten_C:OnTraceBtnClick()
  if self.activityInst:IsActivityInactive() then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  local trackType, trackParams = self.activityInst:GetTrackTypeAndParams()
  if not trackParams or 0 == #trackParams then
    return
  end
  if trackType == Enum.ActivityTrackType.ATKT_WORLD_MAP then
    local worldMapConf = _G.DataConfigManager:GetWorldMapConf(trackParams[1])
    if worldMapConf then
      local refreshIds = worldMapConf.npc_refresh_ids
      if refreshIds and #refreshIds > 0 then
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap, {
          centerNPCRefreshId = refreshIds[1]
        })
      end
    end
  elseif trackType == Enum.ActivityTrackType.ATKT_PETBASE then
    _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_Activity_Kitten_C:OnTraceBtnClick")
    ActivityUtils.RequestTracePetWithContentIds(self.activityInst:GetTrackContentIds(), trackParams, self.activityInst)
  end
end

function UMG_Activity_Kitten_C:OnPeerTaskBtnClick()
  if self.activityInst:IsActivityInactive() then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenPeerTask, self.activityInst)
end

function UMG_Activity_Kitten_C:CheckShowTraceBtn()
  local isHide = false
  local trackConditions = self.activityInst:GetTrackConditions()
  if trackConditions then
    for _, hideTimeData in ipairs(trackConditions) do
      local startTime = 0
      if not string.IsNilOrEmpty(hideTimeData.hide_track_start) then
        startTime = ActivityUtils.ToTimestamp(hideTimeData.hide_track_start)
      end
      local endTime = 0
      if not string.IsNilOrEmpty(hideTimeData.hide_track_end) then
        endTime = ActivityUtils.ToTimestamp(hideTimeData.hide_track_end)
      end
      local serverTimestamp = ActivityUtils.GetSvrTimestamp()
      if startTime <= serverTimestamp and endTime >= serverTimestamp then
        isHide = true
        break
      end
    end
  end
  if isHide then
    self.TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.TraceBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

return UMG_Activity_Kitten_C

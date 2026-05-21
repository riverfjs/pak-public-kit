local UMG_PartnerAndPeer_C = _G.NRCPanelBase:Extend("UMG_PartnerAndPeer_C")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local TimeoutEventListener = require("Common.TimeoutEventListener")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")

function UMG_PartnerAndPeer_C:OnConstruct()
  self.FollowUITypeList = {
    None = 0,
    AcceptTask = 1,
    CancelTrack = 2,
    ConfirmTrack = 3,
    OutArea = 4,
    InArea = 5,
    FinishTask = 6
  }
  self.FollowAnimTypeList = {
    None = 0,
    In = 1,
    Out = 2
  }
  self.CurFollowUIType = self.FollowUITypeList.None
  self.ShowTipsText = ""
  self.IsWaitBackGroundAnim = false
  self.IsWaitTaskDialogFinish = false
  self.DefaultConfId = nil
  self.IsWaitAcceptTaskAnim = false
  self.DefaultCache = nil
  self.IsWaitLastTaskAnim = false
  self.NextTaskDialogCache = nil
  self.IsLoadingPanel = false
  self.TipsCallBack = nil
  self.OldState = Enum.NpcFollowState.NFS_NONE
  self.CurState = Enum.NpcFollowState.NFS_NONE
  self.IsStartTaskWaitDialogFinish = false
  self.IsDialogueEndShow = false
  self.IsTipsPanelShow = false
  self.IsRolePlayPanelShow = false
  self.IsExitVisitWaitLoadingPanelClose = false
  self.IsVisitHintPanelShow = false
  self.NameLimitCount = 10
  self.DefaultLimitCount = 10
  self.ContentLimitCount = 30
  self.Handler = nil
  self.IsPlayMapTips = false
  self.IsJoinVisitWaitLoadingPanelClose = false
  self.FollowId = nil
  self.ConfId = nil
  self.IsPlayDialogue = false
  self.DialogueTypeList = {
    none = 0,
    default = 1,
    dialogue = 2
  }
  self.CurDialogueType = self.DialogueTypeList.none
  self.SoundSession = -1
  self.IsRelogin = false
  self.DelayHandle = nil
  self.EventListener = TimeoutEventListener()
  self:OnAddEventListener()
end

function UMG_PartnerAndPeer_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_PartnerAndPeer_C:OnActive(data)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==000")
  local newFollowDataCache = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetNewFollowDataCache)
  if not data and not newFollowDataCache then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==111")
    self:InitFollowUI()
    return
  end
  if newFollowDataCache then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==222")
    local followData = {}
    table.deepCopy(newFollowDataCache, followData)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetNewFollowDataCache, nil)
    self:HidePanel()
    self:OnShowNPCFollowUI(followData)
  elseif data.IsVisit then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==333")
    self:VisitExitByPanelHasOpen(data.followData)
  elseif data.IsJoinVisit then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==444")
    self:JoinVisit()
  elseif data.isRelogin then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnActive==555")
    self:OnReloginRefreshFollowData(data.followData)
  end
end

function UMG_PartnerAndPeer_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.LoadingPanelClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.LoadingPanelOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.CLOSE_NORMAL_BLACK, self.BlackGroundFadeOut)
  _G.NRCEventCenter:RegisterEvent(self.name, self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.LOBBY_DOWN_TIPS_START, self.LobbyDownTipsStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.LOBBY_DOWN_TIPS_END, self.LobbyDownTipsEnd)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ROLE_PLAY_PANEL_OPEN, self.RolePlayPanelOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ROLE_PLAY_PANEL_CLOSE, self.RolePlayPanelClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.VISIT_HINT_PANEL_OPEN, self.VisitHintPanelOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.VISIT_HINT_PANEL_CLOSE, self.VisitHintPanelClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TipsModuleEvent.TopHud_StartPlayMapTips, self.OnTipsStartPlay)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TipsModuleEvent.TopHud_EndPlayMapTips, self.OnTipsEndPlay)
end

function UMG_PartnerAndPeer_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.LoadingPanelClose)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.LoadingPanelOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.CLOSE_NORMAL_BLACK, self.BlackGroundFadeOut)
  _G.NRCEventCenter:UnRegisterEvent(self, DialogueModuleEvent.DialogueEnded, self.OnDialogueEnded)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.LOBBY_DOWN_TIPS_START, self.LobbyDownTipsStart)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.LOBBY_DOWN_TIPS_END, self.LobbyDownTipsEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ROLE_PLAY_PANEL_OPEN, self.RolePlayPanelOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ROLE_PLAY_PANEL_CLOSE, self.RolePlayPanelClose)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.VISIT_HINT_PANEL_OPEN, self.VisitHintPanelOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.VISIT_HINT_PANEL_CLOSE, self.VisitHintPanelClose)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnMainUIOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.TopHud_StartPlayMapTips, self.OnTipsStartPlay)
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.TopHud_EndPlayMapTips, self.OnTipsEndPlay)
end

function UMG_PartnerAndPeer_C:InitFollowUI()
  local followData = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerFollowInfo)
  if not followData then
    self.CurState = Enum.NpcFollowState.NFS_NONE
    self:HidePanel()
    return
  end
  if followData.state and followData.state == Enum.NpcFollowState.NFS_ENABLE then
    self.CurState = Enum.NpcFollowState.NFS_ENABLE
    self.FollowId = followData.follow_id
    self.ConfId = followData.default_talk_id
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      self:HidePanel()
    else
      self:ShowFollowUIByOpenPanel()
    end
  else
    self:HidePanel()
  end
end

function UMG_PartnerAndPeer_C:OnShowNPCFollowUI(followData)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==111")
  if self.IsExitVisitWaitLoadingPanelClose then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==222")
    self.CurState = followData.new_state
    self.OldState = followData.old_state
    self:SetFollowData(followData)
    return
  end
  local oldState = followData.old_state
  local newState = followData.new_state
  self.CurState = newState
  self.OldState = oldState
  if oldState == Enum.NpcFollowState.NFS_NONE and newState == Enum.NpcFollowState.NFS_ENABLE then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==333")
    if self.IsWaitLastTaskAnim then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==444")
      self.NextTaskDialogCache = followData
    else
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==555")
      self:SetFollowData(followData)
      self.CurFollowUIType = self.FollowUITypeList.AcceptTask
      local followConf = _G.DataConfigManager:GetNpcFollowConf(self.FollowId)
      if followConf.hide_blackscreen then
        Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==666")
        if self.ConfId then
          Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==777")
          self.EventListener:StartGlobalEventListener(2, "UMG_PartnerAndPeer_C", self, TaskModuleEvent.TipsPerformFinished, self.StartTask)
          self.IsWaitAcceptTaskAnim = true
        end
      else
        Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==888")
        self:ShowBlackGround()
      end
    end
  elseif oldState == Enum.NpcFollowState.NFS_ENABLE and newState == Enum.NpcFollowState.NFS_TASK_UNTRACK then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==999")
    self:SetFollowData(followData)
    self.CurFollowUIType = self.FollowUITypeList.CancelTrack
    local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_change_off")
    self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
    self:ShowTips()
    self:PlayFollowUIAnim(false)
  elseif oldState == Enum.NpcFollowState.NFS_TASK_UNTRACK and newState == Enum.NpcFollowState.NFS_ENABLE then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==aaa")
    self:SetFollowData(followData)
    self.CurFollowUIType = self.FollowUITypeList.ConfirmTrack
    local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_change_on")
    self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
    self:ShowTips()
    self:ShowFollowUIByOpenPanel()
  elseif oldState == Enum.NpcFollowState.NFS_ENABLE and newState == Enum.NpcFollowState.NFS_OUT_AREA then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==bbb")
    self:SetFollowData(followData)
    self.CurFollowUIType = self.FollowUITypeList.OutArea
    local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_area_out")
    self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
    self:ShowTips()
    self:PlayFollowUIAnim(false)
  elseif oldState == Enum.NpcFollowState.NFS_OUT_AREA and newState == Enum.NpcFollowState.NFS_ENABLE then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==ccc")
    self:SetFollowData(followData)
    self.CurFollowUIType = self.FollowUITypeList.InArea
    local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_area_in")
    self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
    self:ShowTips()
    self:ShowFollowUIByOpenPanel()
  elseif oldState == Enum.NpcFollowState.NFS_ENABLE and newState == Enum.NpcFollowState.NFS_DISABLE then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==ddd")
    self:SetFollowData(followData)
    self.CurFollowUIType = self.FollowUITypeList.FinishTask
    self.IsWaitLastTaskAnim = true
    if self:CheckIsInDialog() then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==eee")
      self.IsWaitTaskDialogFinish = true
    else
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==fff")
      self:FinishTask()
    end
  elseif oldState == Enum.NpcFollowState.NFS_NONE and newState == Enum.NpcFollowState.NFS_OUT_AREA then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==ggg")
  elseif oldState == newState then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowNPCFollowUI==hhh")
    self:SetFollowData(followData)
    self:ShowFollowUIByOpenPanel()
  end
end

function UMG_PartnerAndPeer_C:UpdateFollowUI()
  self:OnShowUI(self.FollowId, self.ConfId)
end

function UMG_PartnerAndPeer_C:ShowBlackGround()
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.OpenNormalBlack, 0.5)
  self.IsWaitBackGroundAnim = true
end

function UMG_PartnerAndPeer_C:ShowTips(isNotHide)
  local followConf = _G.DataConfigManager:GetNpcFollowConf(self.FollowId)
  if self.CurFollowUIType == self.FollowUITypeList.AcceptTask then
    if followConf.hide_start_tips then
      return
    end
  elseif self.CurFollowUIType == self.FollowUITypeList.FinishTask and followConf.hide_end_tips then
    return
  end
  
  local function cb()
    local globalConfig = _G.DataConfigManager:GetGlobalConfig("follow_tips_time", true)
    local showTime = 10
    if globalConfig then
      showTime = globalConfig.num
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, self.ShowTipsText, nil, nil, showTime, isNotHide)
  end
  
  if self.IsLoadingPanel then
    self.TipsCallBack = cb
  else
    self.TipsCallBack = cb
    self:ExecuteTipsCallBack()
  end
end

function UMG_PartnerAndPeer_C:PlayFollowUIAnim(isShow)
  if isShow then
    self:UpdateFollowUI()
  else
    self:PlayFrameOutAnim()
  end
end

function UMG_PartnerAndPeer_C:UpdateHeadIcon(path)
  self.NPCRole:SetPath(path)
end

function UMG_PartnerAndPeer_C:BlackGroundFadeOut()
  if self.IsWaitBackGroundAnim then
    self.IsWaitBackGroundAnim = false
    if self.CurFollowUIType == self.FollowUITypeList.AcceptTask then
      if self.ConfId then
        self.EventListener:StartGlobalEventListener(2, "UMG_PartnerAndPeer_C", self, TaskModuleEvent.TipsPerformFinished, self.StartTask)
        self.IsWaitAcceptTaskAnim = true
      end
    elseif self.CurFollowUIType == self.FollowUITypeList.FinishTask then
      self.IsWaitLastTaskAnim = false
      self:ShowTips()
      self:PlayFollowUIAnim(false)
    end
  end
end

function UMG_PartnerAndPeer_C:OnDialogueEnded()
  if not self:CheckIsInDialog() then
    if self.IsWaitTaskDialogFinish then
      self.IsWaitTaskDialogFinish = false
      self:FinishTask()
    elseif self.IsStartTaskWaitDialogFinish then
      self.IsStartTaskWaitDialogFinish = false
      self:StartFollowTask()
    elseif self.IsDialogueEndShow then
      self.IsDialogueEndShow = false
      self:ShowFollowUIByOpenPanel()
    end
  end
end

function UMG_PartnerAndPeer_C:FinishTask()
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_finish")
  self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
  local followConf = _G.DataConfigManager:GetNpcFollowConf(self.FollowId)
  if followConf.hide_blackscreen then
    self.IsWaitLastTaskAnim = false
    self:ShowTips()
    self:PlayFollowUIAnim(false)
  else
    self:ShowBlackGround()
  end
end

function UMG_PartnerAndPeer_C:StartTask()
  if self.IsWaitAcceptTaskAnim then
    self.EventListener:Stop()
    self.IsWaitAcceptTaskAnim = false
    if self:CheckIsInDialog() then
      self.IsStartTaskWaitDialogFinish = true
    else
      self:StartFollowTask()
    end
  end
end

function UMG_PartnerAndPeer_C:GetFollowNpcName()
  if self.FollowId then
    local followConf = _G.DataConfigManager:GetNpcFollowConf(self.FollowId)
    return followConf.npc_name
  else
    Log.Error("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:GetFollowNpcName\231\154\132FollowId\228\184\186nil!!!")
  end
end

function UMG_PartnerAndPeer_C:GetFollowTaskName()
  local TaskConf = _G.DataConfigManager:GetTaskConf(self.TaskId)
  return TaskConf.name
end

function UMG_PartnerAndPeer_C:GetMatchString(str)
  local text = str
  if string.find(text, "{\232\183\159\233\154\143\228\187\187\229\138\161}") or string.find(text, "{FollowerTask}") then
    local taskName = self:GetFollowTaskName()
    text = text:gsub("{\232\183\159\233\154\143\228\187\187\229\138\161}", function()
      return taskName
    end)
    text = text:gsub("{FollowerTask}", function()
      return taskName
    end)
  end
  if string.find(text, "{\232\183\159\233\154\143npc}") or string.find(text, "{FollowerNpc}") then
    local npcName = self:GetFollowNpcName()
    text = text:gsub("{\232\183\159\233\154\143npc}", function()
      return npcName
    end)
    text = text:gsub("{FollowerNpc}", function()
      return npcName
    end)
  end
  return text
end

function UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==111")
  if not self.FollowId then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==222")
    return
  end
  if not self.ConfId then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==333")
    return
  end
  local followTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId)
  if followTalkConf and followTalkConf.ui_type == "UI_STATE" then
    local nextConfId = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId).next_id
    if not nextConfId or 0 == nextConfId then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==444")
      self:HidePanel()
      return
    end
  end
  local isVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  local MainUIIsShow = _G.NRCModeManager:DoCmd(MainUIModuleCmd.MainUIIsShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag1==", self.CurState == Enum.NpcFollowState.NFS_ENABLE)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag2==", isVisit)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag3==", self.IsWaitBackGroundAnim)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag4==", self.IsTipsPanelShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag4==", self.IsRolePlayPanelShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag5==", self.IsVisitHintPanelShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag6==", MainUIIsShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==flag7==", self.IsWaitAcceptTaskAnim)
  if self.CurState == Enum.NpcFollowState.NFS_ENABLE and not isVisit and not self.IsWaitBackGroundAnim and not self.IsTipsPanelShow and not self.IsRolePlayPanelShow and not self.IsVisitHintPanelShow and MainUIIsShow and not self.IsWaitAcceptTaskAnim then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==555")
    if self:CheckIsInDialog() then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==666")
      self.IsDialogueEndShow = true
    else
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ShowFollowUIByOpenPanel==777")
      self:PlayFollowUIAnim(true)
    end
  end
end

function UMG_PartnerAndPeer_C:LoadingPanelClose()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LoadingPanelClose==111")
  if self.TipsCallBack then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LoadingPanelClose==222")
    self:OnCancelDelayHandle()
    self.DelayHandle = _G.DelayManager:DelaySeconds(2.0, self.ExecuteTipsCallBack, self)
  elseif self.IsExitVisitWaitLoadingPanelClose then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LoadingPanelClose==333")
    
    local function cb()
      if self.FollowId then
        self:ShowFollowUIByOpenPanel()
        local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_online_on")
        self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
        self:ShowTips()
      end
    end
    
    self:OnCancelDelayHandle()
    self.DelayHandle = _G.DelayManager:DelaySeconds(2.0, cb, self)
    self.IsExitVisitWaitLoadingPanelClose = false
  elseif self.IsJoinVisitWaitLoadingPanelClose then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LoadingPanelClose==444")
    
    local function cb()
      if self.FollowId then
        self:ShowFollowUIByOpenPanel()
        local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_online_off")
        self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
        self:ShowTips()
      end
    end
    
    self:OnCancelDelayHandle()
    self.DelayHandle = _G.DelayManager:DelaySeconds(2.0, cb, self)
    self.IsJoinVisitWaitLoadingPanelClose = false
  end
  self.IsLoadingPanel = false
end

function UMG_PartnerAndPeer_C:LoadingPanelOpen()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LoadingPanelOpen==111")
  self.IsLoadingPanel = true
end

function UMG_PartnerAndPeer_C:OnMainWindowChanged(isShow)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainWindowChanged==111")
  if isShow then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainWindowChanged==222")
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainWindowChanged==333")
      self:HideFollowUIByClosePanel()
    else
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainWindowChanged==444")
      self:ShowFollowUIByOpenPanel()
    end
  else
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainWindowChanged==555")
    self:HideFollowUIByClosePanel()
  end
end

function UMG_PartnerAndPeer_C:HidePanel()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:HidePanel")
  if self and UE4.UObject.IsValid(self) then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PartnerAndPeer_C:PlayFrameInAnim()
  if self:GetVisibility() == UE4.ESlateVisibility.Hidden then
    self:PlayAnimation(self.In, 0)
    self:PauseAnimation(self.In)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:PlayAnimation(self.In)
end

function UMG_PartnerAndPeer_C:PlayFrameOutAnim()
  if self:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  end
  self:PlayAnimation(self.Out)
end

function UMG_PartnerAndPeer_C:SetFollowData(followData)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:SetFollowData==111")
  if not followData then
    Log.Error("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:SetFollowData followData is nil")
    return
  end
  if followData.follow_id then
    self.FollowId = followData.follow_id
  end
  if followData.conf_id then
    self.ConfId = followData.conf_id
  end
  if followData.task_id then
    self.TaskId = followData.task_id
  end
  if not self.ConfId then
    return
  end
  local dialogueType = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId).condition
  if dialogueType == Enum.FollowConditionType.FL_DEFAULT then
    self.DefaultConfId = self.ConfId
  end
end

function UMG_PartnerAndPeer_C:OnAnimationFinished(anim)
  if anim == self.In and self.CurFollowUIType == self.FollowUITypeList.AcceptTask then
    if self.DefaultCache then
      self:SetFollowData(self.DefaultCache)
      self:ShowFollowUIByOpenPanel()
      self.DefaultCache = nil
    end
  elseif anim == self.Out and self.CurFollowUIType == self.FollowUITypeList.FinishTask and not self.IsWaitLastTaskAnim then
    if self.NextTaskDialogCache then
      self:SetFollowData(self.NextTaskDialogCache)
      self.CurFollowUIType = self.FollowUITypeList.AcceptTask
      self.IsWaitBackGroundAnim = true
      self:BlackGroundFadeOut()
      self.NextTaskDialogCache = nil
    end
  elseif anim == self.Out then
    self:HidePanel()
    self:ResetData()
  end
end

function UMG_PartnerAndPeer_C:OnShowUI(followId, confId)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==111")
  local followConf = _G.DataConfigManager:GetNpcFollowConf(followId)
  if not followConf then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==222")
    return
  end
  if self.IsPlayDialogue and self.ConfId == confId then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==333")
    return
  end
  self.DefaultHeadIcon = followConf.npc_icon
  self.DefaultName = followConf.npc_name
  if self.FollowId == followId then
    if self.IsPlayDialogue then
      if self.ConfId and 0 ~= self.ConfId then
        local curPriority = _G.DataConfigManager:GetNpcFollowTalkConf(confId).priority
        local prePriority = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId).priority
        if curPriority >= prePriority then
          Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==444")
          self.ConfId = confId
          self:InterruptPlayDialog()
          self:PlayDialogue()
        end
      end
    else
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==555")
      self.ConfId = confId
      self:PlayDialogue()
    end
  else
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnShowUI==666")
    self.FollowId = followId
    self.ConfId = confId
    self:InterruptPlayDialog()
    self:PlayDialogue()
  end
end

function UMG_PartnerAndPeer_C:PlayDialogue()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayDialogue")
  if self.ConfId and 0 ~= self.ConfId then
    local followTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId)
    if followTalkConf then
      if followTalkConf.ui_type == "UI_STATE" then
        self:PlayDefaultDialogue()
      elseif followTalkConf.ui_type == "UI_DIALOGUE" then
        self:PlayTalkDialogue()
      end
    end
  else
    self:PlayNoneDialogue()
  end
end

function UMG_PartnerAndPeer_C:PlayTalkDialogue()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==111")
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ZoneSceneGetFollowInfoReq, self.ConfId)
  local followTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId)
  local content = followTalkConf.text
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_default")
  self:SetTextLimit(content and content or GlobalConfig.str, self.ContentLimitCount, self.describe)
  local name = followTalkConf.npc_name
  self:SetTextLimit(name and name or self.DefaultName, self.NameLimitCount, self.Name)
  local npcIcon = followTalkConf.npc_icon
  self:UpdateHeadIcon(npcIcon and npcIcon or self.DefaultHeadIcon)
  self:PlayDialogueAnim()
  self.IsPlayDialogue = true
  local stayTime = followTalkConf.stay_time
  stayTime = stayTime or 3
  local soundName = followTalkConf.text_voice
  if soundName then
    local soundTime = _G.NRCAudioManager:GetMaxTimeFromEventName(soundName)
    self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(soundName, "UMG_PartnerAndPeer_C")
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==222==soundTime==", soundTime)
    if soundTime then
      self:OnCancelHandler()
      soundTime = math.floor(soundTime * 10 + 0.5) / 10
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==333===soundTime==", soundTime)
      self.Handler = _G.DelayManager:DelaySeconds(soundTime, self.PlayNextDialogue, self)
    else
      Log.Error("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==\232\175\173\233\159\179\232\161\168\228\184\173\230\178\161\230\156\137\232\191\153\228\184\170id\239\188\129\239\188\129\239\188\129")
    end
  else
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==444")
    if stayTime > 0 then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayTalkDialogue==555")
      self:OnCancelHandler()
      self.Handler = _G.DelayManager:DelaySeconds(stayTime, self.PlayNextDialogue, self)
    end
  end
end

function UMG_PartnerAndPeer_C:PlayDefaultDialogue()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayDefaultDialogue==111")
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ZoneSceneGetFollowInfoReq, self.ConfId)
  local followTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId)
  local content = followTalkConf.text
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_default")
  self:SetTextLimit(content and content or GlobalConfig.str, self.DefaultLimitCount, self.describe)
  local name = followTalkConf.npc_name
  self:SetTextLimit(name and name or self.DefaultName, self.NameLimitCount, self.Name)
  local npcIcon = followTalkConf.npc_icon
  self:UpdateHeadIcon(npcIcon and npcIcon or self.DefaultHeadIcon)
  self:HidePanel()
  self.IsPlayDialogue = false
  local stayTime = followTalkConf.stay_time
  stayTime = stayTime or 3
  if stayTime > 0 then
    self:PlayNextDialogue()
  end
end

function UMG_PartnerAndPeer_C:PlayNoneDialogue()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayNoneDialogue==111")
  self.IsPlayDialogue = false
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_default")
  self:SetTextLimit(GlobalConfig.str, self.DefaultLimitCount, self.describe)
  self:SetTextLimit(self.DefaultName, self.NameLimitCount, self.Name)
  self:UpdateHeadIcon(self.DefaultHeadIcon)
  self:HidePanel()
end

function UMG_PartnerAndPeer_C:PlayNextDialogue()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayNextDialogue==111")
  self:OnCancelHandler()
  self.IsPlayDialogue = false
  if self.ConfId then
    local followTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId)
    if followTalkConf then
      local nextConfId = followTalkConf.next_id
      if nextConfId and 0 ~= nextConfId then
        local nextFollowTalkConf = _G.DataConfigManager:GetNpcFollowTalkConf(nextConfId)
        if nextFollowTalkConf then
          local nextNexConfId = nextFollowTalkConf.next_id
          if nextNexConfId == self.ConfId then
            Log.Error("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayNextDialogue==\228\184\164\228\184\170\229\175\185\232\175\157\231\154\132\228\184\139\228\184\128\229\143\165\228\186\146\228\184\186\229\189\188\230\173\164\233\153\183\229\133\165\230\173\187\229\190\170\231\142\175\239\188\140\229\175\188\232\135\180\230\160\136\230\186\162\229\135\186\239\188\140\232\175\183\230\163\128\230\159\165follow.xlsx")
            self:StopCurDialog()
            self:HidePanel()
          else
            Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayNextDialogue==222")
            self.ConfId = nextConfId
            self:ShowFollowUIByOpenPanel()
          end
          return
        end
      end
    end
  end
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayNextDialogue==333")
  self.ConfId = nil
  self:StopCurDialog()
  self:HidePanel()
end

function UMG_PartnerAndPeer_C:PlayDialogueAnim()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayDialogueAnim==111")
  self:PlayFrameInAnim()
  self.CurDialogueType = self.DialogueTypeList.dialogue
end

function UMG_PartnerAndPeer_C:PlayDefaultAnim()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:PlayDefaultAnim==111")
  self:PlayFrameInAnim()
  self.CurDialogueType = self.DialogueTypeList.default
end

function UMG_PartnerAndPeer_C:HideFollowUIByClosePanel()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:HideFollowUIByClosePanel==111")
  if self:GetVisibility() == UE4.ESlateVisibility.Hidden then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:HideFollowUIByClosePanel==222")
    return
  end
  self:ClearCurDialog()
end

function UMG_PartnerAndPeer_C:ClearCurDialog()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ClearCurDialog==111")
  if self.IsPlayDialogue then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ClearCurDialog==222")
    local nextConfId = _G.DataConfigManager:GetNpcFollowTalkConf(self.ConfId).next_id
    if nextConfId and 0 ~= nextConfId then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ClearCurDialog==333")
      self.ConfId = nextConfId
    end
  end
  self:InterruptPlayDialog()
  self:HidePanel()
  self.IsDialogueEndShow = false
end

function UMG_PartnerAndPeer_C:StopSound()
  if self.SoundSession and -1 ~= self.SoundSession then
    _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, "UMG_PartnerAndPeer_C")
    self.SoundSession = -1
  end
end

function UMG_PartnerAndPeer_C:ResetData()
  self:StopCurDialog()
end

function UMG_PartnerAndPeer_C:SetTextLimit(content, limitLen, obj)
  local len = #content
  if len > limitLen * 3 then
    content = string.sub(content, 1, limitLen * 3)
  end
  obj:SetText(content)
end

function UMG_PartnerAndPeer_C:LobbyDownTipsStart()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LobbyDownTipsStart==111")
  self.IsTipsPanelShow = true
  self:CheckShowPanel(false)
end

function UMG_PartnerAndPeer_C:LobbyDownTipsEnd()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:LobbyDownTipsEnd==111")
  self.IsTipsPanelShow = false
  self:CheckShowPanel(true)
end

function UMG_PartnerAndPeer_C:CheckIsInDialog()
  return _G.NRCModuleManager:DoCmd(DialogueModuleCmd.HasDialogue)
end

function UMG_PartnerAndPeer_C:StartFollowTask()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:StartFollowTask==111")
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("follow_task_accept")
  self.ShowTipsText = self:GetMatchString(GlobalConfig.str)
  self:ShowTips(true)
  self:ShowFollowUIByOpenPanel()
end

function UMG_PartnerAndPeer_C:RolePlayPanelOpen()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:RolePlayPanelOpen==111")
  self.IsRolePlayPanelShow = true
  self:CheckShowPanel(false)
end

function UMG_PartnerAndPeer_C:RolePlayPanelClose()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:RolePlayPanelClose==222")
  self.IsRolePlayPanelShow = false
  self:CheckShowPanel(true)
end

function UMG_PartnerAndPeer_C:VisitHintPanelOpen()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:VisitHintPanelOpen==111")
  self.IsVisitHintPanelShow = true
  self:CheckShowPanel(false)
end

function UMG_PartnerAndPeer_C:VisitHintPanelClose()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:VisitHintPanelClose==111")
  self.IsVisitHintPanelShow = false
  self:CheckShowPanel(true)
end

function UMG_PartnerAndPeer_C:OnMainUIClose()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainUIClose==111")
  self:CheckShowPanel(false)
end

function UMG_PartnerAndPeer_C:OnMainUIOpen()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnMainUIOpen==111")
  self:CheckShowPanel(true)
end

function UMG_PartnerAndPeer_C:DoClose()
  if self.IsRelogin then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:DoClose==\230\150\173\231\186\191\233\135\141\232\191\158\232\175\183\230\177\130\230\156\141\229\138\161\229\153\168\230\149\176\230\141\174")
    self.IsRelogin = false
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ZoneSceneGetFollowInfoReq, nil)
    return
  end
  if self.CurState == Enum.NpcFollowState.NFS_ENABLE and self.FollowId then
    local followData = {
      old_state = self.OldState,
      new_state = self.CurState,
      follow_id = self.FollowId,
      conf_id = self.ConfId,
      task_id = self.TaskId
    }
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetFollowDataCache, followData)
  end
  self:OnCancelHandler()
  self:OnCancelDelayHandle()
  _G.NRCPanelBase.DoClose(self)
end

function UMG_PartnerAndPeer_C:CheckShowPanel(isShow)
  if isShow then
    self:ShowFollowUIByOpenPanel()
  else
    self:HideFollowUIByClosePanel()
  end
end

function UMG_PartnerAndPeer_C:InterruptPlayDialog()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:InterruptPlayDialog==111")
  if self.IsPlayDialogue then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:InterruptPlayDialog==222")
    self:StopCurDialog()
  end
end

function UMG_PartnerAndPeer_C:StopCurDialog()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:StopCurDialog==111")
  self:OnCancelHandler()
  self:StopSound()
  self.IsPlayDialogue = false
end

function UMG_PartnerAndPeer_C:OnTipsStartPlay()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnTipsStartPlay==111")
  self.IsPlayMapTips = true
end

function UMG_PartnerAndPeer_C:OnTipsEndPlay()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnTipsStartPlay==222")
  self.IsPlayMapTips = false
  self:ExecuteTipsCallBack()
end

function UMG_PartnerAndPeer_C:ExecuteTipsCallBack()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ExecuteTipsCallBack==111")
  local isHasMapTips = _G.NRCModeManager:DoCmd(TipsModuleCmd.CheckHasMapTips)
  if not isHasMapTips and not self.IsPlayMapTips and self.TipsCallBack then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ExecuteTipsCallBack==222")
    self.TipsCallBack()
    self.TipsCallBack = nil
  end
end

function UMG_PartnerAndPeer_C:VisitExitByPanelHasOpen(followData)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:VisitExitByPanelHasOpen==111")
  self:HidePanel()
  self.CurState = followData.new_state
  self.OldState = followData.old_state
  self:SetFollowData(followData)
  self.IsExitVisitWaitLoadingPanelClose = true
end

function UMG_PartnerAndPeer_C:JoinVisit()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:JoinVisit==111")
  self:HidePanel()
  self.IsJoinVisitWaitLoadingPanelClose = true
end

function UMG_PartnerAndPeer_C:OnRelogin()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnRelogin")
  self:HidePanel()
  self.IsRelogin = true
  self:StopCurDialog()
end

function UMG_PartnerAndPeer_C:OnReloginRefreshFollowData(followData)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnReloginRefreshFollowData")
  self.CurState = followData.new_state
  self:SetFollowData(followData)
  self:CheckShowPanel(true)
end

function UMG_PartnerAndPeer_C:OnCancelHandler()
  if self.Handler then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = nil
  end
end

function UMG_PartnerAndPeer_C:OnCancelDelayHandle()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
end

return UMG_PartnerAndPeer_C

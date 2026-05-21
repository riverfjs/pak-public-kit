local FsmAction = require("NewRoco.Modules.Core.Fsm.FsmAction")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local NPCSayAction = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineNPCSayState")
local CameraDOFState = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineCameraDOFState")
local TimelineWaitUserClickState = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineWaitUserClickState")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local Base = require("NewRoco.Modules.Core.Fsm.FsmTimelineState")
local FsmDialogueTimelineState = Base:Extend("FsmDialogueTimelineState")

function FsmDialogueTimelineState:Ctor(name, properties, actions, transitions, totalTime)
  Base.Ctor(self, name, properties, actions, transitions)
end

function FsmDialogueTimelineState:OnEnter(fsm)
  if self.entered then
    Log.Error("FsmDialogueTimelineState:OnEnter, enter while already entered!!!")
    return
  end
  self.execTime = 0
  if 0 == not #self.actions then
    Log.Warning("FsmDialogueTimelineState:OnEnter, existing actions while enter a timeline state!!!")
    table.clear(self.actions)
  end
  local timeline_config = fsm:GetProperty("CurrentTimeline")
  if timeline_config and #timeline_config.actions > 0 then
    local num_actions = #timeline_config.actions
    local timeline_length = timeline_config.length
    for action_index = 1, num_actions do
      local action_config = timeline_config.actions[action_index]
      if action_config.EndTime and timeline_length < action_config.EndTime then
        Log.Warning(string.format("FsmDialogueTimelineState:OnEnter, timeline action %s end time %f is bigger than timeline length %f, extend timeline length!!!", action_config.Name, action_config.EndTime, timeline_config.length))
        timeline_length = action_config.EndTime
      end
    end
    self:SetTotalTime(timeline_length)
    local bHasAnySayActionInTimeline = false
    local bHasShowUIAction = false
    local ShowUITime = 0.0
    local CameraDOFEvents = {}
    local CameraSetupActions = {}
    for action_index = 1, num_actions do
      local action_config = timeline_config.actions[action_index]
      local action_class = require(action_config.ClassPath)
      if action_class and action_class:SubclassOf(FsmAction) then
        if string.find(action_config.ClassPath, "NPCActorAnim") then
          local owner_actor_id = action_config.OwnerActorID
          local npc_content_id = action_config.NPCContentID
          local anim_name = action_config.Action
          local Actor = DialogueUtils.GrabActor(owner_actor_id, fsm, npc_content_id)
          if Actor and not string.IsNilOrEmpty(anim_name) then
            local AnimComp = Actor.GetAnimComponent and Actor:GetAnimComponent()
            if AnimComp then
              local anim_length = AnimComp:GetAnimLengthByName(anim_name)
              local action_length = action_config.EndTime - action_config.StartTime
              if anim_length > 0 and action_length > 0 then
                local anim_rate = anim_length / action_length
                action_config.StartTime = action_config.StartTime + action_config.StartPoint / anim_rate
                action_config.EndTime = action_config.EndTime - action_config.EndPoint / anim_rate
              end
            end
          end
        end
        local action = action_class(action_config.Name, action_config)
        self:AddAction(action)
        if string.find(action_config.ClassPath, "NPCSay") ~= nil then
          bHasAnySayActionInTimeline = true
        end
        if nil ~= string.find(action_config.ClassPath, "ShowUI") then
          bHasShowUIAction = true
          ShowUITime = action_config.StartTime or 0.0
        end
        if nil ~= string.find(action_config.ClassPath, "CameraDOFEvent") then
          table.insert(CameraDOFEvents, action)
        end
        if nil ~= string.find(action_config.ClassPath, "DialogueTimelineCameraSetupEvent") then
          table.insert(CameraSetupActions, action)
        end
      else
        Log.Warning(string.format("FsmDialogueTimelineState:OnEnter, timeline action class %s is not a valid FsmAction class, skip!!!", action_config.ClassPath))
      end
    end
    if bHasAnySayActionInTimeline then
      fsm:SetProperty("HasAnySayActionInTimeline", true)
    else
      fsm:SetProperty("HasAnySayActionInTimeline", false)
      if NPCSayAction then
        local action = NPCSayAction("DefaultNPCSay", {
          StartTime = ShowUITime,
          EndTime = ShowUITime + 1.0
        })
        self:AddAction(action)
        fsm:SetProperty("HasAnySayActionInTimeline", true)
      end
    end
    fsm:SetProperty("HasShowUIAction", bHasShowUIAction)
    if #CameraDOFEvents > 0 and CameraDOFState then
      local DOFStartTime = timeline_length
      local DOFEndTime = 0.0
      for _, DOFAction in ipairs(CameraDOFEvents) do
        DOFStartTime = math.min(DOFStartTime, DOFAction:GetStartTime())
        DOFEndTime = math.max(DOFEndTime, DOFAction:GetStartTime())
      end
      local CameraDOFStateInstance = CameraDOFState("DefaultCameraDOFState", {
        StartTime = DOFStartTime,
        EndTime = DOFEndTime,
        Keys = CameraDOFEvents
      })
      self:AddAction(CameraDOFStateInstance)
    end
    table.sort(CameraSetupActions, function(a, b)
      return a:GetStartTime() < b:GetStartTime()
    end)
    local LastCameraSetupTime = 0.0
    local WaitUserClickTimeKeys = {}
    for _, action in ipairs(CameraSetupActions) do
      if not action:GetProperty("SkipUserClick") and action:GetStartTime() - LastCameraSetupTime > 0.1 then
        LastCameraSetupTime = action:GetStartTime()
        table.insert(WaitUserClickTimeKeys, LastCameraSetupTime)
      end
    end
    if timeline_length - LastCameraSetupTime > 0.1 then
      table.insert(WaitUserClickTimeKeys, timeline_length)
    elseif #WaitUserClickTimeKeys > 0 then
      WaitUserClickTimeKeys[#WaitUserClickTimeKeys] = timeline_length
    else
      table.insert(WaitUserClickTimeKeys, timeline_length)
    end
    local WaitUserClickState = TimelineWaitUserClickState("TimelineWaitUserClickState", {
      Keys = WaitUserClickTimeKeys,
      StartTime = 0.0,
      EndTime = timeline_length
    })
    self:AddAction(WaitUserClickState)
  end
  fsm:SetProperty("UserClicked", false)
  self.ParentModule = fsm:GetProperty("ParentModule")
  if self.ParentModule then
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished, self.OnUserClick)
  end
  local DialogueID = fsm:GetProperty("NextConfID", 0)
  if DialogueID > 0 then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  end
  if self.ParentModule and fsm:GetProperty("SpectatorMode") then
    self.ParentModule:RegisterEvent(self, DialogueModuleEvent.SyncNextDialogue, self.OnSyncNextDialogue)
  end
  Base.OnEnter(self, fsm)
  _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.CLOSE_BLACK_SCREEN)
  NRCModuleManager:DoCmd(DialogueModuleCmd.FadeOutDialogueCameraBlack)
end

function FsmDialogueTimelineState:OnExit()
  local ActorsToStopAnim = self.fsm:GetProperty("ActorsToStopAnim") or {}
  for _, actor in ipairs(ActorsToStopAnim) do
    if actor then
      DialogueUtils.StopAnim(actor, 0.2)
    end
  end
  self.fsm:SetProperty("ActorsToStopAnim", {})
  if not self.entered then
    Log.Error("FsmDialogueTimelineState:OnExit, exit while not entered!!!")
    return
  end
  self.entered = false
  if self.ParentModule then
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished)
    self.ParentModule:UnRegisterEvent(self, DialogueModuleEvent.SyncNextDialogue)
  end
  Base.OnExit(self)
  table.clear(self.actions)
end

function FsmDialogueTimelineState:OnUserClick(DialogueConfOnPanel)
  if DialogueConfOnPanel then
    local CurrentDialogue = self.fsm:GetProperty("CurrentDialogue")
    if CurrentDialogue and DialogueConfOnPanel.id ~= CurrentDialogue.id then
      Log.Error("dialogue id mismatch", DialogueConfOnPanel.id, CurrentDialogue.id)
      return
    end
  end
  if self.entered and not self.finished then
    self.fsm:SetProperty("UserClicked", true)
  end
end

function FsmDialogueTimelineState:OnSyncNextDialogue()
  if self:CheckSyncNextReady() then
    self:FastForwardState()
  end
end

function FsmDialogueTimelineState:CheckSyncNextReady()
  if #self.fsm:GetProperty("PendingSyncList") > 0 and self.ParentModule and self.ParentModule.PanelOn and self.ParentModule:HasPanel(self.ParentModule._currentMainPanel) then
    local CurPanel = self.ParentModule:GetPanel(self.ParentModule._currentMainPanel)
    if CurPanel then
      return CurPanel:IsTypeFinish()
    end
  end
  return false
end

function FsmDialogueTimelineState:FastForwardState()
  if self.entered and not self.finished then
    local CurTime = self.execTime
    local FastForwardTime = self.totalTime - CurTime
    if FastForwardTime > 0 then
      Log.DebugFormat("FsmDialogueTimelineState:FastForwardState, fastforward %f", FastForwardTime)
      self.fsm:OnTick(FastForwardTime + 1.0E-7)
    end
  end
end

return FsmDialogueTimelineState

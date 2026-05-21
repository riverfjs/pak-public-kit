local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local FsmDoCmdAction = require("NewRoco.Modules.Core.Fsm.Actions.FsmDoCmdAction")
local DialogueWaitCommitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitCommitAction")
local DialogueWaitExecutingAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitExecutingAction")
local DialogueSyncDispatchAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSyncDispatchAction")
local SendNextActReqAction = require("NewRoco.Modules.System.Dialogue.Action.SendNextActReqAction")
local DialogueInitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueInitAction")
local BlockInputAction = require("NewRoco.Modules.System.Dialogue.Action.BlockInputAction")
local DialogueWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitNPCSpawnAction")
local DialogueWaitSetupEnvAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSetupEnvAction")
local DialogueShowOptionsAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueShowOptionsAction")
local DialogueWaitSyncOptionChoiceAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSyncOptionChoiceAction")
local DialogueWaitSyncShowOptionsAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSyncShowOptionsAction")
local CameraBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenAction")
local CameraBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenOutAction")
local DialoguePresetAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePresetAction")
local DialogueCameraSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueCameraSetupAction")
local DialogueNPCSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCSetupAction")
local OpenMainDialogueAction = require("NewRoco.Modules.System.Dialogue.Action.OpenMainDialogueAction")
local DialogueNPCAnimAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCAnimAction")
local DialogueWaitTalkAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitTalkAction")
local DialogueWaitNextSyncAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitNextSyncAction")
local DialogueSyncActionAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSyncActionAction")
local DialogueWaitUserAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitUserAction")
local ResolveCameraSettingsAction = require("NewRoco.Modules.System.Dialogue.Action.ResolveCameraSettingsAction")
local DialogueResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueResolveAction")
local DialogueDestroyAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueDestroyAction")
local UnskippableCameraMotionAction = require("NewRoco.Modules.System.Dialogue.Action.UnskippableCameraMotionAction")
local DialogueSaveViewTargetAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSaveViewTargetAction")
local DialogueEmojiAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueEmojiAction")
local DialogueNPCMoveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCMoveAction")
local DialogueStopCurAudioAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueStopCurAudioAction")
local TryOpenGlobalBlackAction = require("NewRoco.Modules.System.Dialogue.Action.TryOpenGlobalBlackAction")
local DialogueSendUserSelectAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSendUserSelectAction")
local FsmDialogueTimelineState = require("NewRoco.Modules.System.Dialogue.FsmDialogueTimelineState")
local TimelineStateBranchAction = require("NewRoco.Modules.System.Dialogue.Action.TimelineStateBranchAction")
local DialogueTimelineResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueTimelineResolveAction")
local DialoguePrevTimelineBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenAction")
local DialoguePrevTimelineBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenOutAction")
local DialoguePostTimelineWaitUserClickAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePostTimelineWaitUserClickAction")
local DialoguePrevTimelineWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineWaitNPCSpawnAction")
local DialogueSkipBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSkipBlackScreenAction")
local DialogueAutoBlackScreenAtEndAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueAutoBlackScreenAtEndAction")
local ClearNextConfIDAction = require("NewRoco.Modules.System.Dialogue.Action.ClearNextConfIDAction")

local function CreateFsm()
  local FINISHED = "FINISHED"
  local fsm = Fsm("SycnDialogueFSM")
  local CurrentDialogue = fsm:CreateVar("CurrentDialogue", nil)
  local CurrentTimeline = fsm:CreateVar("CurrentTimeline", nil)
  local HasAnySayActionInTimeline = fsm:CreateVar("HasAnySayActionInTimeline", false)
  local HasShowUIAction = fsm:CreateVar("HasShowUIAction", true)
  local CurrentAction = fsm:CreateVar("CurrentAction", nil)
  local CameraSetting1 = fsm:CreateVar("CameraSetting1", nil)
  local CameraSetting2 = fsm:CreateVar("CameraSetting2", nil)
  local TargetSide = fsm:CreateVar("TargetSide", nil)
  local CameraSide = fsm:CreateVar("CameraSide", nil)
  local TargetValue = fsm:CreateVar("TargetValue", nil)
  local TargetNPC = fsm:CreateVar("TargetNPC", nil)
  local Center = fsm:CreateVar("Center", nil)
  local Options = fsm:CreateVar("Options", nil)
  local ParentModule = fsm:CreateVar("ParentModule", nil)
  local LastConfID = fsm:CreateVar("LastConfID", nil)
  local NextConfID = fsm:CreateVar("NextConfID", nil)
  local NpcIDs = fsm:CreateVar("NpcIDs", {})
  local ClientAction = fsm:CreateVar("ClientAction", nil)
  local PrevUIType = fsm:CreateVar("PrevUIType", nil)
  local ViewTargetTransform = fsm:CreateVar("ViewTargetTransform", nil)
  local HasLoopAnimation = fsm:CreateVar("HasLoopAnimation", false)
  local IsReconnect = fsm:CreateVar("bIsReconnect", false)
  local Participants = fsm:CreateVar("Participants", nil)
  local LastSpeaker = fsm:CreateVar("LastSpeaker", nil)
  local bIsDebugging = fsm:CreateVar("bIsDebugging", false)
  local BornTransform = fsm:CreateVar("BornTransform", nil)
  local StageActor = fsm:CreateVar("StageActor", nil)
  local ActionInfo = fsm:CreateVar("ActionInfo", nil)
  local UserClicked = fsm:CreateVar("UserClicked", false)
  local ReturnCamera = fsm:CreateVar("ReturnCamera", true)
  local CurrentSelection = fsm:CreateVar("CurrentSelection", nil)
  local bClickIntercept = fsm:CreateVar("bClickIntercept", false)
  local PlayerPosSyncBlocker = fsm:CreateVar("PlayerPosSyncBlocker", nil)
  local SyncSkipDialogueID = fsm:CreateVar("SyncSkipDialogueID", nil)
  local CleanUpFsmAtEnd = fsm:CreateVar("CleanUpFsmAtEnd", false)
  local NextSelectIDs = fsm:CreateVar("NextSelectIDs", {})
  local PendingSyncList = fsm:CreateVar("PendingSyncList", {})
  local SpectatorMode = fsm:CreateVar("SpectatorMode", true)
  local Progress = fsm:CreateVar("Progress", nil)
  local OptionConf = fsm:CreateVar("OptionConf", nil)
  local ActorsToStopAnim = fsm:CreateVar("ActorsToStopAnim", {})
  local InitState = fsm:CreateSequentialState("InitState")
  local PrepareState = fsm:CreateBurstState("PrepareState")
  local DispatchState = fsm:CreateSequentialState("DispatchState")
  local WaitNextSelectState = fsm:CreateSequentialState("WaitNextSelectState")
  local NextState = fsm:CreateBurstState("NextState")
  local EndState = fsm:CreateSequentialState("EndState")
  local RestartState = fsm:CreateSequentialState("RestartState")
  local SkipState = fsm:CreateSequentialState("SkipState")
  local PrevTimelineState = fsm:CreateBurstState("PrevTimelineState")
  local TimelineState = FsmDialogueTimelineState("TimelineState")
  fsm:AddState(TimelineState)
  local PostTimelineState = fsm:CreateBurstState("PostTimelineState")
  InitState:AddAction(DialogueInitAction("InitDialogue", {ConfID = NextConfID, TargetNPC = TargetNPC}))
  PrepareState:AddAction(BlockInputAction("BlockInput", {Block = true}))
  PrepareState:AddAction(ResolveCameraSettingsAction("ResolveCameraSettings", {
    DialogueConf = CurrentDialogue,
    CameraSettingFirst = CameraSetting1,
    CameraSettingSecond = CameraSetting2
  }))
  PrepareState:AddAction(CameraBlackScreenAction("CameraBlackScreen", {
    DialogueConf = CurrentDialogue,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting1
  }))
  PrepareState:AddAction(DialogueWaitSetupEnvAction("WaitSetupEnv", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule
  }))
  PrepareState:AddAction(DialogueWaitNPCSpawnAction("WaitSpawnNPCs", {DialogueConf = CurrentDialogue, TargetNPC = TargetNPC}))
  PrepareState:AddAction(DialoguePresetAction("Preset", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule
  }))
  PrepareState:AddAction(DialogueCameraSetupAction("SetupCamera", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting1,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    Center = Center
  }))
  PrepareState:AddAction(DialogueNPCSetupAction("SetupNPC", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    NpcIDs = NpcIDs
  }))
  PrepareState:AddAction(DialogueEmojiAction("NPCEmoji", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    NpcIDs = NpcIDs
  }))
  PrepareState:AddAction(DialogueNPCAnimAction("NPCAnim", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    NpcIDs = NpcIDs,
    Participants = Participants
  }))
  PrepareState:AddAction(OpenMainDialogueAction("OpenMainDialogue", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  PrepareState:AddAction(CameraBlackScreenOutAction("CameraBlackScreenOut", {CameraSetting = CameraSetting1}))
  PrepareState:AddAction(DialogueNPCMoveAction("NPCMove", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    NpcIDs = NpcIDs
  }))
  PrepareState:AddAction(BlockInputAction("BlockInput", {Block = false}))
  PrepareState:AddAction(UnskippableCameraMotionAction("UnskippableCameraMotionAction", {
    CameraSetting = CameraSetting1,
    ParentModule = ParentModule,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    TargetNPC = TargetNPC,
    DialogueConf = CurrentDialogue,
    isLast = false,
    Center = Center
  }))
  PrepareState:AddAction(CameraBlackScreenAction("CameraBlackScreen2", {
    DialogueConf = CurrentDialogue,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting2
  }))
  PrepareState:AddAction(DialogueCameraSetupAction("SetupCamera2", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting2,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    Center = Center
  }))
  PrepareState:AddAction(CameraBlackScreenOutAction("CameraBlackScreenOut2", {CameraSetting = CameraSetting2}))
  PrepareState:AddAction(UnskippableCameraMotionAction("UnskippableCameraMotionAction2", {
    CameraSetting = CameraSetting2,
    ParentModule = ParentModule,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    TargetNPC = TargetNPC,
    DialogueConf = CurrentDialogue,
    isLast = true,
    Center = Center
  }))
  PrepareState:AddAction(DialogueSaveViewTargetAction("SaveViewTarget", {Transform = ViewTargetTransform}))
  PrepareState:AddAction(DialogueWaitTalkAction("WaitTalkFinish", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  PrevTimelineState:AddAction(BlockInputAction("BlockInput", {Block = true}))
  PrevTimelineState:AddAction(DialogueTimelineResolveAction("ResolveTimelineJson", {CurrentDialogue = CurrentDialogue, CurrentTimeline = CurrentTimeline}))
  PrevTimelineState:AddAction(DialoguePrevTimelineBlackScreenAction("PrevTimelineBlack", {CurrentTimeline = CurrentTimeline, ParentModule = ParentModule}))
  PrevTimelineState:AddAction(DialogueWaitSetupEnvAction("WaitSetupEnv", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule
  }))
  PrevTimelineState:AddAction(DialoguePrevTimelineWaitNPCSpawnAction("TimelineWaitSpawnNPCs", {
    DialogueConf = CurrentDialogue,
    CurrentTimeline = CurrentTimeline,
    TargetNPC = TargetNPC,
    NpcIDs = NpcIDs
  }))
  PrevTimelineState:AddAction(DialoguePresetAction("Preset", {
    DialogueConf = CurrentDialogue,
    TargetNPC = TargetNPC,
    ParentModule = ParentModule
  }))
  PrevTimelineState:AddAction(BlockInputAction("BlockInput", {Block = false}))
  PostTimelineState:AddAction(DialogueSaveViewTargetAction("SaveViewTarget", {Transform = ViewTargetTransform}))
  PostTimelineState:AddAction(DialoguePostTimelineWaitUserClickAction("PostTimelineWaitUserClick", {
    CurrentDialogue = CurrentDialogue,
    CurrentTimeline = CurrentTimeline,
    UserClicked = UserClicked,
    ParentModule = ParentModule,
    HasShowUIAction = HasShowUIAction
  }))
  DispatchState:AddAction(DialogueSyncDispatchAction("Dispatch", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    NextSelectIDs = NextSelectIDs,
    Options = Options
  }))
  WaitNextSelectState:AddAction(DialogueWaitSyncShowOptionsAction("WaitSyncShowOptions", {ParentModule = ParentModule, Progress = Progress}))
  WaitNextSelectState:AddAction(DialogueShowOptionsAction("ShowOptions"))
  WaitNextSelectState:AddAction(DialogueWaitSyncOptionChoiceAction("SyncOptionChoice", {ParentModule = ParentModule, PendingSyncList = PendingSyncList}))
  NextState:AddAction(DialogueSyncActionAction("SyncActionAction", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  NextState:AddAction(DialogueWaitNextSyncAction("WaitNextSync", {
    ParentModule = ParentModule,
    NextConfID = NextConfID,
    NextSelectIDs = NextSelectIDs,
    PendingSyncList = PendingSyncList
  }))
  NextState:AddAction(DialogueResolveAction("ResolveConf", {DialogueConf = CurrentDialogue, ConfID = NextConfID}))
  NextState:AddAction(ClearNextConfIDAction("ClearNextConfIDAction", {ConfID = NextConfID}))
  NextState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  SkipState:AddAction(DialogueSkipBlackScreenAction("DialogueWaitBlackScreenAction", {
    ParentModule = ParentModule,
    ConfID = NextConfID,
    LastConfID = LastConfID
  }))
  RestartState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  EndState:AddAction(DialogueStopCurAudioAction("StopAudioAtEnd"))
  EndState:AddAction(DialogueAutoBlackScreenAtEndAction("AutoBlackScreenAtEnd", {ParentModule = ParentModule}))
  EndState:AddAction(DialogueDestroyAction("CloseDialogueUI", {
    TargetNPC = TargetNPC,
    Cmd = DialogueModuleCmd.CloseMainPanel,
    ParentModule = ParentModule,
    NpcIDs = NpcIDs,
    bIsReconnect = IsReconnect
  }))
  InitState:AddTransitionToState(FINISHED, NextState)
  NextState:AddTransitionToState(DialogueModuleEvent.EnterTimelineState, PrevTimelineState)
  NextState:AddTransitionToState(FINISHED, PrepareState)
  RestartState:AddTransitionToState(DialogueModuleEvent.EnterTimelineState, PrevTimelineState)
  RestartState:AddTransitionToState(FINISHED, PrepareState)
  PrevTimelineState:AddTransitionToState(FINISHED, TimelineState)
  TimelineState:AddTransitionToState(FINISHED, PostTimelineState)
  PostTimelineState:AddTransitionToState(FINISHED, DispatchState)
  PrepareState:AddTransitionToState(FINISHED, DispatchState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterSelectState, WaitNextSelectState)
  DispatchState:AddTransitionToState(FINISHED, NextState)
  WaitNextSelectState:AddTransitionToState(FINISHED, NextState)
  SkipState:AddTransitionToState(FINISHED, NextState)
  fsm:AddTransitionToState(DialogueModuleEvent.EnterEndState, EndState)
  fsm:AddTransitionToState(DialogueModuleEvent.EnterSkipState, SkipState)
  fsm:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  fsm:SetInitState(InitState)
  EndState.isFinalState = true
  return fsm
end

return CreateFsm

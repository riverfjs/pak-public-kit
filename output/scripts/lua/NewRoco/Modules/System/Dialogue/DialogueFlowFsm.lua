local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local FsmDoCmdAction = require("NewRoco.Modules.Core.Fsm.Actions.FsmDoCmdAction")
local DialogueWaitCommitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitCommitAction")
local DialogueWaitExecutingAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitExecutingAction")
local DialogueDispatchAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueDispatchAction")
local SendNextActReqAction = require("NewRoco.Modules.System.Dialogue.Action.SendNextActReqAction")
local DialogueInitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueInitAction")
local BlockInputAction = require("NewRoco.Modules.System.Dialogue.Action.BlockInputAction")
local DialogueWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitNPCSpawnAction")
local DialogueWaitSetupEnvAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSetupEnvAction")
local DialogueShowOptionsAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueShowOptionsAction")
local CameraBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenAction")
local CameraBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenOutAction")
local DialoguePresetAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePresetAction")
local DialogueCameraSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueCameraSetupAction")
local DialogueNPCSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCSetupAction")
local OpenMainDialogueAction = require("NewRoco.Modules.System.Dialogue.Action.OpenMainDialogueAction")
local DialogueNPCAnimAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCAnimAction")
local DialogueWaitTalkAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitTalkAction")
local DialogueWaitActionAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitActionAction")
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
local DialogueWaitSkipAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSkipAction")
local DialogueSkipBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSkipBlackScreenAction")
local DialogueAutoBlackScreenAtEndAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueAutoBlackScreenAtEndAction")
local DialogueSyncNextAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSyncNextAction")
local DialogueSyncSkipAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSyncSkipAction")
local DialogueSyncEndAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSyncEndAction")
local DialoguePreloadClientActionAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePreloadClientActionAction")
local DialogueStopCameraSkillAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueStopCameraSkillAction")

local function CreateFsm()
  local FINISHED = "FINISHED"
  local fsm = Fsm("DialogueFlowFsm")
  local CurrentOption = fsm:CreateVar("CurrentOption", nil)
  local CurrentDialogue = fsm:CreateVar("CurrentDialogue", nil)
  local CurrentTimeline = fsm:CreateVar("CurrentTimeline", nil)
  local LastTimeline = fsm:CreateVar("LastTimeline", nil)
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
  local bIsRestoring = fsm:CreateVar("bIsRestore", false)
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
  local LastSelection = fsm:CreateVar("LastSelection", nil)
  local bClickIntercept = fsm:CreateVar("bClickIntercept", false)
  local PlayerPosSyncBlocker = fsm:CreateVar("PlayerPosSyncBlocker", nil)
  local ActorsToStopAnim = fsm:CreateVar("ActorsToStopAnim", {})
  local InitState = fsm:CreateSequentialState("InitState")
  local PrepareState = fsm:CreateBurstState("PrepareState")
  local DispatchState = fsm:CreateSequentialState("DispatchState")
  local SendSelectState = fsm:CreateSequentialState("SendSelectState")
  local SendNextActState = fsm:CreateSequentialState("SendNextActState")
  local ActionState = fsm:CreateSequentialState("ActionState")
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
  PrepareState:AddAction(DialogueStopCameraSkillAction("StopCameraSkill"))
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
  PrepareState:AddAction(OpenMainDialogueAction("OpenMainDialogue", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
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
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID,
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
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID,
    isLast = true,
    Center = Center
  }))
  PrepareState:AddAction(DialogueSaveViewTargetAction("SaveViewTarget", {Transform = ViewTargetTransform}))
  PrepareState:AddAction(DialogueWaitTalkAction("WaitForUserClick", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
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
  DispatchState:AddAction(DialogueDispatchAction("Dispatch", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    Options = Options,
    ConfID = NextConfID,
    Action = ActionInfo
  }))
  SendNextActState:AddAction(TryOpenGlobalBlackAction("TryOpenGlobalBlack(BeforeSendNextAck)", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  SendNextActState:AddAction(SendNextActReqAction("SendNextAction", {
    TargetNPC = TargetNPC,
    Option = CurrentOption,
    DialogueConf = CurrentDialogue,
    ConfID = NextConfID,
    ParentModule = ParentModule
  }))
  SendNextActState:AddAction(DialogueWaitCommitAction("WaitCommit(SendNextAct)", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
  ActionState:AddAction(DialogueWaitActionAction("WaitActionEnd", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID,
    ClientAction = ClientAction,
    ServerAction = ActionInfo
  }))
  ActionState:AddAction(DialogueWaitCommitAction("WaitCommit(Action)", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
  SendSelectState:AddAction(DialogueShowOptionsAction("ShowOptions", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    NPCOption = CurrentOption
  }))
  SendSelectState:AddAction(DialogueWaitUserAction("WaitForUserToSelect", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID,
    CurrentSelection = CurrentSelection
  }))
  SendSelectState:AddAction(TryOpenGlobalBlackAction("TryOpenGlobalBlack(BeforeSendUserSelect)", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  SendSelectState:AddAction(DialogueSendUserSelectAction("SendUserSelect", {
    CurrentSelection = CurrentSelection,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID,
    Action = ActionInfo
  }))
  SendSelectState:AddAction(DialogueWaitCommitAction("WaitCommit(SendSelect)", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
  NextState:AddAction(DialogueWaitExecutingAction("Wait Executing", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID,
    Action = ActionInfo,
    Restoring = bIsRestoring
  }))
  NextState:AddAction(DialogueResolveAction("ResolveConf", {DialogueConf = CurrentDialogue, ConfID = NextConfID}))
  NextState:AddAction(DialogueSyncNextAction("SyncNext", {
    ConfID = NextConfID,
    TargetNPC = TargetNPC,
    Action = ActionInfo,
    NPCOption = CurrentOption
  }))
  NextState:AddAction(DialoguePreloadClientActionAction("PreloadClientAction", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ClientAction = ClientAction,
    ServerAction = ActionInfo
  }))
  NextState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  SkipState:AddAction(DialogueWaitSkipAction("DialogueWaitSkipAction", {
    DialogueConf = CurrentDialogue,
    ParentModule = ParentModule,
    ConfID = NextConfID,
    LastConfID = LastConfID,
    Option = CurrentOption
  }))
  SkipState:AddAction(DialogueSyncSkipAction("DialogueSyncSkipAction", {
    DialogueConf = CurrentDialogue,
    ConfID = NextConfID,
    LastConfID = LastConfID,
    TargetNPC = TargetNPC,
    NPCOption = CurrentOption
  }))
  SkipState:AddAction(DialogueSkipBlackScreenAction("DialogueSkipBlackScreenAction", {
    ParentModule = ParentModule,
    ConfID = NextConfID,
    LastConfID = LastConfID
  }))
  RestartState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  EndState:AddAction(DialogueStopCurAudioAction("StopAudioAtEnd"))
  EndState:AddAction(DialogueSyncEndAction("SyncEndAction", {
    DialogueConf = CurrentDialogue,
    ConfID = NextConfID,
    TargetNPC = TargetNPC,
    NPCOption = CurrentOption
  }))
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
  PrevTimelineState:AddTransitionToState(DialogueModuleEvent.EnterDispatchState, DispatchState)
  PrevTimelineState:AddTransitionToState(FINISHED, TimelineState)
  TimelineState:AddTransitionToState(FINISHED, PostTimelineState)
  PrevTimelineState:AddTransitionToState(DialogueModuleEvent.EnterDispatchState, DispatchState)
  PostTimelineState:AddTransitionToState(FINISHED, DispatchState)
  PrepareState:AddTransitionToState(DialogueModuleEvent.EnterDispatchState, DispatchState)
  PrepareState:AddTransitionToState(FINISHED, DispatchState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterActionState, ActionState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterSelectState, SendSelectState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterSendNextActState, SendNextActState)
  DispatchState:AddTransitionToState(FINISHED, SendNextActState)
  SendNextActState:AddTransitionToState(DialogueModuleEvent.EnterNextState, NextState)
  SendNextActState:AddTransitionToState(FINISHED, NextState)
  ActionState:AddTransitionToState(FINISHED, NextState)
  SendSelectState:AddTransitionToState(FINISHED, NextState)
  SkipState:AddTransitionToState(FINISHED, NextState)
  PrepareState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  SendSelectState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PrevTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  TimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PostTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  fsm:AddTransitionToState(DialogueModuleEvent.EnterEndState, EndState)
  PrepareState:AddTransitionToState(DialogueModuleEvent.EnterSkipState, SkipState)
  SendSelectState:AddTransitionToState(DialogueModuleEvent.EnterSkipState, SkipState)
  TimelineState:AddTransitionToState(DialogueModuleEvent.EnterSkipState, SkipState)
  PostTimelineState:AddTransitionToState(DialogueModuleEvent.EnterSkipState, SkipState)
  fsm:SetInitState(InitState)
  EndState.isFinalState = true
  return fsm
end

return CreateFsm

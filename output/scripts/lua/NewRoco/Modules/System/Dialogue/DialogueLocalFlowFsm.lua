local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local FsmDoCmdAction = require("NewRoco.Modules.Core.Fsm.Actions.FsmDoCmdAction")
local DialogueLocalDispatchAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueLocalDispatchAction")
local DialogueInitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueInitAction")
local BlockInputAction = require("NewRoco.Modules.System.Dialogue.Action.BlockInputAction")
local DialogueWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitNPCSpawnAction")
local DialogueWaitSetupEnvAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitSetupEnvAction")
local CameraBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenAction")
local CameraBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.CameraBlackScreenOutAction")
local DialoguePresetAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePresetAction")
local DialogueCameraSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueCameraSetupAction")
local DialogueNPCSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCSetupAction")
local OpenMainDialogueAction = require("NewRoco.Modules.System.Dialogue.Action.OpenMainDialogueAction")
local DialogueNPCAnimAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCAnimAction")
local DialogueWaitTalkAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitTalkAction")
local DialogueWaitLocalActionAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitLocalActionAction")
local DialogueWaitUserAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitUserAction")
local ResolveCameraSettingsAction = require("NewRoco.Modules.System.Dialogue.Action.ResolveCameraSettingsAction")
local DialogueResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueResolveAction")
local DialogueDestroyAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueDestroyAction")
local UnskippableCameraMotionAction = require("NewRoco.Modules.System.Dialogue.Action.UnskippableCameraMotionAction")
local DialogueSaveViewTargetAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSaveViewTargetAction")
local DialogueEmojiAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueEmojiAction")
local DialogueNPCMoveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCMoveAction")
local DialogueSendUserSelectAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSendUserSelectAction")
local FsmDialogueTimelineState = require("NewRoco.Modules.System.Dialogue.FsmDialogueTimelineState")
local TimelineStateBranchAction = require("NewRoco.Modules.System.Dialogue.Action.TimelineStateBranchAction")
local DialogueTimelineResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueTimelineResolveAction")
local DialoguePrevTimelineBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenAction")
local DialoguePrevTimelineBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenOutAction")
local DialoguePostTimelineWaitUserClickAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePostTimelineWaitUserClickAction")
local DialoguePrevTimelineWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineWaitNPCSpawnAction")

local function CreateFsm()
  local FINISHED = "FINISHED"
  local fsm = Fsm("DialogueLocalFlowFsm")
  local CurrentOption = fsm:CreateVar("CurrentOption", nil)
  local IsLocalDialogue = fsm:CreateVar("IsLocalDialogue", nil)
  local CurrentDialogue = fsm:CreateVar("CurrentDialogue", nil)
  local CurrentTimeline = fsm:CreateVar("CurrentTimeline", nil)
  local HasAnySayActionInTimeline = fsm:CreateVar("HasAnySayActionInTimeline", false)
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
  local InitState = fsm:CreateSequentialState("InitState")
  local PrepareState = fsm:CreateBurstState("PrepareState")
  local DispatchState = fsm:CreateSequentialState("DispatchState")
  local SendSelectState = fsm:CreateSequentialState("SendSelectState")
  local ActionState = fsm:CreateSequentialState("ActionState")
  local NextState = fsm:CreateBurstState("NextState")
  local EndState = fsm:CreateSequentialState("EndState")
  local RestartState = fsm:CreateSequentialState("RestartState")
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
    TargetNPC = TargetNPC
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
    ParentModule = ParentModule
  }))
  DispatchState:AddAction(DialogueLocalDispatchAction("Dispatch", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    Options = Options,
    ConfID = NextConfID,
    Action = ActionInfo
  }))
  ActionState:AddAction(DialogueWaitLocalActionAction("WaitActionEnd", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID,
    ClientAction = ClientAction,
    ServerAction = ActionInfo
  }))
  SendSelectState:AddAction(FsmDoCmdAction("SetPanelToSelectMode", {
    Cmd = DialogueModuleCmd.ShowOptions
  }))
  SendSelectState:AddAction(DialogueWaitUserAction("WaitForUserToSelect", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
  SendSelectState:AddAction(DialogueSendUserSelectAction("SendUserSelect", {
    CurrentSelection = CurrentSelection,
    DialogueConf = CurrentDialogue,
    Option = CurrentOption,
    ConfID = NextConfID
  }))
  NextState:AddAction(DialogueResolveAction("ResolveConf", {DialogueConf = CurrentDialogue, ConfID = NextConfID}))
  NextState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  RestartState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
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
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterSendNextActState, NextState)
  DispatchState:AddTransitionToState(FINISHED, NextState)
  ActionState:AddTransitionToState(FINISHED, NextState)
  SendSelectState:AddTransitionToState(FINISHED, NextState)
  PrepareState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  SendSelectState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PrevTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  TimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PostTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  fsm:AddTransitionToState(DialogueModuleEvent.EnterEndState, EndState)
  fsm:SetInitState(InitState)
  return fsm
end

return CreateFsm

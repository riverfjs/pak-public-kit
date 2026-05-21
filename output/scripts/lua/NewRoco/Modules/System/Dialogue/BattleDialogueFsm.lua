local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local Fsm = require("NewRoco.Modules.Core.Fsm.Fsm")
local FsmDoCmdAction = require("NewRoco.Modules.Core.Fsm.Actions.FsmDoCmdAction")
local BlockInputAction = require("NewRoco.Modules.System.Dialogue.Action.BlockInputAction")
local DialogueCameraSetupAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueCameraSetupAction")
local OpenMainDialogueAction = require("NewRoco.Modules.System.Dialogue.Action.OpenMainDialogueAction")
local DialogueNPCAnimAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueNPCAnimAction")
local DialogueWaitTalkAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitTalkAction")
local DialogueWaitUserAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitUserAction")
local ResolveCameraSettingsAction = require("NewRoco.Modules.System.Dialogue.Action.ResolveCameraSettingsAction")
local DialogueResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueResolveAction")
local DialogueDestroyAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueDestroyAction")
local UnskippableCameraMotionAction = require("NewRoco.Modules.System.Dialogue.Action.UnskippableCameraMotionAction")
local DialogueInitAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueInitAction")
local DialogueLocalDispatchAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueLocalDispatchAction")
local DialogueWaitLocalActionAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueWaitLocalActionAction")
local DialogueSendUserSelectAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueSendUserSelectAction")
local DialogueStopCurAudioAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueStopCurAudioAction")
local FsmDialogueTimelineState = require("NewRoco.Modules.System.Dialogue.FsmDialogueTimelineState")
local TimelineStateBranchAction = require("NewRoco.Modules.System.Dialogue.Action.TimelineStateBranchAction")
local DialogueTimelineResolveAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueTimelineResolveAction")
local DialoguePrevTimelineBlackScreenAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenAction")
local DialoguePrevTimelineBlackScreenOutAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineBlackScreenOutAction")
local DialoguePostTimelineWaitUserClickAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePostTimelineWaitUserClickAction")
local DialoguePrevTimelineWaitNPCSpawnAction = require("NewRoco.Modules.System.Dialogue.Action.DialoguePrevTimelineWaitNPCSpawnAction")
local DialogueStopCameraSkillAction = require("NewRoco.Modules.System.Dialogue.Action.DialogueStopCameraSkillAction")

local function CreateFsm()
  local FINISHED = "FINISHED"
  local fsm = Fsm("BattleDialogueFsm")
  local bInBattle = fsm:CreateVar("bInBattle", true)
  local bUseBattleCamera = fsm:CreateVar("bUseBattleCamera", true)
  local TargetNpcBp = fsm:CreateVar("TargetNpcBp", nil)
  local TargetPetBp = fsm:CreateVar("TargetPetBp", nil)
  local caller = fsm:CreateVar("caller", nil)
  local callback = fsm:CreateVar("callback", nil)
  local CurrentDialogue = fsm:CreateVar("CurrentDialogue", nil)
  local CurrentTimeline = fsm:CreateVar("CurrentTimeline", nil)
  local LastTimeline = fsm:CreateVar("LastTimeline", nil)
  local HasShowUIAction = fsm:CreateVar("HasShowUIAction", true)
  local HasAnySayActionInTimeline = fsm:CreateVar("HasAnySayActionInTimeline", false)
  local CameraSetting1 = fsm:CreateVar("CameraSetting1", nil)
  local CameraSetting2 = fsm:CreateVar("CameraSetting2", nil)
  local TargetSide = fsm:CreateVar("TargetSide", nil)
  local CameraSide = fsm:CreateVar("CameraSide", nil)
  local TargetValue = fsm:CreateVar("TargetValue", nil)
  local Center = fsm:CreateVar("Center", nil)
  local Options = fsm:CreateVar("Options", nil)
  local ParentModule = fsm:CreateVar("ParentModule", nil)
  local NextConfID = fsm:CreateVar("NextConfID", nil)
  local NpcIDs = fsm:CreateVar("NpcIDs", {})
  local ViewTargetTransform = fsm:CreateVar("ViewTargetTransform", nil)
  local ReturnCamera = fsm:CreateVar("ReturnCamera", true)
  local CurrentSelection = fsm:CreateVar("CurrentSelection", nil)
  local UserClicked = fsm:CreateVar("UserClicked", false)
  local InitState = fsm:CreateSequentialState("InitState")
  local PrepareState = fsm:CreateSequentialState("PrepareState")
  local DispatchState = fsm:CreateSequentialState("DispatchState")
  local SelectState = fsm:CreateSequentialState("SelectState")
  local ActionState = fsm:CreateSequentialState("ActionState")
  local NextState = fsm:CreateSequentialState("NextState")
  local EndState = fsm:CreateSequentialState("EndState")
  local RestartState = fsm:CreateSequentialState("RestartState")
  local PrevTimelineState = fsm:CreateBurstState("PrevTimelineState")
  local TimelineState = FsmDialogueTimelineState("TimelineState")
  fsm:AddState(TimelineState)
  local PostTimelineState = fsm:CreateBurstState("PostTimelineState")
  InitState:AddAction(DialogueInitAction("InitDialogue", {
    bInBattle = bInBattle,
    ConfID = NextConfID,
    TargetNPC = nil
  }))
  InitState:AddAction(BlockInputAction("InitDialogue", {Block = true}))
  PrepareState:AddAction(DialogueStopCameraSkillAction("StopCameraSkill"))
  PrepareState:AddAction(ResolveCameraSettingsAction("ResolveCameraSettings", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    DialogueConf = CurrentDialogue,
    CameraSettingFirst = CameraSetting1,
    CameraSettingSecond = CameraSetting2
  }))
  PrepareState:AddAction(DialogueCameraSetupAction("SetupCamera", {
    TargetPetBp = TargetPetBp,
    TargetNpcBp = TargetNpcBp,
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    DialogueConf = CurrentDialogue,
    TargetNPC = nil,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting1,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    Center = Center
  }))
  PrepareState:AddAction(DialogueNPCAnimAction("NPCAnim", {
    TargetNpcBp = TargetNpcBp,
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    DialogueConf = CurrentDialogue,
    TargetNPC = nil,
    NpcIDs = NpcIDs
  }))
  PrepareState:AddAction(OpenMainDialogueAction("OpenMainDialogue", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = nil,
    ConfID = NextConfID
  }))
  PrepareState:AddAction(BlockInputAction("BlockInput", {Block = false}))
  PrepareState:AddAction(UnskippableCameraMotionAction("UnskippableCameraMotionAction", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    TargetNpcBp = TargetNpcBp,
    CameraSetting = CameraSetting1,
    ParentModule = ParentModule,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    TargetNPC = nil,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = nil,
    ConfID = NextConfID,
    isLast = false,
    Center = Center
  }))
  PrepareState:AddAction(DialogueCameraSetupAction("SetupCamera2", {
    TargetPetBp = TargetPetBp,
    TargetNpcBp = TargetNpcBp,
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    DialogueConf = CurrentDialogue,
    TargetNPC = nil,
    ParentModule = ParentModule,
    CameraSetting = CameraSetting2,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    Center = Center
  }))
  PrepareState:AddAction(UnskippableCameraMotionAction("UnskippableCameraMotionAction2", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    TargetNpcBp = TargetNpcBp,
    CameraSetting = CameraSetting2,
    ParentModule = ParentModule,
    SideOfTarget = TargetSide,
    SideOfCamera = CameraSide,
    TargetValue = TargetValue,
    TargetNPC = nil,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = nil,
    ConfID = NextConfID,
    isLast = true,
    Center = Center
  }))
  PrepareState:AddAction(DialogueWaitTalkAction("WaitForUserClick", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = nil,
    ConfID = NextConfID
  }))
  DispatchState:AddAction(DialogueLocalDispatchAction("Dispatch", {
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    ConfID = NextConfID
  }))
  PrevTimelineState:AddAction(BlockInputAction("BlockInput", {Block = true}))
  PrevTimelineState:AddAction(DialogueTimelineResolveAction("ResolveTimelineJson", {CurrentDialogue = CurrentDialogue, CurrentTimeline = CurrentTimeline}))
  PrevTimelineState:AddAction(BlockInputAction("BlockInput", {Block = false}))
  PostTimelineState:AddAction(DialoguePostTimelineWaitUserClickAction("PostTimelineWaitUserClick", {
    CurrentDialogue = CurrentDialogue,
    CurrentTimeline = CurrentTimeline,
    UserClicked = UserClicked,
    ParentModule = ParentModule,
    HasShowUIAction = HasShowUIAction
  }))
  SelectState:AddAction(FsmDoCmdAction("SetPanelToSelectMode", {
    Cmd = DialogueModuleCmd.ShowOptions
  }))
  SelectState:AddAction(DialogueWaitUserAction("WaitForUserToSelect", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    ParentModule = ParentModule,
    DialogueConf = CurrentDialogue,
    Options = Options,
    Option = nil,
    ConfID = NextConfID
  }))
  SelectState:AddAction(DialogueSendUserSelectAction("SendUserSelect", {
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    CurrentSelection = CurrentSelection,
    DialogueConf = CurrentDialogue,
    Option = nil,
    ConfID = NextConfID
  }))
  ActionState:AddAction(DialogueWaitLocalActionAction("DialogueWaitLocalActionAction", {ParentModule = ParentModule, DialogueConf = CurrentDialogue}))
  NextState:AddAction(DialogueResolveAction("ResolveConf", {DialogueConf = CurrentDialogue, ConfID = NextConfID}))
  NextState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
  EndState:AddAction(DialogueDestroyAction("CloseDialogueUI", {
    TargetNpcBp = TargetNpcBp,
    caller = caller,
    callback = callback,
    bInBattle = bInBattle,
    bUseBattleCamera = bUseBattleCamera,
    TargetNPC = nil,
    Cmd = DialogueModuleCmd.CloseMainPanel,
    ParentModule = ParentModule,
    NpcIDs = NpcIDs
  }))
  RestartState:AddAction(TimelineStateBranchAction("TimelineStateBranchAction", {DialogueConf = CurrentDialogue}))
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
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterSelectState, SelectState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterActionState, ActionState)
  DispatchState:AddTransitionToState(DialogueModuleEvent.EnterNextState, NextState)
  DispatchState:AddTransitionToState(FINISHED, NextState)
  ActionState:AddTransitionToState(FINISHED, NextState)
  SelectState:AddTransitionToState(FINISHED, NextState)
  PrepareState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  SelectState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PrevTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  TimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  PostTimelineState:AddTransitionToState(DialogueModuleEvent.Restart, RestartState)
  fsm:AddTransitionToState(DialogueModuleEvent.EnterEndState, EndState)
  fsm:SetInitState(InitState)
  return fsm
end

return CreateFsm

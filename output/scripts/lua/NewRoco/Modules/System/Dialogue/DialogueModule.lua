local rapidjson = require("rapidjson")
local NpcOptionEvent = require("NewRoco.Modules.Core.NPC.Executors.NpcOptionEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueFlowFsm = require("NewRoco.Modules.System.Dialogue.DialogueFlowFsm")
local DialogueLocalFlowFsm = require("NewRoco.Modules.System.Dialogue.DialogueLocalFlowFsm")
local BattleDialogueFsm = require("NewRoco.Modules.System.Dialogue.BattleDialogueFsm")
local SyncDialogueFsm = require("NewRoco.Modules.System.Dialogue.SyncDialogueFsm")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local TextReplaceContext = require("NewRoco.Modules.System.TextReplaceContext")
local DialogueTextReplacer = require("NewRoco.Modules.System.Dialogue.DialogueTextReplacer")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UMG_DialogueSelector_C = require("NewRoco.Modules.System.Dialogue.Res.UMG_DialogueSelector_C")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
_G.DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModule = NRCModuleBase:Extend("DialogueModule")
local UITypePanelNameMapping = {
  [Enum.UIsourceType.UIT_COMMON] = {
    "DialogueCommon",
    {ShowAutoPlayUI = true}
  },
  [Enum.UIsourceType.UIT_BLACK] = {
    "DialogueBlack",
    {ShowAutoPlayUI = false, CustomAutoplayDelay = 6.0}
  },
  [Enum.UIsourceType.UIT_BLACK_ENTER] = {
    "DialogueBlack",
    {ShowAutoPlayUI = false, CustomAutoplayDelay = 6.0}
  },
  [Enum.UIsourceType.UIT_BLACK_EXIT] = {
    "DialogueBlack",
    {ShowAutoPlayUI = false, CustomAutoplayDelay = 6.0}
  },
  [Enum.UIsourceType.UIT_SHOCK] = {
    "DialogueShock",
    {ShowAutoPlayUI = true}
  },
  [Enum.UIsourceType.UIT_THINK] = {
    "DialogueThinking",
    {ShowAutoPlayUI = true}
  },
  [Enum.UIsourceType.UIT_PANGBAI] = {
    "DialogueSolo",
    {ShowAutoPlayUI = false, CustomAutoplayDelay = 6.0}
  },
  [Enum.UIsourceType.UIT_PIC2] = {
    "DialogueSpecialWithPicture",
    {ShowAutoPlayUI = true, CustomAutoplayDelay = 6.0}
  },
  [Enum.UIsourceType.UIT_TRANS] = {
    "DialogueAncient",
    {
      Translate = true,
      ShowAutoPlayUI = true,
      CustomAutoplayDelay = 6.0
    }
  },
  [Enum.UIsourceType.UIT_NOTRANS] = {
    "DialogueAncient",
    {Translate = false, ShowAutoPlayUI = true}
  },
  [Enum.UIsourceType.UIT_TITLE] = {
    "TaskFetchText",
    {ShowAutoPlayUI = false}
  },
  [Enum.UIsourceType.UIT_NIGHTMARE] = {
    "DialogueNightmare",
    {Glow = false, ShowAutoPlayUI = true}
  },
  [Enum.UIsourceType.UIT_NIGHTMAREGLOW] = {
    "DialogueNightmare",
    {Glow = true, ShowAutoPlayUI = true}
  }
}

function DialogueModule:OnConstruct()
  self.data = self:SetData("DialogueModuleData", "NewRoco.Modules.System.Dialogue.DialogueModuleData")
  self.safeguard = UMG_DialogueSelector_C
  self._currentMainPanel = "DialogueCommon"
  self.DialogueFsm = nil
  self.FsmStack = {}
  self.CameraParent = nil
  self.SideTar = nil
  self.SideKam = nil
  self.MoveDir = nil
  self.CameraBlackScreen = false
  self.PreDialogueFlag = false
  self.HasDialogue = false
  self.VideoAlreadyPlayed = {}
  self.OverrideCallbacks = {}
  self.CurDlgAudioSessionID = 0
  self.CachedActions = {}
  self.FirstEnter = true
  self.LastTalkedDialogue = false
  self.ButtonAutoplayVisible = false
  self.ButtonSkipVisible = false
  self:RegisterCmd(DialogueModuleCmd.DialogueTest, self.CmdDialogueTest)
  self:RegisterCmd(DialogueModuleCmd.HideDialoguePanel, self.HideDialogueMain)
  self:RegisterCmd(DialogueModuleCmd.ShowDialoguePanel, self.ShowDialogueMain)
  self:RegisterCmd(DialogueModuleCmd.FadeInDialogueCameraBlack, self.FadeInDialogueCameraBlack)
  self:RegisterCmd(DialogueModuleCmd.FadeOutDialogueCameraBlack, self.FadeOutDialogueCameraBlack)
  self:RegisterCmd(DialogueModuleCmd.CleanUpOptions, self.CleanUpOptions)
  self:RegisterCmd(DialogueModuleCmd.ShowDialogueBlack, self.ShowDialogueBlack)
  self:RegisterCmd(DialogueModuleCmd.FadeOutDialogueBlack, self.FadeOutDialogueBlack)
  self:RegisterCmd(DialogueModuleCmd.PlayVideo, self.PlayVideo)
  self:RegisterCmd(DialogueModuleCmd.CloseVideo, self.CloseVideo)
  self:RegisterCmd(DialogueModuleCmd.DebugAddVideo, self.DebugAddVideo)
  self:RegisterCmd(DialogueModuleCmd.VideoOnlyDialogueOver, self.VideoOnlyDialogueOver)
  self:RegisterCmd(DialogueModuleCmd.OnSyncVideo, self.OnSyncVideo)
  self:RegisterCmd(DialogueModuleCmd.OnSyncDialogue, self.OnSyncDialogue)
  self:RegisterCmd(DialogueModuleCmd.RegisterVideo, self.RegisterVideo)
  self:RegisterCmd(DialogueModuleCmd.IsVideoPlayed, self.IsVideoPlayed)
  self:RegisterCmd(DialogueModuleCmd.PlayEndAnimation, self.PlayEndAnimation)
  self:RegisterCmd(DialogueModuleCmd.RestoreCamera, self.RestoreCamera)
  self:RegisterCmd(DialogueModuleCmd.ShowStoryDebugCenter, self.ShowStoryDebugCenter)
  self:RegisterCmd(DialogueModuleCmd.ShowStartupPanel, self.ShowStartupPanel)
  self:RegisterCmd(DialogueModuleCmd.CloseStartupPanel, self.CloseStartupPanel)
  self:RegisterCmd(DialogueModuleCmd.PlayStartUpEndAnim, self.PlayStartUpEndAnim)
  self:RegisterCmd(DialogueModuleCmd.OpenNormalBlack, self.OnCmdOpenNormalBlack)
  self:RegisterCmd(DialogueModuleCmd.CloseNormalBlack, self.OnCmdCloseNormalBlack)
  self:RegisterCmd(DialogueModuleCmd.SendZoneReportTaskReq, self.SendZoneReportTaskReq)
  self:RegisterCmd(DialogueModuleCmd.OpenBloodMagic, self.OpenBloodMagic)
  self:RegisterCmd(DialogueModuleCmd.CloseBloodMagic, self.CloseBloodMagic)
  self:RegisterCmd(DialogueModuleCmd.UpdateExitConfirmMsgOn, self.UpdateExitConfirmMsgOn)
  self:RegisterCmd(DialogueModuleCmd.CheckHasDialogue, self.CheckHasDialogue)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, SceneEvent.PreLoadMapStart, self.OnPlayerDead)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, SceneEvent.OnPlayerAttacked, self.OnPlayerDead)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnPlayerDead)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, SceneEvent.OnTeleportNotify, self.OnTeleport)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, FriendModuleEvent.OnEnterVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, FriendModuleEvent.OnLeaveVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:RegisterEvent("DialogueModule", self, BattleEvent.BattleOver, self.OnBattleOver)
  self:RegPanel("DialogueBlack", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueBlack", Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("DialogueCameraBlack", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueCameraBlack", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("DialogueVideo", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueVideo", Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("DialogueTest", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueTest", Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("DialogueCommon", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueCommon", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueShock", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueShock", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueThinking", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueThinking", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueSolo", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueSolo", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueSpecialWithPicture", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_Specialdialogue", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueAncient", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueAncient", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("StoryDebugCenter", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_StoryDebugCenter", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("DialogueNightmare", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueNightmare", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("DialogueEnablement", "/Game/NewRoco/Modules/System/Dialogue/Res/DialogueTextWidgets/UMG_DialogueEnablement", Enum.UILayerType.UI_LAYER_DIALOGUE, true)
  self:RegPanel("NormalBlack", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_Dialogue_MainRoleBlack", Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("ReadingMatter_Book", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_Book", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, true)
  self:RegPanel("ReadingMatter_Note", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_Note", Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("ReadingMatter_Scrolls", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_Scroll", Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("PetGiftPanel", "/Game/NewRoco/Modules/System/Dialogue/Res/DialogueTextWidgets/UMG_DialogueText_Intimacy", Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("TaskFetchText", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_TaskFetchText", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("DialogueOverlay", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueOverlay", Enum.UILayerType.UI_LAYER_DIALOGUE_OVERLAY)
  self:RegPanel("ReasonanceMagic", "/Game/NewRoco/Modules/System/LevelUpUI/Res/UMG_ResonanceMagic", Enum.UILayerType.UI_LAYER_DIALOGUE)
  self:RegPanel("MapModeSelection", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_MapModeSelection", Enum.UILayerType.UI_LAYER_POPUP, nil, true)
  self:RegPanel("TeachingImageUI", "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_TaskGuidanceBetweenChapters", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, true)
  self:RegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished, self.OnTalkFinishMonitor)
  self.LastDialogueEndTime = -1
  self.StatusChecker = StatusCheckerGroup({
    StatusCheckerEnum.Scene,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.MainPanel,
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Loading
  }, Log.LOG_LEVEL.ELogDebug, "Dialogue")
  self.IdleChecker = StatusCheckerGroup({
    StatusCheckerEnum.FastLoading,
    StatusCheckerEnum.Loading
  }, Log.LOG_LEVEL.ELogDebug, "DialogueIdle")
  NPCLuaUtils.PreLoad("WidgetBlueprint'/Game/NewRoco/Modules/System/Dialogue/Res/DialogueComponentWidgets/UMG_DialogueSelector.UMG_DialogueSelector_C'")
  if _G.GlobalConfig.PrepareForCE then
    DialogueUtils.SkipDialogue = false
    self:OpenPanel("StoryDebugCenter")
  end
end

function DialogueModule:OnTalkFinishMonitor(Dialogue)
  if Dialogue then
    self.LastTalkedDialogue = Dialogue
  end
  local PanelDialogue = Dialogue and Dialogue.id or "no dialogue"
  local FrontFsm = self:GetFrontDialogue()
  if FrontFsm and FrontFsm.GetNextStateName then
    local ActiveStateName = FrontFsm:GetActiveStateName()
    local NextStateName = FrontFsm:GetNextStateName()
    Log.Debug("DialogueModule:OnTalkFinishMonitor", PanelDialogue, FrontFsm:GetName(), ActiveStateName, NextStateName)
  else
    Log.Debug("DialogueModule:OnTalkFinishMonitor", PanelDialogue, "\230\178\161\230\156\137Fsm")
  end
end

function DialogueModule:GetLastTalkedDialogue()
  local Conf = self.LastTalkedDialogue
  self.LastTalkedDialogue = false
  return Conf
end

function DialogueModule:ShowStoryDebugCenter(bTurnOn)
  if bTurnOn then
    self:OpenPanel("StoryDebugCenter")
  else
    self:ClosePanel("StoryDebugCenter")
  end
end

function DialogueModule:CmdOpenMapModeSelection(IsBigWorldOpen, action)
  self:OpenPanel("MapModeSelection", IsBigWorldOpen, action)
end

function DialogueModule:OpenTeachingImageUI(teach_id, action)
  self:OpenPanel("TeachingImageUI", teach_id, action)
end

function DialogueModule:ShowStartupPanel(Action)
  self:OpenPanel("DialogueEnablement", Action)
end

function DialogueModule:PlayStartUpEndAnim()
  local StartUpPanel = self:GetPanel("DialogueEnablement")
  if StartUpPanel then
    StartUpPanel:PlayAnimation(StartUpPanel.Out)
    StartUpPanel.Action:PlayLevel4()
  else
    Log.Error("\230\156\170\232\142\183\229\190\151\226\128\152\230\180\155\229\133\139\229\143\183\229\144\175\229\138\168\226\128\153UI\233\157\162\230\157\191")
  end
end

function DialogueModule:CloseStartupPanel()
  self:ClosePanel("DialogueEnablement")
end

function DialogueModule:OnPlayerDead()
  self:DispatchEvent(DialogueModuleEvent.BattleOver)
  self:ShutDownAllDialogueFsm()
end

function DialogueModule:OnEnterOrLeaveVisit()
  self:ShutDownAllDialogueFsm()
end

function DialogueModule:OnTeleport(Notify, NoLoading)
  if self.DialogueFsm then
    self.DialogueFsm:SetProperty("PlayerPosSyncBlocker", false)
    local player = DialogueUtils.GetHero()
    if player.movementComponent and player.movementComponent.SetSyncMove then
      player.movementComponent:SetSyncMove(true)
    end
  end
  if not NoLoading then
    return
  end
  self:OnPlayerDead()
end

function DialogueModule:IsInBlackScreen()
  if self._currentMainPanel == "DialogueBlack" then
    return true
  else
    return false
  end
end

function DialogueModule:ShutDownAllDialogueFsm()
  local HasDialogueToClose = false
  while self.DialogueFsm do
    self.DialogueFsm:SetProperty("bIsReconnect", true)
    if self.DialogueFsm.active then
      HasDialogueToClose = true
    end
    self:OnCloseDialogue()
  end
  if HasDialogueToClose then
    _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.ReturnCamera, self.ParentModule)
  end
end

function DialogueModule:RegisterVideo(VideoPath)
  self.VideoAlreadyPlayed[VideoPath] = true
end

function DialogueModule:IsVideoPlayed(VideoPath)
  if self.VideoAlreadyPlayed[VideoPath] then
    return true
  else
    return false
  end
end

function DialogueModule:DebugAddVideo(param)
  self:SetHasDialogue(true)
  if self:HasPanel("DialogueVideo") then
    local UMG_DialogueVideo = self:GetPanel("DialogueVideo")
    UMG_DialogueVideo:DebugAddVideo(param)
  end
  local player = DialogueUtils.GetPlayer()
  if player and player.inputComponent then
    player.inputComponent:PlayDialogueVideo(true)
  end
end

function DialogueModule:PlayVideo(param)
  self:SetHasDialogue(true)
  if self:HasPanel("DialogueVideo") then
    self:ClosePanel("DialogueVideo")
  end
  local player = DialogueUtils.GetPlayer()
  if player and player.inputComponent then
    player.inputComponent:PlayDialogueVideo(true)
  end
  self:OpenPanel("DialogueVideo", param)
end

function DialogueModule:CloseVideo()
  if self:HasPanel("DialogueVideo") then
    local DialogueVideo = self:GetPanel("DialogueVideo")
    if DialogueVideo then
      DialogueVideo:MovieDone(true)
    end
    self:SetHasDialogue(false)
  end
  self:ClosePanel("DialogueVideo")
end

function DialogueModule:OnOpenPanelCallback(panelName, panelIndex, isSucc)
  NRCModuleBase.OnOpenPanelCallback(self, panelName, panelIndex, isSucc)
  if not isSucc and "DialogueVideo" == panelName then
    self:SetHasDialogue(false)
    Log.Error("DialogueModule open dialogue video panel failed!!!!!")
    local player = DialogueUtils.GetPlayer()
    if player and player.inputComponent then
      player.inputComponent:PlayDialogueVideo(false)
    end
  end
end

function DialogueModule:VideoOnlyDialogueOver()
  self:SetHasDialogue(false)
end

function DialogueModule:OnBattleOver()
  self:DispatchEvent(DialogueModuleEvent.BattleOver)
end

function DialogueModule:CmdDialogueTest()
  self:OpenPanel("DialogueTest")
end

function DialogueModule:Write()
  NRCEventCenter:DispatchEvent(DialogueModuleEvent.StartTyping)
end

function DialogueModule:RegPanel(name, path, layer, isSingleTouchPanel, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer or _G.Enum.UILayerType.UI_LAYER_DIALOGUE
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function DialogueModule:OnActive()
  if NRCModuleManager:IsModuleRegistered("TowerModeModule") then
    NRCModuleManager:ActiveModule("TowerModeModule")
  end
  self.resRequest = NRCResourceManager:LoadResAsync(self, "/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueBlack.UMG_DialogueBlack_C", -1, 10, function(caller, resRequest, asset)
    Log.Debug("[DialogueModule] OnActive LoadPanel succ:/Game/NewRoco/Modules/System/Dialogue/Res/UMG_DialogueBlack.UMG_DialogueBlack_C")
  end)
end

function DialogueModule:OnOverlayPanelPreloaded()
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay then
    UMG_Overlay.UMG_Skip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    UMG_Overlay.UMG_Autoplay:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.ButtonSkipVisible then
    self:ShowButtonSkip(self.ButtonSkipCaller, self.ButtonSkipCallback)
  end
  if self.ButtonAutoplayVisible then
    self:ShowButtonAutoPlay()
  end
  if self.ButtonExitVisible then
    self:ShowButtonExit()
  end
end

function DialogueModule:GetFrontDialogue()
  if #self.FsmStack < 1 then
    return nil
  else
    return self.FsmStack[#self.FsmStack]
  end
end

function DialogueModule:CreateNewFsm(CreationFunction)
  local NewDialogueFsm = CreationFunction()
  table.insert(self.FsmStack, NewDialogueFsm)
  return NewDialogueFsm
end

function DialogueModule:RemoveFrontFsm()
  if #self.FsmStack < 1 then
    return false
  else
    local Fsm = table.remove(self.FsmStack, #self.FsmStack)
    if Fsm and self.data.SavedTargetView then
      self.data.SavedTargetView[Fsm] = nil
    end
    local NextFsm = self:GetFrontDialogue()
    return NextFsm
  end
end

function DialogueModule:RemoveFsm(fsm)
  if not fsm then
    return
  end
  return table.removeValue(self.FsmStack, fsm)
end

function DialogueModule:MakeFsmFront(fsm)
  if not table.contains(self.FsmStack, fsm) then
    Log.Error("\229\175\185\232\175\157\231\138\182\230\128\129\230\156\186\231\174\161\231\144\134\229\157\143\228\186\134...")
    return false
  end
  table.removeValue(self.FsmStack, fsm)
  table.insert(self.FsmStack, fsm)
  self.DialogueFsm = self:GetFrontDialogue()
  return true
end

function DialogueModule:GetBattleDialogue()
  for i = 1, #self.FsmStack do
    local Fsm = self.FsmStack[i]
    if Fsm:GetProperty("bInBattle", false) then
      return Fsm
    end
  end
  return nil
end

function DialogueModule:GetCommonDialogue()
  for i = #self.FsmStack, 1, -1 do
    local Fsm = self.FsmStack[i]
    if not Fsm:GetProperty("bInBattle", false) then
      return Fsm
    end
  end
  return nil
end

function DialogueModule:GetLocalDialogue()
  for i = #self.FsmStack, 1, -1 do
    local Fsm = self.FsmStack[i]
    if Fsm:GetProperty("IsLocalDialogue", false) then
      return Fsm
    end
  end
  return nil
end

function DialogueModule:OnOpenMainPanel(EnterCallback, EnterCaller)
  if not self.DialogueFsm then
    return
  end
  local DialogueConf = self.DialogueFsm:GetProperty("CurrentDialogue")
  if not DialogueConf then
    return
  end
  local ContextOption = self.DialogueFsm:GetProperty("CurrentOption")
  local UIType = DialogueConf.ui_source_type
  UE4.UNRCTUIStatics.ReleaseCursorCapture(0)
  self:_OpenConfiggedPanel(DialogueConf, self.PreUIType, ContextOption, nil, EnterCallback, EnterCaller)
  self.PreUIType = UIType
  if _G.BattleManager.isInBattle then
    _G.NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  _G.NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  local ShouldPlaySound = true
  local CurrentTimeline = self.DialogueFsm:GetProperty("CurrentTimeline")
  if CurrentTimeline then
    local play_dialogue_sound_when_show_ui_if_no_say_action = CurrentTimeline.play_dialogue_sound_when_show_ui_if_no_say_action == nil or CurrentTimeline.play_dialogue_sound_when_show_ui_if_no_say_action
    local HasAnySayActionInTimeline = self.DialogueFsm:GetProperty("HasAnySayActionInTimeline")
    if play_dialogue_sound_when_show_ui_if_no_say_action and not HasAnySayActionInTimeline then
      ShouldPlaySound = true
    else
      ShouldPlaySound = false
    end
  end
  if ShouldPlaySound then
    self:PlayDialogueAudio(DialogueConf.dialogue_sound, DialogueConf.dialogue_sound_id)
  end
end

function DialogueModule:PlayDialogueAudio(InSoundFile, InSoundID)
  self:StopCurDialogueAudio()
  if InSoundID and InSoundID > 0 then
    self.CurDlgAudioSessionID = _G.NRCAudioManager:PlaySound2DAuto(InSoundID)
    self.CurDlgAudioLength = _G.NRCAudioManager:GetMaxTimeFromID(InSoundID)
  elseif not string.IsNilOrEmpty(InSoundFile) then
    self.CurDlgAudioSessionID = _G.NRCAudioManager:PlaySound2DByEventNameAuto(InSoundFile)
    self.CurDlgAudioLength = _G.NRCAudioManager:GetMaxTimeFromEventName(InSoundFile)
  end
  if self.CurDlgAudioSessionID and self.CurDlgAudioSessionID > 0 then
    self.CurDlgAudioStartTime = UE4.UGameplayStatics.GetTimeSeconds(_G.UE4Helper.GetCurrentWorld())
    _G.NRCAudioManager:AddSessionFinishCallback(self.CurDlgAudioSessionID, self, self.OnDialogueAudioFinish)
  end
end

function DialogueModule:IsCurDialogueAudioPlaying()
  return self.CurDlgAudioSessionID and self.CurDlgAudioSessionID > 0
end

function DialogueModule:GetCurDialogueAudioProgress()
  if self.CurDlgAudioSessionID and self.CurDlgAudioSessionID > 0 then
    if self.CurDlgAudioLength and self.CurDlgAudioLength > 1.0E-4 then
      local CurTime = UE4.UGameplayStatics.GetTimeSeconds(_G.UE4Helper.GetCurrentWorld())
      return math.clamp((CurTime - self.CurDlgAudioStartTime) / self.CurDlgAudioLength, 0.0, 1.0)
    end
    return 1.0
  end
  return 1.0
end

function DialogueModule:StopCurDialogueAudio()
  if self.CurDlgAudioSessionID and self.CurDlgAudioSessionID > 0 then
    _G.NRCAudioManager:ReleaseSession(self.CurDlgAudioSessionID, true, "DialogueModule")
    self.CurDlgAudioSessionID = 0
  end
end

function DialogueModule:OnDialogueAudioFinish(InAudioSessionID)
  if self.CurDlgAudioSessionID == InAudioSessionID then
    self.CurDlgAudioSessionID = 0
  end
end

function DialogueModule:OpenMainUIOnBattleAndDialogueEnd(callback, caller)
  if not self.HasDialogue then
    return false
  end
  local DialogueConf = self.DialogueFsm:GetProperty("CurrentDialogue")
  if not DialogueConf then
    return false
  end
  self.OpenMainUIOnDialogueEnd = true
  DialogueUtils.RegisterCallback(self, caller, callback, "Battle", "MainUIControlOnBattleLeave")
  return true
end

function DialogueModule:CheckedOpenMainUIOnDialogueEnd()
  if self.OpenMainUIOnDialogueEnd then
    DialogueUtils.CallAndRemoveCallback(self, "Battle", "MainUIControlOnBattleLeave")
    self.OpenMainUIOnDialogueEnd = false
  else
  end
end

function DialogueModule:TryCloseAllPanel(bIncludeBlack)
  self:ClosePanel("DialogueCommon")
  self:ClosePanel("DialogueShock")
  self:ClosePanel("DialogueThinking")
  self:ClosePanel("DialogueSolo")
  self:ClosePanel("DialogueSpecialWithPicture")
  self:ClosePanel("DialogueAncient")
  self:ClosePanel("DialogueNightmare")
  self.PanelOn = false
  self.PreUIType = nil
  if self:HasPanel("DialogueBlack") or self:IsPanelInOpening("DialogueBlack") then
    local BlackPanel = self:GetPanel("DialogueBlack")
    if BlackPanel then
      if BlackPanel.enableView and BlackPanel:GetIsVisible() and BlackPanel:GetIsEnabled() then
        if BlackPanel:HasFadeOutDone() then
          Log.Debug("[DialogueFlow]Try to close Dialogue black...... silent close")
          self:ClosePanel("DialogueBlack")
        else
          Log.Debug("[DialogueFlow]Try to close Dialogue black...... with animation")
          BlackPanel:PlayEndAnimationDirect()
        end
      else
        Log.Debug("[DialogueFlow]Try to close Dialogue black...... force close")
        self:ClosePanel("DialogueBlack")
      end
    else
      Log.Debug("[DialogueFlow]Try to close Dialogue black, it's still loading, force close")
      self:ClosePanel("DialogueBlack")
    end
  end
end

function DialogueModule:CloseMessage()
  if self.SkipMessageOn or self.ExitConfirmMsgOn then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
  end
  self.ExitConfirmMsgOn = nil
  self.SkipMessageOn = nil
end

function DialogueModule:UpdateExitConfirmMsgOn(bFlag)
  self.ExitConfirmMsgOn = bFlag
end

function DialogueModule:_OpenConfiggedPanel(DialogueConf, PreUIType, ContextOption, extraConf, EnterCallback, EnterCaller)
  local OpenData = UITypePanelNameMapping[DialogueConf.ui_source_type]
  OpenData = OpenData or UITypePanelNameMapping[Enum.UIsourceType.UIT_COMMON]
  self:_OpenMainPanelByName(OpenData[1], DialogueConf, ContextOption, extraConf or OpenData[2], EnterCallback, EnterCaller)
  local SpectatorMode = self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode", false)
  local isBattleDialogue = self.DialogueFsm and self.DialogueFsm:GetProperty("bInBattle", false) or false
  local bShowButtonAutoPlay = #OpenData >= 2 and OpenData[2].ShowAutoPlayUI and not isBattleDialogue and not SpectatorMode
  if bShowButtonAutoPlay then
    self:ShowButtonAutoPlay()
  else
    self:CloseButtonAutoPlay()
  end
  local ServerActionInfo = self.DialogueFsm and self.DialogueFsm:GetProperty("ActionInfo", nil)
  local bShowButtonSkip = ServerActionInfo and (ServerActionInfo.dialog_id == DialogueConf.id or ServerActionInfo.bound_dialog_id == DialogueConf.id) and (ServerActionInfo.dialog_skip_state == ProtoEnum.DialogSkipState.DSS_SKIPPABLE or ServerActionInfo.dialog_skip_state == ProtoEnum.DialogSkipState.DSS_STOP_AND_SKIPPABLE) and DialogueConf.ui_source_type ~= Enum.UIsourceType.UIT_BLACK and DialogueConf.ui_source_type ~= Enum.UIsourceType.UIT_BLACK_ENTER and DialogueConf.ui_source_type ~= Enum.UIsourceType.UIT_BLACK_EXIT and not SpectatorMode
  if bShowButtonSkip then
    self:ShowButtonSkip(self, self.OnSkipDialogue)
  else
    if self.SkipMessageOn then
      self:CloseMessage()
    end
    self:CloseButtonSkip()
  end
  local bShowButtonExit = SpectatorMode
  if bShowButtonExit then
    self:ShowButtonExit()
  else
    self:CloseButtonExit()
  end
end

function DialogueModule:_OpenMainPanelByName(PanelName, DialogueConf, ContextOption, ExtraConf, EnterCallback, EnterCaller)
  Log.DebugFormat("[DialogueFlow]Open main panel: %s, Dialogue ID: %d", PanelName, DialogueConf and DialogueConf.id or 0)
  local bBlockEnterAnimation = false
  if self._currentMainPanel == PanelName then
    bBlockEnterAnimation = true
  else
    self:TryCloseAllPanel()
  end
  self._currentMainPanel = PanelName
  self.PanelOn = true
  if self:HasPanel(PanelName) then
    local DialoguePanel = self:GetPanel(PanelName)
    if DialoguePanel then
      self:EnablePanel(PanelName)
      DialoguePanel:RefreshView(DialogueConf, ContextOption, bBlockEnterAnimation, ExtraConf, EnterCallback, EnterCaller)
    end
  else
    self.safeguard = require("NewRoco.Modules.System.Dialogue.Res.UMG_DialogueSelector_C")
    self:OpenPanel(PanelName, DialogueConf, ContextOption, bBlockEnterAnimation, ExtraConf, EnterCallback, EnterCaller)
  end
end

function DialogueModule:OnCloseMainPanel()
  self:TryCloseAllPanel()
  self:CloseMessage()
  self:CloseButtonAutoPlay()
  self:CloseButtonSkip()
end

function DialogueModule:OpenBloodMagic(Action)
  if not self:HasPanel("ReasonanceMagic") then
    self:OpenPanel("ReasonanceMagic", Action)
  end
end

function DialogueModule:CloseBloodMagic()
  if self:HasPanel("ReasonanceMagic") then
    self:ClosePanel("ReasonanceMagic")
  end
end

function DialogueModule:ShowDialogueBlack(conf, prev, extraConf, contextOption)
  conf.ui_source_type = Enum.UIsourceType.UIT_BLACK
  self:_OpenConfiggedPanel(conf, nil, contextOption, extraConf)
  self.PreUIType = conf.ui_source_type
end

function DialogueModule:FadeInDialogueCameraBlack()
  if self:HasPanel("DialogueCameraBlack") then
    local DialogueCameraBlack = self:GetPanel("DialogueCameraBlack")
    if DialogueCameraBlack then
      self:EnablePanel("DialogueCameraBlack")
    end
  else
    self:OpenPanel("DialogueCameraBlack")
  end
  self.CameraBlackScreen = true
end

function DialogueModule:FadeOutDialogueBlack()
  if self:HasPanel("DialogueBlack") then
    local Panel = self:GetPanel("DialogueBlack")
    Panel:PlayEndAnimation()
    self._currentMainPanel = nil
    self.PreUIType = nil
  end
end

function DialogueModule:FadeOutDialogueCameraBlack()
  if self:HasPanel("DialogueCameraBlack") then
    local Panel = self:GetPanel("DialogueCameraBlack")
    Panel:DoFadeOut()
    self.CameraBlackScreen = false
  else
    self:ClosePanel("DialogueCameraBlack")
  end
end

function DialogueModule:OnShowOptions()
  if not self.DialogueFsm then
    Log.Error("\229\175\185\232\175\157\231\138\182\230\128\129\230\156\186\229\183\178\231\187\143\233\148\128\230\175\129\239\188\140\232\175\183\230\163\128\230\159\165\230\151\182\229\186\143")
    return
  end
  local Options = self.DialogueFsm:GetProperty("Options")
  local Option = self.DialogueFsm:GetProperty("CurrentOption")
  if self:HasPanel(self._currentMainPanel) then
    local Panel = self:GetPanel(self._currentMainPanel)
    Panel:ShowOptions(Options, Option)
  else
    self:LogError("Need to show option but not panel...")
  end
end

function DialogueModule:RestoreDialogue(Option, Action, DialogueID)
  if not Option then
    Log.Error("[DialogueFlow]\229\174\162\230\136\183\231\171\175\230\129\162\229\164\141\229\175\185\232\175\157\229\164\177\232\180\165,Option\228\184\186\231\169\186", DialogueID)
    return
  end
  local Conf = Option.config
  if not Conf then
    Log.Error("[DialogueFlow]\229\174\162\230\136\183\231\171\175\230\129\162\229\164\141\229\175\185\232\175\157\229\164\177\232\180\165,Conf\228\184\186\231\169\186", DialogueID)
    return
  end
  if not Action then
    Log.Error("[DialogueFlow]\229\174\162\230\136\183\231\171\175\230\129\162\229\164\141\229\175\185\232\175\157\229\164\177\232\180\165,Action\228\184\186\231\169\186", Conf and Conf.id, DialogueID)
    return
  end
  Log.Debug("[DialogueFlow]\229\174\162\230\136\183\231\171\175\229\135\134\229\164\135\230\129\162\229\164\141\229\175\185\232\175\157", Conf, DialogueID)
  Log.Dump(Action.Info, 2, "[DialogueFlow] Show Restore Action")
  self:PreUnregisterOption(Option)
  self:PreRegisterOption(Option)
  self.StatusChecker:Check(self, self.OnStartDialogue, Option, Action, DialogueID, true)
end

function DialogueModule:OnStartDialogueInBattle(TargetNpcBp, DialogueConfId, caller, callback, TargetPetBp)
  self:SetHasDialogue(true)
  self.HasBattleDialogue = true
  self.DialogueFsm = self:CreateNewFsm(BattleDialogueFsm)
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueConfId)
  if DialogueConf then
    self.Controller = UE4.UGameplayStatics.GetPlayerController(UE4Helper.GetCurrentWorld(), 0)
    local bUseBattleCamera = false
    local BattleActors = DialogueUtils.BuildBattleActors()
    local TargetNPC = BattleActors[-2]
    local TargetView = DialogueUtils.ExtraActorView(TargetNPC)
    local BornTransform
    if TargetView then
      local Transform = TargetView:Abs_GetTransform()
      BornTransform = UE.FTransform(Transform.Rotation, Transform.Translation, Transform.Scale3D)
    end
    self.DialogueFsm:SetProperty("TargetNpcBp", TargetNpcBp)
    self.DialogueFsm:SetProperty("TargetPetBp", TargetPetBp)
    self.DialogueFsm:SetProperty("ExtraActors", BattleActors)
    self.DialogueFsm:SetProperty("ParentModule", self)
    self.DialogueFsm:SetProperty("NextConfID", DialogueConfId)
    self.DialogueFsm:SetProperty("bInBattle", true)
    self.DialogueFsm:SetProperty("bUseBattleCamera", bUseBattleCamera)
    self.DialogueFsm:SetProperty("BornTransform", BornTransform)
    self.DialogueFsm:SetProperty("caller", caller)
    self.DialogueFsm:SetProperty("callback", callback)
    self.DialogueFsm:SetProperty("ReturnCamera", true)
    self.DialogueFsm:Play()
    DialogueUtils.ToggleInput(false)
  end
end

function DialogueModule:OnOverridePropertiesInBattleFsm(Properties)
  if not self.HasBattleDialogue then
    return
  end
  for K, V in pairs(Properties) do
    self.DialogueFsm:SetProperty(K, V)
  end
end

function DialogueModule:OnStartDialogue(Option, Action, DialogueID, bIsRestore)
  if self.HasBattleDialogue then
    self:OnCloseDialogueInBattle()
    self.HasBattleDialogue = false
  end
  self.LastConf = nil
  self.LastTarget = nil
  self.LastPlayer = nil
  self.FirstEnter = true
  self._currentMainPanel = nil
  self.PreUIType = nil
  local ActionInfo = Action and Action.Info
  local OptionInfo = Option and Option.optionInfo
  if ActionInfo and OptionInfo then
    local ActionInfoDialogueID = math.max(ActionInfo.dialog_id, ActionInfo.bound_dialog_id)
    local ActionStatus = table.getKeyName(ProtoEnum.SpaceEnum_NpcActionStatus.ENUM, ActionInfo.act_status)
    Log.DebugFormat("[DialogueFlow]\229\174\162\230\136\183\231\171\175\229\188\128\229\167\139\229\175\185\232\175\157:option_id:%d,first_dialog_id:%d,dialog_id:%d,act_status:%s", OptionInfo.option_id, OptionInfo.first_dialog_id or 0, ActionInfoDialogueID, ActionStatus)
  else
    Log.Debug("[DialogueFlow]\229\174\162\230\136\183\231\171\175\229\188\128\229\167\139\229\175\185\232\175\157:\230\178\161\230\156\137\229\175\185\232\175\157\230\149\176\230\141\174,\230\151\160\230\179\149\229\188\128\229\167\139")
  end
  if not Option then
    Log.Error("\228\188\160\229\133\165\231\154\132NpcOption\228\184\186\231\169\186")
    return
  end
  Action.ShouldRestore = false
  DialogueID = DialogueID and DialogueID or 0
  if 0 == DialogueID then
    if ActionInfo then
      DialogueID = DialogueUtils.ResolveDialogueID(ActionInfo)
    else
      Log.Debug("no action info found")
    end
  end
  if 0 == DialogueID then
    if bIsRestore then
      self:PreUnregisterOption(Option)
      return
    end
    local ActionConfig = Option.config and Option.config.action
    local ActionType = ActionConfig and ActionConfig.action_type
    if ActionType == Enum.ActionType.ACT_DIALOG then
      DialogueID = tonumber(ActionConfig.action_param1)
    else
      Log.Error("Option\229\134\133Action\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133ActionType\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\239\188\129")
      Log.Dump(Option, 4, "Show Wrong Option")
    end
  end
  if 0 == DialogueID then
    Option:SetNeedStatusNotify(false)
    self:PreUnregisterOption(Option)
    return
  end
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueID)
  if not DialogueConf then
    Option:SetNeedStatusNotify(false)
    self:PreUnregisterOption(Option)
    return
  end
  self:SetHasDialogue(true)
  local CommonDialogue = self:GetCommonDialogue()
  if CommonDialogue then
    CommonDialogue:Stop()
    self.DialogueFsm = CommonDialogue
  else
    self.DialogueFsm = self:CreateNewFsm(DialogueFlowFsm)
  end
  Option:AddEventListener(self, NpcOptionEvent.Destroy, self.OnOptionDestroy)
  local Participants = DialogueUtils.CollectParticipants(DialogueConf.id)
  self.DialogueFsm:SetProperty("ParentModule", self)
  self.DialogueFsm:SetProperty("TargetNPC", Option.owner)
  self.DialogueFsm:SetProperty("CurrentOption", Option)
  self.DialogueFsm:SetProperty("Options", nil)
  self.DialogueFsm:SetProperty("bInBattle", false)
  self.DialogueFsm:SetProperty("bIsReconnect", false)
  self.DialogueFsm:SetProperty("CurrentAction", Action)
  self.DialogueFsm:SetProperty("Participants", Participants)
  self.DialogueFsm:SetProperty("NextConfID", DialogueConf.id)
  self.DialogueFsm:SetProperty("Action", Action)
  self.DialogueFsm:SetProperty("ReturnCamera", true)
  self.DialogueFsm:SetProperty("bIsRestore", bIsRestore)
  self.DialogueFsm:Play()
  DialogueUtils.ToggleInput(false)
end

function DialogueModule:OnStartDialogueLocal(Option, Action, DialogueID, bIsRestore)
  if self.HasBattleDialogue then
    self:OnCloseDialogueInBattle()
    self.HasBattleDialogue = false
  end
  self.LastConf = nil
  self.LastTarget = nil
  self.LastPlayer = nil
  self.FirstEnter = true
  self._currentMainPanel = nil
  self.PreUIType = nil
  self:Log("OnStartDialogue", table.tostring(Action.Info))
  if not Option then
    Log.Error("\228\188\160\229\133\165\231\154\132NpcOption\228\184\186\231\169\186")
    return
  end
  Action.ShouldRestore = false
  DialogueID = DialogueID and DialogueID or 0
  local IsRestore = false
  if 0 == DialogueID then
    local ActionInfo = Action and Action.Info
    if ActionInfo then
      DialogueID = DialogueUtils.ResolveDialogueID(ActionInfo)
    else
      Log.Debug("no action info found")
    end
  end
  if 0 == DialogueID then
    local ActionConfig = Option.config and Option.config.action
    local ActionType = ActionConfig and ActionConfig.action_type
    if ActionType == Enum.ActionType.ACT_DIALOG then
      DialogueID = tonumber(ActionConfig.action_param1)
      IsRestore = false
    else
      Log.Error("Option\229\134\133Action\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133ActionType\231\177\187\229\158\139\228\184\141\229\140\185\233\133\141\239\188\129")
      Log.Dump(Option, 4, "Show Wrong Option")
    end
  end
  if 0 == DialogueID then
    Option:SetNeedStatusNotify(false)
    self:PreUnregisterOption(Option)
    return
  end
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueID)
  if not DialogueConf then
    Option:SetNeedStatusNotify(false)
    self:PreUnregisterOption(Option)
    return
  end
  self:SetHasDialogue(true)
  local LocalDialogue = self:GetLocalDialogue()
  if LocalDialogue then
    LocalDialogue:Stop()
    self.DialogueFsm = LocalDialogue
  else
    self.DialogueFsm = self:CreateNewFsm(DialogueLocalFlowFsm)
  end
  Option:AddEventListener(self, NpcOptionEvent.Destroy, self.OnOptionDestroy)
  local Participants = DialogueUtils.CollectParticipants(DialogueConf.id)
  self.DialogueFsm:SetProperty("IsLocalDialogue", true)
  self.DialogueFsm:SetProperty("ParentModule", self)
  self.DialogueFsm:SetProperty("TargetNPC", Option.owner)
  self.DialogueFsm:SetProperty("CurrentOption", Option)
  self.DialogueFsm:SetProperty("Options", nil)
  self.DialogueFsm:SetProperty("bInBattle", false)
  self.DialogueFsm:SetProperty("bIsReconnect", false)
  self.DialogueFsm:SetProperty("CurrentAction", Action)
  self.DialogueFsm:SetProperty("Participants", Participants)
  self.DialogueFsm:SetProperty("NextConfID", DialogueConf.id)
  self.DialogueFsm:SetProperty("Action", Action)
  self.DialogueFsm:SetProperty("ReturnCamera", true)
  self.DialogueFsm:Play()
  DialogueUtils.ToggleInput(false)
end

function DialogueModule:PreRegisterOption(Option)
  Option:AddEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionInfoChange)
end

function DialogueModule:PreUnregisterOption(Option)
  Option:RemoveEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionInfoChange)
end

function DialogueModule:OnOptionInfoChange(option, action)
  if action and action.is_cancel then
    local List = self.CachedActions[option]
    if List then
      table.clear(List)
    end
    self.CachedActions[option] = nil
    self:OnCloseDialogue()
    return
  end
  local List = self.CachedActions[option]
  if not List then
    List = {}
    self.CachedActions[option] = List
  end
  if not action.act_info then
    return
  end
  if Log.GetLogLevel() <= Log.LOG_LEVEL.ELogDebug then
    Log.DebugFormat("[DialogueFlow] \230\156\141\229\138\161\229\153\168\230\142\168\232\191\155Action\230\137\167\232\161\140,option_id:%d,dialog_id:%d,act_status:%s,next_dialog_id:%s", option.optionInfo.option_id, math.max(action.act_info.dialog_id, action.act_info.bound_dialog_id), table.getKeyName(ProtoEnum.SpaceEnum_NpcActionStatus.ENUM, action.act_info.act_status or 0), action.act_info.next_dialog_id or "\230\178\161\230\156\137next_dialog_id")
  end
  table.insert(List, action.act_info)
  if action.act_info.act_type == Enum.ActionType.ACT_PET_CATCH_REPORT and action.act_info.act_status == _G.ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing then
    self.LastPetSubmitReportInfo = action.act_info.begin_act_params
  end
  self:DispatchEvent(DialogueModuleEvent.ForwardOptionChange, option)
  if action.act_info.act_status == _G.ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing and action.act_info.dialog_skip_state == _G.ProtoEnum.DialogSkipState.DSS_ACT_INVALID then
    local dialogue_id = action.act_info.dialog_id
    if not dialogue_id or 0 == dialogue_id then
      dialogue_id = action.act_info.bound_dialog_id
    end
    Log.ErrorFormat("[DialogueFlow] Skippable dialogue %d contains invalid action", dialogue_id)
    if not _G.RocoEnv.IS_SHIPPING then
      OpenMessageBox("Error", string.format("Skippable dialogue %d contains invalid action", dialogue_id), LuaText.tips_dialog_butten_accept, LuaText.CANCEL, DialogContext.Mode.OK)
    end
  end
end

function DialogueModule:OnOptionDestroy(Option)
  self:Log("OnOptionDestroy", Option.optionInfo.option_id)
end

function DialogueModule:OnCloseDialogue()
  Log.Debug("DialogueModule:OnCloseDialogue")
  self:SetHasDialogue(false)
  if not self.DialogueFsm then
    return
  end
  self.DialogueFsm:Resume()
  self.DialogueFsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
  self:TryCloseAllPanel()
  self:CloseMessage()
  self:RemoveFrontFsm()
  self.DialogueFsm = nil
  if self:CheckHasDialogue() then
    self:SetHasDialogue(true)
  end
end

function DialogueModule:CleanUpBattleFsm()
  local BattleDialogue = self:GetBattleDialogue()
  if not BattleDialogue then
    return
  end
  self:SetHasDialogue(false)
  self:TryCloseAllPanel()
  self:CloseMessage()
  self:RemoveFsm(BattleDialogue)
  BattleDialogue:Stop()
  self.HasBattleDialogue = false
  self.DialogueFsm = self:GetFrontDialogue()
  if self:CheckHasDialogue() then
    self:SetHasDialogue(true)
  end
end

function DialogueModule:OnCloseDialogueInBattle()
  Log.Debug("DialogueModule:OnCloseDialogueInBattle")
  if not self.HasBattleDialogue then
    return
  end
  local BattleDialogue = self:GetBattleDialogue()
  if not BattleDialogue then
    return
  end
  if BattleDialogue.finished then
    self:RemoveFsm(BattleDialogue)
    return
  end
  BattleDialogue:Resume()
  BattleDialogue:SendEvent(DialogueModuleEvent.EnterEndState, self)
end

function DialogueModule:CleanUpOptions()
  local DialogueFsm = self:GetCommonDialogue()
  if not DialogueFsm then
    return
  end
  local Option = DialogueFsm:GetProperty("CurrentOption")
  if not Option then
    return
  end
  Option:RemoveEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionInfoChange)
  Option:RemoveEventListener(self, NpcOptionEvent.Destroy, self.OnOptionDestroy)
  local List = self.CachedActions[Option]
  if List then
    table.clear(List)
  end
  self.CachedActions[Option] = nil
end

function DialogueModule:GetActions(option)
  if not option then
    return nil
  end
  return self.CachedActions[option]
end

function DialogueModule:CheckActionStatus(Action, ConfID, Status)
  if not Action then
    return false
  end
  if Action.act_status ~= Status then
    return false
  end
  if Action.dialog_id == ConfID then
    return true
  end
  if Action.bound_dialog_id == ConfID then
    return true
  end
  return false
end

function DialogueModule:FindAction(Option, ConfID, Status, bRestoring, bNotDiscardOld)
  local CurrentAction = Option and Option.optionInfo and Option.optionInfo.cur_action_info
  local Actions = self:GetActions(Option)
  if not Actions then
    if self:CheckActionStatus(CurrentAction, ConfID, Status) then
      DialogueUtils.LogAction(CurrentAction, "\229\189\147\229\137\141\229\176\177\230\152\175\231\172\166\229\144\136\231\154\132Action")
      return CurrentAction
    end
    if bRestoring and CurrentAction.act_status and CurrentAction.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commitable then
      DialogueUtils.LogAction(CurrentAction, "\230\150\173\231\186\191\233\135\141\232\191\158\233\166\150\228\184\170Action\239\188\140\229\143\175\228\187\165\230\138\138Committable\231\138\182\230\128\129\229\189\147\230\136\144Executing\231\138\182\230\128\129")
      return CurrentAction
    end
    if CurrentAction then
      Log.Debug("\229\144\142\229\143\176\229\176\154\230\156\170\229\155\158\229\140\133", ConfID, Option.config.id, "\229\189\147\229\137\141\230\149\176\230\141\174", math.max(CurrentAction.dialog_id, CurrentAction.bound_dialog_id), table.getKeyName(Enum.ActionType, CurrentAction.act_type), table.getKeyName(ProtoEnum.SpaceEnum_NpcActionStatus.ENUM, CurrentAction.act_status), table.getKeyName(Enum.ActionResultType, CurrentAction.act_result_type), CurrentAction.next_dialog_id)
    else
      Log.Debug("\229\144\142\229\143\176\229\176\154\230\156\170\229\155\158\229\140\133", ConfID, Option and Option.config and Option.config.id, "\230\178\161\230\156\137\228\187\187\228\189\149action")
    end
    return nil
  end
  local FoundAction
  local FoundIndex = -1
  Log.Debug("\229\188\128\229\167\139\230\159\165\229\175\185\232\175\157\229\155\158\229\140\133", ConfID, Option.config.id, #Actions)
  for i = #Actions, 1, -1 do
    local Action = Actions[i]
    if self:CheckActionStatus(Action, ConfID, Status) then
      FoundIndex = i
      FoundAction = Action
      break
    end
  end
  if FoundAction then
    if not bNotDiscardOld then
      for _ = 1, FoundIndex do
        local DiscardedAction = table.remove(Actions, 1)
        if DiscardedAction then
          DialogueUtils.LogAction(DiscardedAction, "\228\184\162\229\188\131\232\191\135\230\156\159Action")
        end
      end
    end
    DialogueUtils.LogAction(FoundAction, "\230\137\190\229\136\176\231\172\166\229\144\136\231\154\132Action")
    Log.Debug("\229\137\169\228\189\153Action", #Actions)
  elseif self:CheckActionStatus(CurrentAction, ConfID, Status) then
    DialogueUtils.LogAction(CurrentAction, "\229\189\147\229\137\141\229\176\177\230\152\175\231\172\166\229\144\136\231\154\132Action")
    return CurrentAction
  elseif CurrentAction then
    Log.Debug("\230\151\160\230\179\149\230\137\190\229\136\176\233\128\130\229\144\136\231\154\132\229\175\185\232\175\157Action", ConfID, Option.config.id, "\229\189\147\229\137\141\230\149\176\230\141\174", math.max(CurrentAction.dialog_id, CurrentAction.bound_dialog_id), table.getKeyName(Enum.ActionType, CurrentAction.act_type), table.getKeyName(ProtoEnum.SpaceEnum_NpcActionStatus.ENUM, CurrentAction.act_status), table.getKeyName(Enum.ActionResultType, CurrentAction.act_result_type), CurrentAction.next_dialog_id)
  else
    Log.Debug("\230\151\160\230\179\149\230\137\190\229\136\176\233\128\130\229\144\136\231\154\132\229\175\185\232\175\157Action", ConfID, Option.config.id, "\230\178\161\230\156\137\228\187\187\228\189\149action")
  end
  return FoundAction
end

function DialogueModule:CheckHasDialogue()
  return self.DialogueFsm and self.DialogueFsm.active
end

function DialogueModule:SetPreDialogueFlag(Flag)
  local OldFlag = self.PreDialogueFlag
  local NewFlag = true == Flag
  if OldFlag == NewFlag then
    return
  end
  self:Log("[DialogueFlow][Common] Setting PreDialogueFlag to %s", NewFlag)
  self.PreDialogueFlag = NewFlag
end

function DialogueModule:GetHasDialogue()
  return self.PreDialogueFlag or self.HasDialogue
end

function DialogueModule:GetHasBattleDialogue()
  return self.HasBattleDialogue
end

function DialogueModule:HideDialogueMain()
  if self:HasPanel(self._currentMainPanel) then
    local panel = self:GetPanel(self._currentMainPanel)
    panel:Disable()
  end
end

function DialogueModule:ShowDialogueMain()
  Log.Debug("DialogueModule:ShowDialogueMain")
  if self:HasPanel(self._currentMainPanel) then
    local panel = self:GetPanel(self._currentMainPanel)
    panel:Enable()
  end
end

function DialogueModule:DestroyUICamera()
  if not self:CheckUICamera() then
    return
  end
  if self.data.IsCameraUIAlive then
    return
  end
  if self.data.CameraUI and UE.UObject.IsValid(self.data.CameraUI) then
    self.data.CameraUI:K2_DestroyActor()
  end
  self.data.CameraUI = nil
end

function DialogueModule:SetSavedTargetView(fsm, target)
  self.data.SavedTargetView[fsm] = target
end

function DialogueModule:GetSavedTargetView(fsm)
  return self.data.SavedTargetView[fsm]
end

function DialogueModule:SetUICamera(UICamera)
  self.data.CameraUI = UICamera
end

function DialogueModule:GetUICamera()
  return self.data.CameraUI
end

function DialogueModule:SetUICameraCaptureTickable(bTick)
  if not (self.data and self.data.CameraUI) or not UE.UObject.IsValid(self.data.CameraUI) then
    Log.Error("\230\137\190\228\184\141\229\136\176CameraUI\239\188\140\230\151\160\230\179\149\232\174\190\231\189\174SetUICameraCaptureTickable\239\188\140\232\175\183\230\163\128\230\159\165\232\191\153\232\161\140\228\187\163\231\160\129\232\162\171\232\176\131\231\148\168\231\154\132\230\151\182\229\186\143")
    return
  end
  local captureComp = self.data.CameraUI:GetComponentByClass(UE4.USceneCaptureComponent2D)
  if not captureComp then
    Log.Error("captureComp is nil")
    return
  end
  UE4.UNRCStatics.SetCapturePostProcessing(captureComp)
  captureComp.bCaptureEveryFrame = bTick
end

function DialogueModule:CheckUICamera()
  if not self.data then
    return false
  end
  if not self.data.CameraUI then
    return false
  end
  if not UE.UObject.IsValid(self.data.CameraUI) then
    return false
  end
  return true
end

function DialogueModule:SetUICameraState(IsUICameraAlive)
  self.data.IsCameraUIAlive = IsUICameraAlive
end

function DialogueModule:PlayEndAnimation(caller, callback)
  if not self:HasPanel(self._currentMainPanel) or not self.PanelOn then
    callback(caller)
    return
  end
  local panel = self:GetPanel(self._currentMainPanel)
  if panel.DoPlayEndAnimation then
    panel:DoPlayEndAnimation(caller, callback)
  else
    callback(caller)
  end
end

function DialogueModule:RestoreCamera(BlendTime, BlendFunc, BlendExp)
  if not self.HasBattleDialogue then
    return false
  end
  if not self.DialogueFsm then
    return false
  end
  local Transform = self.DialogueFsm:GetProperty("ViewTargetTransform")
  if not Transform then
    return false
  end
  local Player = DialogueUtils.GetPlayer()
  local Controller = DialogueUtils.GetController(Player)
  Controller:SetFadeEnable(false)
  Controller.CameraActor:K2_SetActorTransform(Transform, false)
  Controller:RequestRocoCamera(BlendTime, BlendFunc, BlendExp)
  return true
end

function DialogueModule:OnDeactive()
  self:ShutDownAllDialogueFsm()
end

function DialogueModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerAttacked, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapStart, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPreTeleportNotify, self.OnTeleport)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnEnterOrLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.BattleOver, self.OnBattleOver)
  self:UnRegisterEvent(self, DialogueModuleEvent.DialogueTalkFinished)
  self.StatusChecker:Reset()
  self:ClearAllData()
end

function DialogueModule:GetLastDialogueEndTime()
  return self.LastDialogueEndTime
end

function DialogueModule:GetDialogueCenter()
  if not self.HasDialogue then
    return nil
  end
  local CommonDialogue = self:GetCommonDialogue()
  if not CommonDialogue then
    Log.Error("Dialogue Fsm is nil when getting dialogue center")
    return nil
  end
  local TargetNPC = CommonDialogue:GetProperty("TargetNPC")
  if not TargetNPC then
    Log.Error("TargetNPC is nil when getting dialogue center")
    return nil
  end
  local View = TargetNPC
  if not View then
    Log.Error("Dialogue View Object is nil when getting dialogue center")
    return nil
  end
  return View
end

function DialogueModule:SetHasDialogue(HasDialogue)
  self.HasDialogue = HasDialogue
end

function DialogueModule:ShowDialogueOverlay()
  self:ShowButtonAutoPlay()
end

function DialogueModule:HideDialogueOverlay()
  self:CloseButtonAutoPlay()
end

function DialogueModule:CheckLipSyncExists(File)
  local AssetPath = string.format("/Game/ArtRes/BP/Lipsync/%s.%s", File, File)
  if RocoEnv.IS_EDITOR then
    return UE.UNRCStatics.CheckAssetExists(AssetPath)
  end
  if not self.NonExist then
    local JsonPath = string.format("%sData/Dialogue/NonExistLipsync.non", UE4.UNRCStatics.ProjectScriptDir())
    local Result, Success = UE4.UNRCStatics.LoadToString(JsonPath)
    if Success then
      Log.Error("\229\138\160\232\189\189\228\184\141\229\173\152\229\156\168\232\181\132\230\186\144\229\136\151\232\161\168\230\136\144\229\138\159")
      self.NonExist = rapidjson.decode(Result)
    else
      return true
    end
  end
  local NotExist = table.contains(self.NonExist, File)
  return not NotExist
end

function DialogueModule:OnAddOverrideCallback(EntryType, Caller, Callback)
  if not Callback then
    return
  end
  if string.IsNilOrEmpty(EntryType) then
    return
  end
  local Payload = self.OverrideCallbacks[EntryType]
  if Payload then
    for _, Item in ipairs(Payload) do
      if Caller == Item.Caller and Callback == Item.Callback then
        return
      end
    end
  else
    Payload = {}
    self.OverrideCallbacks[EntryType] = Payload
  end
  table.insert(Payload, setmetatable({Caller = Caller, Callback = Callback}, {__mode = "v"}))
end

function DialogueModule:OnRemoveOverrideCallback(EntryType, Caller, Callback)
  if not Callback then
    return
  end
  if string.IsNilOrEmpty(EntryType) then
    return
  end
  local Payload = self.OverrideCallbacks[EntryType]
  if not Payload then
    return
  end
  local Found
  for Index, Item in ipairs(Payload) do
    if Caller == Item.Caller and Callback == Item.Callback then
      Found = Index
      break
    end
  end
  if not Found then
    return
  end
  table.remove(Payload, Found)
end

function DialogueModule:GetOverrides(EntryType, DialogueID)
  if string.IsNilOrEmpty(EntryType) then
    return nil
  end
  local Payloads = self.OverrideCallbacks[EntryType]
  if not Payloads then
    return nil
  end
  for Index, Payload in ipairs(Payloads) do
    local Caller = Payload.Caller
    local Callback = Payload.Callback
    local Value
    if Callback then
      if Caller then
        Value = Callback(Caller, DialogueID, EntryType)
      else
        Value = Callback(DialogueID, EntryType)
      end
    end
    if not string.IsNilOrEmpty(Value) then
      Log.Debug("Found Override Value", Index, EntryType, DialogueID, Value)
      return Value
    end
  end
  return nil
end

function DialogueModule:OnCmdOpenNormalBlack(showTime)
  self:OnCmdCloseNormalBlack()
  self:OpenPanel("NormalBlack", showTime)
end

function DialogueModule:OnCmdCloseNormalBlack()
  if self:HasPanel("NormalBlack") then
    self:ClosePanel("NormalBlack")
  end
end

function DialogueModule:OpenPetGiftPanel(action)
  self:Log("DialogueModule:OpenPetGiftPanel")
  if not self:HasPanel("PetGiftPanel") then
    self:OpenPanel("PetGiftPanel", action)
  else
    Log.Warning("\229\183\178\231\187\143\229\173\152\229\156\168PetGiftPanel")
  end
end

function DialogueModule:ClosePetGiftPanel()
  self:Log("DialogueModule:ClosePetGiftPanel")
  if self:HasPanel("PetGiftPanel") then
    self:ClosePanel("PetGiftPanel")
  end
end

function DialogueModule:OpenReadingMatter(ConfigID, Action)
  if not ConfigID then
    Log.Error("DialogueModule:OpenReadingMatter ConfigID is nil")
    if Action then
      Action:Finish(false)
    end
    return
  end
  local ReadingMatterPanelNameMapping = {
    [Enum.ReadType.RT_BOOK] = "ReadingMatter_Book",
    [Enum.ReadType.RT_NOTE] = "ReadingMatter_Note",
    [Enum.ReadType.RT_SCROLLS] = "ReadingMatter_Scrolls"
  }
  local ReadingMatterData = _G.DataConfigManager:GetReadConf(ConfigID)
  if not ReadingMatterData then
    Log.Error("DialogueModule:OpenReadingMatter ReadingMatterData is nil")
    if Action then
      Action:Finish(false)
    end
    return
  end
  if ReadingMatterPanelNameMapping[ReadingMatterData.read_type] then
    local HandleText = string.gsub(ReadingMatterData.text, "|||", "\n")
    local Replacer = DialogueTextReplacer()
    local ReplaceContext = TextReplaceContext(Action and Action.Owner)
    HandleText = Replacer:Replace(HandleText, ReplaceContext)
    self:OpenPanel(ReadingMatterPanelNameMapping[ReadingMatterData.read_type], ConfigID, HandleText, Action)
  elseif ReadingMatterData.read_type == Enum.ReadType.RT_MESSAGE then
    _G.NRCModeManager:DoCmd(_G.TaskModuleCmd.lookLetter, ReadingMatterData.letter_id, Action)
  end
end

function DialogueModule:SendZoneReportTaskReq(TaskClientTriggerType, ReadID)
  local req = _G.ProtoMessage:newZoneReportTaskReq()
  req.tctt = TaskClientTriggerType
  req.data = ReadID
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_REPORT_TASK_REQ, req, self, self.OnZoneReportTaskRsp, true, false)
end

function DialogueModule:OnZoneReportTaskRsp(_rsp)
end

local SALS_NORMAL = ProtoEnum.SpaceActorLogicStatus.SALS_NORMAL
local LockStartTime = -1
local TickSkipFrames = 5
local TickStep = 0
local ShitHappened = false
local LockedSpecialTag = {HomeSit = true}

function DialogueModule:OnTick()
  if ShitHappened then
    return
  end
  TickStep = (TickStep + 1) % TickSkipFrames
  if 0 ~= TickStep then
    return
  end
  local State = _G.SceneModuleCmd and _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.CheckSceneFullyEntered) or false
  if not State then
    LockStartTime = -1
    return
  end
  local InBattle = _G.BattleManager:IsInBattle()
  if InBattle then
    LockStartTime = -1
    return
  end
  local IsInDialogue = self:CheckHasDialogue()
  if IsInDialogue then
    LockStartTime = -1
    return
  end
  local Player = DialogueUtils.GetPlayer()
  local InputComp = Player and Player.inputComponent
  local InputLocked = InputComp and not InputComp:GetInputEnable() or false
  InputLocked = InputLocked or _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.HasInputBlocker) or false
  if not InputLocked then
    LockStartTime = -1
    return
  end
  local StatusNormal = false
  local LogicComp = Player and Player.LogicStatusComponent
  if LogicComp and LogicComp.StatusInfo then
    StatusNormal = 1 == #LogicComp.StatusInfo
    local First = StatusNormal and LogicComp.StatusInfo[1]
    StatusNormal = StatusNormal and First.status == SALS_NORMAL
  end
  if not StatusNormal then
    LockStartTime = -1
    return
  end
  if _G.NRCPanelManager:GetLayerWindowCount(Enum.UILayerType.UI_LAYER_POPUP) > 0 then
    LockStartTime = -1
    return
  end
  if not self.IdleChecker:CheckPass() then
    LockStartTime = -1
    return
  end
  local Now = os.msTime() or 0
  local ElapsedTime = Now - LockStartTime
  if ElapsedTime < 20000.0 then
    Log.Debug("Locked during normal state", ElapsedTime * 0.001)
    return
  end
  local FlagString = InputComp and InputComp:GetDisableFlags()
  if LockedSpecialTag[FlagString] then
    LockStartTime = -1
    return
  end
  if LockStartTime < 0 then
    LockStartTime = Now
    return
  end
  ShitHappened = true
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.general_title)
  if _G.RocoEnv.IS_SHIPPING then
    Ctx:SetContent(LuaText.user_locked_too_long)
  else
    Ctx:SetContent(LuaText.user_locked_too_long_editor)
  end
  Ctx:SetMode(DialogContext.Mode.OK)
  Ctx:SetButtonText(LuaText.general_confirm, LuaText.general_confirm)
  Ctx:SetCallback(nil, function(OK)
    UE.UNRCStatics.RestartApp()
  end)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
  local BlockString = ""
  local TipsModule = _G.NRCModuleManager:GetModule("TipsModule")
  if TipsModule and TipsModule.InputBlockDic then
    local BlockTable = {}
    for Tag, _ in pairs(TipsModule.InputBlockDic) do
      table.insert(BlockTable, Tag)
    end
    BlockString = table.concat(BlockTable, ",")
  end
  local ErrorString = string.format(LuaText.player_stall_hint, FlagString, BlockString)
  if RocoEnv.IS_EDITOR then
    Log.Error(ErrorString)
  elseif _G.NRCSDKManager and _G.NRCSDKManager.CrashSightReportException then
    _G.NRCSDKManager:CrashSightReportException(ErrorString, "")
  end
end

function DialogueModule:ShowButtonAutoPlay()
  self.ButtonAutoplayVisible = true
  if not self:HasPanel("DialogueOverlay") and not self:IsPanelInOpening("DialogueOverlay") then
    self:OpenPanel("DialogueOverlay", self, self.OnOverlayPanelPreloaded)
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay and UMG_Overlay.UMG_Autoplay and UMG_Overlay.UMG_Autoplay:GetVisibility() ~= UE4.ESlateVisibility.Visible and not UMG_Overlay.UMG_Autoplay:IsAnimationPlaying(UMG_Overlay.UMG_Autoplay.In) then
    UMG_Overlay.UMG_Autoplay:PlayAnimation(UMG_Overlay.UMG_Autoplay.In)
  end
end

function DialogueModule:CloseButtonAutoPlay()
  self.ButtonAutoplayVisible = false
  if not self:HasPanel("DialogueOverlay") then
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay and UMG_Overlay.UMG_Autoplay and UMG_Overlay.UMG_Autoplay:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and not UMG_Overlay.UMG_Autoplay:IsAnimationPlaying(UMG_Overlay.UMG_Autoplay.Out) then
    UMG_Overlay.UMG_Autoplay:PlayAnimation(UMG_Overlay.UMG_Autoplay.Out)
  end
end

function DialogueModule:ShowButtonSkip(Caller, Callback)
  self.ButtonSkipCaller = Caller
  self.ButtonSkipCallback = Callback
  self.ButtonSkipVisible = true
  if not self:HasPanel("DialogueOverlay") and not self:IsPanelInOpening("DialogueOverlay") then
    self:OpenPanel("DialogueOverlay", self, self.OnOverlayPanelPreloaded)
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if not UMG_Overlay then
    return
  end
  if UMG_Overlay.UMG_Skip and UMG_Overlay.UMG_Skip:GetVisibility() ~= UE4.ESlateVisibility.Visible and not UMG_Overlay.UMG_Skip:IsAnimationPlaying(UMG_Overlay.UMG_Skip.In) then
    UMG_Overlay.UMG_Skip:PlayAnimation(UMG_Overlay.UMG_Skip.In)
  end
end

function DialogueModule:CloseButtonSkip()
  self.ButtonSkipVisible = false
  if not self:HasPanel("DialogueOverlay") then
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay and UMG_Overlay.UMG_Skip and UMG_Overlay.UMG_Skip:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and not UMG_Overlay.UMG_Skip:IsAnimationPlaying(UMG_Overlay.UMG_Skip.Out) then
    self.ButtonSkipCaller = nil
    self.ButtonSkipCallback = nil
    UMG_Overlay.UMG_Skip:PlayAnimation(UMG_Overlay.UMG_Skip.Out)
  end
end

function DialogueModule:ShowButtonExit()
  self.ButtonExitVisible = true
  if not self:HasPanel("DialogueOverlay") and not self:IsPanelInOpening("DialogueOverlay") then
    self:OpenPanel("DialogueOverlay", self, self.OnOverlayPanelPreloaded)
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay and UMG_Overlay.ExitBtn then
    if UMG_Overlay.ExitBtn:GetVisibility() == UE4.ESlateVisibility.Collapsed then
      UMG_Overlay.ExitBtn:PlayAnimation(UMG_Overlay.ExitBtn.In)
    end
    UMG_Overlay.ExitBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function DialogueModule:CloseButtonExit()
  self.ButtonExitVisible = false
  if not self:HasPanel("DialogueOverlay") then
    return
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if UMG_Overlay and UMG_Overlay.ExitBtn then
    UMG_Overlay.ExitBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function DialogueModule:IsButtonSkipVisible()
  if not self:HasPanel("DialogueOverlay") then
    return false
  end
  local UMG_Overlay = self:GetPanel("DialogueOverlay")
  if not UMG_Overlay then
    return false
  end
  if UMG_Overlay.UMG_Skip then
    return UMG_Overlay.UMG_Skip:GetVisibility() == UE4.ESlateVisibility.Visible or UMG_Overlay.UMG_Skip:IsAnimationPlaying(UMG_Overlay.UMG_Skip.In)
  end
  return false
end

function DialogueModule:OnButtonSkip()
  if self and self.ButtonSkipCaller and self.ButtonSkipCallback then
    self.ButtonSkipCallback(self.ButtonSkipCaller)
  end
end

function DialogueModule:OnSkipDialogue()
  if not self then
    return
  end
  if self.SkipMessageOn then
    return
  end
  self.SkipMessageOn = true
  OpenMessageBoxWthCaller(LuaText.Title_DialogueSkip, LuaText.Msg_DialogueSkip, LuaText.tips_dialog_butten_accept, LuaText.CANCEL, DialogContext.Mode.OK_CANCEL, self.OnConfirmSkipClick, self, nil, true)
  self.CachedAutoPlay = _G.UserSettingManager:IsDialogueAutoPlayOn()
  _G.UserSettingManager:SetDialogueAutoPlay(false)
end

function DialogueModule:OnConfirmSkipClick(bResult)
  self.SkipMessageOn = false
  if self.CachedAutoPlay then
    _G.UserSettingManager:SetDialogueAutoPlay(true)
    self.CachedAutoPlay = false
  end
  if bResult then
    if self.DialogueFsm then
      local DialogueConf = self.DialogueFsm:GetProperty("CurrentDialogue")
      if DialogueConf then
        Log.InfoFormat("DialogueModule:OnConfirmSkipClick, skip dialogue %d", DialogueConf.id)
      end
      self.DialogueFsm:SendEvent(DialogueModuleEvent.EnterSkipState, self)
    end
    self:CloseButtonSkip()
  end
end

function DialogueModule:GetLastPetSubmitReportInfo()
  return self.LastPetSubmitReportInfo
end

function DialogueModule:OnSyncVideo(msg)
  if msg.operation.operator_type == ProtoEnum.ClientOperationType.COT_TOGETHER_MOVIE and msg.operation and msg.operation.movie_info then
    Log.Debug("DialogueModule:OnSyncVideo", msg.operation.movie_info.target_npc_id or 0, msg.operation.movie_info.movie_id or 0, msg.operation.movie_info.sync_type)
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local player_id = player and player:GetServerId()
    if msg.operation.movie_info.target_npc_id == player_id then
      local movie_id = msg.operation.movie_info.movie_id
      if movie_id >= 0 then
        if msg.operation.movie_info.sync_type == ProtoEnum.PlayerOperationSyncType.POST_START then
          local param = {}
          param.Conf = _G.DataConfigManager:GetMovieConf(movie_id, true)
          param.bIsSync = true
          if param.Conf then
            _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.PlayVideo, param)
          end
        elseif msg.operation.movie_info.sync_type == ProtoEnum.PlayerOperationSyncType.POST_END then
          local DialogueVideo = self:GetPanel("DialogueVideo")
          if DialogueVideo and DialogueVideo.bIsSync then
            DialogueVideo:MovieDone(true)
          end
        end
      end
    end
  end
end

function DialogueModule:OnSyncDialogue(msg)
  Log.DebugFormat("DialogueModule:OnSyncDialogue, dialogue_id = %d, dialogue_npc_id = %d!, type = %d", msg.dialogue_id or 0, msg.dialogue_npc_id or 0, msg.sync_type or 0)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local player_id = player and player:GetServerId()
  if msg.target_npc_id ~= player_id then
    return
  end
  if msg.sync_type == ProtoEnum.PlayerOperationSyncType.POST_START then
    self:OnSyncStartDialogue(msg.dialogue_id, msg.dialogue_npc_id, msg.select_ids, msg.option_conf_id)
  elseif msg.sync_type == ProtoEnum.PlayerOperationSyncType.POST_NEXT then
    self:OnSyncNextDialogue(msg.dialogue_id, msg.select_ids, msg.last_select_id)
  elseif msg.sync_type == ProtoEnum.PlayerOperationSyncType.POST_END then
    self:OnSyncCloseDialogue()
  elseif msg.sync_type == ProtoEnum.PlayerOperationSyncType.POST_SKIP then
    self:OnSyncSkipDialogue(msg.dialogue_id)
  elseif msg.sync_type == ProtoEnum.PlayerOperationSyncType.POST_PROGRESS then
    self:OnSyncDialogueProgress(msg.dialogue_id, msg.progress)
  end
end

function DialogueModule:OnSyncStartDialogue(DialogueID, TargetNPCContentID, SelectIDs, OptionConfID)
  if not DialogueID or DialogueID <= 0 then
    return
  end
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueID)
  if not DialogueConf then
    Log.ErrorFormat("DialogueModule:OnStartSyncDialogue, sync start together dialogue %d but cant find dialogue conf, skip!", DialogueID)
    return
  end
  local TargetNPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, TargetNPCContentID or 0)
  if not TargetNPC then
    Log.ErrorFormat("DialogueModule:OnStartSyncDialogue, sync start together dialogue %d but cant find target npc[ContentID=%d], skip!", DialogueID, TargetNPCContentID or 0)
    return
  end
  if self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode") then
    local CurSyncDialogueID = self.DialogueFsm and self.DialogueFsm:GetProperty("CurrentDialogue")
    CurSyncDialogueID = CurSyncDialogueID and CurSyncDialogueID.id
    Log.ErrorFormat("DialogueModule:OnStartSyncDialogue, sync start together dialogue %d when there is already a sync dialogue %d, skip!", DialogueID, CurSyncDialogueID)
    return
  end
  if self.HasBattleDialogue then
    self:OnCloseDialogueInBattle()
    self.HasBattleDialogue = false
  end
  self.LastConf = nil
  self.LastTarget = nil
  self.LastPlayer = nil
  self.FirstEnter = true
  self._currentMainPanel = nil
  self.PreUIType = nil
  self:SetHasDialogue(true)
  self.DialogueFsm = self:CreateNewFsm(SyncDialogueFsm)
  local Participants = DialogueUtils.CollectParticipants(DialogueID)
  self.DialogueFsm:SetProperty("ParentModule", self)
  self.DialogueFsm:SetProperty("TargetNPC", TargetNPC)
  self.DialogueFsm:SetProperty("NextConfID", DialogueID)
  self.DialogueFsm:SetProperty("bInBattle", false)
  self.DialogueFsm:SetProperty("bIsReconnect", false)
  self.DialogueFsm:SetProperty("Participants", Participants)
  self.DialogueFsm:SetProperty("ReturnCamera", true)
  self.DialogueFsm:SetProperty("CleanUpFsmAtEnd", true)
  self.DialogueFsm:SetProperty("SpectatorMode", true)
  self.DialogueFsm:SetProperty("PendingSyncList", {
    {
      DialogueID = DialogueID,
      SelectIDs = SelectIDs,
      Progress = 22
    }
  })
  self.DialogueFsm:SetProperty("OptionConf", _G.DataConfigManager:GetNpcOptionConf(OptionConfID, true))
  self.DialogueFsm:Play()
  self:ShowButtonExit()
  DialogueUtils.ToggleInput(false)
end

function DialogueModule:OnSyncNextDialogue(DialogueID, SelectIDs, LastSelectID)
  if self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode") then
    local PendingSyncList = self.DialogueFsm:GetProperty("PendingSyncList", {})
    table.insert(PendingSyncList, {
      DialogueID = DialogueID,
      SelectIDs = SelectIDs,
      LastSelectID = LastSelectID,
      Progress = 22
    })
    self.DialogueFsm:SetProperty("PendingSyncList", PendingSyncList)
    self:OnSyncDialogueProgress(DialogueID, 22)
    self:DispatchEvent(DialogueModuleEvent.SyncNextDialogue, DialogueID, SelectIDs)
  end
end

function DialogueModule:OnSyncSkipDialogue(DialogueID)
  if self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode") then
    self.DialogueFsm:SetProperty("NextConfID", DialogueID)
    self.DialogueFsm:SendEvent(DialogueModuleEvent.EnterSkipState, self)
  end
end

function DialogueModule:OnSyncCloseDialogue()
  if self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode") then
    self.DialogueFsm:SendEvent(DialogueModuleEvent.EnterEndState, self)
  end
end

function DialogueModule:OnSyncDialogueProgress(DialogueID, Progress)
  if self.DialogueFsm and self.DialogueFsm:GetProperty("SpectatorMode") then
    local bNextDialogueSkipped = false
    local PendingSyncList = self.DialogueFsm:GetProperty("PendingSyncList", {})
    if PendingSyncList and #PendingSyncList > 0 then
      for i = #PendingSyncList, 1, -1 do
        local v = PendingSyncList[i]
        if bNextDialogueSkipped then
          v.Progress = 0
        elseif v.DialogueID == DialogueID then
          v.Progress = Progress
          bNextDialogueSkipped = true
        end
      end
    end
    local cur_dialogue = self.DialogueFsm:GetProperty("CurrentDialogue")
    Progress = cur_dialogue and cur_dialogue.id == DialogueID and Progress or 0
    self.DialogueFsm:SetProperty("Progress", Progress)
    if self:HasPanel(self._currentMainPanel) then
      local Panel = self:GetPanel(self._currentMainPanel)
      if Panel then
        Panel:OnSyncProgressUpdate()
      end
    else
      local DialogueConf = _G.DataConfigManager:GetDialogueConf(DialogueID)
      self:DispatchEvent(DialogueModuleEvent.DialogueTalkFinished, DialogueConf)
    end
    if 0 == Progress then
      self:DispatchEvent(DialogueModuleEvent.SyncShowOptions)
    end
  end
end

function DialogueModule:CleanUpFsm()
  self:SetHasDialogue(false)
  self:RemoveFrontFsm()
  self.DialogueFsm = self:GetFrontDialogue()
  if self:CheckHasDialogue() then
    self:SetHasDialogue(true)
  end
end

function DialogueModule:SyncProgress(dialogue_id, progress)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and not player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    if other_player then
      local other_player_id = other_player:GetServerId()
      local req = _G.ProtoMessage:newZoneClientOperationReq()
      req.operation.operator_id = player:GetServerId()
      req.operation.operator_type = ProtoEnum.ClientOperationType.COT_TOGETHER_DIALOGUE
      req.operation.aim_info = nil
      req.operation.npc_action_info = nil
      req.operation.catch_info = nil
      req.operation.player_perform_info = nil
      req.operation.cinematic_info = nil
      req.operation.dialogue_info.target_npc_id = other_player_id
      req.operation.dialogue_info.dialogue_id = dialogue_id
      req.operation.dialogue_info.dialogue_npc_id = 0
      req.operation.dialogue_info.sync_type = ProtoEnum.PlayerOperationSyncType.POST_PROGRESS
      req.operation.dialogue_info.progress = progress
      req.operation.movie_info = nil
      Log.Debug("DialoguePanelBase:OnEnter, send client operation %d %s", self.ConfID, "CLICK")
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req, self, self.OnSyncReqRsp)
    end
  end
end

function DialogueModule:OnSyncReqRsp(rsp)
  Log.Debug("DialogueModule:OnSyncReqRsp, on client operation req rsp", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
end

function DialogueModule:GetCurDialogueOption()
  if not self.HasDialogue then
    return nil
  end
  local fsm = self.DialogueFsm
  if fsm then
    return fsm:GetProperty("CurrentOption", nil)
  end
  return nil
end

return DialogueModule

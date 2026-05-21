local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local DialogueConst = require("NewRoco.Modules.System.Dialogue.DialogueConst")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local HoldingItemComponent = require("NewRoco.Modules.Core.Scene.Component.Show.HoldingItemComponent")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local CameraModuleCmd = reload("NewRoco.Modules.System.Camera.CameraModuleCmd")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local Base = DialogueActionBase
local DialogueDestroyAction = Base:Extend("DialogueDestroyAction")
FsmUtils.MergeMembers(Base, DialogueDestroyAction, {
  {name = "TargetNPC", type = "var"},
  {name = "Cmd", type = "string"},
  {
    name = "ParentModule",
    type = "var"
  },
  {name = "NpcIDs", type = "var"},
  {
    name = "bIsReconnect",
    type = "var"
  },
  {
    name = "CurrentOption",
    type = "var"
  }
})

function DialogueDestroyAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.StatusChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Cinematic
  }, Log.LOG_LEVEL.ELogWarn)
end

function DialogueDestroyAction:ResetCamera()
  local Player = DialogueUtils.GetPlayer()
  local Controller = DialogueUtils.GetController(Player)
  if Controller and Controller.BP_RocoCameraControlComponent then
    Controller.BP_RocoCameraControlComponent:EnableLag(true)
    Controller:ChangeRocoCameraFadeRange(100, 150)
  end
  DialogueUtils.SetPlayerVisible(Player, true)
  local Actor = self.TargetNPC
  local HudComp = Actor and Actor.PetHUDComponent
  if HudComp then
    HudComp:SetVisible(true)
  end
  if Controller and Controller.ReleaseRocoCamera then
    Controller:ReleaseRocoCamera(0, 0, 0, true)
    Controller:SetFadeEnable(true)
  end
  if self.ParentModule:CheckUICamera() then
    local savedTargetView = self.ParentModule:GetSavedTargetView(self.fsm)
    if savedTargetView then
      _G.NRCModeManager:DoCmd(DialogueModuleCmd.SetUICameraState, false)
      DialogueUtils.ChangeCamera(savedTargetView, DialogueConst.EnterTime, nil, Controller, self.OnChangeCameraCallback)
    end
  else
    local SpringArm = DialogueUtils.GetPlayerSpringArm(Player)
    if SpringArm then
      SpringArm:SetLerpTime(DialogueConst.ExitTime, DialogueConst.CameraEase)
      SpringArm.DialogStateType = "[DialogueDestroyAction:OnEnter]"
    end
  end
  if Player then
    Player.inputComponent:SetCameraControlEnable(self.ParentModule, true)
  end
  _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.RequestCameraDOF, false)
end

function DialogueDestroyAction:ResetUI()
  _G.NRCModeManager:DoCmd(DialogueModuleCmd.CloseMainPanel)
  if self.StatusChecker:CheckPass() then
    _G.NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  _G.NRCModeManager:DoCmd(DialogueModuleCmd.CleanUpOptions)
  self.ParentModule:SetHasDialogue(false)
  self.ParentModule:ClosePanel("DialogueCameraBlack")
  self.ParentModule:ClosePanel("DialogueOverlay")
  self.ParentModule.LastDialogueEndTime = _G.UpdateManager.Timestamp
  _G.NRCEventCenter:DispatchEvent(DialogueModuleEvent.DialogueEnded, self:GetProperty("bIsReconnect", false))
  NRCModuleManager:DoCmd(DialogueModuleCmd.CheckedOpenMainUIOnDialogueEnd)
end

function DialogueDestroyAction:ResetNpc()
  for _, ID in ipairs(self.NpcIDs) do
    local Character = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ID)
    if Character then
      if not Character.config or 1 ~= Character.config.is_clean_ani then
        DialogueUtils.StopAnim(Character, 0.1)
      end
      DialogueUtils.ToggleAI(Character, true, true)
    else
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, ID)
      if Player then
        DialogueUtils.StopAnim(Player, 0.1)
        Character = Player
      end
    end
    DialogueUtils.StopTalk(Character, 0.1)
    DialogueUtils.StopLookAt(Character)
    local LookAt = Character and Character:GetHeadLookAtComponent()
    if LookAt then
      LookAt:DisableManualOverride()
    end
    DialogueUtils.StopTurn(Character)
    DialogueUtils.ToggleLOD(Character, false)
    DialogueUtils.ToggleSignificance(Character, false)
  end
  table.clear(self.NpcIDs)
  local Participants
  if self.fsm.GetProperty then
    Participants = self.fsm:GetProperty("Participants", nil)
  end
  if Participants then
    for _, Character in pairs(Participants) do
      if Character and (not Character.config or 1 ~= Character.config.is_clean_ani) then
        DialogueUtils.StopAnim(Character, 0.1)
      end
      DialogueUtils.StopTalk(Character, 0.1)
      local LookAt = Character and Character:GetHeadLookAtComponent()
      if LookAt then
        LookAt:DisableManualOverride()
      end
      DialogueUtils.StopLookAt(Character)
      DialogueUtils.StopTurn(Character)
      DialogueUtils.ToggleAI(Character, true, true)
      DialogueUtils.ToggleLOD(Character, false)
      DialogueUtils.ToggleSignificance(Character, false)
    end
    table.clear(Participants)
  end
  DialogueUtils.ToggleAI(self.TargetNPC, true)
end

function DialogueDestroyAction:CheckDestroyCommon()
  _G.NRCAudioManager:PlaySound2DByEventNameAuto("Dialogue_Stop")
  self:ResetCamera()
  self:ResetNpc()
  local Player = DialogueUtils.GetHero()
  if not _G.BattleManager.isInBattle and Player then
    local bHasLoopAnimation = self:GetProperty("HasLoopAnimation")
    local bIsReconnect = self:GetProperty("bIsReconnect", false)
    if bHasLoopAnimation or bIsReconnect then
      DialogueUtils.StopAnim(Player, 0.1)
      DialogueUtils.StopTalk(Player, 0.1)
    end
    Player:SetVisible(true)
    local PlayerView = Player.viewObj
    if PlayerView then
      local Movement = PlayerView.CharacterMovement
      local MovementMode = Movement.MovementMode
      if Movement and MovementMode == UE.EMovementMode.MOVE_None then
        DialogueUtils.ToggleMovement(Player, true)
      end
    end
  end
  DialogueUtils.StopLookAt(Player)
  local LookAt = Player and Player:GetHeadLookAtComponent()
  if LookAt then
    LookAt:DisableManualOverride()
  end
  NRCModuleManager:DoCmd(CameraModuleCmd.ReturnCamera, self.ParentModule)
  DialogueUtils.ToggleInput(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "DialogueModule.BlockInputAction")
  NRCModuleManager:DoCmd(FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_OPTION)
  self:ResetUI()
  local AudioHandlers = self.fsm:GetProperty("StopAudioHandlers")
  if AudioHandlers then
    for Handler, _ in pairs(AudioHandlers) do
      _G.NRCAudioManager:ReleaseSession(Handler, true, "DialogueDestroyAction", false, 0.0)
    end
  end
  local holdItemComponent = Player and Player:GetComponent(HoldingItemComponent)
  if holdItemComponent then
    holdItemComponent:ClearAllItem()
  end
  return true
end

function DialogueDestroyAction:CheckDestroyInBattle()
  local bInBattle = self.fsm:GetProperty("bInBattle", false)
  local bUseBattleCamera = self:GetProperty("bUseBattleCamera")
  if not bInBattle then
    return false
  end
  local ShouldReturnCamera = self.fsm:GetProperty("ReturnCamera")
  if not bUseBattleCamera and ShouldReturnCamera then
    local Controller = UE4.UGameplayStatics.GetPlayerController(UE4Helper.GetCurrentWorld(), 0)
    if not Controller or Controller:GetClass():GetName() ~= "BP_PlayerController_C" then
      Log.Warning("Controller is missing or cannot get Controller with type BP_PlayerController_C")
    else
      if self.ParentModule:CheckUICamera() then
        local savedTargetView = _G.BattleManager.vBattleField.battleCameraManager.PCGCam
        _G.NRCModeManager:DoCmd(DialogueModuleCmd.SetUICameraState, false)
        DialogueUtils.ChangeCamera(savedTargetView, DialogueConst.EnterTime, nil, Controller, self.OnChangeCameraCallback, self)
      else
        _G.BattleManager:ReturnCameraFromDialogue()
      end
      Controller.BP_RocoCameraControlComponent:EnableLag(true)
      Controller:SetFadeEnable(false)
    end
  end
  local TargetNpcBp = self:GetProperty("TargetNpcBp")
  if TargetNpcBp and ShouldReturnCamera then
    local AnimComp = TargetNpcBp:GetAnimComponent()
    if not AnimComp and TargetNpcBp.GetComponentByClass then
      AnimComp = TargetNpcBp:GetComponentByClass(UE4.URocoAnimComponent)
    end
    if AnimComp then
      AnimComp:StopAllMontage(0.1)
    end
  end
  DialogueUtils.ToggleInput(true)
  return true
end

function DialogueDestroyAction:ContinueDestroyInBlack()
  self:CheckDestroyCommon()
  self:FinishDestroy()
end

function DialogueDestroyAction:OnEnter()
  Log.Debug("DialogueDestroyAction:OnEnter")
  self:InjectProperties()
  _G.NRCAudioManager:SetStateByName("Dialogue", "Close", "DialogueDestroyAction:OnEnter")
  self.ParentModule = self:GetProperty("ParentModule")
  self.fsm:SetProperty("LastConfID", 0)
  self.fsm:SetProperty("CurrentDialogue", nil)
  local PlayerPosSyncBlocker = self.fsm:GetProperty("PlayerPosSyncBlocker")
  if PlayerPosSyncBlocker then
    local player = DialogueUtils.GetHero()
    if player then
      local player_view = DialogueUtils.ExtraActorView(player)
      if player_view then
        if player:IsInTogetherMove() then
          player:SetActorLocation(PlayerPosSyncBlocker.Translation)
          player:SetActorRotation(PlayerPosSyncBlocker.Rotation:ToRotator())
        end
        if player.movementComponent and player.movementComponent.SetSyncMove then
          player.movementComponent:SetSyncMove(true)
        end
      end
    end
  end
  local player = DialogueUtils.GetHero()
  if player and player:IsInTogetherMove() then
    DialogueUtils.SetAudioGender(DialogueUtils.GetPlayer())
  end
  _G.NRCModuleManager:DoCmd(CameraModuleCmd.StopCameraSkillPlaying)
  if self:CheckDestroyInBattle() then
    self:FinishDestroy()
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.CleanUpBattleFsm)
    return
  end
  if self.fsm:GetProperty("CleanUpFsmAtEnd", false) then
    _G.NRCModeManager:DoCmd(DialogueModuleCmd.CleanUpFsm)
  end
  if self:CheckDestroyCommon() then
    self:FinishDestroy()
    return
  end
  Log.Error("DialogueDestroyAction destroying with expected context")
end

function DialogueDestroyAction:FinishDestroy()
  if not self.fsm or not self.fsm.GetProperty then
    self:Finish()
    return
  end
  local Action = self.fsm:GetProperty("CurrentAction")
  if Action then
    NRCEventCenter:DispatchEvent(NPCModuleEvent.NpcActionFinish, Action)
  end
  local Owner = Action and Action:GetOwnerNPC()
  if Owner then
    Owner:SendEvent(NPCModuleEvent.OnLeaveDialogue)
  end
  local Option = self.fsm:GetProperty("CurrentOption")
  if Option and Option.needRestoreRide then
    local Conf = _G.DataConfigManager:GetDialogueOnlyOptionConf(Option.config.id, true)
    if Conf then
      Option:RestoreRideStateAfterInteract()
    else
      Option:ClearRideRestoreState()
    end
  end
  Log.Debug("Clean up Dialogue Fsm variables")
  self.fsm:SetProperty("CurrentAction", nil)
  self.fsm:SetProperty("CurrentOption", nil)
  self.fsm:SetProperty("TargetNPC", nil)
  self.fsm:SetProperty("ClientAction", nil)
  self.fsm:SetProperty("Participants", nil)
  self.fsm:SetProperty("BornTransform", nil)
  self.fsm:SetProperty("LastSpeaker", nil)
  local Player = DialogueUtils.GetPlayer()
  if Player then
    Player.inputComponent:SetCameraControlEnable(self.ParentModule, true)
  end
  if self.ParentModule then
    self.ParentModule:GetLastTalkedDialogue()
    Log.Debug("End Dialogue Consume Last Talked Dialogue")
  end
  self:Finish()
end

function DialogueDestroyAction:DestroyStageActor()
  if not RocoEnv.IS_EDITOR then
    return
  end
  local StageActor = self.fsm:GetProperty("StageActor")
  self.fsm:SetProperty("StageActor", nil)
  if not StageActor or not UE.UObject.IsValid(StageActor) then
    StageActor = nil
    return
  end
  StageActor:K2_DestroyActor()
  StageActor = nil
end

function DialogueDestroyAction:OnExit()
end

function DialogueDestroyAction:OnFinish()
  local bInBattle = self:GetProperty("bInBattle")
  if not bInBattle then
    return
  end
  local caller = self:GetProperty("caller")
  local callback = self:GetProperty("callback")
  self:SetProperty("caller", nil)
  self:SetProperty("callback", nil)
  if caller and callback then
    Log.Debug("BattleDialogueFsm closed, returning to battle")
    callback(caller)
  else
    Log.Debug("BattleDialogueFsm caller missing or callback missing")
  end
end

function DialogueDestroyAction:OnChangeCameraCallback()
  NRCModeManager:DoCmd(DialogueModuleCmd.DestroyUICamera)
end

return DialogueDestroyAction

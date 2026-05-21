local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")
local Base = DialogueActionBase
local DialogueInitAction = Base:Extend("DialogueInitAction")
FsmUtils.MergeMembers(Base, DialogueInitAction, {
  {name = "TargetNPC", type = "var"},
  {name = "ConfID", type = "var"}
})

function DialogueInitAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialogueInitAction:OnEnter()
  self:InjectProperties()
  self.DialogueConf = _G.DataConfigManager:GetDialogueConf(self.ConfID, true)
  local bInBattle = self.fsm:GetProperty("bInBattle", false)
  if bInBattle then
  else
    _G.NRCEventCenter:DispatchEvent(DialogueModuleEvent.DialogueStarted, self)
    _G.NRCAudioManager:SetStateByName("Dialogue", "Open", "DialogueInitAction:OnEnter")
    NRCModuleManager:DoCmd(FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_OPTION)
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    if self.TargetNPC then
      if self.TargetNPC.PetHUDComponent then
        self.TargetNPC.PetHUDComponent:SetVisible(false)
      end
      self.TargetNPC:SendEvent(NPCModuleEvent.OnEnterDialogue, self.DialogueConf)
    end
    DialogueUtils.ToggleAI(self.TargetNPC, false)
    DialogueUtils.ToggleInput(false)
    self:MakeStageTransform()
    self:CreateStageActor()
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "DialogueModule.BlockInputAction")
  self.fsm:SetProperty("PlayerPosSyncBlocker", nil)
  local player = DialogueUtils.GetHero()
  if player and player:IsInTogetherMove() then
    local player_view = DialogueUtils.ExtraActorView(player)
    if player_view then
      self.fsm:SetProperty("PlayerPosSyncBlocker", player:GetActorTransform())
      if player.movementComponent and player.movementComponent.SetSyncMove then
        player.movementComponent:SetSyncMove(false)
      end
    end
    DialogueUtils.SetAudioGender(DialogueUtils.GetHero())
  end
  DialogueUtils.ClearLookAt(player)
  self:Finish()
end

function DialogueInitAction:MakeStageTransform()
  local Transform
  local Option = self.fsm:GetProperty("CurrentOption")
  local Config = Option and Option.config
  Config = Config or self.fsm:GetProperty("OptionConf")
  local StageString = Config and Config.action.action_param2
  if not string.IsNilOrEmpty(StageString) then
    Transform = SceneUtils.StringToTransform(StageString)
  end
  Transform = Transform or DialogueUtils.GetBornTransform(self.TargetNPC)
  self.fsm:SetProperty("BornTransform", Transform)
end

function DialogueInitAction:CreateStageActor()
  if not RocoEnv.IS_EDITOR then
    return
  end
  local StageActor = self.fsm:GetProperty("StageActor")
  local StageTransform = self.fsm:GetProperty("BornTransform")
  if not StageTransform then
    return
  end
  if not StageActor or not UE.UObject.IsValid(StageActor) then
    local Klass = _G.NRCBigWorldPreloader:Get("DialogueStage") or NRCModuleManager:DoCmd(CreatePlayerModuleCmd.GetAsset, "DialogueStage")
    local World = UE4Helper.GetCurrentWorld()
    StageActor = World:SpawnActor(Klass, UE.FTransform(), UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, World)
    self.fsm:SetProperty("StageActor", StageActor)
  end
  StageActor:SetActorEnableCollision(false)
  StageActor:Abs_K2_SetActorTransform_WithoutHit(StageTransform, false, true)
  local Option = self.fsm:GetProperty("CurrentOption")
  local Config = Option and Option.config
  Config = Config or self.fsm:GetProperty("OptionConf")
  local ConfigID = Config and Config.id or 999
  local DisplayText = string.format("Stage-%d-%d", ConfigID, self.DialogueConf.id)
  StageActor:SetActorLabelNoFlush(DisplayText, false)
  local Text = StageActor.TextRender
  if Text then
    Text:SetText(DisplayText)
  end
end

function DialogueInitAction:OnExit()
end

return DialogueInitAction

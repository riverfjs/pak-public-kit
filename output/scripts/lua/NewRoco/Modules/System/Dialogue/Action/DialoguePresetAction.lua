local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local DialogueActionBase = require("NewRoco.Modules.System.Dialogue.Action.DialogueActionBase")
local Base = DialogueActionBase
local DialoguePresetAction = Base:Extend("DialoguePresetAction")
FsmUtils.MergeMembers(Base, DialoguePresetAction, {
  {name = "TargetNPC", type = "var"},
  {
    name = "DialogueConf",
    type = "var"
  }
})

function DialoguePresetAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
end

function DialoguePresetAction:OnEnter()
  self:InjectProperties()
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    self:Finish()
    return
  end
  if self.DialogueConf and self.DialogueConf.dialoguePreset and 0 ~= self.DialogueConf.dialoguePreset then
    local NPC = self.TargetNPC
    if NPC then
      local view = NPC.viewObj
      if view and view.resourceLoaded then
        self:Preset()
      else
        NPC:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.Preset)
      end
      return
    end
  end
  if DialogueUtils.IsEntryDialogue(self.fsm) then
    local Target = self.TargetNPC
    DialogueUtils.ToggleAI(Target, false)
    DialogueUtils.StopTurn(Target)
    if self:NeedFixNPCLocation() then
      DialogueUtils.ResetLookAt(Target, true)
      if not self:DontResetToBornTransform() then
        DialogueUtils.RestoreBornTransform(Target)
      end
      self:FixNPCLocation()
      return
    elseif self:NeedFixPlayerLocation() then
      DialogueUtils.ResetLookAt(Target, true)
      if not self:DontResetToBornTransform() then
        DialogueUtils.RestoreBornTransform(Target)
      end
      self:FixPlayerLocation()
    end
  end
  self:Finish()
end

function DialoguePresetAction:OnFinish()
  local bInBattle = self:GetProperty("bInBattle")
  if bInBattle then
    return
  end
  if not self.fsm:GetProperty("CurrentTimeline", nil) then
    self:ResetActorTransforms()
  end
  self:RecordActorTransforms()
  if DialogueUtils.IsEntryDialogue(self.fsm) and not self.fsm:GetProperty("PlayerPosSyncBlocker") then
    self:SyncPlayerPosition()
  end
end

function DialoguePresetAction:NeedFixNPCLocation()
  local CurrentOption = self.fsm:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or self.fsm:GetProperty("OptionConf")
  if not OptionConf then
    return false
  end
  if not OptionConf.enablefix_angle then
    return false
  end
  return 1 == OptionConf.enablefix_angle
end

function DialoguePresetAction:FixNPCLocation()
  local TargetView = self.TargetNPC and self.TargetNPC.viewObj
  if not TargetView then
    self:FinishFixNPCLocation()
    return
  end
  local CurrentOption = self.fsm:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or self.fsm:GetProperty("OptionConf")
  if not OptionConf then
    return
  end
  local Runner = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetEQS, "Dialogue")
  local Request = Runner:MakeRequest(nil, TargetView)
  Request:SetFloatParam("OnCircle.CircleRadius", math.max(100, OptionConf.fix_distance or 100))
  local Result = Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.SingleResult, Request, self, self.OnQueryNPCLocation)
  if Result < 0 then
    self:FinishFixNPCLocation()
  end
end

function DialoguePresetAction:OnQueryNPCLocation(Runner)
  if not Runner then
    self:FinishFixNPCLocation()
    return
  end
  if not Runner.bFinished or not Runner.bSuccess then
    self:FinishFixNPCLocation()
    return
  end
  local Locations = Runner.ResultLocations
  if not Locations or 0 == Locations:Length() then
    Log.Error("\229\164\170\233\154\190\228\186\134\239\188\140\228\184\128\228\184\170\228\189\141\231\189\174\233\131\189\230\178\161\230\156\137\231\174\151\229\135\186\230\157\165")
    self:FinishFixNPCLocation()
    return
  end
  local TargetView = self.TargetNPC and self.TargetNPC.viewObj
  local NPCLoc = TargetView:K2_GetActorLocation()
  local FixLoc = Locations:Get(1)
  local Delta = FixLoc - NPCLoc
  Delta.Z = 0
  self.TargetNPC:SetActorRotation(Delta:ToRotator())
  local Player = DialogueUtils.GetHero()
  if Player then
    local AbsLocation = Runner.AbsoluteResultLocations:Get(1)
    if AbsLocation then
      AbsLocation.Z = AbsLocation.Z + Player:GetHalfHeight()
      Player:SetActorLocation(AbsLocation)
      Player:FaceTo(self.TargetNPC)
    end
  end
  self:FinishFixNPCLocation()
end

function DialoguePresetAction:FinishFixNPCLocation()
  self:Finish()
end

function DialoguePresetAction:NeedFixPlayerLocation()
  local CurrentOption = self.fsm:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or self.fsm:GetProperty("OptionConf")
  if not OptionConf then
    return false
  end
  local FixType = OptionConf.enablefix_distance
  return 2 == FixType or 5 == FixType
end

function DialoguePresetAction:DontResetToBornTransform()
  local CurrentOption = self.fsm:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or self.fsm:GetProperty("OptionConf")
  if not OptionConf then
    return false
  end
  local FixType = OptionConf.enablefix_distance
  return 5 == FixType
end

function DialoguePresetAction:FixPlayerLocation()
  local CurrentOption = self.fsm:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or self.fsm:GetProperty("OptionConf")
  local Player = DialogueUtils.GetHero()
  if not Player then
    return
  end
  local DefaultFixDistance = 100
  local FixDistance = OptionConf and OptionConf.fix_distance or DefaultFixDistance
  local FixPosition = self.TargetNPC:GetForwardVector() * FixDistance + self.TargetNPC:GetActorLocation()
  FixPosition = SceneUtils.GetPosInNearLand(FixPosition, Player:GetHalfHeight()) or FixPosition + UE4.FVector(0, 0, Player:GetHalfHeight())
  Player:SetActorLocation(FixPosition)
  Player:FaceTo(self.TargetNPC)
end

function DialoguePresetAction:Preset()
  if not self.TargetNPC then
    return
  end
  if not self.TargetNPC.viewObj then
    return
  end
  if 1 == self.DialogueConf.dialoguePreset then
    local CampFire = self.TargetNPC.viewObj
    local skillPath = "/Game/ArtRes/Effects/G6Skill/Luying/CampingLoop.CampingLoop"
    local skillProxy = RocoSkillProxy.Create(skillPath, CampFire.RocoSkill, _G.PriorityEnum.Active_Player_Action)
    skillProxy:SetPassive(true)
    _G.NRCModuleManager:DoCmd(_G.CampingModuleCmd.PlayFixCampingSkill, CampFire, skillProxy)
  elseif self.DialogueConf.dialoguePreset == _G.Enum.DialoguePreset.AlchemyPreset then
    local IronPan = self.TargetNPC.viewObj
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.DoFixPerform, IronPan, 102)
  end
  self:Finish()
end

function DialoguePresetAction:OnExit()
end

function DialoguePresetAction:ResetActorTransforms()
  if not self.DialogueConf then
    return
  end
  local Performs = self.DialogueConf.actor_perform
  if not Performs then
    return
  end
  if 0 == #Performs then
    return
  end
  local Transform = self.fsm:GetProperty("BornTransform")
  if not Transform then
    return
  end
  for _, Perform in ipairs(Performs) do
    if Perform.move_action == Enum.MoveActionType.Moment and not string.IsNilOrEmpty(Perform.transform) then
      local Actor = self:GetActor(Perform.actor)
      local RelativeTransform = SceneUtils.StringToTransform(Perform.transform)
      local FinalTransform = RelativeTransform * Transform
      DialogueUtils.PinOnGround(Actor, FinalTransform)
      if _G.RocoEnv.IS_EDITOR then
        DialogueUtils.RecordPreActionTransform(Actor)
      end
    end
  end
end

local MoveReq = _G.ProtoMessage:newZoneSceneInteractMoveReq()

function DialoguePresetAction:SyncPlayerPosition()
  local Player = DialogueUtils.GetPlayer()
  if not Player then
    return
  end
  Player:GetServerPoint(MoveReq.to_point)
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_INTERACT_MOVE_REQ, MoveReq)
end

function DialoguePresetAction:RecordActorTransforms()
  if not RocoEnv.IS_EDITOR then
    return
  end
  local Player = DialogueUtils.GetHero()
  local Speaker = self:GetActor(self.DialogueConf.speaker)
  local CameraTarget = self:GetActor(DialogueUtils.GetCameraTarget(self.DialogueConf))
  local bIsDebugging = self.fsm:GetProperty("bIsDebugging", false)
  if bIsDebugging then
    Log.Error("\232\176\131\232\175\149\228\184\173...\232\183\179\232\191\135\232\174\176\229\189\149\232\167\146\232\137\178\231\138\182\230\128\129\229\138\159\232\131\189")
    self.fsm:SetProperty("bIsDebugging", false)
    local Performs = self.DialogueConf.actor_perform
    if Performs then
      for _, Perform in ipairs(Performs) do
        local Actor = self:GetActor(Perform.actor)
        if Actor ~= Player and Actor ~= Speaker and Actor ~= CameraTarget then
          DialogueUtils.RestorePreActionTransform(Actor)
        end
      end
    end
    DialogueUtils.RestorePreActionTransform(Player)
    DialogueUtils.RestorePreActionTransform(Speaker)
    DialogueUtils.RestorePreActionTransform(CameraTarget)
  else
    local Performs = self.DialogueConf.actor_perform
    if Performs then
      for _, Perform in ipairs(Performs) do
        local Actor = self:GetActor(Perform.actor)
        if Actor ~= Player and Actor ~= Speaker and Actor ~= CameraTarget then
          DialogueUtils.RecordPreActionTransform(Actor)
        end
      end
    end
    DialogueUtils.RecordPreActionTransform(Player)
    DialogueUtils.RecordPreActionTransform(Speaker)
    DialogueUtils.RecordPreActionTransform(CameraTarget)
  end
end

return DialoguePresetAction

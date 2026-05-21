require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.Instance.BP_NPCInstanceMechanismBase_C")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local BP_NPCInstanceWeightPlate_C = Base:Extend("BP_NPCInstanceWeightPlate_C")
local CheckEnterSize = UE.FVector(23, 23, 10)

function BP_NPCInstanceWeightPlate_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.PlayerStanding = 0
  self.bControlByServer = false
  self.TriggerOnAudioSessionId = nil
  self.TriggerOffAudioSessionId = nil
  self.bSilence = false
  self.CheckLeaveSize = nil
  self.AnimInst = nil
end

function BP_NPCInstanceWeightPlate_C:OnVisible()
  if self.sceneCharacter then
    self:ChangeState(self.sceneCharacter.luaObj.LogicStatus)
  end
  Base.OnVisible(self)
  if self.PlayerStanding <= 0 then
    self.NiagaraInstance:SetActive(true, true)
  end
  self.AnimInst = self:GetAnimInstance()
end

function BP_NPCInstanceWeightPlate_C:ReceiveDestroyed()
  self:TryReleaseAudioSession(self.TriggerOnAudioSessionId)
  self:TryReleaseAudioSession(self.TriggerOffAudioSessionId)
  self.AnimInst = nil
  Base.ReceiveDestroyed(self)
end

function BP_NPCInstanceWeightPlate_C:TryReleaseAudioSession(SessionId, Source)
  if nil ~= SessionId then
    _G.NRCAudioManager:ReleaseSession(SessionId, true, Source or self.name)
  end
end

function BP_NPCInstanceWeightPlate_C:UpdateState(bInit)
  Base.UpdateState(self, bInit)
  if not self.sceneCharacter then
    return
  end
  if not SceneUtils.IsLogicStatusUnlock(self.sceneCharacter) and not self.bSilence then
    self.sceneCharacter.canTriggerInteraction = false
    self.sceneCharacter.InteractionComponent:UpdateMarkShowDistance()
    self.bControlByServer = true
    self.PlayerStanding = 999
    self:CheckActorShow(true)
    self:SetActorTickEnabled(false)
    self.bSilence = true
  end
end

function BP_NPCInstanceWeightPlate_C:ChangeState(State, bInit)
  Base.ChangeState(self, State, bInit)
  if not self.NiagaraInstance then
    return
  end
  if 1 == self.CurrentState then
    if self:CheckActorShow(true) then
    end
  else
    if self.PlayerStanding > 0 then
      self.bControlByServer = false
      return
    end
    if self:CheckActorShow(false) then
      self.bControlByServer = false
      self:TryFreeTriggerPetAI()
    end
  end
end

function BP_NPCInstanceWeightPlate_C:TryFreeTriggerPetAI()
  if self.TriggerPet then
    local AIComp = self.TriggerPet:EnsureComponent(AIComponent)
    AIComp:ForceLockForReason(false, true, _G.AIDefines.LockReason.WAITING)
    self.TriggerPet = nil
  end
end

function BP_NPCInstanceWeightPlate_C:ReceiveActorBeginOverlap(OtherActor)
  if not UE.UObject.IsValid(self) then
    return
  end
  self.Overridden.ReceiveActorBeginOverlap(self, OtherActor)
end

function BP_NPCInstanceWeightPlate_C:ReceiveActorEndOverlap(OtherActor)
  if not UE.UObject.IsValid(self) then
    return
  end
  self.Overridden.ReceiveActorEndOverlap(self, OtherActor)
end

function BP_NPCInstanceWeightPlate_C:Overlap(OtherActor, Component)
  if Component ~= OtherActor.CapsuleComponent then
    return
  end
  if self:CheckFunctionBan() then
    return
  end
  local Character = OtherActor.sceneCharacter
  local PlayerView = OtherActor
  local MoveComp
  if not Character and UE.UObject.IsValid(OtherActor) then
    if OtherActor:IsA(UE.ARocoVehicleCharacter) then
      local Rider = OtherActor.Rider
      if not Rider then
        MoveComp = OtherActor.CharacterMovement
      else
        Character = Rider and Rider.sceneCharacter
        PlayerView = Rider
        else
          return
        end
        if not (self.sceneCharacter and Character) or not Character.isLocal then
          return
        end
      end
  end
  self.PlayerStanding = self.PlayerStanding + 1
  Log.DebugFormat("WeightPlate Overlap: Actor=%s    PlayerStanding=%d", UE.UObject.GetName(OtherActor), self.PlayerStanding)
  if self.PlayerStanding > 1 then
    return
  end
  self:CheckActorShow(true)
  MoveComp = MoveComp or Character.movementComponent
  if MoveComp and MoveComp.SendMoveReq then
    MoveComp:SendMoveReq(true)
  end
  if 1 == self.sceneCharacter.luaObj.LogicStatus then
    return
  end
  self.sceneCharacter.InteractionComponent:OnPlayerEnterActionArea()
end

function BP_NPCInstanceWeightPlate_C:LeaveOverlap(OtherActor, Component)
  if Component ~= OtherActor.CapsuleComponent then
    return
  end
  if not self.PlayerStanding then
    return
  end
  if self.PlayerStanding <= 0 then
    return
  end
  local Character = OtherActor.sceneCharacter
  local PlayerView = OtherActor
  if not Character and UE.UObject.IsValid(OtherActor) then
    if OtherActor:IsA(UE.ARocoVehicleCharacter) then
      local Rider = OtherActor.Rider
      Character = Rider and Rider.sceneCharacter
      PlayerView = Rider
    else
      return
    end
  end
  if not (self.sceneCharacter and Character) or not Character.isLocal then
    return
  end
  self.PlayerStanding = self.PlayerStanding - 1
  Log.DebugFormat("WeightPlate LeaveOverlap: Actor=%s    PlayerStanding=%d", UE.UObject.GetName(OtherActor), self.PlayerStanding)
  if self.PlayerStanding > 0 then
    return
  end
  a.task(function()
    a.wait(au.DelaySeconds(0.1))
    local MoveComp = Character and Character.movementComponent
    if MoveComp then
      MoveComp:SendMoveReq(true)
    end
  end)()
  if not self.bControlByServer then
    self:CheckActorShow(false)
  end
  self.sceneCharacter.InteractionComponent:OnPlayerLeaveActionArea()
end

function BP_NPCInstanceWeightPlate_C:PostActivation()
  if self.sceneCharacter then
    self.sceneCharacter.InteractionComponent:TryDisableInteraction()
  end
end

function BP_NPCInstanceWeightPlate_C:PostDeactivation()
  if self.sceneCharacter then
    self.sceneCharacter.InteractionComponent:TryEnableInteraction()
  end
end

function BP_NPCInstanceWeightPlate_C:CanThrowInter(Item)
  if self.bSilence or self.PlayerStanding > 0 then
    return false
  end
  return Base.CanThrowInter(self, Item)
end

function BP_NPCInstanceWeightPlate_C:CanEnterThrowInter(Comp)
  if self.bSilence or self.PlayerStanding > 0 then
    return false
  end
  if 1 == self.CurrentState then
    Log.Warning("\229\144\142\229\143\176\230\173\163\229\156\168\229\133\168\229\138\155\230\129\162\229\164\141\232\184\143\230\157\191\228\184\173")
    return false
  end
  if not Comp then
    return false
  end
  if Comp == self.NRCSkeletalMesh then
    return true
  end
  if Comp == self.TriggerOn then
    return true
  end
  return false
end

function BP_NPCInstanceWeightPlate_C:CheckFunctionBan()
  local Ban, _ = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_OPTION, true, false)
  return Ban
end

function BP_NPCInstanceWeightPlate_C:CheckActorShow(bEnablePlate)
  if self.bSilence then
    return false
  end
  local highlightVisible = self.NiagaraInstance:IsVisible()
  local highlightShouldBeVisible = not bEnablePlate
  if highlightVisible == highlightShouldBeVisible then
    return false
  end
  self:TogglePlateState(bEnablePlate)
  return true
end

function BP_NPCInstanceWeightPlate_C:TogglePlateState(bEnablePlate)
  self.NiagaraInstance:SetVisibility(not bEnablePlate, true)
  local soundId = bEnablePlate and 1185 or 10020007
  local audioSessionField = bEnablePlate and "TriggerOnAudioSessionId" or "TriggerOffAudioSessionId"
  self[audioSessionField] = _G.NRCAudioManager:PlaySound3DWithActorAuto(soundId, self, self.name)
  self:ChangeTriggerBox(bEnablePlate)
  self:SetOptionDisabledByCustomCondition(bEnablePlate)
  if self.AnimInst then
    self.AnimInst.On = bEnablePlate
    self.AnimInst.Off = not bEnablePlate
  end
end

function BP_NPCInstanceWeightPlate_C:ChangeTriggerBox(bEnter)
  if bEnter then
    if not self.CheckLeaveSize then
      local Scale = self.TriggerOn:GetScaledBoxExtent().Z / CheckEnterSize.Z
      self.CheckLeaveSize = UE.FVector(CheckEnterSize.X + 6, CheckEnterSize.Y + 6, 80 / Scale)
    end
    self.TriggerOn:SetBoxExtent(self.CheckLeaveSize, false)
  else
    self.TriggerOn:SetBoxExtent(CheckEnterSize, false)
  end
end

function BP_NPCInstanceWeightPlate_C:GetAnimInstance()
  if not self.NRCSkeletalMesh then
    return nil
  end
  return self.NRCSkeletalMesh:GetAnimInstance()
end

function BP_NPCInstanceWeightPlate_C:GetBottomAndTop()
  local origin = UE.FVector(0, 0, 0)
  local extent = UE.FVector(0, 0, 0)
  local radius = 0
  UE.UKismetSystemLibrary.GetComponentBounds(self.NRCSkeletalMesh, origin, extent, radius)
  return origin.Z, extent.Z
end

function BP_NPCInstanceWeightPlate_C:SetOptionDisabledByCustomCondition(bNewState)
  local npc = self.sceneCharacter
  if not npc then
    return
  end
  local interactionComponent = npc.InteractionComponent
  if not interactionComponent then
    return
  end
  local options = interactionComponent:GetAllOptions()
  for _, option in pairs(options) do
    option.disable_by_custom_condition = bNewState
  end
end

return BP_NPCInstanceWeightPlate_C

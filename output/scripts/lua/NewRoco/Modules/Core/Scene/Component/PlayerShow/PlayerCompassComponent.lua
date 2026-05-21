local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local ResQueue = require("NewRoco.Utils.ResQueue")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = ActorComponent
local PlayerCompassStateEnum = {
  IDLE = 1,
  START_LOADING = 2,
  START_SHOWING = 3,
  STARTED = 4,
  END_LOADING = 5,
  END_SHOWING = 6
}
local PlayerCompassComponent = Base:Extend("PlayerCompassComponent")

function PlayerCompassComponent:Ctor()
  Base.Ctor(self)
end

function PlayerCompassComponent:Attach(owner)
  Base.Attach(self, owner)
  self.started = false
  self.is_loading = false
  self.is_showing = false
  self.IsForceTargetSetActorHiddenInGame = false
  self:AddEventListener()
  self.localPlayer = _G.PlayerModuleCmd and _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function PlayerCompassComponent:DeAttach()
  self:StopImmediate()
  self:RemoveEventListener()
  Base.DeAttach(self)
end

function PlayerCompassComponent:Destroy()
  self:StopImmediate()
  self:RemoveEventListener()
  Base.Destroy(self)
end

function PlayerCompassComponent:AddEventListener()
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnLogicStatusUpdated)
  self.owner:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnLogicStatusUpdated)
end

function PlayerCompassComponent:RemoveEventListener()
  if self.owner then
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_AVATAR_READY, self.OnLogicStatusUpdated)
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnLogicStatusUpdated)
  end
end

function PlayerCompassComponent:PlayAnimStart()
  self.PlayerStarted = true
  local param = {
    1,
    0,
    0,
    0.2,
    1,
    0,
    "Locomotion"
  }
  local Type = _G.ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainOpen", param) or Play(self, Type.WPST_SWIMMING, "SwimMainOpen", param) or Play(self, nil, "LobbyMainOpen", param)
end

function PlayerCompassComponent:PlayAnimIdle()
  local param = {
    1,
    0,
    0.2,
    0.05,
    -1,
    0,
    "Locomotion"
  }
  local Type = _G.ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainIdle", param) or Play(self, Type.WPST_SWIMMING, "SwimMainIdle", param) or Play(self, nil, "LobbyMainIdle", param)
end

function PlayerCompassComponent:PlayAnimEnd()
  self.PlayerStarted = false
  local param = {
    1,
    0,
    0.05,
    0.5,
    1,
    0,
    "Locomotion"
  }
  local Type = _G.ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  local player = self:GetOwner()
  if player then
    player:StopAllMontage()
  end
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainEnd", param) or Play(self, Type.WPST_SWIMMING, "SwimMainEnd", param) or Play(self, nil, "LobbyMainEnd", param)
end

function PlayerCompassComponent:TryPlayAnimWithStatus(Status, Anim, Param)
  local player = self:GetOwner()
  if nil == player then
    return false
  end
  if nil == Status then
    player:PlayAnim(Anim, table.unpack(Param))
    return true
  end
  if player.statusComponent:HasStatus(Status) then
    player:PlayAnim(Anim, table.unpack(Param))
    return true
  end
  return false
end

function PlayerCompassComponent:PlayShowCompass()
  if self.started then
    return
  end
  if self.owner.buffComponent and self.owner.buffComponent:HasBuff("Transform_Buff") then
    return
  end
  if not self.owner.avatarLoaded then
    return
  end
  if self.is_loading or self.is_showing then
    self:StopImmediate()
  end
  self.started = true
  self.is_loading = true
  self.is_showing = false
  if self.LoadQueue then
    self.LoadQueue:Release()
  else
    self.LoadQueue = ResQueue(30, ResQueue.RunMode.Concurrent, PriorityEnum.Passive_3P_TakeCompass)
  end
  self.LoadQueue:InsertClass("StartSkill", "/Game/ArtRes/Effects/G6Skill/SceneEffect/Compass/G6_Scene_Compass_Star_Sync.G6_Scene_Compass_Star_Sync")
  self.LoadQueue:InsertClass("Compass", "/Game/NewRoco/Modules/Core/NPC/LobbyMain/BP_CompassHalo.BP_CompassHalo_C")
  self.LoadQueue:StartLoad(self, self.OnShowResReady)
end

function PlayerCompassComponent:OnShowResReady(Queue, Success)
  if not Success then
    self.LoadQueue:Release()
    Log.Error("Load Res Failed!!!!!!")
    self.started = false
    self.is_loading = false
    self.is_showing = false
    return
  end
  local CompassClass = self.LoadQueue:Get("Compass")
  if not UE.UObject.IsValid(CompassClass) then
    self.LoadQueue:Release()
    Log.Error("Load CompassClass Failed!!!!!!")
    self.started = false
    self.is_loading = false
    self.is_showing = false
    return
  end
  self.is_loading = false
  self.is_showing = true
  local world = _G.UE4Helper.GetCurrentWorld()
  self.Halo = world:SpawnActor(CompassClass, UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0)), UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, world)
  self.IsForceTargetSetActorHiddenInGame = self:ShouldSetCompassHidden()
  self:ForceTargetSetActorHiddenInGame(self.IsForceTargetSetActorHiddenInGame)
  local caster = self:GetOwnerView()
  if caster then
    UE4.UNRCStatics.SetActorOwner(self.Halo, caster)
    local skillComponent = caster.RocoSkill
    if skillComponent then
      self.StartSkill = skillComponent:FindOrAddSkillObj(self.LoadQueue:Get("StartSkill"))
      if not self.StartSkill then
        self:StopImmediate()
        return
      end
      self.StartSkill:SetCaster(caster)
      local targets = {}
      table.insert(targets, self.Halo)
      self.StartSkill:SetTargets(targets)
      self.StartSkill:RegisterEventCallback("PlayStart", self, self.PlayAnimStart)
      self.StartSkill:RegisterEventCallback("PlayIdle", self, self.PlayAnimIdle)
      self.StartSkill:RegisterEventCallback("PreEnd", self, self.StartEnd)
      self.StartSkill:RegisterEventCallback("End", self, self.StartEnd)
      self.StartSkill:RegisterEventCallback("Interrupt", self, self.StartInterrupt)
      self.StartSkill:RegisterEventCallback("StartFailed", self, self.StartInterrupt)
      self.StartSkill:SetPassive(false)
      skillComponent:PlaySkill(self.StartSkill)
    end
  end
end

function PlayerCompassComponent:StartEnd()
  self.is_showing = false
end

function PlayerCompassComponent:StartInterrupt()
  self.is_showing = false
  self.StartSkill = nil
  self:DestroyActor()
end

function PlayerCompassComponent:HideShowCompass()
  if not self.started then
    return
  end
  if self.is_loading or self.is_showing then
    self:StopImmediate()
    return
  end
  self.started = false
  self.is_loading = true
  if self.LoadQueue then
    self.LoadQueue:Release()
  else
    self.LoadQueue = ResQueue(30, ResQueue.RunMode.Concurrent, PriorityEnum.Passive_3P_TakeCompass)
  end
  self.LoadQueue:InsertClass("EndSkill", "/Game/ArtRes/Effects/G6Skill/SceneEffect/Compass/G6_Scene_Compass_End_Sync.G6_Scene_Compass_End_Sync")
  self.LoadQueue:StartLoad(self, self.OnHideResReady)
end

function PlayerCompassComponent:OnHideResReady(Queue, Success)
  if not Success then
    Log.Error("Load Res Failed!!!!!!")
    self.LoadQueue:Release()
    self.started = false
    self.is_loading = false
    self.is_showing = false
    self:StopImmediate()
    return
  end
  self.is_loading = false
  self.is_showing = true
  local player = self:GetOwner()
  local caster = player.viewObj
  if caster then
    local skillComponent = caster.RocoSkill
    if skillComponent then
      self.EndSkill = skillComponent:FindOrAddSkillObj(self.LoadQueue:Get("EndSkill"))
      self.EndSkill:SetCaster(caster)
      local targets = {}
      table.insert(targets, self.Halo)
      self.EndSkill:SetTargets(targets)
      self.EndSkill:SetPassive(false)
      self.EndSkill:RegisterEventCallback("PlayEnd", self, self.PlayAnimEnd)
      self.EndSkill:RegisterEventCallback("PreEnd", self, self.EndSkillFinish)
      self.EndSkill:RegisterEventCallback("End", self, self.EndSkillFinish)
      self.EndSkill:RegisterEventCallback("Interrupt", self, self.EndSkillFinish)
      self.EndSkill:RegisterEventCallback("StartFailed", self, self.EndSkillFinish)
      skillComponent:PlaySkill(self.EndSkill)
    end
  end
end

function PlayerCompassComponent:EndSkillFinish()
  self.is_showing = false
  self:DestroyActor()
end

function PlayerCompassComponent:DestroyActor()
  if UE.UObject.IsValid(self.Halo) then
    self.Halo:K2_DestroyActor()
  end
  self.Halo = nil
end

function PlayerCompassComponent:StopImmediate()
  local player = self:GetOwner()
  if player then
    player:StopAllMontage()
  end
  local playerView = player and player.viewObj
  local skillComponent = playerView and playerView.RocoSkill
  if skillComponent and self.EndSkill then
    skillComponent:CancelSkill(self.EndSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  if skillComponent and self.StartSkill then
    skillComponent:CancelSkill(self.StartSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  self.StartSkill = nil
  self.EndSkill = nil
  self:DestroyActor()
  if self.LoadQueue then
    self.LoadQueue:Release()
  end
  self.started = false
  self.is_showing = false
  self.is_loading = false
end

function PlayerCompassComponent:ShouldShowCompass()
  if not self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_OPEN_LOBBY_MAIN_INNER) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_OPEN_UI_FULL_SCENE) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) or self.owner.statusComponent and self.owner.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN) then
    return false
  end
  return true
end

function PlayerCompassComponent:OnLogicStatusUpdated()
  if self:ShouldShowCompass() then
    self:PlayShowCompass()
  else
    self:HideShowCompass()
  end
end

function PlayerCompassComponent:ShouldSetCompassHidden()
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if playerModule and playerModule._hideAllPlayer and playerModule._hideAllPlayer:any() and self.owner:GetServerId() ~= playerModule._localUin then
    return true
  end
  if not self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_OPEN_LOBBY_MAIN_INNER) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_OPEN_UI_FULL_SCENE) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST) or self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER) or self.owner.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    return true
  end
  return false
end

function PlayerCompassComponent:OnViewObjVisibleChanged(Visible, Reason)
  if Visible then
    if self:ShouldSetCompassHidden() then
      self:ForceTargetSetActorHiddenInGame(true)
    else
      self:ForceTargetSetActorHiddenInGame(false)
    end
  else
    self:ForceTargetSetActorHiddenInGame(true)
  end
end

function PlayerCompassComponent:ForceTargetSetActorHiddenInGame(isHidden, ignoreSetFlag)
  if self.Halo and UE.UObject.IsValid(self.Halo) then
    self.Halo:SetVisibleFromCppByReason(not isHidden, NPCModuleEnum.NpcReasonFlags.ANY)
    if not ignoreSetFlag then
      self.IsForceTargetSetActorHiddenInGame = isHidden
    end
  end
end

function PlayerCompassComponent:Update(deltaTime)
  if self.IsForceTargetSetActorHiddenInGame or not self.Halo then
    return
  end
  if self.localPlayer then
    local controller = self.localPlayer:GetUEController()
    if controller and UE.UObject.IsValid(controller) then
      local cameraManager = controller.playerCameraManager
      if cameraManager and UE.UObject.IsValid(cameraManager) then
        local caster = self:GetOwner()
        if cameraManager and caster and caster.viewObj then
          local fadeInfo = cameraManager:GetCurActorFadeInfo(caster.viewObj)
          if not self.IsForceTargetSetActorHiddenInGame then
            if -1 == fadeInfo or fadeInfo >= 0.8 then
              self:ForceTargetSetActorHiddenInGame(false, true)
            else
              self:ForceTargetSetActorHiddenInGame(true, true)
            end
          end
        end
      end
    end
  end
end

return PlayerCompassComponent

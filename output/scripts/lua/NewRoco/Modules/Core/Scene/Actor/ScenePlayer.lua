local Base = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerBase")
local AbilityComp = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityComponent")
local MovementComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.ReplicateMovementComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local HUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.HUDComponent")
local StatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.StatusSyncComponent")
local VitalityComponent = require("NewRoco.Modules.Core.Scene.Component.Vitality.VitalityComponentNew")
local TemperatureComponent = require("NewRoco.Modules.Core.Scene.Component.Temperature.TemperatureComponent")
local RolePlayComponent = require("NewRoco.Modules.Core.Scene.Component.RolePlay.RolePlayComponent")
local RoleHPComponent = require("NewRoco.Modules.Core.Scene.Component.RoleHP.RoleHPSyncComponent")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local TakePhotoComponent = require("NewRoco.Modules.Core.Scene.Component.TakePhoto.TakePhotoComponent")
local AbnormalStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusComponent")
local ResonanceComponent = require("NewRoco.Modules.Core.Scene.Component.ResonanceComponent")
local ScenePlayer = Base:Extend("ScenePlayer")

function ScenePlayer:Ctor(module)
  Base.Ctor(self, module)
  self.isLocal = false
  self.VisitorTeleportChecker = StatusCheckerGroup({
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.FullScreen,
    StatusCheckerEnum.Loading
  })
  self.AvatarUnloadFlags = 0
end

function ScenePlayer:InitData(Config, ServerData)
  Base.InitData(self, Config, ServerData)
  self.serverData = ServerData
  self:InitComponent()
  if ServerData and ServerData.base then
    local bornPos = ServerData.base.pt.pos
    bornPos = SceneUtils.ServerPos2PlayerPos(bornPos)
    local surfaceBornPos = bornPos
    if surfaceBornPos then
      self.pos = surfaceBornPos
      Log.DebugFormat("Init new player,bornPos %s, landpos %s ", tostring(bornPos), tostring(self.pos))
      self:InitActor(UEPath.BP_Player, self.pos, ServerData.base.pt.dir)
      if self.viewObj and self.viewObj.bIsUnloaded then
        self.NoAvatar = true
        self.UnloadReasonFlag = PlayerModuleCmd.AvatarUnloadReason.Significance
      end
      NRCModuleManager:DoCmd(PlayerModuleCmd.AddDistanceFadeMesh, self.viewObj)
    end
  end
  if ServerData then
    self.hudComponent:SetHudName(ServerData.base.name)
    self:SetCharacterGender(ServerData.base.gender)
    self:LoadWand()
  end
end

function ScenePlayer:InitActor(url, pos, rotation)
  Base.InitActor(self, url, pos, rotation)
  local serverRot = SceneUtils.ServerPos2ClientRotator(rotation)
  self.viewObj:K2_SetActorRotation(serverRot, true)
  local bLanded = self.viewObj.CharacterMovement:Abs_Land(pos)
end

function ScenePlayer:InitComponent()
  self.movementComponent = MovementComponent()
  self:AddComponent(self.movementComponent)
  self.hudComponent = HUDComponent()
  self:AddComponent(self.hudComponent)
  self.roleHPComponent = RoleHPComponent()
  self:AddComponent(self.roleHPComponent)
  Base.InitComponent(self)
  self.abilityComponent = AbilityComp()
  self:AddComponent(self.abilityComponent)
  self.statusComponent = StatusComponent()
  self:AddComponent(self.statusComponent)
  self:EnsureComponent(TemperatureComponent)
  self:EnsureComponent(RolePlayComponent)
  self:EnsureComponent(TakePhotoComponent)
  self:EnsureComponent(AbnormalStatusComponent)
  self:EnsureComponent(ResonanceComponent)
end

function ScenePlayer:OnPlayerTeleport(to_pt)
  local serverPos = to_pt.pos
  local newPos = UE4.FVector(serverPos.x, serverPos.y, serverPos.z + 1000)
  local landPos = SceneUtils.GetPosInLand(newPos, self:GetHalfHeight())
  if landPos then
    self:SetActorLocation(landPos)
  else
    self:SetVisible(false)
  end
end

function ScenePlayer:OnPlayerSuitRelax(ActionInfo)
  local performType = ActionInfo.player_perform_info.perform_type
  if performType == ProtoEnum.PlayerPerformType.PPT_SUIT_IDLE then
    local skillId = ActionInfo.player_perform_info.idle_perform_skill_id
    local petId = ActionInfo.player_perform_info.idle_perform_id
    self.abilityComponent:StartSuitPerform(skillId, petId)
  elseif performType == ProtoEnum.PlayerPerformType.PPT_SUIT_IDLE_BREAK then
    self.abilityComponent:StopSuitPerform()
  end
end

function ScenePlayer:PlayVisitorTeleportEffect()
  if self:IsInTogetherMove() then
    return
  end
  Log.Debug("ScenePlayer:PlayVisitorTeleportEffect")
  if not self.viewObj then
    Log.Error("ScenePlayer:PlayVisitorTeleportEffect \231\142\169\229\174\182\230\146\173\230\148\190\228\188\160\233\128\129\231\137\185\230\149\136\230\151\182\230\178\161\230\156\137viewobj\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  self.VisitorTeleportChecker:Check(self, self.InternalVisitorTeleportEffect)
end

function ScenePlayer:InternalVisitorTeleportEffect()
  Log.Debug("ScenePlayer:InternalVisitorTeleportEffect")
  local skillClass = NPCLuaUtils.GetClass(UEPath.PLAYER_EFFECT.PlayerAppearEffect)
  local skillObj = self.viewObj.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("\231\142\169\229\174\182\228\188\160\233\128\129\231\137\185\230\149\136\232\181\132\230\186\144\232\174\190\231\189\174\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165")
    return
  end
  skillObj:SetPassive(true)
  skillObj:SetCaster(self.viewObj)
  self.viewObj.RocoSkill:PlaySkill(skillObj)
end

function ScenePlayer:LoadWand()
  local newWandPath = self:GetCurWandPath()
  if self._defaultWand == nil or newWandPath ~= self._defaultWand then
    self._defaultWand = newWandPath
    NPCLuaUtils.PreLoad(string.format("%s%s%s", "SkeletalMesh'", self._defaultWand, "'"), PriorityEnum.Other_Player_Logic)
  end
end

function ScenePlayer:UnloadThrownPets()
  local thrown_pets = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetPetByPlayer, self.serverData.base.actor_id or 0)
  for _, pet_id in ipairs(thrown_pets or {}) do
    if pet_id then
      local thrown_pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pet_id)
      if thrown_pet and thrown_pet.viewObj then
        thrown_pet.viewObj:ForceHidden()
      end
    end
  end
end

function ScenePlayer:LoadThrownPets()
  local thrown_pets = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetPetByPlayer, self.serverData.base.actor_id or 0)
  for _, pet_id in ipairs(thrown_pets or {}) do
    if pet_id then
      local thrown_pet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pet_id)
      if thrown_pet and thrown_pet.viewObj then
        thrown_pet.viewObj:ReleaseVisibleLevel()
      end
    end
  end
end

function ScenePlayer:UnLoadAvatar(UnloadReason)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.InviteComponent and localPlayer.InviteComponent:IsTogetherPlayer(self) then
    return
  end
  local UnloadReasonFlag = UnloadReason or PlayerModuleCmd.AvatarUnloadReason.Unknown
  if 0 == UnloadReasonFlag then
    Log.Error("ScenePlayer:UnLoadAvatar UnloadReasonFlag is 0")
    return
  end
  if 0 ~= self.AvatarUnloadFlags & UnloadReasonFlag then
    Log.Warning("ScenePlayer:UnLoadAvatar Unload Avatar failed, already unloaded with this reason" .. UnloadReasonFlag)
    return
  end
  if UnloadReasonFlag == PlayerModuleCmd.AvatarUnloadReason.Unknown then
    Log.Warning("ScenePlayer:UnLoadAvatar UnloadReasonFlag is unknown")
  end
  self.AvatarUnloadFlags = self.AvatarUnloadFlags | UnloadReasonFlag
  Log.Debug("ScenePlayer:UnLoadAvatar UnloadReasonFlag is " .. UnloadReasonFlag)
  if not self.NoAvatar and UE.UObject.IsValid(self.viewObj) then
    self.viewObj.AvatarComponent:UnInitAvatar(true)
    self.viewObj:SetHiddenMask(true, UE.EPlayerForceHiddenType.UnInitAvatar)
    self.NoAvatar = true
    self:UnloadThrownPets()
  end
end

function ScenePlayer:LoadAvatar(UnloadReason)
  local UnloadReasonFlag = UnloadReason or PlayerModuleCmd.AvatarUnloadReason.Unknown
  if 0 == UnloadReasonFlag then
    Log.Error("ScenePlayer:LoadAvatar UnloadReasonFlag is 0")
    return
  end
  if 0 == self.AvatarUnloadFlags & UnloadReasonFlag then
    Log.Warning("ScenePlayer:LoadAvatar Reload Avatar failed but never been unloaded with this reason" .. UnloadReasonFlag)
  end
  if UnloadReasonFlag == PlayerModuleCmd.AvatarUnloadReason.Unknown then
    Log.Warning("ScenePlayer:LoadAvatar UnloadReasonFlag is unknown")
  end
  self.AvatarUnloadFlags = self.AvatarUnloadFlags & ~UnloadReasonFlag
  if self.AvatarUnloadFlags > 0.5 then
    Log.Debug("ScenePlayer:LoadAvatar Reload Avatar, but not all reasons are unloaded. Current AvatarUnloadFlags: " .. self.AvatarUnloadFlags)
    return
  end
  Log.Debug("ScenePlayer:LoadAvatar Reload Avatar, all reasons are unloaded.")
  if self.NoAvatar and UE.UObject.IsValid(self.viewObj) then
    self.NoAvatar = false
    local fashionItems = self:GetFashionItems()
    local salonIds = self:GetSalonIds()
    self:SetDefaultSuit(self.viewObj.Mesh, self.gender, fashionItems, salonIds, true)
    self.viewObj.Mesh:SetVisibility(true)
    self:LoadWand()
    self:LoadThrownPets()
  end
end

function ScenePlayer:Update(DeltaTime)
  Base.Update(self, DeltaTime)
  if self.avtarDirty then
    self:UpdateSuit()
    self.avtarDirty = false
  end
end

function ScenePlayer:SetPlayerFashionWearData(wearingItems)
  if table.valueEquals(wearingItems, self.serverData.wearing_item) then
    return
  end
  self.avtarDirty = true
  Base.SetPlayerFashionWearData(self, wearingItems)
end

function ScenePlayer:SetPlayerSalonWearData(salonInfo)
  if table.valueEquals(salonInfo, self.serverData.salon_item_wear_data) then
    return
  end
  self.avtarDirty = true
  Base.SetPlayerSalonWearData(self, salonInfo)
end

function ScenePlayer:UpdateSuit()
  if UE.UObject.IsValid(self.viewObj) then
    local fashionItems = self:GetFashionItems()
    local salonIds = self:GetSalonIds()
    if self.AvatarID then
      self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
      self.avatarSystem:StopSwitchAvatarSuit(self.AvatarID)
    end
    self:SetDefaultSuit(self.viewObj.Mesh, self.gender, fashionItems, salonIds, true)
    self:LoadWand()
    local skill_path = "/Game/ArtRes/Effects/G6Skill/AvaTar/G6_Avatar_FullBody_Fx01.G6_Avatar_FullBody_Fx01"
    local skillComponent = self.viewObj.RocoSkill
    if skillComponent then
      local skillProxy = RocoSkillProxy.Create(skill_path, skillComponent, PriorityEnum.Passive_3P_ChangeAvatar)
      skillProxy:SetCaster(self.viewObj)
      skillProxy:SetPassive(true)
      local target = self.viewObj
      skillProxy:SetTargets({target})
      skillProxy:PlaySkill()
    end
  end
end

function ScenePlayer:SetDefaultSuit(playerMesh, gender, fashionItems, salonIds, dontChangeMeshComp)
  if self.NoAvatar then
    return
  end
  Base.SetDefaultSuit(self, playerMesh, gender, fashionItems, salonIds, dontChangeMeshComp)
end

function ScenePlayer:OnAvatarComplete()
  Base.OnAvatarComplete(self)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetHiddenMask(false, UE.EPlayerForceHiddenType.UnInitAvatar)
  end
end

function ScenePlayer:SetHeadLookAtActor(TargetActor)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent and HeadLookAtComponent:PreUpdateParamByType(UE4.ELookAtParamType.Target, TargetActor) then
    if GlobalConfig.LookAtLog then
      Log.Debug("ScenePlayer:SetHeadLookAtActor", TargetActor and UE.UObject.IsValid(TargetActor) and TargetActor:GetName())
    end
    HeadLookAtComponent:ResetAutoLookAt()
    if TargetActor then
      HeadLookAtComponent:SetAutoLookAtParam(UE4.ELookAtParamType.Target, TargetActor)
      HeadLookAtComponent:ActiveAutoLookAt(false, nil, nil, true)
    end
  end
end

function ScenePlayer:EnablePlayerTick()
  Log.Debug("ScenePlayer EnablePlayerTick")
  if not self.viewObj or not self.viewObj.CharacterMovement then
    return
  end
  self.viewObj:SetCharacterMovementTickEnabled(true, "EnablePlayerTick")
  self.viewObj:SetActorTickEnabled(true)
  if self.viewObj.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_None then
    self.viewObj.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking, UE.ERocoCustomMovementMode.MOVE_N)
  end
end

function ScenePlayer:DisablePlayerTick()
  Log.Debug("ScenePlayer DisablePlayerTick")
  if not self.viewObj or not self.viewObj.CharacterMovement then
    return
  end
  self.viewObj:SetCharacterMovementTickEnabled(true, "DisablePlayerTick")
  self.viewObj:SetActorTickEnabled(false)
end

return ScenePlayer

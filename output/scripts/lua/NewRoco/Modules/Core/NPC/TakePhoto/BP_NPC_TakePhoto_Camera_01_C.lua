local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local MagicCreationUtils = require("NewRoco/Modules/System/MagicCreation/MagicCreationUtils")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")
local BP_NPC_TakePhoto_Camera_01_C = Base:Extend("BP_NPC_TakePhoto_Camera_01_C")

function BP_NPC_TakePhoto_Camera_01_C:LuaBeginPlay()
  self.bDisableTakePhoto = false
  self.isNeedSkillStartBorn = true
  self.RocoSpringArm.bEnableCameraRotationLag = false
  self.bLocalPlayerTripod = false
  self.bOwnerPlayerValid = false
  Base.LuaBeginPlay(self)
  if not self.sceneCharacter then
    Log.Error("BP_NPC_TakePhoto_Camera_01_C:OnFirstVisible  sceneActor is nil")
    return
  end
  local ServerData = self.sceneCharacter.serverData
  local AvatarId = ServerData.npc_base.create_avatar_id
  self._AvatarId = AvatarId
  local Owner = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, AvatarId)
  self.OwnerUin = Owner and Owner.serverData.base.logic_id
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local LocalActorId = localPlayer.serverData.base.actor_id
  Log.Info("[TakePhoto] NPC created, create_avatar_id=", AvatarId, "local_actor_id=", LocalActorId)
  if AvatarId == LocalActorId then
    self.bLocalPlayerTripod = true
    self.bOwnerPlayerValid = true
  elseif Owner then
    self:OnVisitorChanged()
    local born_die_info = Owner.serverData.base.born_die_info
    if born_die_info then
      if not born_die_info.is_borning and not born_die_info.is_dying then
        self:OnClientBornEnd()
      end
    else
      Log.Error("BP_NPC_TakePhoto_Camera_01_C:OnFirstVisible  born_die_info is nil")
    end
  else
    Log.Error("BP_NPC_TakePhoto_Camera_01_C Invalid Owner", AvatarId)
  end
  self.bAudioPlayEnabled = not self.bLocalPlayerTripod
end

function BP_NPC_TakePhoto_Camera_01_C:BlueprintGetActorEyesViewPoint()
  local Location = self.SceneCaptureComponent2D:K2_GetComponentLocation()
  return Location, self:K2_GetActorRotation()
end

function BP_NPC_TakePhoto_Camera_01_C:OnClientBornEnd()
  self.RocoSpringArm.bEnableCameraRotationLag = self.bLocalPlayerTripod and true or false
  self:OnStartLoopSkill()
end

function BP_NPC_TakePhoto_Camera_01_C:SetAudioPlayEnabled(bEnabled)
  if bEnabled ~= self.bAudioPlayEnabled then
    self.bAudioPlayEnabled = bEnabled
    if self.LoopSkillProxy and self.LoopSkillObj then
      self.LoopSkillProxy.SkillComp:CancelSkill(self.LoopSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
    self:OnStartLoopSkill()
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnCheckLoopAudio(_, SkillObj)
  local bSuccess = self.bAudioPlayEnabled
  if bSuccess then
    SkillObj:BroadcastTriggerEvent("LoopAudio")
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreStartLoop(_, SkillObj)
  self.LoopSkillObj = SkillObj
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreEndLoop()
  self.LoopSkillObj = nil
  self.LoopSkillProxy = nil
end

function BP_NPC_TakePhoto_Camera_01_C:OnStartLoopSkill()
  if self.bDisableTakePhoto then
    return
  end
  if not UE.UObject.IsValid(self) then
    return
  end
  local skillPath = self.LoopG6Skill.AssetPathName
  local OwnerActor = self:GetTripodOwner()
  if "" ~= skillPath then
    local function OnLogicalStart(SkillProxy)
      SkillProxy:RegisterEventCallback("CheckLoopAudio", self, self.OnCheckLoopAudio)
      
      SkillProxy:RegisterEventCallback("PreStart", self, self.OnPreStartLoop)
      SkillProxy:RegisterEventCallback("PreEnd", self, self.OnPreEndLoop)
      self.LoopSkillProxy = SkillProxy
    end
    
    self:PlaySkill(skillPath, self, OwnerActor, OnLogicalStart, self.OnStartLoopSkill, true)
  end
end

function BP_NPC_TakePhoto_Camera_01_C:GetTripodOwner()
  if not self.bOwnerPlayerValid then
    return nil
  end
  local Owner = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self._AvatarId)
  local OwnerActor = Owner and Owner.viewObj or nil
  if OwnerActor and UE.UObject.IsValid(OwnerActor) then
    return OwnerActor
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnVisible()
  Base.OnVisible(self)
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnPhotosTaken, self.OnPhotoTaken)
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnSyncPhotoToken, self.OnSyncPhotoToken)
    Module:RegisterEvent(self, TakePhotosModuleEvent.OnSyncCameraTextureChanged, self.OnSyncCameraTextureChanged)
  end
  _G.NRCEventCenter:RegisterEvent("BP_NPC_TakePhoto_Camera_01_C", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
end

function BP_NPC_TakePhoto_Camera_01_C:OnInVisible()
  Base.OnInVisible(self)
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  if Module then
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnPhotosTaken)
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnSyncPhotoToken, self.OnSyncPhotoToken)
    Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnSyncCameraTextureChanged, self.OnSyncCameraTextureChanged)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
end

function BP_NPC_TakePhoto_Camera_01_C:OnVisitorChanged(Notify)
  if not self.bLocalPlayerTripod then
    local visitList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    local visitorList = visitList or _G.DataModelMgr.PlayerDataModel.visitList
    local bEnable = false
    if visitorList then
      for i, visitor in ipairs(visitorList) do
        if visitor.uin == self.OwnerUin then
          bEnable = true
          break
        end
      end
    end
    self.bOwnerPlayerValid = bEnable
    if not bEnable then
      Log.Warning("Visitor invalid", self.OwnerUin)
    end
  end
end

function BP_NPC_TakePhoto_Camera_01_C:BeforeDestroyAnim(Skill)
  self.bDisableTakePhoto = true
  local OwnerActor = self:GetTripodOwner()
  if OwnerActor then
    Skill:SetTargets({OwnerActor})
  end
end

function BP_NPC_TakePhoto_Camera_01_C:ReceiveBeginPlay()
  Base.ReceiveBeginPlay(self)
  self.SceneCaptureComponent2D = self.SingleSceneCaptureComponent2D
  self.RocoSkill = self:GetComponentByClass(UE4.URocoSkillComponent)
  if not self.RocoSkill then
    local Identity = UE4.FTransform()
    self.RocoSkill = self:AddComponentByClass(UE4.URocoSkillComponent, false, Identity, false)
  end
end

function BP_NPC_TakePhoto_Camera_01_C:ReceiveEndPlay(Reason)
  Base.ReceiveEndPlay(self, Reason)
  if self.ReplaceRecycler then
    self.ReplaceRecycler()
    self.ReplaceRecycler = nil
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnPhotoTaken(PhotoData, bIsTripodMode)
  if not UE.UObject.IsValid(self) then
    return
  end
  if self.bDisableTakePhoto then
    return
  end
  if bIsTripodMode then
    if self.FlashSkillProxy and self.FlashSkillObj then
      self.FlashSkillProxy.SkillComp:CancelSkill(self.FlashSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
      self.FlashSkillObj = nil
      self.FlashSkillProxy = nil
    end
    return
  end
  if PhotoData and self.bLocalPlayerTripod then
    self:InternalPlayFlashAnim(self:GetTripodOwner())
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnSyncPhotoToken(AvatarId, NpcId)
  if AvatarId and AvatarId == self._AvatarId then
    local Owner = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, AvatarId)
    local OwnerActor = Owner and Owner.viewObj or nil
    if OwnerActor and UE.UObject.IsValid(OwnerActor) then
      Log.Debug("[TakePhoto] sync photo flash", AvatarId)
      if self.sceneCharacter then
        if NpcId == self.sceneCharacter.serverData.base.actor_id then
          self:InternalPlayFlashAnim(OwnerActor)
        else
          Log.Warning("[TakePhoto] cannot found avatar tripod to sync photo flash", AvatarId, NpcId, "got", self.sceneCharacter.serverData.base.actor_id)
        end
      end
    else
      Log.Warning("[TakePhoto] cannot found avatar to sync photo flash")
    end
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreStartLoop(_, SkillObj)
  self.LoopSkillObj = SkillObj
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreEndLoop()
  self.LoopSkillObj = nil
  self.LoopSkillProxy = nil
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreStartFlash(_, SkillObj)
  self.FlashSkillObj = SkillObj
end

function BP_NPC_TakePhoto_Camera_01_C:OnPreEndFlash()
  self.FlashSkillObj = nil
  self.FlashSkillProxy = nil
end

function BP_NPC_TakePhoto_Camera_01_C:InternalPlayFlashAnim(Owner)
  if not Owner then
    return
  end
  if self.FlashSkillProxy and self.FlashSkillObj then
    self.FlashSkillProxy.SkillComp:CancelSkill(self.FlashSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.FlashSkillObj = nil
    self.FlashSkillProxy = nil
  end
  local skillPath = self.TakePhotoG6Skill.AssetPathName
  Log.Info("[TakePhoto] OnPhotoTaken, play take photo skill:", skillPath)
  if "" ~= skillPath then
    local function OnPlay(FlashSkillProxy)
      FlashSkillProxy:RegisterEventCallback("PreStart", self, self.OnPreStartFlash)
      
      FlashSkillProxy:RegisterEventCallback("PreEnd", self, self.OnPreEndFlash)
      self.FlashSkillProxy = FlashSkillProxy
    end
    
    self:PlaySkill(skillPath, self, Owner, OnPlay, nil, false)
  end
end

function BP_NPC_TakePhoto_Camera_01_C:Debug_Play(SkillPath)
  SkillPath = MagicCreationUtils.GetSkillLoadPath(SkillPath)
  Log.Info("[TakePhoto] Debug_Play", SkillPath)
  self:PlaySkill(SkillPath, self)
end

function BP_NPC_TakePhoto_Camera_01_C:StartOverlap()
  local Actors = UE.TArray(UE.AActor)
  self:BlueprintGetOverlapActors(Actors)
  if not self.OverlapsPlayers then
    self.OverlapsPlayers = {}
  end
  for i, Overlap in tpairs(Actors) do
    self:InternalBeginOverlap(Overlap)
  end
end

function BP_NPC_TakePhoto_Camera_01_C:EndOverlap()
  if self.OverlapsPlayers then
    for Overlap, _ in pairs(self.OverlapsPlayers) do
      if UE.UObject.IsValid(Overlap) then
        Overlap:SetHiddenMask(false, UE.EPlayerForceHiddenType.TakePhoto)
      end
    end
    self.OverlapsPlayers = nil
  end
end

function BP_NPC_TakePhoto_Camera_01_C:ReceiveActorBeginOverlap(OverlapActor)
  Base.ReceiveActorBeginOverlap(self, OverlapActor)
  self:InternalBeginOverlap(OverlapActor)
end

function BP_NPC_TakePhoto_Camera_01_C:InternalBeginOverlap(OverlapActor)
  if self.OverlapsPlayers and not self.OverlapsPlayers[OverlapActor] and OverlapActor.sceneCharacter and OverlapActor.sceneCharacter.isLocal == false then
    self.OverlapsPlayers[OverlapActor] = true
    OverlapActor:SetHiddenMask(true, UE.EPlayerForceHiddenType.TakePhoto)
  end
end

function BP_NPC_TakePhoto_Camera_01_C:ReceiveActorEndOverlap(OverlapActor)
  Base.ReceiveActorEndOverlap(self, OverlapActor)
  if self.OverlapsPlayers and self.OverlapsPlayers[OverlapActor] then
    self.OverlapsPlayers[OverlapActor] = nil
    if UE.UObject.IsValid(OverlapActor) then
      OverlapActor:SetHiddenMask(false, UE.EPlayerForceHiddenType.TakePhoto)
    end
  end
end

function BP_NPC_TakePhoto_Camera_01_C:OnResourceLoadFinish()
  Base.OnResourceLoadFinish(self)
  Log.Debug("BP_NPC_TakePhoto_Camera_01_C:OnResourceLoadFinish", self.SkeletalMesh)
  self.bCameraMeshLoadFinish = true
  self:ConditionChangeTexture()
end

function BP_NPC_TakePhoto_Camera_01_C:OnSyncCameraTextureChanged(ActorId)
  if ActorId == self._AvatarId then
    self:ConditionChangeTexture()
  end
end

function BP_NPC_TakePhoto_Camera_01_C:ConditionChangeTexture()
  if self.bCameraMeshLoadFinish then
    local Actor = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self._AvatarId)
    if Actor then
      Log.Debug("BP_NPC_TakePhoto_Camera_01_C:ConditionChangeTexture")
      if self.ReplaceRecycler then
        self.ReplaceRecycler()
      end
      self.ReplaceRecycler = TakePhotosUtils.ReplaceCameraTexture(self.SkeletalMesh, Actor)
    end
  end
end

return BP_NPC_TakePhoto_Camera_01_C

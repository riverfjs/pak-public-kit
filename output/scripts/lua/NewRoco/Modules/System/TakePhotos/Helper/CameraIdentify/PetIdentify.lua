local PetIdentify = Class("PetIdentify")

function PetIdentify:Ctor(Proxy)
  self.Identify = Proxy
  self.MaxiIdentifyDistance = TakePhotosEnum.TPGlobalNum("takephoto_identify_distance_max")
  self.AimIdentifyRadius = TakePhotosEnum.TPGlobalNum("takephoto_aim_radius")
  self.IdentifyBlackList = TakePhotosEnum.TPGlobalNumList("takephoto_pet_hide_blacklist", {})
  self.IdentifyObjectTypes = {
    UE.EObjectTypeQuery.Pawn,
    UE.EObjectTypeQuery.Character
  }
  self.HandBookStatusWidgetSwitcher = Proxy.Panel.WidgetSwitcher_0
  self.PetNameView = Proxy.Panel.Text_Name
  self.PetFormView = Proxy.Panel.PlaceName
  self.bIdentifySuccess = false
  self.PetOutlineActor = nil
end

function PetIdentify:OnOutlineClassLoaded(OutlineClass)
  if UE.UObject.IsValid(UE4Helper.GetCurrentWorld()) and UE.UObject.IsValid(OutlineClass) then
    self.PetOutlineActor = UE4Helper.GetCurrentWorld():SpawnActor(OutlineClass, UE.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    self.PetOutlineActor:SetOutlineEnabled(false)
    self.PetOutlineActor:SetActorEnableCollision(false)
  end
end

function PetIdentify:OnDestroy()
  if self.PetOutlineActor and UE.UObject.IsValid(self.PetOutlineActor) then
    self.PetOutlineActor:K2_DestroyActor()
  end
end

function PetIdentify:TryUploadPetFound()
  if self.HitPetBaseConf then
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdZoneAddPetRecordReq, self.HitPetBaseConf.id, _G.ProtoEnum.ZoneAddPetRecordReq.Reason.TAKE_PHOTO, self.HitNpcActorId)
  end
end

function PetIdentify:GetPetIdentifyInfo()
  if self.HitPetBaseConf then
    return {
      PetBaseId = self.HitPetBaseConf and self.HitPetBaseConf.id
    }
  end
end

function PetIdentify:OnShared(PhotoData)
  local PetIdentifyInfo = PhotoData:GetPetIdentifyInfo()
  if PetIdentifyInfo then
    Log.Debug("[TakePhoto] OnShared Pet", PetIdentifyInfo.PetBaseId)
    _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.ZoneAddPetRecordAndShareReq, PetIdentifyInfo.PetBaseId)
  end
end

function PetIdentify:TryStopPetIdentify()
  self.HitPetBaseConf = nil
  if self.PetOutlineActor then
    local bOutlineVisibleChange = self.PetOutlineActor:SetOutlineEnabled(false)
    if bOutlineVisibleChange then
      self:OnAimStop()
    end
  end
end

function PetIdentify:TryPetIdentify(Mode)
  local Player = self.Identify.Player
  local PlayerController = self.Identify.PlayerController
  local WinSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  local CameraLocation, ForwardVector = PlayerController:Abs_DeprojectScreenPositionToWorld(WinSize.X / 2, WinSize.Y / 2)
  local Scale = self.Identify:GetDistanceScale()
  local MaxiDistance = self.MaxiIdentifyDistance / Scale
  local Radius = self.AimIdentifyRadius
  local Ignores = UE4.TArray(UE4.AActor)
  if Mode.Mgr:Is1PMode() or Mode.Mgr:IsSelfieMode() then
    Ignores:Add(Player.viewObj)
    if Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      local Pet = Player.viewObj.BP_RideComponent.RidePet
      if Pet then
        Ignores:Add(Pet)
      end
    end
  end
  local HitResults, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceMultiForObjects(UE4Helper.GetCurrentWorld(), CameraLocation + ForwardVector * (Radius + 10), CameraLocation + ForwardVector * MaxiDistance, Radius, self.IdentifyObjectTypes, false, Ignores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 1)
  local HitActorView, HitPetBaseConf
  local NpcActorId = 0
  if bHit then
    for _, HitResult in tpairs(HitResults) do
      local Actor = HitResult.Actor
      if Actor then
        local SceneCharacter = Actor.sceneCharacter
        if SceneCharacter and SceneCharacter.IsPet and SceneCharacter:IsPet() then
          local BlackList = self.IdentifyBlackList
          local bInBlackList = false
          for _, Status in ipairs(BlackList) do
            if SceneCharacter:IsLogicStatus(Status) then
              bInBlackList = true
              break
            end
          end
          if not bInBlackList then
            Ignores:Add(Actor)
            HitActorView = Actor
            HitPetBaseConf = SceneCharacter:GetConfPetData()
            NpcActorId = SceneCharacter.serverData and SceneCharacter.serverData.base.actor_id
            break
          end
        end
        if Actor.Rider then
          local HitScenePlayerPet = Actor.Rider.BP_RideComponent.ScenePet
          if HitScenePlayerPet then
            Ignores:Add(Actor)
            Ignores:Add(Actor.Rider)
            HitPetBaseConf = HitScenePlayerPet.config
            HitActorView = Actor.Rider
            break
          end
        end
      end
    end
    if HitPetBaseConf then
      local TargetLocation = HitActorView:Abs_K2_GetActorLocation()
      local TargetHitResult, bTargetHit = UE.UKismetSystemLibrary.Abs_LineTraceSingle(UE4Helper.GetCurrentWorld(), TargetLocation, CameraLocation, UE.ETraceTypeQuery.Visibility, false, Ignores, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 1)
      if bTargetHit then
        HitActorView = nil
        HitPetBaseConf = nil
      end
    end
    if HitPetBaseConf then
      local bInHandbook = _G.NRCModuleManager:DoCmd(TakePhotosModuleCmd.IsPetInHandbook, HitPetBaseConf.id)
      if not bInHandbook then
        HitPetBaseConf = nil
      end
    end
    if HitActorView and not HitActorView.bHidden and HitPetBaseConf then
      self:UpdateOutlineEnabled(true, HitActorView)
      local HandbookStatus = NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, HitPetBaseConf.id)
      local Name = HitPetBaseConf.name or ""
      local Form = HitPetBaseConf.form or ""
      if "" ~= Name then
        self.PetNameView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.PetNameView:SetText(Name)
      else
        self.PetNameView:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
      if "" ~= Form then
        self.PetFormView:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.PetFormView:SetText(Form)
      else
        self.PetFormView:SetVisibility(UE.ESlateVisibility.Collapsed)
      end
      if HandbookStatus == ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
        self.HandBookStatusWidgetSwitcher:SetActiveWidgetIndex(1)
      elseif HandbookStatus == ProtoEnum.PetHandbookStatus.PHS_FOUND then
        self.HandBookStatusWidgetSwitcher:SetActiveWidgetIndex(2)
      else
        self.HandBookStatusWidgetSwitcher:SetActiveWidgetIndex(0)
      end
    else
      self:UpdateOutlineEnabled(false)
    end
  else
    self:UpdateOutlineEnabled(false)
  end
  self.HitPetBaseConf = HitPetBaseConf
  self.HitNpcActorId = NpcActorId
end

function PetIdentify:UpdateOutlineEnabled(bEnable, HitActorView)
  local bOutlineVisibleChange, bOutlineFadeout
  if bEnable then
    if self.PetOutlineActor then
      bOutlineVisibleChange, bOutlineFadeout = self.PetOutlineActor:SetOutlineEnabled(true, HitActorView)
    end
  elseif self.PetOutlineActor then
    bOutlineVisibleChange, bOutlineFadeout = self.PetOutlineActor:SetOutlineEnabled(false)
  end
  if bOutlineVisibleChange then
    if bOutlineFadeout then
      self:OnAimStop()
    else
      self:OnAimStart()
    end
  end
end

function PetIdentify:OnAimStart()
  local Panel = self.Identify.Panel
  Panel:StopAnimation(Panel.Aim)
  Panel:StopAnimation(Panel.Lost)
  Panel:PlayAnimation(Panel.Aim)
end

function PetIdentify:OnAimStop()
  local Panel = self.Identify.Panel
  Panel:StopAnimation(Panel.Aim)
  Panel:StopAnimation(Panel.Lost)
  Panel:PlayAnimation(Panel.Lost)
end

return PetIdentify

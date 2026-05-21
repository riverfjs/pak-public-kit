local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local NRCResourceManagerEnum = require("Core.Service.ResourceManager.NRCResourceManagerEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
require("Common.UE4Extension")
local UMG_PetImage3D_C = _G.NRCViewBase:Extend("UMG_PetImage3D_C")

function UMG_PetImage3D_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_PetImage3D_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetImage3D_C", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetImage3D_C", self, PetUIModuleEvent.OnPlayPetSkill, self.OnPlayPetSkill)
  self:RegisterEvent(self, PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, self.UpdatePetLocationInHatchingPanel)
  self:RegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBagDetails, self.OnShowOrHidePetModule)
  self:RegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBag, self.OnOpenNewPetBag)
  self:RegisterEvent(self, PetUIModuleEvent.OnUpdatePetImage3dData, self.OnUpdatePetImage3dData)
  self:RegisterEvent(self, PetUIModuleEvent.PetSkillTipsOpen, self.OnPetSkillTipsOpen)
end

function UMG_PetImage3D_C:OnActive(baseConf, ModuleName, ModelPath)
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(1)
  self._refActorIsolateWorld = nil
  self._evoTargetActor = nil
  self.bPetLoaded = false
  self._TypeFx = nil
  self.HavingActor = nil
  self.HavingEmptyLocation = {}
  self.HavingPropLocation = {}
  self.loadResRequest = {}
  self.PlayAnimationList = {}
  self.modelPath = ModelPath
  self._startLocation = nil
  self._rotateValueTemp = 0
  self._playerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  self._canRotate = false
  self.isResetRotate = false
  self.curAnimInfo = {isPlayAnim = false, curAniLength = 0}
  self._startActorLocation = nil
  self.skillClass = nil
  self.skillClassRef = nil
  self.evoSkillClass = nil
  self.SelectPetHideSkill = nil
  self.SelectPetShowSkill = nil
  self.OpenDetailsPlaySkill = nil
  self.CloseDetailsPlaySkill = nil
  self.OpenPetBagPlaySkill = nil
  self.ClosePetBagPlaySkill = nil
  self.OpenDetailsPetBagPlaySkill = nil
  self.CloseDetailsPetBagPlaySkill = nil
  self.IsPlayShowPetSkill = false
  self.IsDetailsMoveEnd = false
  self.AudioId = _G.NRCAudioManager:StartRegisterSpecialPet()
  self.AudioIdEvo = _G.NRCAudioManager:StartRegisterSpecialPet()
  self.CineCamera = nil
  self.CineSceneComponent = nil
  self.PetLevelSequence = nil
  self.StartTime = 0
  self.EndTime = 0.7
  self.PetRotationZero = false
  self.PetRotation_Z = 57.295734
  self.PetRotationTest_Z = 57.295734
  self.PetRotationAngle = nil
  self.IsClockwiseRotation = false
  self.OpenTwoPanelLevelSequence = nil
  self.CloseTwoPanelLevelSequence = nil
  self.OpenEstablishContractLevelSequence = nil
  self.CloseEstablishContractLevelSequence = nil
  self.SkeletalMesh = nil
  self.ModuleName = ModuleName
  if not self.module then
    self.module = NRCModuleManager:GetModule("PetUIModule")
  elseif self.module.moduleName == "ShareUIModule" then
    self.module = NRCModuleManager:GetModule("PetUIModule")
  end
  self:InitCineCameraActor()
  local CameraActor = self.PetWorldView:getActorByName("MainCamera")
  self.PetWorldView:SetCameraActor(CameraActor)
  self._moveCamera = false
  self._moveCameraTime = 0
  self._moveCameraDeltaTime = 0
  self._moveCameraTarget = nil
  self._moveOldPos = nil
  self.bSetPathEvo = false
  self.bMoving = false
  self.EvoBP = nil
  self.EvoJinjieBP = nil
  self.EnterSequence = nil
  self.LoopSequence = nil
  self.LoopSequenceRef = nil
  self.QuitSequence = nil
  self.skillCamera = nil
  self.skillCameraMesh = nil
  self.MainCameraActor = self.PetWorldView:getActorByName("MainCamera")
  self.MainCameraPosActor = self.PetWorldView:getActorByName("CameraPosActor")
  if UE.UObject.IsValid(self.MainCameraActor) then
    self.MainCameraTransfrom = self.MainCameraActor.RootComponent:GetRelativeTransform()
  end
  self.EvoPetLocation = nil
  self.evoPetData = nil
  self.evoPetDataInfo = nil
  self.startActorRotation = nil
  self.bEvoing = false
  self.IsOpenEvoPanel = false
  self.bPlayingEggCrackSkill = false
  self.isPlayEggEffect = false
  self.isEgg = false
  self.eggModuleScale = nil
  self.IsPlayingAnimationList = false
  self.IsPlayTwoPanelSequence = false
  self.PetLocation = UE4.FVector(0, 0, 0)
  self.ScaleInfo = nil
  self.PetBaseConf = nil
  self.curBlackAnim = nil
  self.OldModelFxType = nil
  self.IsGradient = false
  self.BgDelayStartTime = 0
  self.BgDelayEndTime = 0.4
  self.BgStartTime = 1
  self.BgEndTime = 0
  self.MaterialInstance = nil
  self.MaterialInstanceNew = nil
  self.MaterialInstanceNewBottom = nil
  self.CurrenSkill = nil
  self:LoadSelectPetSkill()
  self.eggSwitchSkillClass = nil
  self:LoadEggSwitchAssect()
  self.EvoFx1 = nil
  self.EvoFx2 = nil
  self.BgMeshComp = nil
  self.EvoSkillAnim01 = nil
  self.startLoader = nil
  self.petConf = nil
  self.bOnClick = false
  self.randomAnimList = {
    "Alert",
    "Happy",
    "Fear",
    "Relax",
    "Shock",
    "Sad"
  }
  self.maxAnimListIdleTime = 0
  self.IsOnActive = true
  if not self.LoadModel and self.modelPath then
    self.PetBaseConf = baseConf
    self:SetBagColourByUnitType()
  end
  self.PetShareData = nil
  self.shareVideoEndCb = nil
  self.PetModeDataCache = nil
  self.DeltaRot = nil
  self.IsCanSharePet = false
  self.IsPlayShareG6 = false
  self.CurrenSkillName = nil
  self.IsOpenPetBag = false
  self.IsHideModule = false
  self.OpenPetBagOffest = 25
  self.IsPlayOpenPetBagG6 = false
  if true == _G.GlobalConfig.bShowPetViewingGM then
    self.GM:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.GM:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RegisterEvent(self, PetUIModuleEvent.AttributePanelRefresh, self.RefreshAttributeInfo)
end

function UMG_PetImage3D_C:OnEdit1Changed(text)
  self.Edit1Num = tonumber(text)
end

function UMG_PetImage3D_C:OnEdit2Changed(text)
  self.Edit2Num = tonumber(text)
end

function UMG_PetImage3D_C:OnEdit3Changed(text)
  self.Edit3Num = tonumber(text)
end

function UMG_PetImage3D_C:OnEdit4Changed(text)
  self.Edit4Num = tonumber(text)
end

function UMG_PetImage3D_C:InitCineCameraActor()
  local CineCameraActor = self.PetWorldView:getActorByName("CineCamera_1")
  self.CineCamera = CineCameraActor
  if CineCameraActor then
    self.CineSceneComponent = CineCameraActor:GetComponentByClass(UE4.UCineCameraComponent)
  end
  local PetLevelSequence = self.PetWorldView:getActorByName("LevelSequence")
  self.PetLevelSequence = PetLevelSequence
  if self.module then
    local OpenLevelSequence = "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenTwoPanel.OpenTwoPanel'"
    self.OpenTwoPanelLevelSequence = nil
    if self.OpenTwoPanelLevelSequence == nil then
      self:LoadPanelRes(OpenLevelSequence, 255, function(caller, resRequest, asset)
        self.OpenTwoPanelLevelSequence = asset
      end, nil, nil)
    end
    local CloseLevelSequence = "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/CloseTwoPanel.CloseTwoPanel'"
    self.CloseTwoPanelLevelSequence = nil
    if nil == self.CloseTwoPanelLevelSequence then
      self:LoadPanelRes(CloseLevelSequence, 255, function(caller, resRequest, asset)
        self.CloseTwoPanelLevelSequence = asset
      end, nil, nil)
    end
    local OpenEstablishContractLevelSequencePath = "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenTwoPanel_EstablishContract.OpenTwoPanel_EstablishContract'"
    self.OpenEstablishContractLevelSequence = nil
    if nil == self.OpenEstablishContractLevelSequence then
      self:LoadPanelRes(OpenEstablishContractLevelSequencePath, 255, function(caller, resRequest, asset)
        self.OpenEstablishContractLevelSequence = asset
      end, nil, nil)
    end
    local CloseEstablishContractLevelSequencePath = "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/CloseTwoPanel_EstablishContract.CloseTwoPanel_EstablishContract'"
    self.CloseEstablishContractLevelSequence = nil
    if nil == self.CloseEstablishContractLevelSequence then
      self:LoadPanelRes(CloseEstablishContractLevelSequencePath, 255, function(caller, resRequest, asset)
        self.CloseEstablishContractLevelSequence = asset
      end, nil, nil)
    end
  else
    Log.Error("UMG_PetImage3D_C:InitCineCameraActor self.module is nil")
  end
  self:BindingSequenceCamera()
end

function UMG_PetImage3D_C:OnDeactive()
  self:CancelDelay()
  if self.loadResRequest then
    for key, request in pairs(self.loadResRequest) do
      NRCResourceManager:UnLoadRes(request)
      self.loadResRequest[key] = nil
    end
  end
  self:StopEvoSkill()
  self:StopPetAudio()
  self:UnRegisterEvent(self, PetUIModuleEvent.AttributePanelRefresh)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBagDetails)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBag)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnUpdatePetImage3dData)
end

function UMG_PetImage3D_C:LoadPetImageRes(assetPath, cacheTime, name)
  local requset = NRCResourceManager:LoadResAsync(self, assetPath, -1, cacheTime or 10, function(caller, resRequest, asset)
    name = asset
  end, nil, nil)
  table.insert(self.loadResRequest, requset)
end

function UMG_PetImage3D_C:OnPlayCameraBoostSequence(asset)
end

function UMG_PetImage3D_C:PlayCameraRegressionSequence(PetAttributeVisibleState)
end

function UMG_PetImage3D_C:PlayEnterEvoSequence(sequence, bEnter)
  if self.PetLevelSequence then
    self.PetLevelSequence:SetSequence(sequence)
    if bEnter then
      self.PetLevelSequence.SequencePlayer:Play()
      local request1 = NRCResourceManager:LoadResAsync(self, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenDetailsLevelSequence0_2_Jh_Loop.OpenDetailsLevelSequence0_2_Jh_Loop'", -1, 10, function(caller, resRequest, asset)
        self.LoopSequence = asset
        self.LoopSequenceRef = asset and UnLua.Ref(asset)
        self.PetLevelSequence.SequencePlayer.OnFinished:Add(self, self.PlayEvoLoopSequence)
      end, nil, nil)
    else
      self.PetLevelSequence.SequencePlayer:PlayReverse()
    end
  end
end

function UMG_PetImage3D_C:PlayEvoLoopSequence()
  if self.PetLevelSequence then
    self.PetLevelSequence:SetSequence(self.LoopSequence)
    self.PetLevelSequence.SequencePlayer:PlayLooping(-1)
  end
end

function UMG_PetImage3D_C:OnTick(InDeltaTime)
  if self.skillCamera and (self.bEvoing or self.isPlayEggEffect) then
    if UE.UObject.IsValid(self.skillCamera) then
      self.skillCamVec = self.skillCamera:Abs_GetTransform()
    end
    if UE.UObject.IsValid(self.MainCameraActor) then
      self.MainCameraActor:Abs_K2_SetActorTransform_WithoutHit(self.skillCamVec)
    end
  end
  if self.bPetLoaded == false then
    return
  end
  if self.isResetRotate and self._refActorIsolateWorld then
    local offsetRot = InDeltaTime * 360
    local tarRotation = self.petDstRotateDir or 0
    local curRot = self._refActorIsolateWorld:K2_GetActorRotation()
    local angle = UE4.LuaMathUtils.FixedTurn(curRot.Yaw, tarRotation, offsetRot)
    if UE4.UKismetMathLibrary.NearlyEqual_FloatFloat(angle, tarRotation) then
      self.isResetRotate = false
    end
    curRot.Yaw = angle
    self._refActorIsolateWorld:K2_SetActorRotation(curRot, false)
  end
  if self._moveCamera then
    self._moveCameraDeltaTime = self._moveCameraDeltaTime + InDeltaTime
    if self._moveCameraDeltaTime <= self._moveCameraTime then
      local coefficient = self._moveCameraDeltaTime / self._moveCameraTime
      local target = UE4.FVector(self._moveCameraTarget.x * coefficient, self._moveCameraTarget.y * coefficient, self._moveCameraTarget.z * coefficient)
      self.CineCamera:K2_SetActorLocation(self._moveOldPos + target)
    else
      self._moveCamera = false
      self._moveCameraDeltaTime = 0
      self._moveCameraTime = 0
    end
  end
  if not (self.bEvoing or self.IsPlayShowPetSkill or self.IsOpenEvoPanel) or self.isEgg then
    if false == self.IsPlayingAnimationList then
      if self.isEgg and self.isPlayEggEffect == false then
        self:PlayEggAnim(InDeltaTime)
      elseif self.curAnimInfo.isPlayAnim then
        self.curAnimInfo.curAniLength = self.curAnimInfo.curAniLength - InDeltaTime
        if self.curAnimInfo.curAniLength <= 0 then
          self.curAnimInfo.isPlayAnim = false
          self.maxAnimListIdleTime = math.random(5, 10)
        end
      elseif self.randomAnimList then
        local randomAnimList = #self.randomAnimList
        if randomAnimList > 0 then
          self.curAnimListTime = self.curAnimListTime or 0 + InDeltaTime
          if self.curAnimListTime >= self.maxAnimListIdleTime then
            self.curAnimListTime = 0
            local aniName = self:PetAnimRemove()
            self:PlayAnimByName(aniName, 1)
          end
        end
      end
    else
      self:OnTickListAnimation(InDeltaTime)
    end
  end
  if self.PetRotationZero then
    self.StartTime = self.StartTime + InDeltaTime
    local curRot = self._refActorIsolateWorld:K2_GetActorRotation()
    local toRotator = UE4.FRotator()
    if not self.IsClockwiseRotation then
      if curRot.Yaw < 0 then
        curRot.Yaw = curRot.Yaw + 360
      end
      if self.PetRotationTest_Z < 0 then
        self.PetRotationTest_Z = self.PetRotationTest_Z + 360
      end
      if curRot.Yaw < self.PetRotationTest_Z and math.abs(self.PetRotationTest_Z - curRot.Yaw) >= 0.01 then
        curRot.Yaw = curRot.Yaw + 360
      end
    elseif curRot.Yaw > self.PetRotationTest_Z and math.abs(curRot.Yaw - self.PetRotationTest_Z) >= 0.01 then
      curRot.Yaw = curRot.Yaw - 360
    end
    toRotator.Yaw = self.PetRotation_Z
    curRot.Yaw = self:Lerp(curRot, toRotator, self.StartTime * self.EndTime / (self.PetRotationAngle / 360))
    self._refActorIsolateWorld:K2_SetActorRotation(curRot, false)
    if math.abs(curRot.Yaw - self.PetRotation_Z) <= 0.01 then
      curRot.Yaw = self.PetRotation_Z
      self.PetRotationTest_Z = self.PetRotation_Z
      self._refActorIsolateWorld:K2_SetActorRotation(curRot, false)
      self.PetRotationZero = false
      self.StartTime = 0
      self._canRotate = true
    end
  end
  if self.IsGradient then
    if not self.BgDelayStartTime then
      self.BgDelayStartTime = 0
    end
    self.BgDelayStartTime = self.BgDelayStartTime + InDeltaTime
    if self.BgDelayStartTime and self.BgDelayStartTime >= self.BgDelayEndTime then
      self.BgStartTime = self.BgStartTime - InDeltaTime * 3
      local ParameterInfo = UE4.FMaterialParameterInfo()
      ParameterInfo.Name = "Opacity"
      ParameterInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
      ParameterInfo.Index = 0
      local MaterialInstanceDynamic = self.MaterialInstanceNew.AdditionalMaterials:Get(1)
      if MaterialInstanceDynamic and UE4.UObject.IsValid(MaterialInstanceDynamic) then
        if MaterialInstanceDynamic.SetScalarParameterValueByInfo then
          MaterialInstanceDynamic:SetScalarParameterValueByInfo(ParameterInfo, self.BgStartTime)
        end
        if self.BgStartTime <= self.BgEndTime then
          self.BgStartTime = 1
          self.BgDelayStartTime = 0
          self.IsGradient = false
          self.MaterialInstance = self.MaterialInstanceNewBottom
          self.MaterialInstance_Ref = self.MaterialInstanceNewBottom_Ref
          if MaterialInstanceDynamic.SetScalarParameterValueByInfo then
            MaterialInstanceDynamic:SetScalarParameterValueByInfo(ParameterInfo, 0)
          end
          self.MaterialInstanceNew.AdditionalMaterials:Clear()
          UE4.UNRCStatics.MarkRenderStateDirty(self.BgMeshComp)
        end
      end
    end
  end
end

function UMG_PetImage3D_C:PetAnimRemove()
  local RandomIndex = math.random(#self.randomAnimList)
  local aniName = self.randomAnimList[RandomIndex]
  table.remove(self.randomAnimList, RandomIndex)
  if 0 == #self.randomAnimList then
    self.randomAnimList = {
      "Alert",
      "Happy",
      "Fear",
      "Relax",
      "Shock",
      "Sad"
    }
  end
  return aniName
end

function UMG_PetImage3D_C:PlayEggAnim(InDeltaTime)
  if self.curAnimInfo.isPlayAnim then
    self.curAnimInfo.curAniLength = self.curAnimInfo.curAniLength - InDeltaTime
    if self.curAnimInfo.curAniLength <= 0 then
      self.curAnimInfo.isPlayAnim = false
      self:OnAnimFinish(self.curAnimInfo.curAniName)
    end
  elseif self.animList then
    local animCount = #self.animList
    if animCount > 0 then
      self.curAnimListTime = self.curAnimListTime + InDeltaTime
      if self.curAnimListTime >= self.maxAnimListIdleTime then
        self.curAnimListTime = 0
        local aniName = self.animList[self.curAnimListIndex]
        self:PlayAnimByName(aniName, 1)
        self.curAnimListIndex = self.curAnimListIndex + 1
        if animCount < self.curAnimListIndex then
          self.curAnimListIndex = 1
        end
      end
    end
  end
end

function UMG_PetImage3D_C:Lerp(fromRotator, toRotator, percent)
  percent = math.clamp(percent, 0, 1)
  local Yaw = fromRotator.Yaw * (1 - percent) + toRotator.Yaw * percent
  return Yaw
end

function UMG_PetImage3D_C:OnAnimFinish(_aniName)
  self:PlayAnimByName("Idle", -1)
end

function UMG_PetImage3D_C:HandleTouchStart(position)
  if self.PetRotationZero then
    return
  end
  self._canRotate = true
  self._rotateValueTemp = 0
  self._startLocation = nil
end

function UMG_PetImage3D_C:OnRocoTouchMoveHandler(touchIndex, position)
  if self._canRotate == true then
    if self.bPlayingEggCrackSkill then
      return
    end
    if self.isPlayEggEffect then
      return
    end
    if self.IsOpenEvoPanel then
      return
    end
    if self.IsPlayShowPetSkill and not self.isEgg then
      return
    end
    self.bMoving = true
    local mouseLocation = position
    local deltaLocationX = 0
    if self._startLocation then
      deltaLocationX = (mouseLocation.X - self._startLocation.X) * 0.2
    else
      self._startLocation = UE4.FVector2D(position.X, 0)
      return
    end
    if 0 == deltaLocationX then
      return
    end
    self.DeltaRot = UE4.FRotator(0, -deltaLocationX, 0)
    self._rotateValueTemp = self._rotateValueTemp + math.abs(deltaLocationX)
    self.isResetRotate = false
    if UE.UObject.IsValid(self.SkeletalMesh) and not self.isPlayEggEffect then
      self.SkeletalMesh:K2_AddWorldRotation(self.DeltaRot, false, nil, false)
    end
    self._startLocation = UE4.FVector2D(position.X, 0)
  end
end

function UMG_PetImage3D_C:OnRocoTouchEndHandler(touchIndex)
  if self._canRotate == true then
    if self.bPlayingEggCrackSkill then
      return
    end
    if self.isPlayEggEffect == false and self._rotateValueTemp and self._rotateValueTemp < 1 then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnClickPetImage3d)
    end
    if self.isPlayEggEffect then
      return
    end
    self.bMoving = false
    if self.curAnimInfo and self.curAnimInfo.isPlayAnim then
      return
    end
    if self.IsOpenEvoPanel then
      return
    end
    if self.IsPlayShowPetSkill and not self.isEgg then
      return
    end
    if self.isPlayEggEffect == false and self._rotateValueTemp and self.randomAnimList and self._rotateValueTemp < 1 then
      local animCount = #self.randomAnimList
      if animCount > 0 then
        self.curAnimListTime = 0
        local aniName = self:PetAnimRemove()
        if self.isEgg then
          UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002029, "UMG_PetMiddlePanel_C:SetEggAnimList")
        end
        self:PlayAnimByName(aniName, 1)
      end
    end
    self._canRotate = false
    self._rotateValueTemp = 0
  end
end

function UMG_PetImage3D_C:SetPetActorRotation(deltaRotation)
  if self._refActorIsolateWorld then
    self._refActorIsolateWorld:K2_AddActorWorldRotation(deltaRotation)
  end
end

function UMG_PetImage3D_C:GetCameraActor()
  local cameraActor = self.PetWorldView:getActorByName("CWLP_SceneCapture2D")
  if cameraActor then
    return cameraActor
  else
    return nil
  end
end

function UMG_PetImage3D_C:LoadSelectSkill()
  local requset = NRCResourceManager:LoadResAsync(self, "/Game/ArtRes/Effects/G6Skill/UI/G6_UI_Petview_01.G6_UI_Petview_01_C", -1, 10, function(caller, resRequest, asset)
    self.skillClass = asset
    self.skillClassRef = asset and UnLua.Ref(asset)
    self:PlaySelectSkill()
  end, nil, nil)
  table.insert(self.loadResRequest, requset)
end

function UMG_PetImage3D_C:PlaySelectSkill()
  local Caster = self._refActorIsolateWorld
  if self.skillClass and Caster then
    local skillObj = Caster.RocoSkill:FindOrAddSkillObj(self.skillClass)
    skillObj:SetCaster(Caster)
    skillObj:SetPassive(true)
    Caster.RocoSkill:PlaySkill(skillObj)
  end
  local CameraActor = self.PetWorldView:getActorByName("MainCamera")
  self.PetWorldView:SetCameraActor(CameraActor)
end

function UMG_PetImage3D_C:LoadPrepareEvoSkill1()
  self:LoadPanelRes("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Evolution/G6_Evolution_UI_FX01.G6_Evolution_UI_FX01_C'", 255, self.PlayPrepareEvoSkill1, nil, nil)
end

function UMG_PetImage3D_C:PlayPrepareEvoSkill1(resRequest, asset)
  local Caster = self._refActorIsolateWorld
  if asset and Caster and UE4.UObject.IsValid(Caster) then
    local skillComponent = Caster.RocoSkill
    if skillComponent and UE4.UObject.IsValid(skillComponent) then
      local skillObj = skillComponent:FindOrAddSkillObj(asset)
      if skillObj then
        skillObj:SetCaster(Caster)
        skillObj:SetPassive(false)
        self:StopEvoSkill()
        self.EvoFx1 = skillObj:GetBlackboard():GetValueAsObject("Fx1")
        self.EvoFx2 = skillObj:GetBlackboard():GetValueAsObject("Fx2")
        Caster.RocoSkill:PlaySkill(skillObj)
      end
    end
  end
end

function UMG_PetImage3D_C:LoadPrepareEvoSkill2()
  self:LoadPanelRes("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Evolution/G6_Evolution_UI_OutFx.G6_Evolution_UI_OutFx_C'", 255, self.PlayPrepareEvoSkill2, nil, nil)
  self:LoadPanelRes("SkillBlueprint'/Game/ArtRes/Effects/G6Skill/Evolution/G6_Evolution_Anim01.G6_Evolution_Anim01_C'", 255, self.SetEvoSkillAnim01, nil, nil)
end

function UMG_PetImage3D_C:PlayPrepareEvoSkill2(resRequest, asset)
  local Caster = self._refActorIsolateWorld
  if Caster and UE4.UObject.IsValid(Caster) and asset and Caster then
    local skillObj = Caster.RocoSkill:FindOrAddSkillObj(asset)
    skillObj:SetCaster(Caster)
    skillObj:SetPassive(false)
    self:StopEvoSkill()
    skillObj:RegisterEventCallback("ShowWhiteUI", self, self.ShowWhiteUI)
    skillObj:RegisterEventCallback("End", self, self.LoadEvoSkill)
    Caster.RocoSkill:LoadAndPlaySkill(skillObj)
  end
end

function UMG_PetImage3D_C:ShowWhiteUI()
  self.EvoWhiteScreen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local bkg = self.EvoWhiteScreen.dianji
  if bkg then
    bkg:SetRenderOpacity(1)
  end
  self:ShowRealBagColour()
end

function UMG_PetImage3D_C:ShowRealBagColour()
  if self.eggData and self.eggData.random_egg_conf then
    local eggConf = _G.DataConfigManager:GetPetRandomEggConf(self.eggData.random_egg_conf)
    if eggConf and eggConf.known_unit_type then
      self:SetBagColourByUnitType(true)
    end
  end
end

function UMG_PetImage3D_C:HideWhiteUI()
  self.EvoWhiteScreen:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetImage3D_C:PlayWhiteUIAnim()
  self.EvoWhiteScreen:PlayAnimation(self.EvoWhiteScreen.Anim)
end

function UMG_PetImage3D_C:SetEvoSkillAnim01(resRequest, asset)
  self.EvoSkillAnim01 = asset
end

function UMG_PetImage3D_C:StopEvoSkill()
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) and self._refActorIsolateWorld.RocoSkill then
    self._refActorIsolateWorld.RocoSkill:StopCurrentSkill()
  end
  if self.EvoFx1 then
    self.EvoFx1:K2_DestroyActor()
    self.EvoFx1 = nil
  end
  if self.EvoFx2 then
    self.EvoFx2:K2_DestroyActor()
    self.EvoFx2 = nil
  end
end

function UMG_PetImage3D_C:LoadEvoSkill()
  if self.EvoSkillAnim01 then
    self:PlayEvoSkill(nil, self.EvoSkillAnim01)
  end
end

function UMG_PetImage3D_C:LoadSelectPetSkill()
  if self and self.module then
    self.SelectPetShowSkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchPetShow_UI.G6_SwitchPetShow_UI_C'"
    self.OpenDetailsPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenPetInfo_UI.G6_OpenPetInfo_UI_C'"
    self.CloseDetailsPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_ClosePetInfo_UI.G6_ClosePetInfo_UI_C'"
    self.OpenPetBagPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenPetBag_UI.G6_OpenPetBag_UI_C'"
    self.ClosePetBagPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_ClosePetBag_UI.G6_ClosePetBag_UI_C'"
    self.OpenDetailsPetBagPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_OpenDetailsPetBag_UI.G6_OpenDetailsPetBag_UI_C'"
    self.CloseDetailsPetBagPlaySkillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_CloseDetailsPetBag_UI.G6_CloseDetailsPetBag_UI_C'"
  end
end

function UMG_PetImage3D_C:OnPlayPetSkill(SkillPath)
  self:PlayPetSkillAsync(nil, SkillPath, nil)
end

function UMG_PetImage3D_C:PlayPetSkillAsync(Skill, SkillPath, bOnClick)
  if nil ~= Skill then
    local IsDispersion = false
    if SkillPath == self.SelectPetShowSkillPath then
      IsDispersion = true
    end
    self:PlayPetSkill(Skill, bOnClick, IsDispersion)
    return
  end
  self:LoadPanelRes(SkillPath, 255, function(caller, resRequest, asset)
    local IsDispersion = false
    self.IsPlayOpenPetBagG6 = false
    if resRequest.assetPath == self.SelectPetShowSkillPath then
      self.SelectPetShowSkill = asset
      IsDispersion = true
    elseif resRequest.assetPath == self.OpenDetailsPlaySkillPath then
      self.OpenDetailsPlaySkill = asset
    elseif resRequest.assetPath == self.CloseDetailsPlaySkillPath then
      self.CloseDetailsPlaySkill = asset
    elseif resRequest.assetPath == self.OpenPetBagPlaySkillPath then
      self.OpenPetBagPlaySkill = asset
      self.IsPlayOpenPetBagG6 = true
    elseif resRequest.assetPath == self.ClosePetBagPlaySkillPath then
      self.ClosePetBagPlaySkill = asset
    elseif resRequest.assetPath == self.OpenDetailsPetBagPlaySkillPath then
      self.OpenDetailsPetBagPlaySkill = asset
    elseif resRequest.assetPath == self.CloseDetailsPetBagPlaySkillPath then
      self.CloseDetailsPetBagPlaySkill = asset
    end
    if asset then
      self:PlayPetSkill(asset, bOnClick, IsDispersion)
    else
      Log.Error("UMG_PetImage3D_C:PlayPetSkillAsync \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165...", resRequest.assetPath)
    end
    if IsDispersion then
      self:SetModelLocation()
    end
  end, nil, nil)
end

function UMG_PetImage3D_C:PlayPetSkill(Skill, bOnClick, IsDispersion)
  self:SetShowOrHidePet(self.IsHideModule)
  if self.IsPlayShareG6 then
    return
  end
  self.CurrenSkillName = Skill
  self.IsPlayShowPetSkill = true
  self.bOnClick = bOnClick
  if not self:IsCanPlayPetSkill() then
    return
  end
  local Caster = self._refActorIsolateWorld
  if Skill and Caster and UE4.UObject.IsValid(Caster) then
    local skillObj = Caster.RocoSkill:FindOrAddSkillObj(Skill)
    if skillObj then
      skillObj:SetCaster(Caster)
      skillObj:SetTargets({
        self._refActorIsolateWorld
      })
      skillObj:RegisterEventCallback("SkillEnd", self, self.OnSkillEnd)
      skillObj:RegisterEventCallback("MoveEnd", self, self.OnSkillMoveEnd)
      skillObj:RegisterEventCallback("BgSwitchStart", self, self.OnBgSwitchStart)
      skillObj:SetPassive(true)
      if IsDispersion then
        local PosCurveLastFrameValue = self:IsRemoteSkill(skillObj)
        self:SetPetStartPos(PosCurveLastFrameValue)
      end
      if self.CurrenSkill then
        Caster.RocoSkill:CancelSkill(self.CurrenSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
      Caster.RocoSkill:PlaySkill(skillObj)
      self.CurrenSkill = skillObj
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, true, bOnClick)
    else
      Log.Error("\230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165...")
    end
  end
end

function UMG_PetImage3D_C:SetPetStartPos(PosCurveLastFrameValue)
  if self._startActorLocation then
    if self.IsOpenDetails then
      self:DelayFrames(0.5, function()
        if UE.UObject.IsValid(self.SkeletalMesh) then
          local Y = _G.DataConfigManager:GetPetGlobalConfig("open_info_pet_angle").num
          self.SkeletalMesh:K2_SetWorldRotation(UE4.FRotator(0, Y, 0), false, nil, false)
        end
      end)
      local offset = 29
      if self.IsOpenPetBag then
        offset = -self.OpenPetBagOffest
      end
      self._startActorLocation.X = -PosCurveLastFrameValue - offset
      if self.NotChangeAnim then
        self._startActorLocation.X = -offset
      end
    else
      self:DelayFrames(0.5, function()
        if UE.UObject.IsValid(self.SkeletalMesh) then
          local Y = _G.DataConfigManager:GetPetGlobalConfig("switch_pet_angle").num
          self.SkeletalMesh:K2_SetWorldRotation(UE4.FRotator(0, Y, 0), false, nil, false)
        end
      end)
      local offset = 0
      if self.IsOpenPetBag then
        offset = -self.OpenPetBagOffest
      end
      self._startActorLocation.X = -PosCurveLastFrameValue - offset
      if self.NotChangeAnim then
        self._startActorLocation.X = 0 - offset
      end
    end
    Log.Debug(self._startActorLocation.X, 3, "UMG_PetImage3D_C:PlayPetSkill")
  end
end

function UMG_PetImage3D_C:IsRemoteSkill(SkillObject)
  if SkillObject then
    local actions = SkillObject:GetAllActions()
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action.m_Enable and action:IsA(UE4.URocoRootMotionMoveAction) then
        return action:GetPosCurveLastFrameValue()
      end
    end
  end
  return 0
end

function UMG_PetImage3D_C:IsCanPlayPetSkill()
  local IsOpenSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetSKill)
  local isOpenPetBag = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetBag)
  local IsPlayPetSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsPlayPetSkill)
  if IsOpenSkill or isOpenPetBag or IsPlayPetSkill then
    return false
  end
  return true
end

function UMG_PetImage3D_C:OnSkillEnd()
  if not self.IsCanSharePet and self.CurrenSkillName == self.SelectPetShowSkill then
    self.IsCanSharePet = true
  end
  self.IsPlayShowPetSkill = false
  self.curAnimInfo.curAniLength = self:GetAnimLengthByName("Idle")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false, self.bOnClick)
  if self.bOnClick then
    self.bOnClick = false
  end
end

function UMG_PetImage3D_C:OnSkillMoveEnd()
  if self.IsOpenDetails then
    self.IsDetailsMoveEnd = true
  end
end

function UMG_PetImage3D_C:OnBgSwitchStart()
end

function UMG_PetImage3D_C:PlayEvoSkill(resRequest, asset)
  self:SetBackgroundVisible(false)
  self._refActorIsolateWorld.Mesh.BoundsScale = 999
  self.EvoPetLocation = self._refActorIsolateWorld:Abs_GetTransform()
  self.startActorRotation = self._refActorIsolateWorld:K2_GetActorRotation()
  local Caster = self._refActorIsolateWorld
  local Target = self._evoTargetActor
  local Targets = {}
  if asset and Caster then
    local skillObj = Caster.RocoSkill:FindOrAddSkillObj(asset)
    if self.MainCameraPosActor then
      skillObj.Blackboard:SetValueAsObject("PetImage3D_MainCamera", self.MainCameraPosActor)
    end
    if self.MainCameraActor then
      skillObj.Blackboard:SetValueAsObject("PetImage3D_MainCamera1", self.MainCameraActor)
    end
    skillObj:SetCaster(Caster)
    Targets[1] = Target
    skillObj:SetTargets(Targets)
    skillObj:SetPassive(false)
    skillObj:RegisterEventCallback("OpenResultPanel", self, self.OpenResultPanel)
    skillObj:RegisterEventCallback("SetCamera1", self, self.SetSkillCamera1)
    skillObj:RegisterEventCallback("SetCamera2", self, self.SetSkillCamera2)
    skillObj:RegisterEventCallback("SetEvoTransform", self, self.SetEvoPetTransform)
    skillObj:RegisterEventCallback("End", self, self.OnEvoSkillEnd1)
    Caster.RocoSkill:LoadAndPlaySkill(skillObj)
    self:SetBagColourByUnitType()
  end
end

function UMG_PetImage3D_C:OnEvoSkillEnd1(Event, Skill)
  Skill.Blackboard:RemoveObjectValue("PetImage3D_MainCamera")
  Skill.Blackboard:RemoveObjectValue("PetImage3D_MainCamera1")
end

function UMG_PetImage3D_C:OpenResultPanel()
  local PetUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  if PetUIModule:HasPanel("PetEvoNewPanel") then
    local panel = PetUIModule:GetPanel("PetEvoNewPanel")
    if panel then
      self:OpenLight_2()
      panel:SetStepVisible(true)
    end
  end
end

function UMG_PetImage3D_C:SetSkillCamera1(Event, Skill)
  self.skillCamera = Skill:GetBlackboard():GetValueAsObject("camActor_0001")
  self.skillCameraMesh = Skill:GetBlackboard():GetValueAsObject("camActor_0001_SA")
  self:PlayWhiteUIAnim()
end

function UMG_PetImage3D_C:SetSkillCamera2(Event, Skill)
  self.skillCamera = nil
  self.skillCameraMesh = nil
  self.skillCamera = Skill:GetBlackboard():GetValueAsObject("camActor_0002")
  self.skillCameraMesh = Skill:GetBlackboard():GetValueAsObject("camActor_0002_SA")
end

function UMG_PetImage3D_C:UpdateEvoPetMesh(Actor)
  local mesh = Actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  if mesh then
    mesh.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    self.SkeletalMesh = mesh
    mesh:SetForcedLOD(1)
    mesh.bEnableUpdateRateOptimizations = false
    mesh.StreamingDistanceMultiplier = 999
    mesh.bNeverDistanceCull = true
    mesh.bForceMipStreaming = true
  end
end

function UMG_PetImage3D_C:SetBackgroundVisible(bVisible)
end

function UMG_PetImage3D_C:SetEvoPetTransform()
  if self._evoTargetActor == nil or not UE4.UObject.IsValid(self._evoTargetActor) then
    Log.Warning("evoTargetActor is nil")
    return
  end
  self:SetBackgroundVisible(true)
  self._evoTargetActor:SetActorHiddenInGame(false)
  if UE.UObject.IsValid(self.MainCameraActor) and self.MainCameraTransfrom then
    self.MainCameraActor.RootComponent:K2_SetRelativeTransform(self.MainCameraTransfrom, false, nil, false)
  end
  local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.evoPetDataInfo.base_conf_id)
  local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
  local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.uiPetData)
  modelScale = modelScale * heightModelScale * 1.0
  local halfHeight = self._evoTargetActor:GetHalfHeight() * modelScale
  local PetLocation = UE4.FVector(0, 0, 0)
  PetLocation.Z = PetLocation.Z + halfHeight
  if self._startActorLocation then
    self._startActorLocation.Z = PetLocation.Z
  end
  self._evoTargetActor:Abs_K2_SetActorLocation_WithoutHit(PetLocation)
  self._evoTargetActor:K2_SetActorRotation(self.startActorRotation, false)
  self:UpdateEvoPetMesh(self._evoTargetActor)
  self._evoTargetActor:SetIsPlayerModel(true)
  self._refActorIsolateWorld:SetIsPlayerModel(false)
  self:SetEvoModelOffSetInfo()
end

function UMG_PetImage3D_C:MoveCaster(Event, Skill)
  self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(0, 0, 0))
end

function UMG_PetImage3D_C:OnEvoSkillEnd(skillObj)
  if self._refActorIsolateWorld and self._evoTargetActor then
    self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    self._refActorIsolateWorld = nil
    self._refActorIsolateWorld = self._evoTargetActor
  end
end

function UMG_PetImage3D_C:SetHavingLocationByIsHasHaving(_IsHasHaving)
  if self.HavingActor then
    self.HavingActor:SetHavingLocation(_IsHasHaving)
  end
end

function UMG_PetImage3D_C:HavingModelSelect(_IsSelect, _Pos, _CurrentSelectIndex, _Time)
  if self.HavingActor then
    self.HavingActor:SelectHaving(_IsSelect, _Pos - 1, _CurrentSelectIndex, _Time)
  end
end

function UMG_PetImage3D_C:SetHavingColorInfo(_pos, _quality, _IsLerp)
  if self.HavingActor then
    self.HavingActor:SetHavingSColor(_pos, _quality, _IsLerp)
  end
end

function UMG_PetImage3D_C:OnHavingModelMove(_CurrentSelectIndex, _MoveTime)
  if self.HavingActor then
    self.HavingActor:HavingLocationMove(_CurrentSelectIndex, _MoveTime)
  end
end

function UMG_PetImage3D_C:GetHavingScreenPosition()
  if self.HavingActor then
    local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    local ProjMat = UE4.FMatrix()
    local TargetPosition = self.HavingActor:GetCurrentHavingLocation():Get(1)
    local ScreenHavingPosition = UE4.UKismetMathLibrary.Divide_Vector2DVector2D(UE4.UNRCStatics.Abs_ProjectWorldToScreenHidden(TargetPosition, viewportSize.X, viewportSize.Y, ProjMat), viewportSize)
    return ScreenHavingPosition
  end
end

function UMG_PetImage3D_C:BuildTypeFx(SkillDamType)
end

function UMG_PetImage3D_C:CreateDefaultPetData(PetBaseID)
  local Data = {}
  Data.base_conf_id = PetBaseID
  Data.mutation_type = _G.Enum.MutationDiffType.MDT_NONE
  Data.glass_info = nil
  return Data
end

function UMG_PetImage3D_C:UpdateDefaultPetModel3DShow(PetBaseID)
  if nil == PetBaseID then
    return
  end
  local PetBaseCfg = _G.DataConfigManager:GetPetbaseConf(PetBaseID)
  if PetBaseCfg then
    local ModelScale = PetBaseCfg.pet_ui_percentage and PetBaseCfg.pet_ui_percentage > 0 and PetBaseCfg.pet_ui_percentage or 1
    local ModelConf = _G.DataConfigManager:GetModelConf(PetBaseCfg.model_conf)
    if ModelConf then
      local PetData = self:CreateDefaultPetData(PetBaseID)
      self.PetBaseConf = PetBaseCfg
      self:SetPath(ModelConf.path, false, nil, PetData, false)
    end
  end
  self:SetAnimList({"Alert", "Relax"}, 2, {
    "Alert",
    "Becute",
    "Happy",
    "Fear",
    "Relax",
    "Shock",
    "Sad"
  })
end

function UMG_PetImage3D_C:SetPath(modelPath, _isEvolution, _evoMaterialColor, petData, NotChangeAnim)
  self.modelPath = modelPath
  self.bSetPathEvo = _isEvolution
  self.uiPetData = petData
  self.NotChangeAnim = NotChangeAnim
  self.IsCanSharePet = false
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseShareSelectBox)
  if not self.IsOnActive then
    return
  end
  self.LoadModel = true
  self.IsEmptyView = false
  self.AudioId = _G.NRCAudioManager:StartRegisterSpecialPet()
  self.AudioIdEvo = _G.NRCAudioManager:StartRegisterSpecialPet()
  local showOnlyActors
  do
    local shadowCapture = self.PetWorldView:getActorByName("CWLP_SceneCapture2D")
    if shadowCapture then
      local captureComponent = shadowCapture:GetComponentByClass(UE4.USceneCaptureComponent2D)
      showOnlyActors = captureComponent.ShowOnlyActors
    end
  end
  self.isResetRotate = false
  if self._refActorIsolateWorld then
    if showOnlyActors then
      showOnlyActors:Clear()
    end
    if UE4.UObject.IsValid(self._refActorIsolateWorld) then
      self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    end
    self._refActorIsolateWorld = nil
  end
  Log.Debug(modelPath, 6, "UMG_PetImage3D_C:SetPath")
  local isFirstLoadBg = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.IsFirstLoadBackground)
  if nil == isFirstLoadBg then
    isFirstLoadBg = true
  end
  Log.Debug(isFirstLoadBg, 6, "PetUIModuleCmd.IsFirstLoadBackground")
  if self.modelPathLoadReq then
    _G.NRCResourceManager:UnLoadRes(self.modelPathLoadReq)
    self.modelPathLoadReq = nil
  end
  if isFirstLoadBg then
    local modelClass = self.module:GetRes(modelPath, self.ModuleName)
    if modelClass then
      self:PetModelLoadSucceed(nil, modelClass)
    else
      self.modelPathLoadReq = self:LoadPanelRes(modelPath, 255, self.PetModelLoadSucceed, nil, nil)
    end
  else
    self.modelPathLoadReq = self:LoadPanelRes(modelPath, 255, self.PetModelLoadSucceed, nil, nil)
  end
end

function UMG_PetImage3D_C:SetEmptyView()
  Log.Debug("UMG_PetImage3D_C:SetEmptyView")
  self.IsEmptyView = true
  if self._refActorIsolateWorld then
    self._refActorIsolateWorld:SetActorHiddenInGame(true)
    _G.NRCAudioManager:StopAllForActor(self._refActorIsolateWorld)
  end
  if self.targetPetModel and UE4.UObject.IsValid(self.targetPetModel) then
    self.targetPetModel:SetActorHiddenInGame(true)
  end
  if self.AudioId then
    _G.NRCAudioManager:EndRegisterSpecialPet(self.AudioId)
  end
  if self.AudioIdEvo then
    _G.NRCAudioManager:EndRegisterSpecialPet(self.AudioIdEvo)
  end
  self:SetEmptyBackground()
end

function UMG_PetImage3D_C:SetEmptyBackground()
  Log.Debug("UMG_PetImage3D_C:SetEmptyBackground")
  local ModelFxType = _G.Enum.SkillDamType.SDT_GENERAL
  if self.OldModelFxType == ModelFxType then
    return
  end
  self.OldModelFxType = ModelFxType
  local Path = _G.DataConfigManager:GetSkillColorConf(ModelFxType).JL_background_colour
  self.Path_1 = _G.DataConfigManager:GetSkillColorConf(ModelFxType).JL_background_clear
  if Path then
    self:LoadPanelRes(Path, 255, self.OnLoadEmptyBackgroundColorSucc, self.OnLoadBackgroundClearFailed, nil)
  else
    self:OnLoadBackgroundClearFailed()
  end
end

function UMG_PetImage3D_C:PetModelLoadSucceed(resRequest, modelClass)
  if not modelClass then
    Log.ErrorFormat("UMG_PetImage3D_C:SetPath \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", resRequest or "")
    return
  end
  Log.Debug("UMG_PetImage3D_C:PetModelLoadSucceed")
  if UE4.UObject.IsValid(self.targetPetModel) then
    self.PetWorldView:DestroyActor(self.targetPetModel)
    self.targetPetModel = nil
  end
  if self._refActorIsolateWorld then
    self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    self._refActorIsolateWorld = nil
  end
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 1.5)
  if not self.PetLocation then
    self.PetLocation = UE4.FVector(0, 0, 0)
  end
  local fTransfom = UE4.FTransform(quat, self.PetLocation, UE4.FVector(1, 1, 1))
  self._refActorIsolateWorld = self.PetWorldView:SpawnActor(modelClass, fTransfom)
  if self.uiPetData then
    self._refActorIsolateWorld:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
    PetMutationUtils.PrepareMutationAssets(self._refActorIsolateWorld, self.uiPetData)
  end
  _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Show", self._refActorIsolateWorld)
  self._refActorIsolateWorld:SetIsPlayerModel(true)
  self.bPetLoaded = false
  self:StarEffectUnLoader()
  self._refActorIsolateWorld:InitOutSceneAsync(self, self.OnPetLoaded)
  self:SetBagColourByUnitType()
  if self.PetBaseConf then
    local _petBaseCfg = self.PetBaseConf
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    if self.uiPetData then
      local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.uiPetData)
      modelScale = modelScale * heightModelScale * 1.0
      self.ScaleInfo = modelScale
    end
    self:SetModelScale(modelScale)
    if _petBaseCfg.petpage_capsule_offset and next(_petBaseCfg.petpage_capsule_offset) then
      local offsetConf = _petBaseCfg.petpage_capsule_offset
      local modelOffset = UE4.FVector(offsetConf[1] or 0, offsetConf[2] or 0, offsetConf[3] or 0)
      self:SetModelOffset(modelOffset, modelScale)
    end
  end
end

function UMG_PetImage3D_C:OnPetLoaded(actor)
  if not self.PetWorldView then
    return
  end
  self:SetShowOrHidePet(true)
  Log.Debug("UMG_PetImage3D_C:OnPetLoaded")
  if self.IsEmptyView then
    Log.Debug("UMG_PetImage3D_C:OnPetLoaded, IsEmptyView = true, return")
    return
  end
  if actor.RibbonState then
    actor.RibbonState = UE4.ENPCRibbonState.Open
  end
  self.isPlayEggEffect = false
  self.bPetLoaded = true
  actor.IkOverride = false
  actor:SetSelfControlSignificance(true, UE.ESignificanceValue.Highest)
  _G.NRCAudioManager:RegisterSpecialPet(self.AudioId, actor)
  _G.NRCAudioManager:SetListenerToSelf(actor, "SpecialPet")
  local voice = self.uiPetData and self.uiPetData.voice or 0
  _G.NRCAudioManager:SetEmitterRTPC("Pet_Vo_Pitch", voice, actor)
  local SKMComponent = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent.bNRCUseFixedSkelBounds = false
  SKMComponent.bNRCAlwaysUpdateKinematicBonesToAnim = true
  SKMComponent.bEabledAuxiliaryAnimGraphThread = false
  local height = actor:GetHalfHeight()
  local PetLocation = UE4.FVector(0, 0, 0)
  if self.NotChangeAnim then
    PetLocation = UE4.FVector(0, 0, 0)
  end
  PetLocation.Z = PetLocation.Z + height
  Log.Debug(PetLocation, "UMG_PetImage3D_C:OnPetLoaded")
  actor:Abs_K2_SetActorLocation_WithoutHit(PetLocation)
  self:UpdateEvoPetMesh(actor)
  if self.PetBaseConf and self.uiPetData then
    PetMutationUtils.DoMutation(actor, self.uiPetData)
  elseif self.eggData then
    PetMutationUtils.DoPetEggMutation(actor, self.eggData)
  end
  self.idleAnimLen = self:GetAnimLengthByName("Idle")
  self.maxAnimListIdleTime = math.random(5, 10) * self.idleAnimLen
  if not self.evolutionTypeIcon then
    self:GetEvolutionTypeIcon()
  end
  if self.evolutionTypeIcon then
    self.evolutionTypeIcon:SetActorHiddenInGame(not self.bSetPathEvo)
  end
  if self.evolutionBgTex3 then
    self.evolutionBgTex3:SetActorHiddenInGame(not self.bSetPathEvo)
  end
  if self.evolutionBgAnim then
    self.evolutionBgAnim:SetActorHiddenInGame(not self.bSetPathEvo)
  end
  local showOnlyActors
  do
    local shadowCapture = self.PetWorldView:getActorByName("CWLP_SceneCapture2D")
    if shadowCapture then
      local captureComponent = shadowCapture:GetComponentByClass(UE4.USceneCaptureComponent2D)
      showOnlyActors = captureComponent.ShowOnlyActors
    end
  end
  if showOnlyActors then
    showOnlyActors:Add(actor)
  end
  if showOnlyActors and self._TypeFx then
    showOnlyActors:Add(self._TypeFx)
  end
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.UpdatePetModelAnimStatue, nil, true)
  local IsPlaySwitchPetShow = false
  UE4.UNRCStatics.SetCineCameraInfo(actor, self.CineCamera, self.CineSceneComponent)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false)
  if self.isEgg and self.eggModuleScale then
    self:SetModelScale(self.eggModuleScale, true)
    self:PlayEggSwitch()
  elseif self.PetShareData then
    self:SetPetModeByShareData(self.PetShareData)
    self:SetSharePhotoPetAnim(false)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self.NotChangeAnim then
    self.IsPlayShowPetSkill = false
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false)
  else
    self:PlayPetSkillAsync(self.SelectPetShowSkill, self.SelectPetShowSkillPath, true)
    IsPlaySwitchPetShow = true
  end
  self:SetModelLocation()
  self:SetAdjustPetParam(IsPlaySwitchPetShow)
end

function UMG_PetImage3D_C:SetBagColourByUnitType()
  if not self.PetWorldView then
    return
  end
  self.BackgroundPlate = self.PetWorldView:getActorByName("TestBg_2")
  local modelFxType = Enum.SkillDamType.SDT_NONE
  if self.BackgroundPlate and self.PetBaseConf then
    modelFxType = self.PetBaseConf.unit_type[1]
    if modelFxType < Enum.SkillDamType.SDT_COMMON then
      modelFxType = Enum.SkillDamType.SDT_COMMON
    end
  elseif self.eggPetGid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.eggPetGid)
    if petData then
      local petBaseID = petData.base_conf_id
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseID)
      if petBaseConf then
        modelFxType = petBaseConf.unit_type[1]
        if modelFxType < Enum.SkillDamType.SDT_COMMON then
          modelFxType = Enum.SkillDamType.SDT_COMMON
        end
      end
    end
  elseif self.eggData and self.eggData.random_egg_conf then
    modelFxType = Enum.SkillDamType.SDT_UNKNOW
    local eggConf = _G.DataConfigManager:GetPetRandomEggConf(self.eggData.random_egg_conf)
    if eggConf and eggConf.known_unit_type and self.eggData.skill_dam_type and self.eggData.skill_dam_type[1] then
      modelFxType = self.eggData.skill_dam_type[1]
      if modelFxType < Enum.SkillDamType.SDT_COMMON then
        modelFxType = Enum.SkillDamType.SDT_COMMON
      end
    end
  end
  if self.OldModelFxType == modelFxType then
    return
  end
  local isFirstLoadBg = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.IsFirstLoadBackground)
  if nil == isFirstLoadBg then
    isFirstLoadBg = true
  end
  local skillColorConf = _G.DataConfigManager:GetSkillColorConf(modelFxType)
  if not skillColorConf then
    Log.Debug("UMG_PetImage3D_C:SetBagColourByUnitType, skillColorConf is nil, return")
    return
  end
  local Path
  if skillColorConf then
    Path = skillColorConf.JL_background_colour
    self.Path_1 = skillColorConf.JL_background_clear
  end
  self.OldModelFxType = modelFxType
  local module = NRCModuleManager:GetModule("BattlePassModule")
  if module:HasPanel("BattlePassPetDetail") then
    self.mat_bj = self.module:GetRes(Path, self.ModuleName)
    local mat_bj1 = self.module:GetRes(self.Path_1, self.ModuleName)
    if self.mat_bj and mat_bj1 then
      self:OnLoadBackgroundClearSucc(nil, mat_bj1)
      return
    end
  end
  if Path then
    if isFirstLoadBg then
      self.mat_bj = self.module:GetRes(Path, self.ModuleName)
      local mat_bj1 = self.module:GetRes(self.Path_1, self.ModuleName)
      if self.mat_bj and mat_bj1 then
        self:OnLoadBackgroundClearSucc(nil, mat_bj1)
      else
        self:LoadPanelRes(Path, 255, self.OnLoadBackgroundColorSucc, self.OnLoadBackgroundClearFailed, nil)
      end
    else
      self:LoadPanelRes(Path, 255, self.OnLoadBackgroundColorSucc, self.OnLoadBackgroundClearFailed, nil)
    end
  else
    self:OnLoadBackgroundClearFailed()
  end
end

function UMG_PetImage3D_C:OnLoadBackgroundColorSucc(resRequest, mat_bj)
  self.mat_bj = mat_bj
  self:LoadPanelRes(self.Path_1, 255, self.OnLoadBackgroundClearSucc, self.OnLoadBackgroundClearFailed, nil)
end

function UMG_PetImage3D_C:OnLoadBackgroundClearSucc(resRequest, mat_bj_1)
  if mat_bj_1:IsA(UE4.UMaterialInstanceConstant) and self.BackgroundPlate then
    local MeshComponent = self.BackgroundPlate:GetComponentByClass(UE4.UStaticMeshComponent)
    self.BgMeshComp = MeshComponent
    if self.MaterialInstance then
      self.MaterialInstanceNewBottom = self.PetWorldView:CreateDynamicMaterialInstance(self.mat_bj, "")
      self.MaterialInstanceNewBottom_Ref = self.MaterialInstanceNewBottom and UnLua.Ref(self.MaterialInstanceNewBottom)
      self.MaterialInstanceNew = self.PetWorldView:CreateDynamicMaterialInstance(mat_bj_1, "")
      self.MaterialInstanceNew.AdditionalMaterials:Clear()
      self.MaterialInstanceNew.AdditionalMaterials:Add(self.MaterialInstance)
      self.IsGradient = true
      MeshComponent:SetMaterial(0, self.MaterialInstanceNew)
    else
      self.MaterialInstance = self.PetWorldView:CreateDynamicMaterialInstance(self.mat_bj, "")
      self.MaterialInstance_Ref = self.MaterialInstance and UnLua.Ref(self.MaterialInstance)
      self.MaterialInstance_1 = self.PetWorldView:CreateDynamicMaterialInstance(mat_bj_1, "")
      if self.MaterialInstance then
        self.MaterialInstance.AdditionalMaterials:Clear()
      end
      MeshComponent:SetMaterial(0, self.MaterialInstance_1)
    end
    UE4.UNRCStatics.MarkRenderStateDirty(self.BgMeshComp)
  else
    self:LogError("\230\179\168\230\132\143\239\188\140\229\138\160\232\189\189\232\181\132\230\186\144\231\188\186\229\176\145\232\181\132\230\186\144\229\144\141\229\173\151:", self.Path_1)
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsFirstLoadBackground, false)
  self.mat_bj = nil
  self.Path_1 = nil
end

function UMG_PetImage3D_C:OnLoadEmptyBackgroundColorSucc(resRequest, mat_bj)
  Log.Debug("UMG_PetImage3D_C:OnLoadEmptyBackgroundColorSucc mat_bj=[", mat_bj:GetFullName() or "", "]")
  if not self.IsEmptyView then
    return
  end
  self.mat_bj = mat_bj
  self:LoadPanelRes(self.Path_1, 255, self.OnLoadEmptyBackgroundClearSucc, self.OnLoadBackgroundClearFailed, nil)
end

function UMG_PetImage3D_C:OnLoadEmptyBackgroundClearSucc(resRequest, mat_bj_1)
  Log.Debug("UMG_PetImage3D_C:OnLoadEmptyBackgroundClearSucc mat_bj_1=[", mat_bj_1:GetFullName() or "", "]")
  if not self.IsEmptyView then
    return
  end
  self:OnLoadBackgroundClearSucc(resRequest, mat_bj_1)
end

function UMG_PetImage3D_C:OnLoadBackgroundClearFailed(resRequest, mat_bj_1)
  Log.Error("\231\178\190\231\129\181\232\131\140\230\153\175\229\138\160\232\189\189\229\164\177\232\180\165\228\186\134\239\188\140\228\189\134\230\152\175\232\191\152\230\152\175\229\133\129\232\174\184\230\137\147\229\188\128\231\149\140\233\157\162\239\188\140UMG_PetImage3D_C:OnLoadBackgroundClearFailed")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsFirstLoadBackground, false)
  self.mat_bj = nil
  self.Path_1 = nil
end

function UMG_PetImage3D_C:OnEvoPetLoaded(actor)
  actor.IkOverride = false
  actor:SetSelfControlSignificance(true, UE.ESignificanceValue.Highest)
  local height = actor:GetHalfHeight()
  actor:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(0, 0, 0))
  actor:SetActorHiddenInGame(true)
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  mesh:SetForcedLOD(1)
  mesh.bEnableUpdateRateOptimizations = false
  mesh.StreamingDistanceMultiplier = 999
  mesh.bNeverDistanceCull = true
  mesh.bForceMipStreaming = true
  _G.NRCAudioManager:RegisterSpecialPet(self.AudioIdEvo, actor)
  _G.NRCAudioManager:SetListenerToSelf(actor, "SpecialPet")
  local SKMComponent = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  SKMComponent.bNRCUseFixedSkelBounds = false
  SKMComponent.bNRCAlwaysUpdateKinematicBonesToAnim = true
  SKMComponent.bEabledAuxiliaryAnimGraphThread = false
  if self.evoPetDataInfo then
    local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.evoPetDataInfo.base_conf_id)
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.evoPetDataInfo)
    modelScale = modelScale * heightModelScale
    PetMutationUtils.DoMutation(actor, self.evoPetDataInfo)
    self:SetEvoModelScale(modelScale)
    if _petBaseCfg.petpage_capsule_offset and next(_petBaseCfg.petpage_capsule_offset) then
      local offsetConf = _petBaseCfg.petpage_capsule_offset
      local modelOffset = UE4.FVector(offsetConf[1] or 0, offsetConf[2] or 0, offsetConf[3] or 0)
    end
  else
    PetMutationUtils.DoMutation(actor, self.uiPetData)
  end
end

function UMG_PetImage3D_C:BindingSequenceCamera()
  if self.PetLevelSequence and self.PetLevelSequence.SequencePlayer and self.PetLevelSequence.SequencePlayer.Sequence then
    local BindingsKam = self.PetLevelSequence:FindNamedBindings("Camera")
    if BindingsKam:Length() > 0 then
      local CameraBinding = self.PetLevelSequence:FindNamedBinding("Camera")
      if CameraBinding then
        self.PetLevelSequence:SetBinding(CameraBinding, {
          self.CineCamera
        })
      end
    end
  else
    Log.Debug("\229\186\143\229\136\151\231\155\184\230\156\186\230\137\190\228\184\141\229\136\176")
  end
end

function UMG_PetImage3D_C:BinSequenceCamera()
  if self.PetLevelSequence and self.PetLevelSequence.SequencePlayer and self.PetLevelSequence.SequencePlayer.Sequence then
    local BindingsKam = self.PetLevelSequence:FindNamedBindings("Camera")
    if BindingsKam:Length() > 0 then
      local CameraBinding = self.PetLevelSequence:FindNamedBinding("Camera")
      if CameraBinding then
        self.PetLevelSequence:SetBinding(CameraBinding, {
          self.MainCameraActor
        })
      end
    end
  end
end

function UMG_PetImage3D_C:SetCameraPos(time, vector)
  if vector == self.CineCamera:K2_GetActorLocation() then
    return
  end
  if 0 == time then
    self.CineCamera:K2_SetActorLocation(vector)
    return
  end
  self._moveOldPos = self.CineCamera:K2_GetActorLocation()
  self._moveCamera = true
  self._moveCameraTime = time
  self._moveCameraTarget = vector - self.CineCamera:K2_GetActorLocation()
  self._moveCameraDeltaTime = 0
end

function UMG_PetImage3D_C:OpenDetailCameraLocation(_CameraTrackType, _PetAttributeVisibleState, _PetBagVisibleState)
  Log.Debug(_CameraTrackType, _PetAttributeVisibleState, _PetBagVisibleState, "UMG_PetImage3D_C:OpenDetailCameraLocation")
  local isHasNewPetBag = self.module:HasPanel("NewPetBag")
  if self.PetLevelSequence and not isHasNewPetBag then
    if self.IsPlayTwoPanelSequence == false and _PetAttributeVisibleState and _PetBagVisibleState then
      if self.OpenTwoPanelLevelSequence then
        self:PlayOpenTwoPanelLevelSequence()
      end
    elseif self.IsPlayTwoPanelSequence == true and self.CloseTwoPanelLevelSequence then
      self:PlayCloseTwoPanelLevelSequence()
    end
  end
  if 0 == _CameraTrackType then
    self.IsOpenDetails = false
    if false == self.IsOpenPetBag then
      self:PlayPetSkillAsync(self.CloseDetailsPlaySkill, self.CloseDetailsPlaySkillPath, true)
    end
  elseif 1 == _CameraTrackType then
    if isHasNewPetBag then
      self.IsOpenPetBag = true
    end
    if self.IsOpenPetBag then
      self.IsOpenDetails = true
      return
    end
    if self._startActorLocation then
      self._startActorLocation.X = 0
    end
    self:SetModelLocation()
    self.IsOpenDetails = true
    if self.curAnimInfo then
      self.curAnimInfo.isPlayAnim = true
    else
      self.curAnimInfo = {isPlayAnim = true, curAniLength = 0}
    end
    self.IsDetailsMoveEnd = false
    self:PlayPetSkillAsync(self.OpenDetailsPlaySkill, self.OpenDetailsPlaySkillPath, true)
  elseif 2 == _CameraTrackType then
    self:PlayOpenTwoPanelLevelSequence()
    self.IsOpenPetBag = true
    if self.IsOpenDetails then
      self:PlayPetSkillAsync(self.OpenDetailsPetBagPlaySkill, self.OpenDetailsPetBagPlaySkillPath, true)
    else
      self:PlayPetSkillAsync(self.OpenPetBagPlaySkill, self.OpenPetBagPlaySkillPath, true)
    end
  elseif 3 == _CameraTrackType then
    self:PlayCloseTwoPanelLevelSequence()
    self.IsOpenPetBag = false
    if self.IsOpenDetails then
      self:PlayPetSkillAsync(self.CloseDetailsPetBagPlaySkill, self.CloseDetailsPetBagPlaySkillPath, true)
    else
      self:PlayPetSkillAsync(self.ClosePetBagPlaySkill, self.ClosePetBagPlaySkillPath, true)
    end
  end
end

function UMG_PetImage3D_C:PlayOpenTwoPanelLevelSequence()
  if self.IsPlayTwoPanelSequence then
    return
  end
  self.PetLevelSequence:SetSequence(self.OpenTwoPanelLevelSequence)
  self:BinSequenceCamera()
  self.PetLevelSequence.SequencePlayer:Play()
  self.IsPlayTwoPanelSequence = true
end

function UMG_PetImage3D_C:PlayCloseTwoPanelLevelSequence()
  if not self.IsPlayTwoPanelSequence then
    return
  end
  self.PetLevelSequence:SetSequence(self.CloseTwoPanelLevelSequence)
  self:BinSequenceCamera()
  self.PetLevelSequence.SequencePlayer:Play()
  self.IsPlayTwoPanelSequence = false
end

function UMG_PetImage3D_C:UpdatePetLocationInHatchingPanel(IsShowChoosePanel, DisplayMode, IsAnimFinished)
  if IsAnimFinished then
    return
  end
  local TargetLevelSequence
  if IsShowChoosePanel then
    TargetLevelSequence = self.OpenEstablishContractLevelSequence
  else
    TargetLevelSequence = self.CloseEstablishContractLevelSequence
  end
  if self.PetLevelSequence then
    self.PetLevelSequence.SequencePlayer:Stop()
    if TargetLevelSequence then
      self.PetLevelSequence:SetSequence(TargetLevelSequence)
      self:BinSequenceCamera()
      self.PetLevelSequence.SequencePlayer:Play()
    end
  end
end

function UMG_PetImage3D_C:GetOpenTwoPanelLevelSequence()
  return self.OpenTwoPanelLevelSequence
end

function UMG_PetImage3D_C:GetCloseTwoPanelLevelSequence()
  return self.CloseTwoPanelLevelSequence
end

function UMG_PetImage3D_C:SetRotationDirection()
  local PetRotationZ = self._refActorIsolateWorld:K2_GetActorRotation().Yaw
  local CCWAngle = 0
  local CWAngle = 0
  if PetRotationZ < 0 then
    CCWAngle = PetRotationZ + 360 - self.PetRotation_Z
    CWAngle = -PetRotationZ + self.PetRotation_Z
  elseif PetRotationZ > 0 then
    if PetRotationZ > self.PetRotation_Z then
      CCWAngle = PetRotationZ - self.PetRotation_Z
      CWAngle = 360 - (PetRotationZ - self.PetRotation_Z)
    else
      CCWAngle = 360 - (self.PetRotation_Z - PetRotationZ)
      CWAngle = self.PetRotation_Z - PetRotationZ
    end
  end
  if CCWAngle > CWAngle then
    self.PetRotationAngle = CWAngle
    self.IsClockwiseRotation = true
  else
    self.PetRotationAngle = CCWAngle
    self.IsClockwiseRotation = false
  end
end

function UMG_PetImage3D_C:SetCachePetModelScale(_scale)
  self.CachePetModelScale = _scale
end

function UMG_PetImage3D_C:SetModelScale(_scale)
  self.Scale = _scale or 1
  if not self.IsOnActive then
    return
  end
  local scale = _scale or 1
  if self._refActorIsolateWorld then
    self._refActorIsolateWorld:SetActorScale3D(UE4.FVector(scale, scale, scale))
    local height = (self._refActorIsolateWorld:GetHalfHeight() or 0) * scale
    local PetLocation = UE4.FVector(0, 0, 0)
    if self.isEgg then
      PetLocation = UE4.FVector(-100, -6, 0)
    elseif self.NotChangeAnim then
      if self.IsOpenDetails then
        PetLocation = UE4.FVector(-29, 0, 0)
      else
        PetLocation = UE4.FVector(0, 0, 0)
      end
    end
    PetLocation.Z = PetLocation.Z + height
    self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(PetLocation)
    self._startActorLocation = PetLocation
    Log.Debug(PetLocation, "UMG_PetImage3D_C:SetModelScale")
  end
end

function UMG_PetImage3D_C:SetEvoModelOffSetInfo()
  if self.evoPetDataInfo then
    local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.evoPetDataInfo.base_conf_id)
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.evoPetDataInfo)
    modelScale = modelScale * heightModelScale
    PetMutationUtils.DoMutation(self._evoTargetActor, self.evoPetDataInfo)
    self:SetEvoModelScale(modelScale)
    if _petBaseCfg.petpage_capsule_offset and next(_petBaseCfg.petpage_capsule_offset) then
      local offsetConf = _petBaseCfg.petpage_capsule_offset
      local modelOffset = UE4.FVector(offsetConf[1] or 0, offsetConf[2] or 0, offsetConf[3] or 0)
      self:SetEvoModelOffset(modelOffset, modelScale)
    end
  else
    PetMutationUtils.DoMutation(self._evoTargetActor, self.uiPetData)
  end
end

function UMG_PetImage3D_C:SetModelOffset(_offset, modelScale)
  if self._refActorIsolateWorld then
    local height = (self._refActorIsolateWorld:GetHalfHeight() + _offset.Z) * (modelScale or 1)
    local CurPetLocation = self._refActorIsolateWorld:Abs_K2_GetActorLocation()
    local NewPetLocation = UE4.FVector(CurPetLocation.X + _offset.X, CurPetLocation.Y + _offset.Y, height)
    self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(NewPetLocation)
    self._startActorLocation = NewPetLocation
  end
end

function UMG_PetImage3D_C:SetEvoModelOffset(_offset, modelScale)
  if self._evoTargetActor then
    local height = (self._evoTargetActor:GetHalfHeight() + _offset.Z) * (modelScale or 1)
    local CurPetLocation = self._evoTargetActor:Abs_K2_GetActorLocation()
    local NewPetLocation = UE4.FVector(CurPetLocation.X + _offset.X, CurPetLocation.Y + _offset.Y, height)
    self._evoTargetActor:Abs_K2_SetActorLocation_WithoutHit(NewPetLocation)
    self._startActorLocation = NewPetLocation
  end
end

function UMG_PetImage3D_C:UpdateModelScaleAndOffset(_scale, _offset)
  if self._refActorIsolateWorld then
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.uiPetData)
    _scale = _scale * heightModelScale * 1.0
    self._refActorIsolateWorld:SetActorScale3D(UE4.FVector(_scale, _scale, _scale))
    local height = (self._refActorIsolateWorld:GetHalfHeight() + _offset.Z) * _scale
    local CurPetLocation = self._refActorIsolateWorld:Abs_K2_GetActorLocation()
    local NewPetLocation = UE4.FVector(CurPetLocation.X + _offset.X, CurPetLocation.Y + _offset.Y, height)
    self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(NewPetLocation)
    self._startActorLocation = NewPetLocation
  end
end

function UMG_PetImage3D_C:UpdateModelBlackAnim(_blackAnim)
  self.curBlackAnim = _blackAnim
end

function UMG_PetImage3D_C:SetEvoModelScale(_scale)
  local scale = _scale or 1
  if self._evoTargetActor then
    self._evoTargetActor:SetActorScale3D(UE4.FVector(scale, scale, scale))
  end
end

function UMG_PetImage3D_C:SetModelLocation(_location)
  local location = self._startActorLocation
  if _location then
    location = _location
  end
  if not location then
    return
  end
  if not self._refActorIsolateWorld then
    return
  end
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(location)
  end
end

function UMG_PetImage3D_C:SetShowOrHidePet(_IsHide)
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    self._refActorIsolateWorld:SetActorHiddenInGame(_IsHide)
  end
end

function UMG_PetImage3D_C:DestroyHavingModel()
  if self.HavingActor then
    self.PetWorldView:DestroyActor(self.HavingActor)
    self.HavingActor = nil
  end
end

function UMG_PetImage3D_C:SetEvolutionBackGround(_texture)
  if not self.evolutionTypeIcon then
    self:GetEvolutionTypeIcon()
  end
  if self.evolutionTypeMaterial then
    self.evolutionTypeMaterial:SetTextureParameterValue("UI_tu", _texture)
  end
end

function UMG_PetImage3D_C:PlaySkill(_skillPath)
end

function UMG_PetImage3D_C:SetAnimList(_animList, _idleCount, _randomAnimList)
  if not _idleCount or _idleCount <= 0 then
    _idleCount = 1
  end
  self.curAnimListTime = 0
  self.curAnimListIndex = 1
  self.animList = _animList
  self.randomAnimList = {
    "Alert",
    "Happy",
    "Fear",
    "Relax",
    "Shock",
    "Sad"
  }
  if self.idleAnimLen == nil then
    self.idleAnimLen = self:GetAnimLengthByName("Idle")
  end
  self.maxAnimListIdleTime = math.random(5, 10) * self.idleAnimLen
end

function UMG_PetImage3D_C:SetAnimationList(_animList, _idleTime, _randomAnimList)
  if not _idleTime or _idleTime <= 0 then
    _idleTime = 1
  end
  self.animList = _animList
  self.curAnimListTime = 0
  self.curAnimListIndex = 1
  self.randomAnimList = _randomAnimList
  self.maxAnimListIdleTime = _idleTime
end

function UMG_PetImage3D_C:SetAnimationInfoList(animInfoList)
  self.IsPlayingAnimationList = #animInfoList > 0
  self.PlayAnimationList = {}
  self.PlayAnimationIndex = 1
  self.PlayAnimationTimer = 0
  self.PlayAnimationMaxTime = 0
  for i = 1, #animInfoList do
    local animationInfo = {}
    animationInfo.name = animInfoList[i].name
    animationInfo.length = self:GetAnimLengthByName(animInfoList[i].name)
    animationInfo.loop = animInfoList[i].loop
    table.insert(self.PlayAnimationList, animationInfo)
  end
  if #self.PlayAnimationList > 0 then
    self.PlayAnimationMaxTime = self.PlayAnimationList[1].length - 0.5
    self._refActorIsolateWorld:PlayAnimByName(self.PlayAnimationList[1].name, 1, 0, 0.6, 0.2, 1)
  end
end

function UMG_PetImage3D_C:OnTickListAnimation(deltaTime)
  if self.PlayAnimationList == nil then
    self.PlayAnimationList = {}
  end
  if #self.PlayAnimationList > 0 then
    self.PlayAnimationTimer = self.PlayAnimationTimer + deltaTime
    if self.PlayAnimationTimer >= self.PlayAnimationMaxTime then
      self.PlayAnimationIndex = self.PlayAnimationIndex + 1
      if #self.PlayAnimationList < self.PlayAnimationIndex then
        self.IsPlayingAnimationList = false
        return
      end
      local index = self.PlayAnimationIndex
      local length = self.PlayAnimationList[index].length
      local name = self.PlayAnimationList[index].name
      local loop = self.PlayAnimationList[index].loop and -1 or 1
      self.PlayAnimationMaxTime = length
      self.PlayAnimationTimer = 0
      self._refActorIsolateWorld:PlayAnimByName(name, 1, 0, 0.5, 0.5, loop)
    end
  end
end

function UMG_PetImage3D_C:StopTickListAnimation()
  self.IsPlayingAnimationList = false
  self.PlayAnimationList = {}
end

function UMG_PetImage3D_C:PlaySleepAnim()
  local nameList = {}
  table.insert(nameList, {name = "SleepStart", loop = false})
  table.insert(nameList, {name = "SleepLoop", loop = true})
  self:SetAnimationInfoList(nameList)
  self:ResSetActorRotation(90)
end

function UMG_PetImage3D_C:PlayOutSleepAnim()
  self:StopTickListAnimation()
  self._refActorIsolateWorld:PlayAnimByName("SleepEnd", 1, 0, 0.1, 0.1, 1)
end

function UMG_PetImage3D_C:GetAnimLengthByName(_name)
  if UE4.UObject.IsValid(self._refActorIsolateWorld) and _name then
    local animComp = self._refActorIsolateWorld:GetAnimComponent()
    if animComp then
      return animComp:GetAnimLengthByName(_name)
    end
  end
  return 0
end

function UMG_PetImage3D_C:GetEvolutionTypeIcon()
  local evoTypeImage = self.PetWorldView:getActorByName("CWLP_BGIcon")
  if evoTypeImage then
    local meshCmpt = evoTypeImage:GetComponentByClass(UE4.UMeshComponent)
    local meshcomponent = evoTypeImage:GetComponentByClass(UE4.UStaticMeshComponent)
    local sourceMaterial = meshcomponent:GetMaterial(0)
    local dyMaterial = meshcomponent:CreateDynamicMaterialInstance(0, sourceMaterial)
    self.evolutionTypeMaterial = dyMaterial
    self.evolutionTypeMaterial_Ref = self.evolutionTypeMaterial and UnLua.Ref(self.evolutionTypeMaterial)
  end
  self.evolutionTypeIcon = evoTypeImage
  self.evolutionBgAnim = self.PetWorldView:getActorByName("CWLP_CycleAnim")
end

function UMG_PetImage3D_C:PlayAnimByName(_name, _loopCount)
  if self.IsPlayShowPetSkill and not self.isEgg then
    return
  end
  if not self.IsDetailsMoveEnd and self.IsOpenDetails then
    return
  end
  if self.isEgg then
  end
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    if UE4.UNRCStatics.IsEditor() and self.curBlackAnim and self.curBlackAnim[_name] then
      return
    end
    _loopCount = _loopCount or 1
    local curAnimInfo = self.curAnimInfo
    local len = self._refActorIsolateWorld:PlayAnimByName(_name, 1, 0, 0, 0, _loopCount)
    if curAnimInfo then
      if _loopCount and _loopCount > 0 then
        curAnimInfo.isPlayAnim = true
        curAnimInfo.curAniName = _name
        curAnimInfo.curAniLength = len * _loopCount
      else
        curAnimInfo.curAniLength = 0
        curAnimInfo.isPlayAnim = false
      end
    end
    if UE4.UNRCStatics.IsEditor() then
      local PetVisualParam = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetVisualParam)
      if PetVisualParam then
        PetVisualParam.cur_anim = _name
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetVisualParam, PetVisualParam)
      end
    end
  end
end

function UMG_PetImage3D_C:SetActorRotation(_rotation)
  if self._refActorIsolateWorld then
    self._refActorIsolateWorld:K2_SetActorRotation(_rotation or UE4.FRotator(0, 0, 0), false)
  end
end

function UMG_PetImage3D_C:ResSetActorRotation(_dstDir)
  self.isResetRotate = true
  self.petDstRotateDir = _dstDir or 0
end

function UMG_PetImage3D_C:EvoPlayPetSkill(bStart, bPlay)
  if not bPlay or bStart then
  else
    self:PlayPetSkillAsync(self.OpenDetailsPlaySkill, self.OpenDetailsPlaySkillPath, true)
  end
end

function UMG_PetImage3D_C:OnNewEvoPanelOpened()
  if UE.UObject.IsValid(self.MainCameraActor) then
    self.MainCameraTransfrom = self.MainCameraActor.RootComponent:GetRelativeTransform()
  end
  self.IsOpenEvoPanel = true
  self:PlayAlertAnim()
  self:ChangeEvoLight(true)
  self:LoadEvoTargetModel()
  self:LoadPrepareEvoSkill1()
end

function UMG_PetImage3D_C:PlayAlertAnim()
  if not self.IsOpenEvoPanel or self.bEvoing then
    return
  end
  local EmoteDuration = 1
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    local Anim = self._refActorIsolateWorld.RocoAnim:GetAnimSequenceByName("Alert")
    if Anim then
      EmoteDuration = Anim:GetPlayLength()
    end
    self._refActorIsolateWorld:PlayAnimByName("Alert")
  end
  local RandTime = math.random(2, 5)
  self:DelaySeconds(EmoteDuration * RandTime, self.PlayAlertAnim, self)
end

function UMG_PetImage3D_C:OnNewEvoPanelClosed(bSucc)
  self:ChangeEvoLight(false, bSucc)
  self.IsOpenEvoPanel = false
  if bSucc then
    if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) and self._refActorIsolateWorld.RocoSkill and self._evoTargetActor then
      self._refActorIsolateWorld.RocoSkill:StopCurrentSkill()
      self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
      self._refActorIsolateWorld = nil
      self._refActorIsolateWorld = self._evoTargetActor
    end
    self.bEvoing = false
  elseif self._evoTargetActor then
    self.PetWorldView:DestroyActor(self._evoTargetActor)
    self._evoTargetActor = nil
  end
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    _G.NRCAudioManager:StopAllForActor(self._refActorIsolateWorld)
    _G.NRCAudioManager:RegisterSpecialPet(self.AudioId, self._refActorIsolateWorld)
    _G.NRCAudioManager:SetListenerToSelf(self._refActorIsolateWorld, "SpecialPet")
  end
end

function UMG_PetImage3D_C:OnNewEvoPanelDestruct()
  if self.EvoBP then
    self.PetWorldView:DestroyActor(self.EvoBP)
    self.EvoBP = nil
  end
  if self.EvoJinjieBP then
    self.PetWorldView:DestroyActor(self.EvoJinjieBP)
    self.EvoJinjieBP = nil
  end
  self:StopEvoSkill()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ShowPetInfoMainUI, true, true)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, true)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ShowHideTimeRewindBtn, true)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.ShowHideGiftColleaguesBtn, true)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainShareBtnVisibility, true)
  if self.skillCamera then
    self.skillCamera = nil
  end
  if self.skillCameraMesh then
    self.skillCameraMesh = nil
  end
  if UE.UObject.IsValid(self.MainCameraActor) and self.MainCameraTransfrom then
    self.MainCameraActor.RootComponent:K2_SetRelativeTransform(self.MainCameraTransfrom, false, nil, false)
  end
  self.evoPetData = nil
  self.evoPetDataInfo = nil
end

function UMG_PetImage3D_C:ChangeEvoLight(bEvoStart, bEvoSucc)
  local DarkVolumeBP = self.PetWorldView:getActorByName("BP_DarkVolume_3")
  if bEvoStart then
    self:OpenLight_1()
  elseif true == bEvoSucc then
    self:CloseAllLight()
  else
    self:ChangeLight_1(false)
  end
end

function UMG_PetImage3D_C:LoadEvoEnterSequence()
  local requset = NRCResourceManager:LoadResAsync(self, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenDetailsLevelSequence0_2_Jh.OpenDetailsLevelSequence0_2_Jh'", -1, 10, function(caller, resRequest, asset)
    self.EnterSequence = asset
    self:PlayEnterEvoSequence(asset, true)
  end, nil, nil)
  table.insert(self.loadResRequest, requset)
end

function UMG_PetImage3D_C:LoadEvolutionBP()
end

function UMG_PetImage3D_C:LoadEvoTargetModel()
  local targetConfId = _G.NRCModuleManager:GetModule("PetUIModule"):GetEvoTargetCfgId()
  local targetModelId = _G.DataConfigManager:GetPetbaseConf(tonumber(targetConfId)).model_conf
  local targetModelPath = _G.DataConfigManager:GetModelConf(targetModelId).path
  self:LoadPanelRes(targetModelPath, 255, self.LoadEvoPetSucceed, nil, nil)
end

function UMG_PetImage3D_C:LoadEvoPetSucceed(resRequest, targetModelClass)
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 1.5)
  local trans = UE4.FTransform(quat, UE4.FVector(0.0, 0.0, 0.0), UE4.FVector(1, 1, 1))
  if UE.UObject.IsValid(self.SkeletalMesh) and self._refActorIsolateWorld then
    self.SkeletalMesh:K2_SetWorldRotation(UE4.FRotator(0, 20, 0), false, nil, false)
  end
  if targetModelClass then
    self._evoTargetActor = self.PetWorldView:SpawnActor(targetModelClass, trans)
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Show", self._evoTargetActor)
    self._evoTargetActor:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
    if self.evoPetDataInfo then
      PetMutationUtils.PrepareMutationAssets(self._evoTargetActor, self.evoPetDataInfo)
    else
      PetMutationUtils.PrepareMutationAssets(self._evoTargetActor, self.uiPetData)
    end
    self._evoTargetActor:InitOutSceneAsync(self, self.OnEvoPetLoaded)
    local height = self._evoTargetActor:GetHalfHeight()
    self._evoTargetActor:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(0, 0, 0))
  end
end

function UMG_PetImage3D_C:LoadQuitSequence()
  self.PetLevelSequence.SequencePlayer.OnFinished:Remove(self, self.PlayEvoLoopSequence)
  self.PetLevelSequence.SequencePlayer:Stop()
  local requset = NRCResourceManager:LoadResAsync(self, "LevelSequence'/Game/NewRoco/Modules/System/PetUI/Raw/BP/OpenDetailsLevelSequence0_2_Jh.OpenDetailsLevelSequence0_2_Jh'", -1, 10, function(caller, resRequest, asset)
    self.QuitSequence = asset
    self:PlayEnterEvoSequence(asset, false)
  end, nil, nil)
  table.insert(self.loadResRequest, requset)
end

function UMG_PetImage3D_C:StartEvolution()
  self.bEvoing = true
  self.PetLevelSequence.SequencePlayer.OnFinished:Remove(self, self.PlayEvoLoopSequence)
  self.PetLevelSequence.SequencePlayer:Stop()
  self._refActorIsolateWorld:PlayAnimByName("Happy", 1, 0, 0, 0, 1)
  self:LoadPrepareEvoSkill2()
end

function UMG_PetImage3D_C:RefreshEvoPetModel(petData)
  self.evoPetData = petData
  for k, v in ipairs(self.evoPetData) do
    if v.pet_data then
      self.evoPetDataInfo = v.pet_data
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.evoPetDataInfo.base_conf_id)
      self.PetBaseConf = petBaseConf
      break
    end
  end
  if self._evoTargetActor and UE4.UObject.IsValid(self._evoTargetActor) then
    self.PetWorldView:DestroyActor(self._evoTargetActor)
    self._evoTargetActor = nil
    self:LoadEvoTargetModel()
  else
    Log.Error("\232\191\155\229\140\150\229\144\142\230\168\161\229\158\139\228\184\141\229\173\152\229\156\168\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165\233\133\141\231\189\174")
  end
end

function UMG_PetImage3D_C:SetAdjustPetParam(IsPlaySwitchPetShow)
  if not IsPlaySwitchPetShow then
    self:DelaySeconds(0.1, function()
      self:SetShowOrHidePet(false)
    end)
  end
  if not UE4.UNRCStatics.IsEditor() then
    return
  end
  local PetParam = {}
  if self.uiPetData == nil then
    return
  end
  if nil == self._refActorIsolateWorld then
    return
  end
  PetParam.id = self.uiPetData.base_conf_id
  local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.uiPetData.base_conf_id)
  PetParam.name = _petBaseCfg.name
  PetParam.EvolutionLevel = _petBaseCfg.stength_stage
  local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
  PetParam.Scale = modelScale
  if _petBaseCfg.petpage_capsule_offset and next(_petBaseCfg.petpage_capsule_offset) then
    local offsetConf = _petBaseCfg.petpage_capsule_offset
    PetParam.capsule_offset = UE4.FVector(offsetConf[1] or 0, offsetConf[2] or 0, offsetConf[3] or 0)
  else
    PetParam.capsule_offset = _G.FVectorZero
  end
  PetParam.black_anim = _G.DataConfigManager:GetPetpageBlacklist(self.uiPetData.base_conf_id, true)
  PetParam.cur_anim = self._refActorIsolateWorld.RocoAnim:GetCurAnimName()
  local PetMesh = self._refActorIsolateWorld:GetComponentByClass(UE4.USkeletalMeshComponent)
  if PetMesh then
  end
  PetParam.capsule_offset_model = self._refActorIsolateWorld:K2_GetRootComponent():GetRelativeTransform().Translation
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.SetPetVisualParam, PetParam)
end

function UMG_PetImage3D_C:SetSpotLightColorByUnitType()
  if not self.PetWorldView then
    return
  end
  if not self.PetBaseConf and not self.eggPetGid then
    return
  end
  local modelFxType = Enum.SkillDamType.SDT_COMMON
  if self.PetBaseConf then
    modelFxType = self.PetBaseConf.unit_type[1]
    if modelFxType < Enum.SkillDamType.SDT_COMMON then
      modelFxType = Enum.SkillDamType.SDT_COMMON
    end
  elseif self.eggPetGid then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.eggPetBaseID)
    if petBaseConf then
      modelFxType = petBaseConf.unit_type[1]
      if modelFxType < Enum.SkillDamType.SDT_COMMON then
        modelFxType = Enum.SkillDamType.SDT_COMMON
      end
    end
  end
  local colorStr = _G.DataConfigManager:GetSkillColorConf(modelFxType).perform_light_colour
  local color = UE4.UNRCStatics.HexToLinearColor(colorStr)
  local SpotLight = self.PetWorldView:getActorByName("BP_DarkVolumeSpotLight_2")
  SpotLight:SetMaterialColor(color)
end

function UMG_PetImage3D_C:ShowStarEffect(isShow)
  local effectPatch = "NiagaraSystem'/Game/NewRoco/Modules/System/PetUI/Raw/Effects/NS_UI_Star_002.NS_UI_Star_002'"
  if isShow then
    if self.StarID then
      local FxManager = UE.UFXManager.Get()
      local FxParam = UE.FPlayFXParam()
      FxParam.FxSystemTemplate = self.StarID
      self.StarFx = FxManager.SpawnFXAttached(FxParam, self.SkeletalMesh)
    else
      self.startLoader = _G.NRCResourceManager:LoadResAsync(self, effectPatch, NRCResourceManagerEnum.Priority.IMMEDIATELY, 0, self.StarLoadedSuccess, self.StarLoadFailed)
    end
  elseif self.StarID and UE.UObject.IsValid(self.StarFx) then
    self.StarFx:K2_DestroyComponent(self.StarFx)
    self.StarFx = nil
  end
end

function UMG_PetImage3D_C:StarEffectUnLoader()
  if UE4.UObject.IsValid(self.startLoader) then
    _G.NRCResourceManager:UnLoadRes(self.startLoader)
    self.startLoader = nil
  end
end

function UMG_PetImage3D_C:StarLoadedSuccess(resRequest, asset)
  if not UE4.UObject.IsValid(self.SkeletalMesh) then
    return
  end
  self.StarID = asset
  local FxManager = UE.UFXManager.Get()
  if FxManager then
    local FxParam = UE.FPlayFXParam()
    FxParam.FxSystemTemplate = self.StarID
    self.StarFx = FxManager.SpawnFXAttached(FxParam, self.SkeletalMesh)
  end
end

function UMG_PetImage3D_C:StarLoadFailed(resRequest, asset)
  Log.Error("UMG_PetImage3D_C:StarLoadFailed Load Beam Failed")
  self.StarID = nil
  _G.NRCResourceManager:UnLoadRes(resRequest)
end

function UMG_PetImage3D_C:ChangeLight_2(bStart)
  local DarkVolumeBP = self.PetWorldView:getActorByName("BP_DarkVolumeSpotLight_2")
  if bStart then
    DarkVolumeBP:StartSpotLight()
  else
    DarkVolumeBP:EndSpotLight()
  end
end

function UMG_PetImage3D_C:ChangeLight_1(bStart)
  local DarkVolumeBP = self.PetWorldView:getActorByName("BP_DarkVolume_3")
  if bStart then
    DarkVolumeBP:Start()
  else
    DarkVolumeBP:End()
  end
end

function UMG_PetImage3D_C:OpenLight_1()
  self:ChangeLight_1(true)
end

function UMG_PetImage3D_C:OpenLight_2()
  self:ChangeLight_2(true)
  self:SetSpotLightColorByUnitType()
  self:SetBagColourByUnitType()
end

function UMG_PetImage3D_C:CloseAllLight()
  self:ChangeLight_2(false)
  self:ChangeLight_1(false)
end

function UMG_PetImage3D_C:GetPetHeadSlotScreenPos()
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    local petMesh = self._refActorIsolateWorld:GetComponentByClass(UE4.USkeletalMeshComponent)
    if petMesh then
      local headLocation = petMesh:Abs_GetSocketLocation("locator_head")
      local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
      local ProjMat = UE4.FMatrix()
      if self.MainCameraActor and UE4.UObject.IsValid(self.MainCameraActor) then
        UE4.UNRCStatics.CalculateViewProjectionMatrix(self.MainCameraActor:GetComponentByClass(UE4.UCameraComponent), ProjMat)
      end
      local petPos = UE4.UNRCStatics.Abs_ProjectWorldToScreenHidden(headLocation, viewportSize.X, viewportSize.Y, ProjMat)
      local scaleX = 1920 / viewportSize.X
      local scaleY = 1080 / viewportSize.Y
      petPos.X = petPos.X * scaleX
      petPos.Y = petPos.Y * scaleY
      return petPos
    else
      Log.Error("\230\178\161\230\156\137\229\174\160\231\137\169\230\168\161\229\158\139,\230\159\165\231\156\139\229\142\159\229\155\160")
    end
  else
    return nil
  end
end

function UMG_PetImage3D_C:PlayEggSwitch()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.FinshEggSwitch, false)
  if self.eggSwitchSkillClass == nil then
    local skillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchEegShow_UI.G6_SwitchEegShow_UI_C"
    self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
      if asset then
        self.eggSwitchSkillClass = asset
        if self.eggSwitchSkillClass and self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) and self._refActorIsolateWorld.RocoSkill then
          self:PlayEggSwitchEffectOnLoadSkill()
        end
      else
        Log.Error("UMG_PetImage3D_C:LoadEggSwitchAssect \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
      end
    end, nil, nil)
  else
    self:PlayEggSwitchEffectOnLoadSkill()
  end
end

function UMG_PetImage3D_C:EndEggSwitch()
  self.isPlayEggEffect = false
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false)
  self:ShowStarEffect(true)
end

function UMG_PetImage3D_C:ShowEggHatchUI()
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.FinshEggSwitch, true)
end

function UMG_PetImage3D_C:PlayEggEffect(petGid, eggBallItemId)
  Log.Debug("UMG_PetImage3D_C:PlayEggEffect")
  self.eggPetGid = petGid
  self.eggBallItemId = eggBallItemId
  self:LoadEggEffectAssect()
  self.isPlayEggEffect = true
  self.bPlayingEggCrackSkill = true
  self.HatchedPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if self.HatchedPetData then
    self.eggPetBaseID = self.HatchedPetData.base_conf_id
    self:LoadEggToPetModel(self.eggPetBaseID)
  end
  self:ShowStarEffect(false)
  if UE.UObject.IsValid(self.SkeletalMesh) then
    self.SkeletalMesh:K2_SetRelativeRotation(UE4.FRotator(0, 20, 0), false, nil, true)
  end
end

function UMG_PetImage3D_C:EndEggEffect()
  Log.Debug("UMG_PetImage3D_C:EndEggEffect")
  self.eggPetBaseID = nil
  self.eggPetGid = nil
  self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
  self._refActorIsolateWorld = self.targetPetModel
  self.bPlayingEggCrackSkill = false
  self:SetAnimList(nil, nil)
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.EndEggEffect)
end

function UMG_PetImage3D_C:ShowEggEffectUI()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.eggPetBaseID)
  if petBaseConf then
    local scale = petBaseConf.petpage_ui_percentage
    local pos = petBaseConf.petpage_capsule_offset
    local petScale = UE4.FVector(scale, scale, scale)
    local petLocation = UE4.FVector(pos[1] or 0, pos[2] or 0, pos[3] or 0)
    if self.targetPetModel then
      local height = (self.targetPetModel:GetHalfHeight() + petLocation.Z) * (scale or 1)
      local CurPetLocation = self.targetPetModel:Abs_K2_GetActorLocation()
      local NewPetLocation = UE4.FVector(CurPetLocation.X + petLocation.X, CurPetLocation.Y + petLocation.Y, height)
      self.targetPetModel:Abs_K2_SetActorLocation_WithoutHit(NewPetLocation)
      self.targetPetModel:SetActorScale3D(petScale)
      self._startActorLocation = NewPetLocation
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenEggIncubatePanel, self.eggPetBaseID, self.eggPetGid, self.eggBallItemId)
  end
end

function UMG_PetImage3D_C:UpdateEggEffectUI()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.UpdateEggIncubatePanel)
end

function UMG_PetImage3D_C:LoadEggEffectAssect()
  local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'"
  local skillClass = self.module:GetRes(skillPath, self.ModuleName)
  if not skillClass then
    self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
      if asset then
        self.eggEffectSkillClass = asset
      else
        Log.Error("UMG_PetImage3D_C:LoadEggEffectAssect \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
      end
    end, nil, nil)
  else
    self.eggEffectSkillClass = skillClass
  end
end

function UMG_PetImage3D_C:LoadEggSwitchAssect()
  local skillPath = "SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchEegShow_UI.G6_SwitchEegShow_UI_C"
  local skillClass = self.module:GetRes(skillPath, self.ModuleName)
  if not skillClass then
    self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
      if asset then
        self.eggSwitchSkillClass = asset
      else
        Log.Error("UMG_PetImage3D_C:LoadEggSwitchAssect \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
      end
    end, nil, nil)
  else
    self.eggSwitchSkillClass = skillClass
  end
end

function UMG_PetImage3D_C:LoadEggToPetModel(petBaseId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  local moduleConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  local modulePath = moduleConf.path
  Log.Debug("\229\138\160\232\189\189\231\154\132\231\178\190\231\129\181\232\155\139\230\168\161\229\158\139\228\184\186:", modulePath)
  self:LoadPanelRes(modulePath, 255, self.LoadEggToPetModelSucceed, nil, nil)
end

function UMG_PetImage3D_C:LoadEggToPetModelSucceed(resRequest, birthModel)
  if not birthModel then
    Log.Error("UMG_PetImage3D_C:LoadEggToPetModel \230\168\161\229\158\139\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", resRequest or "")
    return
  end
  local mutationType = _G.Enum.MutationDiffType.MDT_NONE
  local quat = UE4.FRotator(0, 0, 0):ToQuat()
  local trans = UE4.FTransform(quat, UE4.FVector(2000.0, 2000.0, 2000.0), UE4.FVector(1, 1, 1))
  self.targetPetModel = self.PetWorldView:SpawnActor(birthModel, trans)
  _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Show", self.targetPetModel)
  if not self.targetPetModel then
    Log.Error("UMG_PetImage3D_C:LoadEggToPetModel \230\168\161\229\158\139\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", resRequest or "")
    return
  end
  if self._refActorIsolateWorld then
    self._refActorIsolateWorld:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
  end
  PetMutationUtils.PrepareMutationAssets(self.targetPetModel, self.HatchedPetData)
  self.targetPetModel:InitOutSceneAsync(self, self.OnEggPetLoaded)
end

function UMG_PetImage3D_C:OnEggPetLoaded(actor)
  actor.IkOverride = false
  local height = actor:GetHalfHeight()
  actor:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(2000, 2000, 2000))
  local rotate = actor:K2_GetActorRotation()
  actor:K2_SetActorRotation(rotate, false)
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  mesh:SetForcedLOD(1)
  mesh.bEnableUpdateRateOptimizations = false
  mesh.StreamingDistanceMultiplier = 999
  mesh.bNeverDistanceCull = true
  mesh.bForceMipStreaming = true
  self.targetPetModel = actor
  if self.HatchedPetData then
    local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(self.HatchedPetData.base_conf_id)
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.HatchedPetData)
    modelScale = modelScale * heightModelScale
    PetMutationUtils.DoMutation(actor, self.HatchedPetData)
    actor:SetActorScale3D(UE4.FVector(modelScale, modelScale, modelScale))
    if self.eggEffectSkillClass == nil then
      local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'"
      self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
        if asset then
          self.eggEffectSkillClass = asset
          self:PlayEggEffectOnLoadSkill()
        else
          Log.Error("UMG_PetImage3D_C:LoadEggEffectAssect \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
        end
      end, nil, nil)
    else
      self:PlayEggEffectOnLoadSkill()
    end
  end
end

function UMG_PetImage3D_C:OnFinshEggCamera()
  if self.skillCamera then
    self.skillCamera = nil
  end
  if self.skillCameraMesh then
    self.skillCameraMesh = nil
  end
  if self.MainCameraActor and self.MainCameraTransfrom then
    self.MainCameraActor.RootComponent:K2_SetRelativeTransform(self.MainCameraTransfrom, false, nil, false)
  end
end

function UMG_PetImage3D_C:StopPetAudio()
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    _G.NRCAudioManager:StopAllForActor(self._refActorIsolateWorld)
  end
end

function UMG_PetImage3D_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  self:UnRegisterEvent(self, PetUIModuleEvent.OnShowOrClosePetEggBallChoosePanel, self.UpdatePetLocationInHatchingPanel)
  self.BgMeshComp = nil
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(0)
  if self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) then
    if self._refActorIsolateWorld.Mesh and UE4.UObject.IsValid(self._refActorIsolateWorld.Mesh) then
      self._refActorIsolateWorld.Mesh:ReleaseResource()
      self._refActorIsolateWorld.Mesh:Release()
    end
    self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    local remainActorsNum = self.PetWorldView.SpawnedActors:Length()
    self._refActorIsolateWorld:Release()
    if self.SkeletalMesh then
      self.SkeletalMesh:Release()
      self.SkeletalMesh = nil
    end
  end
  if self.BackgroundPlate then
    self.BackgroundPlate:Release()
  end
  if self.PetLevelSequence then
    self.PetWorldView:DestroyActor(self.PetLevelSequence)
    self.PetLevelSequence = nil
  end
  if self.CineCamera and UE.UObject.IsValid(self.CineCamera) and UE.UObject.IsValid(self.PetWorldView) then
    self.PetWorldView:DestroyActor(self.CineCamera)
    self.CineCamera = nil
  end
  if self.targetPetModel and UE.UObject.IsValid(self.targetPetModel) and UE.UObject.IsValid(self.PetWorldView) then
    self.PetWorldView:DestroyActor(self.targetPetModel)
    self.targetPetModel = nil
  end
  if nil ~= self.CloseTwoPanelLevelSequence then
    self.CloseTwoPanelLevelSequence:Release()
    self.CloseTwoPanelLevelSequence = nil
  end
  if nil ~= self.OpenTwoPanelLevelSequence then
    self.OpenTwoPanelLevelSequence:Release()
    self.OpenTwoPanelLevelSequence = nil
  end
  _G.NRCAudioManager:EndRegisterSpecialPet(self.AudioId)
  _G.NRCAudioManager:EndRegisterSpecialPet(self.AudioIdEvo)
  self.evolutionTypeMaterial = nil
  self.evolutionTypeMaterial_Ref = nil
  self.evolutionTypeIcon = nil
  self.evolutionBgAnim = nil
  self.skillClass = nil
  self.skillClassRef = nil
  self.MainCameraActor = nil
  self.eggModuleScale = nil
  self.EvoSkillAnim01 = nil
  if self.MaterialInstanceNew then
    self.MaterialInstanceNew:Release()
  end
  if self.MaterialInstance then
    self.MaterialInstance:Release()
  end
  if self.MaterialInstanceNewBottom then
    self.MaterialInstanceNewBottom:Release()
  end
  self.MaterialInstance_Ref = nil
  self.MaterialInstanceNewBottom_Ref = nil
  self:CancelDelay()
  self:SetAnimList(nil, nil)
  self.bPetLoaded = false
  self.LuopanOut:Release()
  self:StarEffectUnLoader()
end

function UMG_PetImage3D_C:InitPetShareData(scale, offset, rotate)
  self.PetShareData = {
    scale = scale,
    offset = offset,
    rotate = rotate
  }
  self.randomAnimList = nil
end

function UMG_PetImage3D_C:SetSharePhotoPetAnim(enable)
  if enable then
    self._refActorIsolateWorld:PlayAnimByName("Idle", 0, 0, 0, 0, -1)
  else
    self._refActorIsolateWorld:PlayAnimByName("Idle", 1, 0, 0, 0, -1)
  end
end

function UMG_PetImage3D_C:PlaySharePetSkill(Skill, cb)
  self.shareVideoEndCb = cb
  local Caster = self._refActorIsolateWorld
  if Skill and Caster then
    local skillObj = Caster.RocoSkill:FindOrAddSkillObj(Skill)
    if skillObj then
      Log.Debug("UMG_PetImage3D_C:PlaySharePetSkill start play share video")
      skillObj:SetCaster(Caster)
      skillObj:SetTargets({
        self._refActorIsolateWorld
      })
      skillObj:RegisterRawCallback(self, self.OnShareSkillEvent)
      skillObj:SetPassive(true)
      if self.CurrenSkill then
        Caster.RocoSkill:CancelSkill(self.CurrenSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
      local blackBoard = skillObj:GetBlackboard()
      self:SetShareSkillBlackBoardValue(blackBoard)
      Caster.RocoSkill:LoadAndPlaySkill(skillObj)
      self.CurrenSkill = skillObj
      self.IsPlayShareG6 = true
      if self.IsHideModule then
        self:OnShowOrHidePetModule(false)
      end
      local PetLocation = self._startActorLocation
      self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(0, 0, PetLocation.Z))
      local rotateYaw = self.SkeletalMesh:K2_GetComponentRotation().Yaw
      self.SkeletalMesh:K2_AddWorldRotation(UE4.FRotator(0, -rotateYaw, 0), false, nil, false)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, true, false)
    else
      Log.Error("UMG_PetImage3D_C:PlaySharePetSkill==\231\178\190\231\129\181\229\136\134\228\186\171G6\229\138\160\232\189\189\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129")
    end
  end
end

function UMG_PetImage3D_C:OnShareSkillEvent(event, skill)
  Log.Debug("UMG_PetImage3D_C:OnShareSkillEvent==event==", event)
  if "VideoEnd" == event and self.shareVideoEndCb then
    self.IsPlayShareG6 = false
    local Caster = self._refActorIsolateWorld
    if self.CurrenSkill then
      Caster.RocoSkill:CancelSkill(self.CurrenSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
    self.CurrenSkill = nil
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false, false)
    self.shareVideoEndCb()
    self.shareVideoEndCb = nil
  end
end

function UMG_PetImage3D_C:SetShareSkillBlackBoardValue(blackBoard)
  if blackBoard then
    if self.uiPetData then
      local nature = self.uiPetData.nature
      local keyName = string.format("share_specialeffect_nature_conf_%d", nature)
      local globalConf = _G.DataConfigManager:GetGlobalConfig(keyName)
      if globalConf and globalConf.str then
        blackBoard:SetValueAsString(globalConf.str, globalConf.str)
      else
        blackBoard:SetValueAsString("Shock", "Shock")
      end
    else
      Log.Error("UMG_PetImage3D_C:SetShareSkillBlackBoardValue==uiPetData is nil\239\188\129\239\188\129\239\188\129")
      blackBoard:SetValueAsString("Shock", "Shock")
    end
  end
end

function UMG_PetImage3D_C:SetPetModeByShareData(shareData)
  if self.PetBaseConf then
    local _petBaseCfg = self.PetBaseConf
    local modelScale = _petBaseCfg.petpage_ui_percentage and _petBaseCfg.petpage_ui_percentage > 0 and _petBaseCfg.petpage_ui_percentage or 1
    if shareData.scale then
      if self.uiPetData then
        local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.uiPetData)
        modelScale = modelScale * heightModelScale * shareData.scale * 1.0
        self.ScaleInfo = modelScale
      end
      self:SetModelScale(modelScale)
    end
    if shareData.offset then
      if _petBaseCfg.petpage_capsule_offset and next(_petBaseCfg.petpage_capsule_offset) then
        local offsetConf = _petBaseCfg.petpage_capsule_offset
        local modelOffset = UE4.FVector((offsetConf[1] or 0) + shareData.offset.X, (offsetConf[2] or 0) + shareData.offset.Y, (offsetConf[3] or 0) + shareData.offset.Z)
        self:SetModelOffset(modelOffset, modelScale)
      else
        local modelOffset = UE4.FVector(shareData.offset.X, shareData.offset.Y, shareData.offset.Z)
        self:SetModelOffset(modelOffset, modelScale)
      end
    end
    if shareData.rotate then
      self.SkeletalMesh:K2_AddWorldRotation(shareData.rotate, false, nil, false)
    end
  end
end

function UMG_PetImage3D_C:SavePetModeDataCache()
  if self and self._refActorIsolateWorld and not self.PetModeDataCache then
    self.PetModeDataCache = {
      scale = self.Scale,
      petLocation = self._refActorIsolateWorld:Abs_K2_GetActorLocation(),
      rotation = self.DeltaRot,
      isHide = self.IsHideModule
    }
  end
end

function UMG_PetImage3D_C:ResetPetModeData()
  if self.PetModeDataCache then
    local scale = self.PetModeDataCache.scale
    local petLocation = self.PetModeDataCache.petLocation
    local rotation = self.PetModeDataCache.rotation
    local isHide = self.PetModeDataCache.isHide
    if scale then
      self:SetModelScale(scale)
    end
    if petLocation then
      self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(petLocation)
    end
    if rotation then
      self.SkeletalMesh:K2_AddWorldRotation(rotation, false, nil, false)
    end
    if isHide then
      self:OnShowOrHidePetModule(true)
    end
    self.PetModeDataCache = nil
  end
end

function UMG_PetImage3D_C:HidePetBeforeCloseAnim()
  local caster = self._refActorIsolateWorld
  if UE.UObject.IsValid(caster) then
    caster:SetVisible(false)
  end
end

function UMG_PetImage3D_C:RefreshAttributeInfo()
  if not self.uiPetData then
    return
  end
  local newPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiPetData.gid)
  PetMutationUtils.TryRemoveNightMareMutation(self._refActorIsolateWorld, self.uiPetData, newPetData)
  self.uiPetData = newPetData
end

function UMG_PetImage3D_C:PlayEggEffectOnLoadSkill()
  if not (self.eggEffectSkillClass and self.targetPetModel and self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld)) or not self._refActorIsolateWorld.RocoSkill then
    return
  end
  local eggSwitchSkillObj = self._refActorIsolateWorld.RocoSkill:FindOrAddSkillObj(self.eggSwitchSkillClass)
  self._refActorIsolateWorld.RocoSkill:CancelSkill(eggSwitchSkillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
  self:SetAnimList(nil, nil)
  local skillObj = self._refActorIsolateWorld.RocoSkill:FindOrAddSkillObj(self.eggEffectSkillClass)
  skillObj:SetCaster(self._refActorIsolateWorld)
  skillObj:RegisterEventCallback("SetCamera", self, self.SetSkillCamera1)
  skillObj:RegisterEventCallback("RemoveCamera", self, self.OnFinshEggCamera)
  skillObj:RegisterEventCallback("OpenEggPanel", self, self.ShowEggEffectUI)
  skillObj:RegisterEventCallback("ShowEggPanelText", self, self.UpdateEggEffectUI)
  skillObj:RegisterEventCallback("OpenLight_1", self, self.OpenLight_1)
  skillObj:RegisterEventCallback("OpenLight_2", self, self.OpenLight_2)
  skillObj:RegisterEventCallback("EggPerEnd", self, self.EndEggEffect)
  local Blackboard = skillObj:GetBlackboard()
  local IsSetHatchGlass = false
  if self.HatchedPetData and self.HatchedPetData.glass_info then
    local GlassType = self.HatchedPetData.glass_info.glass_type
    local GlassValue = self.HatchedPetData.glass_info.glass_value
    if GlassValue then
      if 1 == GlassType then
        local _, ShineID = PetUtils.GetShineDataValue(GlassValue, 20)
        local ColorRandomConfID, _ = PetUtils.GetShineDataValue(ShineID, 0)
        local ColorRandomConf = _G.DataConfigManager:GetColorRandomConf(ColorRandomConfID)
        if ColorRandomConf and ColorRandomConf.mat_color_1 and ColorRandomConf.mat_color_2 then
          Blackboard:SetValueAsString("Fx_Normal_Colorful", "Fx_Normal_Colorful")
          local R1, G1, B1 = ColorRandomConf.mat_color_1[1], ColorRandomConf.mat_color_1[2], ColorRandomConf.mat_color_1[3]
          local MatColor1 = UE4.FVector(R1, G1, B1)
          Blackboard:SetValueAsVector("ColorfulColor1", MatColor1)
          local R2, G2, B2 = ColorRandomConf.mat_color_2[1], ColorRandomConf.mat_color_2[2], ColorRandomConf.mat_color_2[3]
          local MatColor2 = UE4.FVector(R2, G2, B2)
          Blackboard:SetValueAsVector("ColorfulColor2", MatColor2)
          IsSetHatchGlass = true
        end
      elseif 2 == GlassType then
        local HiddenGlassConfID = GlassValue
        local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassConfID)
        if HiddenGlassConf then
          local HatchFxValue = HiddenGlassConf.hatch_fx
          Blackboard:SetValueAsString(HatchFxValue, HatchFxValue)
          IsSetHatchGlass = true
        end
      end
    end
  end
  if not IsSetHatchGlass then
    Blackboard:SetValueAsString("Fx_Normal", "Fx_Normal")
  end
  skillObj:SetTargets({
    self.targetPetModel
  })
  skillObj:SetPassive(true)
  self:SetAnimList(nil, nil)
  self.curAnimInfo = {isPlayAnim = false, curAniLength = 0}
  self._refActorIsolateWorld.RocoSkill:LoadAndPlaySkill(skillObj)
end

function UMG_PetImage3D_C:PlayEggSwitchEffectOnLoadSkill()
  if self.eggSwitchSkillClass and self._refActorIsolateWorld and UE4.UObject.IsValid(self._refActorIsolateWorld) and self._refActorIsolateWorld.RocoSkill then
    self.isPlayEggEffect = true
    local skillObj = self._refActorIsolateWorld.RocoSkill:FindOrAddSkillObj(self.eggSwitchSkillClass)
    skillObj:SetCaster(self._refActorIsolateWorld)
    skillObj:RegisterEventCallback("SwitchEnd", self, self.EndEggSwitch)
    skillObj:RegisterEventCallback("ShowUI", self, self.ShowEggHatchUI)
    skillObj:SetPassive(true)
    self._refActorIsolateWorld.RocoSkill:PlaySkill(skillObj)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, true)
  end
end

function UMG_PetImage3D_C:OnShowOrHidePetModule(isHide)
  self.IsHideModule = isHide
  if isHide then
    self:SetShowOrHidePet(isHide)
  else
    if self.IsEmptyView then
      return
    end
    if self.IsOpenEvoPanel then
      self:SetShowOrHidePet(false)
      local PetLocation = self._startActorLocation
      if self.IsOpenDetails then
        self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(self.OpenPetBagOffest, 0, PetLocation.Z))
      else
        self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(0, 0, PetLocation.Z))
      end
    elseif self.IsPlayShareG6 then
      self:SetShowOrHidePet(false)
    else
      self:SetPath(self.modelPath, self.bSetPathEvo, nil, self.uiPetData, self.NotChangeAnim)
    end
  end
end

function UMG_PetImage3D_C:OnUpdatePetImage3dData(uiPetData)
  if uiPetData and uiPetData.base_conf_id and uiPetData.base_conf_id > 0 then
    local baseConf = _G.DataConfigManager:GetPetbaseConf(uiPetData.base_conf_id)
    local modelConf = _G.DataConfigManager:GetModelConf(baseConf.model_conf)
    self.modelPath = modelConf.path
    self.uiPetData = uiPetData
  end
end

function UMG_PetImage3D_C:OnOpenNewPetBag(isOpen)
  self.IsOpenPetBag = isOpen
end

function UMG_PetImage3D_C:OnPetSkillTipsOpen(isOpen)
  if self.IsOpenPetBag then
    return
  end
  if isOpen then
    self:PlayOpenTwoPanelLevelSequence()
  else
    self:PlayCloseTwoPanelLevelSequence()
  end
end

function UMG_PetImage3D_C:PlayCloseTwoPanelLevelSequenceForced()
  self.PetLevelSequence:SetSequence(self.CloseTwoPanelLevelSequence)
  self:BinSequenceCamera()
  self.PetLevelSequence.SequencePlayer:Play()
  self.IsPlayTwoPanelSequence = false
end

return UMG_PetImage3D_C

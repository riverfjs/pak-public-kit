local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local NRCResourceManagerEnum = require("Core.Service.ResourceManager.NRCResourceManagerEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
require("Common.UE4Extension")
local UMG_PetImage3D_HatchOnly_C = _G.NRCPanelBase:Extend("UMG_PetImage3D_HatchOnly_C")

function UMG_PetImage3D_HatchOnly_C:OnActive(hatchEggData)
  self._refActorIsolateWorld = nil
  self.bPetLoaded = false
  self.loadResRequest = {}
  self.targetPetModel = nil
  self.SkeletalMesh = nil
  self._startActorLocation = nil
  self.isPlayEggEffect = false
  self.isEgg = false
  self.eggModuleScale = nil
  self.eggEffectSkillClass = nil
  self.eggPetBaseID = nil
  self.HatchedPetData = nil
  self.skillCamera = nil
  self.skillCameraMesh = nil
  self.OldModelFxType = nil
  self.MaterialInstance = nil
  self.MaterialInstanceNew = nil
  self.MaterialInstanceNewBottom = nil
  self.BgMeshComp = nil
  self.IsGradient = false
  self.BgDelayStartTime = 0
  self.BgDelayEndTime = 0.4
  self.BgStartTime = 1
  self.BgEndTime = 0
  self.PetBaseConf = nil
  self.PetLocation = UE4.FVector(0, 0, 0)
  self.MainCameraActor = self.PetWorldView:getActorByName("MainCamera")
  if UE.UObject.IsValid(self.MainCameraActor) then
    self.MainCameraTransform = self.MainCameraActor.RootComponent:GetRelativeTransform()
    self.PetWorldView:SetCameraActor(self.MainCameraActor)
  end
  if not self.module then
    self.module = NRCModuleManager:GetModule("PetUIModule")
  end
  local eggConfId = hatchEggData and hatchEggData.eggConfId
  local petBaseId = hatchEggData and hatchEggData.petBaseId
  self.HatchAction = hatchEggData and hatchEggData.Action
  self.HatchBaseInfo = hatchEggData and hatchEggData.baseInfo
  if eggConfId then
    self:SetEggModel(eggConfId, petBaseId)
  end
end

function UMG_PetImage3D_HatchOnly_C:OnDeactive()
  if self.HatchAction then
    self.HatchAction:Finish()
  end
  self:CancelDelay()
  if self.loadResRequest then
    for key, request in pairs(self.loadResRequest) do
      NRCResourceManager:UnLoadRes(request)
      self.loadResRequest[key] = nil
    end
  end
end

function UMG_PetImage3D_HatchOnly_C:OnAddEventListener()
end

function UMG_PetImage3D_HatchOnly_C:SetEggModel(eggConfId, petBaseId)
  if petBaseId then
    self.PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    self.eggPetBaseID = petBaseId
  else
    self.PetBaseConf = nil
    self.eggPetBaseID = nil
  end
  local eggConf = _G.DataConfigManager:GetPetEggConf(eggConfId)
  if not eggConf then
    Log.Error("UMG_PetImage3D_HatchOnly_C:SetEggModel eggConf is nil, eggConfId=%s", tostring(eggConfId))
    return
  end
  local moduleConf = _G.DataConfigManager:GetModelConf(eggConf.model_id)
  if not moduleConf then
    Log.Error("UMG_PetImage3D_HatchOnly_C:SetEggModel moduleConf is nil, model_id=%s", tostring(eggConf.model_id))
    return
  end
  local modulePath = moduleConf.path
  if not modulePath or "" == modulePath then
    Log.Error("UMG_PetImage3D_HatchOnly_C:SetEggModel modulePath is empty, model_id=%s", tostring(eggConf.model_id))
    return
  end
  self.isEgg = true
  self.eggModuleScale = 0.65
  self:SetPath(modulePath)
end

function UMG_PetImage3D_HatchOnly_C:SetPath(modelPath)
  self.modelPath = modelPath
  if self._refActorIsolateWorld then
    if UE4.UObject.IsValid(self._refActorIsolateWorld) then
      self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    end
    self._refActorIsolateWorld = nil
  end
  if self.modelPathLoadReq then
    _G.NRCResourceManager:UnLoadRes(self.modelPathLoadReq)
    self.modelPathLoadReq = nil
  end
  if not modelPath or "" == modelPath then
    return
  end
  self.modelPathLoadReq = self:LoadPanelRes(modelPath, 255, self.PetModelLoadSucceed, nil, nil)
end

function UMG_PetImage3D_HatchOnly_C:PetModelLoadSucceed(resRequest, modelClass)
  if not modelClass then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PetModelLoadSucceed \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", tostring(resRequest))
    return
  end
  if self._refActorIsolateWorld then
    if UE4.UObject.IsValid(self._refActorIsolateWorld) then
      self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
    end
    self._refActorIsolateWorld = nil
  end
  local quat = UE4.FRotator(0, 180, 0):ToQuat()
  if not self.PetLocation then
    self.PetLocation = UE4.FVector(0, 0, 0)
  end
  local fTransform = UE4.FTransform(quat, self.PetLocation, UE4.FVector(1, 1, 1))
  self._refActorIsolateWorld = self.PetWorldView:SpawnActor(modelClass, fTransform)
  if not UE4.UObject.IsValid(self._refActorIsolateWorld) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PetModelLoadSucceed SpawnActor \229\164\177\232\180\165")
    return
  end
  _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Show", self._refActorIsolateWorld)
  self.bPetLoaded = false
  self._refActorIsolateWorld:InitOutSceneAsync(self, self.OnPetLoaded)
  self:SetBagColourByUnitType()
end

function UMG_PetImage3D_HatchOnly_C:OnPetLoaded(actor)
  if not self.PetWorldView then
    return
  end
  if not actor or not UE4.UObject.IsValid(actor) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:OnPetLoaded actor is invalid")
    return
  end
  self.bPetLoaded = true
  actor.IkOverride = false
  local height = actor:GetHalfHeight()
  local PetLocation = UE4.FVector(0, 0, 0)
  PetLocation.Z = PetLocation.Z + height
  actor:Abs_K2_SetActorLocation_WithoutHit(PetLocation)
  local SKMComponent = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  if SKMComponent then
    self.SkeletalMesh = SKMComponent
    SKMComponent:SetForcedLOD(1)
    SKMComponent.bEnableUpdateRateOptimizations = false
    SKMComponent.StreamingDistanceMultiplier = 999
    SKMComponent.bNeverDistanceCull = true
    SKMComponent.bForceMipStreaming = true
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsPlayPetSkill, false)
  if self.isEgg and self.eggModuleScale then
    self:SetModelScale(self.eggModuleScale)
    self:LoadEggEffectAsset()
    self.isPlayEggEffect = true
    if self.eggPetBaseID then
      self:LoadEggToPetModel(self.eggPetBaseID)
    end
  end
end

function UMG_PetImage3D_HatchOnly_C:EndEggEffect()
  self.eggPetBaseID = nil
  if UE4.UObject.IsValid(self._refActorIsolateWorld) then
    self.PetWorldView:DestroyActor(self._refActorIsolateWorld)
  end
  self._refActorIsolateWorld = self.targetPetModel
  _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.EndEggEffect)
end

function UMG_PetImage3D_HatchOnly_C:ShowEggEffectUI()
  if not self.eggPetBaseID then
    Log.Error("UMG_PetImage3D_HatchOnly_C:ShowEggEffectUI eggPetBaseID is nil")
    return
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.eggPetBaseID)
  if not petBaseConf then
    Log.Error("UMG_PetImage3D_HatchOnly_C:ShowEggEffectUI petBaseConf is nil, eggPetBaseID=%s", tostring(self.eggPetBaseID))
    return
  end
  local scale = petBaseConf.petpage_ui_percentage
  local pos = petBaseConf.petpage_capsule_offset
  local petScale = UE4.FVector(scale, scale, scale)
  local petLocation = UE4.FVector(pos[1] or 0, pos[2] or 0, pos[3] or 0)
  if self.targetPetModel and UE4.UObject.IsValid(self.targetPetModel) then
    local height = (self.targetPetModel:GetHalfHeight() + petLocation.Z) * (scale or 1)
    local CurPetLocation = self.targetPetModel:Abs_K2_GetActorLocation()
    local NewPetLocation = UE4.FVector(CurPetLocation.X + petLocation.X, CurPetLocation.Y + petLocation.Y, height)
    self.targetPetModel:Abs_K2_SetActorLocation_WithoutHit(NewPetLocation)
    self.targetPetModel:SetActorScale3D(petScale)
    self._startActorLocation = NewPetLocation
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenEggIncubatePanel, self.eggPetBaseID, nil, nil)
end

function UMG_PetImage3D_HatchOnly_C:UpdateEggEffectUI()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.UpdateEggIncubatePanel)
end

function UMG_PetImage3D_HatchOnly_C:LoadEggEffectAsset()
  local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'"
  local skillClass = self.module:GetRes(skillPath, self.ModuleName)
  if skillClass then
    self.eggEffectSkillClass = skillClass
    return
  end
  self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
    if asset then
      self.eggEffectSkillClass = asset
    else
      Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggEffectAsset \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
    end
  end, nil, nil)
end

function UMG_PetImage3D_HatchOnly_C:LoadEggToPetModel(petBaseId)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  if not petBaseConf then
    Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggToPetModel petBaseConf is nil, petBaseId=%s", tostring(petBaseId))
    return
  end
  local moduleConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  if not moduleConf then
    Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggToPetModel moduleConf is nil, model_conf=%s", tostring(petBaseConf.model_conf))
    return
  end
  local modulePath = moduleConf.path
  if not modulePath or "" == modulePath then
    Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggToPetModel modulePath is empty, petBaseId=%s", tostring(petBaseId))
    return
  end
  Log.Debug("\229\138\160\232\189\189\231\154\132\231\178\190\231\129\181\232\155\139\230\168\161\229\158\139\228\184\186:", modulePath)
  self:LoadPanelRes(modulePath, 255, self.LoadEggToPetModelSucceed, nil, nil)
end

function UMG_PetImage3D_HatchOnly_C:LoadEggToPetModelSucceed(resRequest, birthModel)
  if not birthModel then
    Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggToPetModelSucceed \230\168\161\229\158\139\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", tostring(resRequest))
    return
  end
  local quat = UE4.FRotator(0, 0, 0):ToQuat()
  local trans = UE4.FTransform(quat, UE4.FVector(2000.0, 2000.0, 2000.0), UE4.FVector(1, 1, 1))
  self.targetPetModel = self.PetWorldView:SpawnActor(birthModel, trans)
  if not UE4.UObject.IsValid(self.targetPetModel) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:LoadEggToPetModelSucceed SpawnActor \229\164\177\232\180\165 [%s].", tostring(resRequest))
    return
  end
  _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Show", self.targetPetModel)
  if UE4.UObject.IsValid(self._refActorIsolateWorld) then
    self._refActorIsolateWorld:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
  end
  PetMutationUtils.PrepareMutationAssets(self.targetPetModel, nil)
  self.targetPetModel:InitOutSceneAsync(self, self.OnEggPetLoaded)
end

function UMG_PetImage3D_HatchOnly_C:OnEggPetLoaded(actor)
  if not actor or not UE4.UObject.IsValid(actor) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:OnEggPetLoaded actor is invalid")
    return
  end
  actor.IkOverride = false
  actor:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(2000, 2000, 2000))
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  if mesh then
    mesh:SetForcedLOD(1)
    mesh.bEnableUpdateRateOptimizations = false
    mesh.StreamingDistanceMultiplier = 999
    mesh.bNeverDistanceCull = true
    mesh.bForceMipStreaming = true
  end
  self.targetPetModel = actor
  if self.eggPetBaseID then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.eggPetBaseID)
    if petBaseConf then
      local modelScale = petBaseConf.petpage_ui_percentage and petBaseConf.petpage_ui_percentage > 0 and petBaseConf.petpage_ui_percentage or 1
      actor:SetActorScale3D(UE4.FVector(modelScale, modelScale, modelScale))
    end
  end
  if self.eggEffectSkillClass then
    self:PlayEggEffectOnLoadSkill()
  else
    local skillPath = "SkillBlueprint'/Game/ArtRes/Effects/G6Skill/UI/Hatched/G6_UI_PetHatched.G6_UI_PetHatched_C'"
    self:LoadPanelRes(skillPath, 255, function(caller, resRequest, asset)
      if asset then
        self.eggEffectSkillClass = asset
        self:PlayEggEffectOnLoadSkill()
      else
        Log.Error("UMG_PetImage3D_HatchOnly_C:OnEggPetLoaded \230\138\128\232\131\189\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", skillPath or "")
      end
    end, nil, nil)
  end
end

function UMG_PetImage3D_HatchOnly_C:OnFinishEggCamera()
  self.skillCamera = nil
  self.skillCameraMesh = nil
  if self.MainCameraActor and UE.UObject.IsValid(self.MainCameraActor) and self.MainCameraTransform then
    self.MainCameraActor.RootComponent:K2_SetRelativeTransform(self.MainCameraTransform, false, nil, false)
  end
end

function UMG_PetImage3D_HatchOnly_C:PlayEggEffectOnLoadSkill()
  if not self.eggEffectSkillClass then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PlayEggEffectOnLoadSkill eggEffectSkillClass is nil")
    return
  end
  if not self.targetPetModel or not UE4.UObject.IsValid(self.targetPetModel) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PlayEggEffectOnLoadSkill targetPetModel is invalid")
    return
  end
  if not self._refActorIsolateWorld or not UE4.UObject.IsValid(self._refActorIsolateWorld) then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PlayEggEffectOnLoadSkill _refActorIsolateWorld is invalid")
    return
  end
  if not self._refActorIsolateWorld.RocoSkill then
    Log.Error("UMG_PetImage3D_HatchOnly_C:PlayEggEffectOnLoadSkill RocoSkill is nil")
    return
  end
  local skillObj = self._refActorIsolateWorld.RocoSkill:FindOrAddSkillObj(self.eggEffectSkillClass)
  skillObj:SetCaster(self._refActorIsolateWorld)
  skillObj:RegisterEventCallback("SetCamera", self, self.SetSkillCamera1)
  skillObj:RegisterEventCallback("RemoveCamera", self, self.OnFinishEggCamera)
  skillObj:RegisterEventCallback("OpenEggPanel", self, self.ShowEggEffectUI)
  skillObj:RegisterEventCallback("ShowEggPanelText", self, self.UpdateEggEffectUI)
  skillObj:RegisterEventCallback("OpenLight_1", self, self.OpenLight_1)
  skillObj:RegisterEventCallback("OpenLight_2", self, self.OpenLight_2)
  skillObj:RegisterEventCallback("EggPerEnd", self, self.EndEggEffect)
  local Blackboard = skillObj:GetBlackboard()
  Blackboard:SetValueAsString("Fx_Normal", "Fx_Normal")
  skillObj:SetTargets({
    self.targetPetModel
  })
  skillObj:SetPassive(true)
  self._refActorIsolateWorld.RocoSkill:LoadAndPlaySkill(skillObj)
end

function UMG_PetImage3D_HatchOnly_C:OnTick(InDeltaTime)
  if not self.skillCamera then
    return
  end
  if not self.isPlayEggEffect then
    return
  end
  if UE.UObject.IsValid(self.skillCamera) then
    self.skillCamVec = self.skillCamera:Abs_GetTransform()
  end
  if UE.UObject.IsValid(self.MainCameraActor) then
    self.MainCameraActor:Abs_K2_SetActorTransform_WithoutHit(self.skillCamVec)
  end
end

function UMG_PetImage3D_HatchOnly_C:SetSkillCamera1(Event, Skill)
  self.skillCamera = Skill:GetBlackboard():GetValueAsObject("camActor_0001")
  self.skillCameraMesh = Skill:GetBlackboard():GetValueAsObject("camActor_0001_SA")
end

function UMG_PetImage3D_HatchOnly_C:ChangeLight_1(bStart)
  local DarkVolumeBP = self.PetWorldView:getActorByName("BP_DarkVolume_3")
  if not UE4.UObject.IsValid(DarkVolumeBP) then
    return
  end
  if bStart then
    DarkVolumeBP:Start()
  else
    DarkVolumeBP:End()
  end
end

function UMG_PetImage3D_HatchOnly_C:ChangeLight_2(bStart)
  local DarkVolumeBP = self.PetWorldView:getActorByName("BP_DarkVolumeSpotLight_2")
  if not UE4.UObject.IsValid(DarkVolumeBP) then
    return
  end
  if bStart then
    DarkVolumeBP:StartSpotLight()
  else
    DarkVolumeBP:EndSpotLight()
  end
end

function UMG_PetImage3D_HatchOnly_C:OpenLight_1()
  self:ChangeLight_1(true)
end

function UMG_PetImage3D_HatchOnly_C:OpenLight_2()
  self:ChangeLight_2(true)
  self:SetBagColourByUnitType()
  self:SetSpotLightColorByUnitType()
end

function UMG_PetImage3D_HatchOnly_C:CloseAllLight()
  self:ChangeLight_2(false)
  self:ChangeLight_1(false)
end

function UMG_PetImage3D_HatchOnly_C:SetSpotLightColorByUnitType()
  if not self.PetWorldView then
    return
  end
  if not self.PetBaseConf then
    return
  end
  local unitType = self.PetBaseConf.unit_type
  if not unitType or not unitType[1] then
    return
  end
  local modelFxType = unitType[1]
  if modelFxType < Enum.SkillDamType.SDT_COMMON then
    modelFxType = Enum.SkillDamType.SDT_COMMON
  end
  local skillColorConf = _G.DataConfigManager:GetSkillColorConf(modelFxType)
  if not skillColorConf then
    return
  end
  local colorStr = skillColorConf.perform_light_colour
  local color = UE4.UNRCStatics.HexToLinearColor(colorStr)
  local SpotLight = self.PetWorldView:getActorByName("BP_DarkVolumeSpotLight_2")
  if UE4.UObject.IsValid(SpotLight) then
    SpotLight:SetMaterialColor(color)
  end
end

function UMG_PetImage3D_HatchOnly_C:SetBagColourByUnitType()
  if not self.PetWorldView then
    return
  end
  self.BackgroundPlate = self.PetWorldView:getActorByName("TestBg_2")
  local modelFxType = Enum.SkillDamType.SDT_NONE
  if self.PetBaseConf then
    local unitType = self.PetBaseConf.unit_type
    if unitType and unitType[1] then
      modelFxType = unitType[1]
      if modelFxType < Enum.SkillDamType.SDT_COMMON then
        modelFxType = Enum.SkillDamType.SDT_COMMON
      end
    end
  end
  if self.OldModelFxType == modelFxType then
    return
  end
  local skillColorConf = _G.DataConfigManager:GetSkillColorConf(modelFxType)
  if not skillColorConf then
    Log.Debug("UMG_PetImage3D_HatchOnly_C:SetBagColourByUnitType, skillColorConf is nil, return")
    return
  end
  local Path = skillColorConf.JL_background_colour
  self.Path_1 = skillColorConf.JL_background_clear
  self.OldModelFxType = modelFxType
  if Path then
    self:LoadPanelRes(Path, 255, self.OnLoadBackgroundColorSucc, self.OnLoadBackgroundClearFailed, nil)
  else
    self:OnLoadBackgroundClearFailed()
  end
end

function UMG_PetImage3D_HatchOnly_C:OnLoadBackgroundColorSucc(resRequest, mat_bj)
  self.mat_bj = mat_bj
  self:LoadPanelRes(self.Path_1, 255, self.OnLoadBackgroundClearSucc, self.OnLoadBackgroundClearFailed, nil)
end

function UMG_PetImage3D_HatchOnly_C:OnLoadBackgroundClearSucc(resRequest, mat_bj_1)
  if not mat_bj_1 then
    self:LogError("\230\179\168\230\132\143\239\188\140\229\138\160\232\189\189\232\181\132\230\186\144\229\164\177\232\180\165:", self.Path_1)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsFirstLoadBackground, false)
    self.mat_bj = nil
    self.Path_1 = nil
    return
  end
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

function UMG_PetImage3D_HatchOnly_C:OnLoadBackgroundClearFailed(resRequest, mat_bj_1)
  Log.Error("\231\178\190\231\129\181\232\131\140\230\153\175\229\138\160\232\189\189\229\164\177\232\180\165\228\186\134\239\188\140\228\189\134\230\152\175\232\191\152\230\152\175\229\133\129\232\174\184\230\137\147\229\188\128\231\149\140\233\157\162\239\188\140UMG_PetImage3D_HatchOnly_C:OnLoadBackgroundClearFailed")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetIsFirstLoadBackground, false)
  self.mat_bj = nil
  self.Path_1 = nil
end

function UMG_PetImage3D_HatchOnly_C:SetModelScale(_scale)
  self.Scale = _scale or 1
  local scale = _scale or 1
  if not UE4.UObject.IsValid(self._refActorIsolateWorld) then
    return
  end
  self._refActorIsolateWorld:SetActorScale3D(UE4.FVector(scale, scale, scale))
  local height = (self._refActorIsolateWorld:GetHalfHeight() or 0) * scale
  local PetLocation = UE4.FVector(0, 0, 0)
  PetLocation.Z = PetLocation.Z + height
  self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(PetLocation)
  self._startActorLocation = PetLocation
end

return UMG_PetImage3D_HatchOnly_C

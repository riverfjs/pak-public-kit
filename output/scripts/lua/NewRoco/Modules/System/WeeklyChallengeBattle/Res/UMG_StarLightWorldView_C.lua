local UMG_StarLightWorldView_C = _G.NRCViewBase:Extend("UMG_StarLightWorldView_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local Clamp = math.clamp
local JsonUtils = require("Common.JsonUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local WeeklyChallengeBattleModuleEnum = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEnum")

function UMG_StarLightWorldView_C:OnConstruct()
  self.Overridden.Construct(self)
  self:InitDataStructure()
  self:AddEventListener()
  self:InitUI()
end

function UMG_StarLightWorldView_C:InitDataStructure()
  self.petList = {}
  self.slotActors = {}
  self.isFirstRun = true
  self.PetAnim = {}
  self.petFullIDData = {}
  self.petAnimFrame = {}
  self.PetBody = {}
  self.PetAnimLengthMap = {}
  self.petPosInfo = {}
  self.petHalfHeight = {}
  self.PetRealPos = {}
  self.PetNumberUIScreenPos = {}
  self.PetNumberUIViewportPos = {}
  self.petDataInfoList = {}
  self.petMutationDatas = {}
  self.petMonsterIDs = {}
  self.PhotoMode = WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtFirstFrame
  self.TakePhotoAnimSpeed = DataConfigManager:GetChallengeGlobalConf(3).num / 10000
  self.hasLoadedCount = 0
  self.State = false
  self.LoadJsonPath = "PhotoEditorJson"
  self.EnvSpotLightActorList = {}
end

function UMG_StarLightWorldView_C:AddEventListener()
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamTouchStarted, self.OnPetTeamTouchStarted)
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamTouchMoved, self.OnPetTeamTouchMoved)
  self:RegisterEvent(self, PetUIModuleEvent.PetTeamTouchEnded, self.OnPetTeamTouchEnded)
  NRCEventCenter:RegisterEvent("UMG_StarLightWorldView", self, PetUIModuleEvent.StarLightPlayerPlayAnimAtFrame, self.InitPlayerPlayAnimAtFrame)
  NRCEventCenter:RegisterEvent("UMG_StarLightWorldView", self, PetUIModuleEvent.StarLightPetItemTouchStarted, self.StarLightPetItemTouchStarted)
  NRCEventCenter:RegisterEvent("UMG_StarLightWorldView", self, WeeklyChallengeBattleModuleEvent.OnReleaseDragItem, self.OnReleaseDragItem)
end

function UMG_StarLightWorldView_C:InitUI()
  self:InitCamera()
  self:InitSlots()
  self:LoadFileFromJson()
  self:InitSceneCapture()
  self:LoadSelectSkill()
  self:LoadCurtainAnim()
end

function UMG_StarLightWorldView_C:InitCamera()
  self.CameraActor = self.previewWorld:getActorByName("MainCamera")
end

function UMG_StarLightWorldView_C:LoadSelectSkill()
  local assetPath = "/Game/ArtRes/Effects/G6Skill/UI/Team/G6_UI_PVPTeamShow.G6_UI_PVPTeamShow_C"
  self:LoadPanelRes(assetPath, 255, self.OnSkill1LoadSucc)
  assetPath = "/Game/ArtRes/Effects/G6Skill/UI/Team/G6_UI_PVPTeamLoop.G6_UI_PVPTeamLoop_C"
  self:LoadPanelRes(assetPath, 255, self.OnSkill2LoadSucc)
end

function UMG_StarLightWorldView_C:OnSkill1LoadSucc(resRequest, skillClass)
  self.skillClass = skillClass
  self.skillClassRef = skillClass and UnLua.Ref(skillClass)
  if self.IsWaitingSkillLoad then
    self:SetTeamData(self.teamData)
    self.IsWaitingSkillLoad = false
  end
end

function UMG_StarLightWorldView_C:OnSkill2LoadSucc(resRequest, particleObj)
  self.particleObject = particleObj
  self.particleObjectRef = particleObj and UnLua.Ref(particleObj)
end

function UMG_StarLightWorldView_C:LoadCurtainAnim()
  local animPath = "/Game/ArtRes/Asset/Environment/Interator/Curtain/Animation/World_Loop_2.World_Loop_2"
  if self:IsLoadedResByPath(animPath) then
    self.CurtainAnimAsset = self:TryGetLoadedResByPath(animPath)
  else
    self:LoadPanelRes(animPath, 255, self.OnCurtainAnimLoadSucc)
  end
end

function UMG_StarLightWorldView_C:OnCurtainAnimLoadSucc(resRequest, animAsset)
  self.CurtainAnimAsset = animAsset
  self.CurtainAnimAssetRef = UnLua.Ref(animAsset)
end

function UMG_StarLightWorldView_C:InitSlots()
  local slotActors = self.slotActors
  for i = 1, 6 do
    local slotActor = self.previewWorld:getActorByName("Slot_" .. i)
    if slotActor then
      slotActors[#slotActors + 1] = slotActor
      local meshComponent = slotActors[i]:GetComponentByClass(UE4.UStaticMeshComponent)
      meshComponent:SetMobility(UE4.EComponentMobility.Movable)
    end
  end
  self.Slot_NPC = self.previewWorld:getActorByName("Slot_NPC")
  local meshComponent = self.Slot_NPC:GetComponentByClass(UE4.UStaticMeshComponent)
  meshComponent:SetMobility(UE4.EComponentMobility.Movable)
  self.slotActors[7] = self.Slot_NPC
  self.BGAsset = self.previewWorld:getActorByName("SM_Curtain_001_01_2")
  self:StopCurtainAnim()
  for i = 1, 6 do
    self.EnvSpotLightActorList[i] = self.previewWorld:getActorByName("EnvSpotLightActor_" .. i)
  end
end

function UMG_StarLightWorldView_C:UpdatePetModel(petFullIDData, ShowSkillPetIndexList)
  if not petFullIDData then
    return
  end
  self:HideCaptureImage()
  self.petFullIDData = petFullIDData
  self:UpdateNumberUIVisibility()
  self:UpdateSlotActors(ShowSkillPetIndexList, false)
end

function UMG_StarLightWorldView_C:HideCaptureImage()
  self.captureImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_StarLightWorldView_C:UpdateAnimPercentList(animPercentList)
  if animPercentList then
    for i, animPercent in pairs(animPercentList) do
      if 7 == i then
        self.NPCAnimFrame = animPercent
      else
        self.petAnimFrame[i] = animPercent
      end
    end
  else
    Log.Error("UMG_StarLightWorldView_C animPercentList is nil")
  end
end

function UMG_StarLightWorldView_C:ForceContinue()
  if self.isFirstRun then
    self.isFirstRun = false
  end
end

function UMG_StarLightWorldView_C:PlayShowAnim()
  if #self.petList > 0 then
    for slotId, petItem in ipairs(self.petList) do
      if petItem.actor then
        self:PlayShowSkill(petItem.actor, slotId)
        if self.Parent then
          self.Parent:ShowSlotInfoTag(slotId)
        end
        if slotId == #self.petList and self.Parent then
          self.Parent:SetPanelHitTestVisible(true)
        end
      end
    end
  elseif self.Parent then
    self.Parent:SetPanelHitTestVisible(true)
  end
end

local _iSelected = false

function UMG_StarLightWorldView_C:OnPetTeamTouchStarted(slotId, screenPosition)
  if self:IsSlotEmpty(slotId) then
    _iSelected = false
    return
  end
  _iSelected = true
  self.startPos = screenPosition
  self.curActor = self.petList[slotId].actor
  self.curSlot = slotId
  self.startLocation = self.curActor:ABS_K2_GetActorLocation()
  self.startLocation.Z = self.startLocation.Z + 20
  self.curActor:Abs_K2_SetActorLocation_WithoutHit(self.startLocation)
  self:PlayTouchSkill()
  self:ShowDragIndicator(true)
  self:CalTouchData()
end

function UMG_StarLightWorldView_C:CalTouchData()
  local pet1Pos = self.slotActors[1]:ABS_K2_GetActorLocation()
  local pet6Pos = self.slotActors[6]:ABS_K2_GetActorLocation()
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local ProjMat = UE4.FMatrix()
  UE4.UNRCStatics.CalculateViewProjectionMatrix(self.cameraComponent, ProjMat)
  local Pro1Pos = UE4.UNRCStatics.Abs_ProjectWorldToScreenHiddenWithViewportPos(pet1Pos, viewportSize.X, viewportSize.Y, ProjMat)
  local Pro6Pos = UE4.UNRCStatics.Abs_ProjectWorldToScreenHiddenWithViewportPos(pet6Pos, viewportSize.X, viewportSize.Y, ProjMat)
  Pro1Pos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), Pro1Pos)
  Pro6Pos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(self:GetCachedGeometry(), Pro6Pos)
  self.unitValue = (pet6Pos.Y - pet1Pos.Y) / (Pro6Pos.X - Pro1Pos.X)
  self.leftValue = pet1Pos.Y - Pro1Pos.X * self.unitValue
  self.slot1Pos = self.slotActors[1]:ABS_K2_GetActorLocation()
  self.curMaxPosX = 100000000
  for index = 1, #self.slotActors do
    local pos = self.slotActors[index]:ABS_K2_GetActorLocation()
    self.curMaxPosX = math.min(pos.X, self.curMaxPosX)
  end
end

local newLocation = UE4.FVector(0, 0, 0)

function UMG_StarLightWorldView_C:OnPetTeamTouchMoved(screenPosition)
  if false == _iSelected then
    return
  end
  if self.curActor then
    newLocation.X = self.curMaxPosX - 70
    newLocation.Z = self.startLocation.Z
    newLocation.Y = screenPosition.X * self.unitValue + self.leftValue
    self.curActor:Abs_K2_SetActorLocation_WithoutHit(newLocation)
  end
end

function UMG_StarLightWorldView_C:OnPetTeamTouchEnded(slotId)
  if false == _iSelected then
    return
  end
  self:StopTouchSkill()
  local finalSlot = slotId
  if self:IsSlotEmpty(finalSlot) then
    finalSlot = self.curSlot
  end
  self:SwapSlot(self.curSlot, finalSlot)
  self:ShowDragIndicator(false)
  if finalSlot ~= self.curSlot then
    self:ChangeTeam()
  end
  _iSelected = false
end

function UMG_StarLightWorldView_C:PlayTouchSkill()
  if not self.particleObject then
    return
  end
  local caster = self.curActor
  if caster then
    caster.RocoSkill:ClearAllPassiveSkillObjs()
    local skillObj = caster.RocoSkill:FindOrAddSkillObj(self.particleObject)
    skillObj:SetCaster(caster)
    skillObj:SetPassive(true)
    self.TouchSkillBlackboard = skillObj:GetBlackboard()
    self.TouchSkillBlackboard:SetValueAsBool("TouchLoop", true)
    caster.RocoSkill:LoadAndPlaySkill(skillObj)
  end
end

function UMG_StarLightWorldView_C:StopTouchSkill()
  if self.TouchSkillBlackboard then
    self.TouchSkillBlackboard:SetValueAsBool("TouchLoop", false)
    self.TouchSkillBlackboard = nil
  end
end

function UMG_StarLightWorldView_C:ChangeTeam()
  local teamInfo = self.module:GetPetTeamUITeamInfo(self.curTeamType)
  local changeTeam = teamInfo.teams[self.teamIdx + 1]
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ChangePetTeamInfo, changeTeam.pet_infos, self.teamIdx, self.module.data.OpenTeamType)
  if self.Parent then
    self.Parent:RefreshTeamInfo()
  end
end

function UMG_StarLightWorldView_C:IsSlotEmpty(slotId)
  if self.teamPetGids == nil then
    return true
  end
  return slotId > #self.teamPetGids
end

function UMG_StarLightWorldView_C:SwapSlot(a, b)
  local ALocation, ARotation, BLocation, BRotation
  if a == b then
    self.petList[a].actor:Abs_K2_SetActorLocation_WithoutHit(self.slotActors[a]:Abs_K2_GetActorLocation())
    self.petList[a].actor:K2_SetActorRotation(self.slotActors[a]:K2_GetActorRotation(), false)
    self:RecalcActorLocation(self.petList[a].actor)
    return
  end
  self.petList[a].actor:Abs_K2_SetActorLocation_WithoutHit(self.slotActors[b]:Abs_K2_GetActorLocation())
  self.petList[a].actor:K2_SetActorRotation(self.slotActors[b]:K2_GetActorRotation(), false)
  self.petList[b].actor:Abs_K2_SetActorLocation_WithoutHit(self.slotActors[a]:Abs_K2_GetActorLocation())
  self.petList[b].actor:K2_SetActorRotation(self.slotActors[a]:K2_GetActorRotation(), false)
  self:RecalcActorLocation(self.petList[a].actor)
  self:RecalcActorLocation(self.petList[b].actor)
  local tempPet = self.petList[b]
  self.petList[b] = self.petList[a]
  self.petList[a] = tempPet
  local t_gid = self.teamPetGids[b]
  self.teamPetGids[b] = self.teamPetGids[a]
  self.teamPetGids[a] = t_gid
end

function UMG_StarLightWorldView_C:GetFinalSlot(newLocation)
  local slotActors = self.slotActors
  local miniDistance = 9999999
  local finalSlot
  for index, slotActor in ipairs(slotActors) do
    local slotActorLoc = slotActor:ABS_K2_GetActorLocation()
    local distance = newLocation:Dist(slotActorLoc)
    if miniDistance > distance then
      miniDistance = distance
      finalSlot = index
    end
  end
  return finalSlot
end

function UMG_StarLightWorldView_C:OnDestruct()
  self.Overridden.Destruct(self)
  self:CancelDelay()
  if self.captureDelayId then
    _G.DelayManager:CancelDelayById(self.captureDelayId)
    self.captureDelayId = nil
  end
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamTouchStarted, self.OnPetTeamTouchStarted)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamTouchMoved, self.OnPetTeamTouchMoved)
  self:UnRegisterEvent(self, PetUIModuleEvent.PetTeamTouchEnded, self.OnPetTeamTouchEnded)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.StarLightPlayerPlayAnimAtFrame, self.InitPlayerPlayAnimAtFrame)
  NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.StarLightPetItemTouchStarted, self.StarLightPetItemTouchStarted)
  NRCEventCenter:UnRegisterEvent(self, WeeklyChallengeBattleModuleEvent.OnReleaseDragItem, self.OnReleaseDragItem)
  self:DestoryAllActors()
  self.captureComponent = nil
  self.UpdateCamera = nil
  self.TargetLocation = nil
  self.Parent = nil
  self.focusSlotId = nil
  self.tempPet = nil
  self.isBack = nil
  self.slotActors = nil
  self.petList = nil
  self.skillClass = nil
  if UE.UObject.IsValid(self.skillClassRef) and self.skillClassRef then
    UnLua.Unref(self.skillClassRef)
  end
  self.skillClassRef = nil
  self.curSelPetData = nil
  self.particleObject = nil
  if UE.UObject.IsValid(self.particleObjectRef) and self.particleObjectRef then
    UnLua.Unref(self.particleObjectRef)
  end
  if self.bgRequest then
    _G.NRCResourceManager:UnLoadRes(self.bgRequest)
    self.bgRequest = nil
  end
  self.particleObjectRef = nil
  if UE.UObject.IsValid(self.CurtainAnimAssetRef) and self.CurtainAnimAssetRef then
    UnLua.Unref(self.CurtainAnimAssetRef)
  end
  self.CurtainAnimAssetRef = nil
  self.CurtainAnimAsset = nil
  if self.PetNumberUIItem then
    for i, item in pairs(self.PetNumberUIItem) do
      if item then
        item:RemoveFromParent()
      end
    end
  end
end

function UMG_StarLightWorldView_C:OnTick(deltaTime)
end

function UMG_StarLightWorldView_C:OnReleaseDragItem(index)
  local PetNumberUIItem = self:GetCurrModePetNumberUIItem(index)
  PetNumberUIItem:StopAllAnimations()
  PetNumberUIItem:PlayAnimation(PetNumberUIItem.unselect)
end

function UMG_StarLightWorldView_C:VInterpTo(Current, Target, DeltaTime, Speed)
  if Speed <= 0 then
    return Target, true
  end
  local dist = Target - Current
  if dist:SizeSquared2D() <= 1 then
    return Target, true
  end
  local delta = dist * Clamp(DeltaTime * Speed, 0.0, 1.0)
  return Current + delta, false
end

function UMG_StarLightWorldView_C:FInterpTo(Current, Target, DeltaTime, InterpSpeed)
  if InterpSpeed <= 0 then
    return Target, true
  end
  if nil == Current then
    Current = 0
  end
  local Dist = Target - Current
  if Dist * Dist < 0.001 then
    return Target, true
  end
  local DeltaMove = Dist * Clamp(DeltaTime * InterpSpeed, 0.0, 1.0)
  return Current + DeltaMove, false
end

function UMG_StarLightWorldView_C:ShowDragIndicator(isShow)
  if self.Parent then
    self.Parent:ShowDragIndicator(isShow)
  end
end

function UMG_StarLightWorldView_C:InitCaptureRT()
  local rt = self.captureComponent and self.captureComponent.TextureTarget
  if not rt then
    return
  end
  local vpSize = UE4.UWidgetLayoutLibrary.GetViewportSize(self)
  local vw, vh = vpSize.X, vpSize.Y
  local ratio = 2.1666666666666665
  local w, h
  if ratio <= vw / vh then
    h = vh
    w = vh * ratio
  else
    w = vw
    h = vw / ratio
  end
  UE4.UNRCStatics.ChangeTextureToCustomSize(rt, math.floor(w), math.floor(h))
end

function UMG_StarLightWorldView_C:InitSceneCapture()
  local MainCamera = self.previewWorld:getActorByName("MainCamera")
  if not MainCamera then
    return
  end
  self.CameraActor = MainCamera
  self.cameraComponent = MainCamera:GetComponentByClass(UE4.UCameraComponent)
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local aspectRatio = viewportSize.X / viewportSize.Y
  self.cameraComponent.AspectRatio = aspectRatio
  self:InitCaptureRT()
  local viewInfo = self.cameraComponent:GetCameraView(0)
end

function UMG_StarLightWorldView_C:UpdateSlotActors(ShowSkillPetIndexList, IsInNPCMode)
  self.IsInNPCMode = IsInNPCMode
  local bPlayedSound = false
  local petFullIDData = self.petFullIDData
  self.PetCount = 0
  self.hasLoadedCount = 0
  self.pendingLoadCount = 0
  local slotActors = self.slotActors
  for i = 1, #slotActors do
    if petFullIDData[i] and 0 ~= petFullIDData[i].petID then
      if self.petList[i] == nil then
        self.petList[i] = {}
      end
      self.PetCount = self.PetCount + 1
      local showPlayStartSkill = false
      if ShowSkillPetIndexList then
        for j, petIndex in ipairs(ShowSkillPetIndexList) do
          if petIndex == i then
            showPlayStartSkill = true
            break
          end
        end
      end
      local IsRepeated = false
      if self.oldPetFullIDData and self.oldPetFullIDData[i] and self.oldPetFullIDData[i].petGID == petFullIDData[i].petGID then
        IsRepeated = true
      end
      if false == IsRepeated then
        if self.petList[i].actor then
          self:DestroyActor(self.petList[i].actor)
        end
        self.pendingLoadCount = self.pendingLoadCount + 1
        self.petList[i].actor = self:AddPetToScene(petFullIDData[i].petID, slotActors[i], i, petFullIDData[i].petGID, showPlayStartSkill, bPlayedSound)
        if not bPlayedSound then
          bPlayedSound = true
        end
      else
        local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petFullIDData[i].petID)
        self.petHalfHeight[i] = self:GetModelHalfHeight(petbaseConf.model_conf, petFullIDData[i].petGID)
        local newTransform = self:RecalcActorRealLocation(i)
        self.petList[i].actor:K2_SetActorLocation(newTransform.Translation, false, nil, false)
        self.petList[i].actor:K2_SetActorRotation(newTransform.Rotation:ToRotator(), false)
        local petAnim = self:CheckIsSky(i, self.petList[i].actor)
        if self.PhotoMode == WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent then
          self.petList[i].actor:PlayAnimByNameUsePercent(petAnim, 0, (self.petAnimFrame[i] or 0) / 1000, 0, 0, -1, 0)
        else
          self.petList[i].actor:PlayAnimByNameUsePercent(petAnim, 0, 0, 0, 0, -1, 0)
        end
        self.hasLoadedCount = self.hasLoadedCount + 1
      end
    elseif (nil == petFullIDData[i] or 0 == petFullIDData[i].petGID) and self.petList[i] then
      self:DestroyActor(self.petList[i].actor)
      self.petList[i] = nil
    end
  end
  self.oldPetFullIDData = table.deepCopy(self.petFullIDData)
  self:CheckAllPetLoaded()
end

function UMG_StarLightWorldView_C:CheckAllPetLoaded()
  if self.hasLoadedCount >= self.PetCount + 1 then
    Log.Error("[UMG_StarLightWorldView_C] CheckAllPetLoaded: \229\133\168\233\131\168\228\186\186\231\137\169\229\146\140\231\178\190\231\129\181\229\138\160\232\189\189\229\174\140\230\175\149")
    if self and self.Parent then
      self.Parent:SetHasLoadedAllPet()
      local delayTime = self:GetCaptureDelayByDeviceLevel()
      self.captureDelayId = DelayManager:DelaySeconds(delayTime, function()
        self.captureDelayId = nil
        if self and self.Parent then
          self.Parent.CaptureImageOnce = true
        end
      end)
    end
  end
end

function UMG_StarLightWorldView_C:GetCaptureDelayByDeviceLevel()
  local deviceLevel = UE4.UNRCQualityLibrary.GetDeviceLevel()
  if deviceLevel <= 2 then
    return 1.5
  elseif 3 == deviceLevel then
    return 1.2
  elseif 4 == deviceLevel then
    return 1.0
  else
    return 0.8
  end
end

function UMG_StarLightWorldView_C:SetPhotoMode(PhotoMode)
  self.PhotoMode = PhotoMode
end

function UMG_StarLightWorldView_C:DestroyActor(actor)
  self.previewWorld:DestroyActor(actor)
end

function UMG_StarLightWorldView_C:CreateNPC(NPCID, stopFrame)
  if UE.UObject.IsValid(self.NPCActor) then
    self.NPCActor:SetActorHiddenInGame(false)
    if self.PlayerActor then
      self.PlayerActor:SetActorHiddenInGame(true)
    end
    return
  elseif self.PlayerActor then
    self.PlayerActor:SetActorHiddenInGame(true)
  end
  local NpcConf = _G.DataConfigManager:GetNpcConf(NPCID)
  self.NPCID = NPCID
  if not NPCID then
    Log.Error("\232\175\165\230\136\152\230\150\151\230\178\161\230\156\137NPC")
  end
  local modelCfgID = NpcConf.model_conf
  local modelCfg = _G.DataConfigManager:GetModelConf(modelCfgID)
  local modelClass = UE4.UClass.Load(modelCfg.path)
  if not modelClass then
    Log.ErrorFormat("UMG_PetTeamImage_C:AddPetToScene \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", modelCfg.path or "")
  end
  self.petHalfHeight[7] = self:GetModelHalfHeight(modelCfgID)
  local newTransform = self:RecalcActorRealLocation(7)
  local transform = self.slotActors[7]:GetTransform()
  local actor = self.previewWorld:SpawnActor(modelClass, newTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  actor:InitOutSceneAsync(nil, function(actor)
    self:OnActorLoaded(actor, 7)
  end)
  actor:SetIKEnable(false)
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  actor.CharacterMovement.GravityScale = 0
  self.NPCActor = actor
  mesh.bForceMipStreaming = true
  mesh:SetForcedLOD(1)
  if mesh.SkeletalMesh then
    UE4.UNRCStatics.ForceUpdateStreamingAssets(mesh.SkeletalMesh, 30)
  end
  mesh:SetSimulatePhysics(false)
  mesh:SetEnableGravity(false)
end

function UMG_StarLightWorldView_C:OnActorLoaded(actor, index, showPlayStartSkill, bPlayedSound)
  if not actor then
    Log.Error("UMG_StarLightWorldView_C:OnActorLoaded actor is nil")
    return
  end
  actor.mesh:SetForcedLOD(1)
  if actor.mesh.SkeletalMesh then
    UE4.UNRCStatics.ForceUpdateStreamingAssets(actor.mesh.SkeletalMesh, 30)
  end
  actor.IkOverride = false
  actor:SetSelfControlSignificance(true, UE.ESignificanceValue.Highest)
  if 7 ~= index then
    PetMutationUtils.DoMutation(actor, self.petMutationDatas[index])
  end
  local petAnim = self:CheckIsSky(index, actor)
  if self.PhotoMode == WeeklyChallengeBattleModuleEnum.PhotoMode.PlayAtStart then
    if 7 ~= index then
      actor:PlayAnimByNameUsePercent(petAnim or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
    else
      actor:PlayAnimByNameUsePercent(self.NPCAnim or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
    end
  elseif self.PhotoMode == WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtPercent then
    if 7 ~= index then
      actor:PlayAnimByNameUsePercent(petAnim or "Idle", 1.0E-6, (self.petAnimFrame[index] or 0) / 1000, 0, 0, -1, 0)
    else
      actor:PlayAnimByNameUsePercent(self.NPCAnim or "Idle", 1.0E-6, (self.NPCAnimFrame or 0) / 1000 or 0, 0, 0, -1, 0)
    end
  elseif self.PhotoMode == WeeklyChallengeBattleModuleEnum.PhotoMode.StopAtFirstFrame then
    if 7 ~= index then
      actor:PlayAnimByNameUsePercent(petAnim or "Idle", 1.0E-6, 0, 0, 0, -1, 0)
    else
      actor:PlayAnimByNameUsePercent(self.NPCAnim or "Idle", 1.0E-6, 0, 0, 0, -1, 0)
    end
  end
  if showPlayStartSkill then
    if not bPlayedSound then
      _G.NRCAudioManager:PlaySound2DAuto(1352, "UMG_StarLightWorldView_C:OnActorLoaded")
    end
    self:PlayShowSkill(actor)
  end
  self.hasLoadedCount = self.hasLoadedCount + 1
  self:CheckAllPetLoaded()
  self:CalcuPetNumberUIPos(actor, index)
  self:ShowNumberUI(index)
end

function UMG_StarLightWorldView_C:CalcuPetNumberUIPos(actor, index)
  if index > 6 then
    return
  end
  local hasPet = true
  if not actor then
    if self.petList[index] and self.petList[index].actor then
      actor = self.petList[index].actor
    elseif self.slotActors[index] then
      hasPet = false
      actor = self.slotActors[index]
    else
      return
    end
  end
  local petWorldPos = actor:ABS_K2_GetActorLocation()
  if false == hasPet then
    petWorldPos.Z = petWorldPos.Z + 60
  end
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local ProjMat = UE4.FMatrix()
  UE4.UNRCStatics.CalculateViewProjectionMatrix(self.cameraComponent, ProjMat)
  local ScreenPos3 = UE4.UNRCStatics.ProjectWorldToScreenWithUEApi(petWorldPos, viewportSize.X, viewportSize.Y, ProjMat)
  local ScreenPos4 = UE4.FVector2D(0, 0)
  local PlayerController = UE4.UGameplayStatics.GetPlayerControllerFromID(UE4Helper.GetCurrentWorld(), 0)
  UE4.UGameplayStatics.ProjectWorldToScreen(PlayerController, petWorldPos, ScreenPos4, true, true)
  local ViewportPos3 = UE4.FVector2D()
  UE4.USlateBlueprintLibrary.ScreenToViewport(self.previewWorld, ScreenPos3, ViewportPos3)
  self.PetNumberUIViewportPos[index] = ViewportPos3
  local ViewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(_G.UE4Helper.GetCurrentWorld())
end

function UMG_StarLightWorldView_C:AddPetToScene(petId, slotActor, slotId, petGid, showPlayStartSkill, bPlayedSound)
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petId)
  if self.IsInNPCMode == true then
  elseif petGid then
    self.petMutationDatas[slotId] = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  else
    self.petMutationDatas[slotId] = nil
  end
  local petMutationData = self.petMutationDatas[slotId]
  local modelConfId = petbaseConf.model_conf
  local useShiningModel = petMutationData and PetMutationUtils.GetMutationValue(petMutationData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING)
  if useShiningModel and petbaseConf.shining_model_conf and petbaseConf.shining_model_conf > 0 then
    modelConfId = petbaseConf.shining_model_conf
  end
  local modelCfg = _G.DataConfigManager:GetModelConf(modelConfId)
  local modelScale = petbaseConf.formation_ui_scale
  local modelClass = UE4.UClass.Load(modelCfg.path)
  if not modelClass then
    Log.ErrorFormat("UMG_PetTeamImage_C:AddPetToScene \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", modelCfg.path or "")
    self:ForceContinue()
    return
  end
  self.petHalfHeight[slotId] = self:GetModelHalfHeight(petbaseConf.model_conf, petGid)
  local newTransform = self:RecalcActorRealLocation(slotId)
  local transform = slotActor:GetTransform()
  local actor = self.previewWorld:SpawnActor(modelClass, newTransform)
  if not actor then
    Log.ErrorFormat("UMG_PetTeamImage_C:SpawnActor \229\136\155\229\187\186Actor\229\164\177\232\180\165.", modelCfg.path or "")
    self:ForceContinue()
    return
  end
  actor.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Custom, 0)
  actor:SetIKEnable(false)
  actor.petIndex = slotId
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  mesh.bForceMipStreaming = true
  if self.IsInNPCMode == true then
    actor.scale = modelScale * mesh.RelativeScale3D.Z * (modelCfg.model_scale / 100)
  elseif petGid then
    local heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(self.petDataInfoList[slotId])
    actor.scale = modelScale * mesh.RelativeScale3D.Z * heightModelScale * (modelCfg.model_scale / 100)
  else
    actor.scale = modelScale * mesh.RelativeScale3D.Z * (modelCfg.model_scale / 100)
  end
  if self.petMutationDatas[slotId] then
    actor:SetLoadPriority(PriorityEnum.UI_Pet_Mutation)
    PetMutationUtils.PrepareMutationAssets(actor, self.petMutationDatas[slotId])
  end
  actor.mesh = mesh
  actor:InitOutSceneAsync(nil, function(actor)
    self:OnActorLoaded(actor, slotId, showPlayStartSkill, bPlayedSound)
  end)
  return actor
end

function UMG_StarLightWorldView_C:StopAllPetAnimInCurrFrame()
  for i, pet in pairs(self.petList) do
    local petAnim = self:CheckIsSky(i)
    if pet.actor then
      pet.actor:PlayAnimByNameUsePercent(petAnim or "Idle", 0, pet.actor:GetCurrentAnimPercent(), 0, 0, -1, 0)
    end
  end
  if self.PlayerActor then
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", 0, self.PlayerAnimComponent:GetCurrentAnimPercent(), 0, 0, -1, 0)
  end
end

function UMG_StarLightWorldView_C:StopAllPetAnimInFirstFrame()
  for i, pet in pairs(self.petList) do
    local petAnim = self:CheckIsSky(i)
    if pet.actor then
      pet.actor:PlayAnimByNameUsePercent(petAnim or "Idle", 0, 0, 0, 0, -1, 0)
    end
  end
  if self.PlayerActor then
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", 0, 0, 0, 0, -1, 0)
  end
end

function UMG_StarLightWorldView_C:PlayAllPetAnimInFirstFrame()
  for i, pet in pairs(self.petList) do
    local petAnim = self:CheckIsSky(i)
    if pet.actor then
      pet.actor:PlayAnimByNameUsePercent(petAnim or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
    end
  end
  if self.PlayerActor then
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
  end
end

function UMG_StarLightWorldView_C:PlayShowSkill(actor, slotId)
  if self.State then
    return
  end
  if nil == actor then
    Log.Warning("UMG_PetTeamImage_C:PlayShowSkill actor is nil")
    return
  end
  if nil == self.skillClass then
    Log.Warning("UMG_PetTeamImage_C:PlayShowSkill skillClass is nil")
    return
  end
  local caster = actor
  if self.skillClass and caster then
    caster.RocoSkill:ClearAllPassiveSkillObjs()
    local skillObj = caster.RocoSkill:FindOrAddSkillObj(self.skillClass)
    skillObj:SetCaster(caster)
    skillObj:SetPassive(true)
    skillObj:RegisterEventCallback("SetPosition", self, self.OnSetPosition)
    caster.RocoSkill:LoadAndPlaySkill(skillObj)
  end
end

function UMG_StarLightWorldView_C:OnSetPosition(event, skillObj)
  local caster = skillObj:GetCaster()
  caster:SetActorHiddenInGame(false)
end

function UMG_StarLightWorldView_C:OnSkillEnd()
  local Actors = UE4.TArray(UE.AActor)
  for _, pet in pairs(self.petList) do
    if pet.actor then
      Actors:Add(pet.actor)
    end
  end
  self:SortTeam(Actors, 0.1)
end

function UMG_StarLightWorldView_C:OnTempPetSkillEnd()
  local Actors = UE4.TArray(UE.AActor)
  if self.tempPet and self.tempPet.actor then
    Actors:Add(self.tempPet.actor)
  end
  self:SortTeam(Actors, 0)
end

function UMG_StarLightWorldView_C:RecalcActorRealLocation(slotIndex)
  local halfHeight = self.petHalfHeight[slotIndex] or 0
  local actor = self.slotActors[slotIndex]
  local Transform = actor:GetTransform()
  local newLocation
  if self.IsInNPCMode == true then
    newLocation = UE4.FVector(Transform.Translation.X, Transform.Translation.Y, Transform.Translation.Z + halfHeight)
  else
    newLocation = UE4.FVector(Transform.Translation.X, Transform.Translation.Y, math.max(0, Transform.Translation.Z) + halfHeight)
  end
  self.PetRealPos[slotIndex] = newLocation
  Transform.Translation = newLocation
  return Transform
end

function UMG_StarLightWorldView_C:RecalcActorLocation(actor)
  local Root = actor:K2_GetRootComponent()
  local height = Root:GetScaledCapsuleHalfHeight()
  local location = actor:K2_GetActorLocation()
  location.Z = location.Z + height
  actor:K2_SetActorLocation(location, false, nil, false)
end

function UMG_StarLightWorldView_C:DestoryAllActors()
  for i = 1, 6 do
    if self.petList and self.petList[i] and self.petList[i].actor then
      self.petList[i].actor.mesh:ReleaseResource()
      self.petList[i].actor.mesh:Release()
      self.previewWorld:DestroyActor(self.petList[i].actor)
      self.petList[i] = nil
    end
  end
  self:DeleteBGBP()
end

function UMG_StarLightWorldView_C:UpdateBgImg()
  local BPPath = "/Game/NewRoco/Modules/System/PetUI/Res/BackGroundBP/BP_UI_PetTeamBg_02.BP_UI_PetTeamBg_02_C"
  if self.curTeamType == Enum.PlayerTeamType.PTT_PVP_BATTLE_2 then
    BPPath = "/Game/NewRoco/Modules/System/PetUI/Res/BackGroundBP/BP_UI_PetTeamBg_03.BP_UI_PetTeamBg_03_C"
  elseif self.curTeamType == Enum.PlayerTeamType.PTT_PVP_BATTLE_3 then
    BPPath = "/Game/NewRoco/Modules/System/PetUI/Res/BackGroundBP/BP_UI_PetTeamBg.BP_UI_PetTeamBg_C"
  elseif self.curTeamType == Enum.PlayerTeamType.PTT_PVP_BATTLE_4 then
    BPPath = "/Game/NewRoco/Modules/System/PetUI/Res/BackGroundBP/BP_UI_PetTeamBg_PVP.BP_UI_PetTeamBg_PVP_C"
  end
  self:DeleteBGBP()
  self.bgRequest = _G.NRCResourceManager:LoadResAsync(self, BPPath, -1, -1, self.LoadBpOver)
end

function UMG_StarLightWorldView_C:DeleteBGBP()
  if self.BGRef and UE.UObject.IsValid(self.BGRef) then
    UnLua.Unref(self.BGRef)
  end
  self.BGRef = nil
  if self.BGbp then
    self.previewWorld:DestroyActor(self.BGbp)
  end
  self.BGbp = nil
end

function UMG_StarLightWorldView_C:LoadBpOver(resRequest, BgClass)
  local actor = self.previewWorld:SpawnActor(BgClass, UE.FTransform())
  if not actor then
    Log.Error("zgx load bp of Bg faild")
  else
    self.BGbp = actor
    self.BGRef = UnLua.Ref(actor)
  end
end

function UMG_StarLightWorldView_C:GetAssetPath_PlayerAvatar()
  return UEPath.STARLIGHT_LOCAL_PLAYER
end

function UMG_StarLightWorldView_C:GetAssetPath_AnimSequence()
end

function UMG_StarLightWorldView_C:unordered_deep_equal(t1, t2)
  if type(t1) ~= type(t2) then
    return false
  end
  if type(t1) ~= "table" then
    return t1 == t2
  end
  local t1_count, t2_count = 0, 0
  for _ in pairs(t1) do
    t1_count = t1_count + 1
  end
  for _ in pairs(t2) do
    t2_count = t2_count + 1
  end
  if t1_count ~= t2_count then
    return false
  end
  local count_t1 = {}
  local count_t2 = {}
  for _, v in pairs(t1) do
    local key
    if type(v) == "table" then
      key = table.concat({
        unordered_deep_equal
      }, tostring(v))
    else
      key = tostring(v)
    end
    count_t1[key] = (count_t1[key] or 0) + 1
  end
  for _, v in pairs(t2) do
    local key
    if type(v) == "table" then
      key = table.concat({
        unordered_deep_equal
      }, tostring(v))
    else
      key = tostring(v)
    end
    count_t2[key] = (count_t2[key] or 0) + 1
  end
end

function UMG_StarLightWorldView_C:ChangeSalonIDsIntoTable(salonIds)
end

function UMG_StarLightWorldView_C:LoadPlayerAndAnimRes(fashionItems, salonIds)
  if not self.CurrPhotoPlayerFashionItems then
    self.CurrPhotoPlayerFashionItems = fashionItems
    self.CurrPhotoPlayerSalonIDs = salonIds
  end
  local hasSameAppearance = self:CheckPlayerAppearanceSame(fashionItems, salonIds)
  if not hasSameAppearance and fashionItems and salonIds then
    self.CurrPhotoPlayerFashionItems = fashionItems
    self.CurrPhotoPlayerSalonIDs = salonIds
  end
  if UE4.UObject.IsValid(self.PlayerActor) then
    self.PlayerActor:SetActorHiddenInGame(false)
    if self.NPCActor then
      self.NPCActor:SetActorHiddenInGame(true)
    end
    if hasSameAppearance then
      Log.Debug("[UMG_StarLightWorldView_C] LoadPlayerAndAnimRes: \229\164\150\232\178\140\231\155\184\229\144\140\239\188\140\233\135\141\230\150\176\232\174\190\229\174\154\228\189\141\231\189\174\229\146\140\230\151\139\232\189\172\229\185\182\230\155\180\230\150\176\229\138\168\231\148\187")
      self.petHalfHeight[7] = self:GetModelHalfHeight(10000)
      local newTransform = self:RecalcActorRealLocation(7)
      self.PlayerActor:K2_SetActorLocation(newTransform.Translation, false, nil, false)
      self.PlayerActor:K2_SetActorRotation(newTransform.Rotation:ToRotator(), false)
      self:PlayerPlayAnimAtFrame()
      self.hasLoadedCount = self.hasLoadedCount + 1
      self:CheckAllPetLoaded()
      return
    end
  elseif self.NPCActor then
    self.NPCActor:SetActorHiddenInGame(true)
  end
  self.gender = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex
  if not self.previewWorld or not UE4.UObject.IsValid(self.previewWorld) then
    Log.Warning("UMG_TaskPhoto_C:SetPlayerPath previewWorld is destroyed")
    return
  end
  local AvatarAssetPath = self:GetAssetPath_PlayerAvatar()
  if self:IsLoadedResByPath(AvatarAssetPath) then
    self:SpawnPlayerActor()
  else
    self:LoadPanelRes(AvatarAssetPath, -1, self.OnAssetLoaded_SetPlayerPath)
  end
end

function UMG_StarLightWorldView_C:CheckPlayerAppearanceSame(fashionItems, salonIds)
  if not fashionItems or not salonIds then
    return false
  end
  if not self.CurrPhotoPlayerFashionItems or not self.CurrPhotoPlayerSalonIDs then
    return false
  end
  if not self:CompareTable(fashionItems, self.CurrPhotoPlayerFashionItems) then
    return false
  end
  if not self:CompareTable(salonIds, self.CurrPhotoPlayerSalonIDs) then
    return false
  end
  return true
end

function UMG_StarLightWorldView_C:CompareTable(t1, t2)
  if t1 == t2 then
    return true
  end
  if type(t1) ~= "table" or type(t2) ~= "table" then
    return t1 == t2
  end
  local len1, len2 = 0, 0
  for _ in pairs(t1) do
    len1 = len1 + 1
  end
  for _ in pairs(t2) do
    len2 = len2 + 1
  end
  if len1 ~= len2 then
    return false
  end
  for k, v in pairs(t1) do
    if type(v) == "table" then
      if not self:CompareTable(v, t2[k]) then
        return false
      end
    elseif t2[k] ~= v then
      return false
    end
  end
  return true
end

function UMG_StarLightWorldView_C:OnAssetLoaded_SetPlayerPath(resRequest, asset)
  self:SpawnPlayerActor()
end

function UMG_StarLightWorldView_C:OnAssetLoaded_ApplyAnimSequence(resRequest, asset)
  self:SpawnPlayerActor()
end

function UMG_StarLightWorldView_C:SpawnPlayerActor()
  local BP_CardLocalPlayer_C = self:TryGetLoadedResByPath(self:GetAssetPath_PlayerAvatar())
  if not BP_CardLocalPlayer_C then
    return
  end
  if self.PlayerActor then
  end
  if self.PlayerActor then
    self.previewWorld:DestroyActor(self.PlayerActor)
    self.PlayerActor = nil
  end
  self.petHalfHeight[7] = self:GetModelHalfHeight(10000)
  local newTransform = self:RecalcActorRealLocation(7)
  local Transfom = self.slotActors[7]:GetTransform()
  self.PlayerActor = self.previewWorld:SpawnActor(BP_CardLocalPlayer_C, newTransform)
  self.PlayerActor:SetActorScale3D(UE4.FVector(1, 1, 1))
  local mesh = self.PlayerActor:GetComponentByClass(UE4.USkeletalMeshComponent)
  local RocoAnimComponent = self.PlayerActor:GetComponentByClass(UE4.URocoAnimComponent)
  self.PlayerAnimComponent = RocoAnimComponent
  if 1 == self.gender then
    self:LoadResAnimClass(mesh, UEPath.ABP_STARLIGHT_PLAYER_MALE)
    self:LoadResAnimConfig(RocoAnimComponent, UEPath.ANIM_CONFIG_MALE)
  elseif 2 == self.gender then
    self:LoadResAnimClass(mesh, UEPath.ABP_STARLIGHT_PLAYER_FEMALE)
    self:LoadResAnimConfig(RocoAnimComponent, UEPath.ANIM_CONFIG_FEMALE)
  end
  self:SetPlayerAppearanceInfo(self.CurrPhotoPlayerFashionItems, self.CurrPhotoPlayerSalonIDs)
end

function UMG_StarLightWorldView_C:SetParent(Parent)
  self.Parent = Parent
  self.PetNumberUIItem = {
    self.Parent.TeamSequenceNumber1,
    self.Parent.TeamSequenceNumber2,
    self.Parent.TeamSequenceNumber3,
    self.Parent.TeamSequenceNumber4,
    self.Parent.TeamSequenceNumber5,
    self.Parent.TeamSequenceNumber6
  }
  self.PetNumberUIItemHistory = {
    self.Parent.TeamSequenceNumber1_1,
    self.Parent.TeamSequenceNumber2_1,
    self.Parent.TeamSequenceNumber3_1,
    self.Parent.TeamSequenceNumber4_1,
    self.Parent.TeamSequenceNumber5_1,
    self.Parent.TeamSequenceNumber6_1
  }
end

function UMG_StarLightWorldView_C:PlayerPlayAnimAtFrame()
  self:CheckPlayerHasSameAnimWithNPC()
  if self.Parent and self.Parent:CheckIsInCurrShoot() then
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
  else
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", 0, (self.NPCAnimFrame or 0) / 1000, 0, 0, -1, 0)
  end
end

function UMG_StarLightWorldView_C:InitPlayerPlayAnimAtFrame()
  self:SetAnimInstance()
  self:CheckPlayerHasSameAnimWithNPC()
  if self.Parent and self.Parent:CheckIsInCurrShoot() then
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", self.TakePhotoAnimSpeed, 0, 0, 0, -1, 0)
  else
    self.PlayerAnimComponent:PlayAnimByNameUsePercent(self.PetAnim[7] or "Idle", 0, (self.NPCAnimFrame or 0) / 1000, 0, 0, -1, 0)
  end
  self.hasLoadedCount = self.hasLoadedCount + 1
  self:CheckAllPetLoaded()
end

function UMG_StarLightWorldView_C:CheckPlayerHasSameAnimWithNPC()
  if self.PlayerAnimComponent then
    if not self.PlayerAnimNameLengthMap then
      local PlayerAnimNameLengthMap = self.PlayerAnimComponent:GetAnimNameLengthMap()
      self.PlayerAnimNameLengthMap = {}
      for animName, length in pairs(PlayerAnimNameLengthMap) do
        self.PlayerAnimNameLengthMap[animName] = length
      end
    end
    if self.PlayerAnimNameLengthMap[self.NPCAnim] then
      self.PetAnim[7] = self.NPCAnim
    else
      local photo_template_id = self.Parent.photo_template_id
      local photoConf = DataConfigManager:GetWeeklyPhotoConf(photo_template_id)
      if photoConf then
        self.PetAnim[7] = photoConf.action
        if not photoConf.action then
          self.PetAnim[7] = "Idle"
          Log.Error("\232\175\165\230\168\161\230\157\191\230\178\161\230\156\137\233\133\141\231\189\174\231\142\169\229\174\182\229\138\168\228\189\156\239\188\140\232\175\183\233\128\154\231\159\165\233\171\152\229\133\134\231\144\170\239\188\140\230\168\161\230\157\191ID\230\152\175" .. photo_template_id)
        end
      end
    end
  end
end

function UMG_StarLightWorldView_C:SetAnimInstance()
  if self.PlayerActor then
    local AnimComponent = self.PlayerActor:GetComponentByClass(UE4.URocoAnimComponent)
    if AnimComponent then
      AnimComponent:InitAnimInstance()
    end
  end
end

function UMG_StarLightWorldView_C:SetPlayerAppearanceInfo(fashionItems, salonIds)
  if not fashionItems or not salonIds then
    Log.Warning("UMG_StarLightWorldView_C:CreatePlayer fashionIds or salonIds is nil, please check the team data")
  end
  _G.NRCModeManager:DoCmd(TaskModuleCmd.SetDefaultSuit, self.PlayerActor, self.gender, fashionItems, salonIds)
end

function UMG_StarLightWorldView_C:LoadResAnimClass(mesh, Path)
  local asset = self.module:GetRes(Path, self.panelName or "StarlightPhoto")
  asset = asset or UE4.UClass.Load(Path)
  mesh:SetAnimClass(asset)
end

function UMG_StarLightWorldView_C:LoadResAnimConfig(AnimComponent, Path)
  local asset = self.module:GetRes(Path, self.panelName or "StarlightPhoto")
  asset = asset or UE4.UClass.Load(Path)
  AnimComponent:SetAnimConfig(asset)
end

function UMG_StarLightWorldView_C:ChangeActorPlayAnimData(actor, anim, index)
  if 7 ~= index then
    self.PetAnim[index] = anim
  else
    self.NPCAnim = anim
  end
end

function UMG_StarLightWorldView_C:GetModelHalfHeight(modelCfgID, petGID)
  local heightModelScale = 1
  if petGID then
    local petDataInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGID)
    heightModelScale = PetMutationUtils.GetHeightModelScaleByPetData(petDataInfo)
  end
  local modelConf = _G.DataConfigManager:GetModelConf(modelCfgID)
  local modelScale1 = math.clamp((modelConf.model_scale or 100) / 100, 0.001, 100.0)
  local modelScale = 1
  local modelHalfHeight = (modelConf.capsule_halfheight or 1000) / 1000
  return modelScale * modelHalfHeight * heightModelScale
end

function UMG_StarLightWorldView_C:LoadFileFromJson(jsonPath, isNPC)
  local SaveJsonInfoList = JsonUtils.LoadSavedFromStarLight(jsonPath or self.LoadJsonPath or "PhotoEditorJson", {})
  if 0 == #SaveJsonInfoList then
    if jsonPath then
      Log.Error("\230\178\161\230\156\137" .. jsonPath .. "\229\175\185\229\186\148\231\154\132json\230\150\135\228\187\182\239\188\140\228\189\191\231\148\168\233\187\152\232\174\164\230\168\161\230\157\191")
    end
  else
    self.LoadJsonPath = jsonPath
  end
  if #SaveJsonInfoList > 0 then
    local GlobalInfo = SaveJsonInfoList[1]
    if GlobalInfo and #GlobalInfo >= 2 then
      self.BattleID = GlobalInfo[1]
      self.BGPath = GlobalInfo[2]
      local FilePath = "/Game/ArtRes/Asset/Environment/Interator/Curtain/TEX/"
      local FullPath = FilePath .. self.BGPath .. "." .. self.BGPath
      local Material = LoadObject(FullPath)
      local meshComponent = self.BGAsset:GetComponentByClass(UE4.USkeletalMeshComponent)
      meshComponent:SetMaterial(0, Material)
    end
    if GlobalInfo and #GlobalInfo >= 9 then
      local BGPos = UE4.FVector(GlobalInfo[4], GlobalInfo[5], GlobalInfo[6])
      local BGRot = UE4.FRotator(GlobalInfo[8], GlobalInfo[9], GlobalInfo[7])
      self.BGAsset:K2_GetRootComponent():SetMobility(UE4.EComponentMobility.Movable)
      self.BGAsset:Abs_K2_SetActorLocation_WithoutHit(BGPos)
      self.BGAsset:K2_SetActorRotation(BGRot, false)
    end
  end
  if #SaveJsonInfoList > 1 then
    local CameraInfo = SaveJsonInfoList[2]
    if CameraInfo and #CameraInfo >= 6 then
      local cameraPos = UE4.FVector(CameraInfo[1], CameraInfo[2], CameraInfo[3])
      self.CameraActor:Abs_K2_SetActorLocation_WithoutHit(cameraPos)
      local cameraRot = UE4.FRotator(CameraInfo[5], CameraInfo[6], CameraInfo[4])
      self.CameraActor:K2_SetActorRotation(cameraRot, false)
      if CameraInfo[7] then
        local CameraComponent = self.CameraActor:GetComponentByClass(UE4.UCameraComponent)
        CameraComponent:SetFieldOfView(CameraInfo[7])
      end
    end
  end
  if #SaveJsonInfoList > 2 then
    local NPCInfo = SaveJsonInfoList[3]
    if NPCInfo and #NPCInfo >= 8 then
      self.NPCID = NPCInfo[1]
      self.NPCAnim = NPCInfo[2]
      local slotPos = UE4.FVector(NPCInfo[3], NPCInfo[4], NPCInfo[5])
      local npcPos = UE4.FVector(NPCInfo[3], NPCInfo[4], NPCInfo[5])
      self.Slot_NPC:Abs_K2_SetActorLocation_WithoutHit(slotPos)
      local npcRot = UE4.FRotator(NPCInfo[7], NPCInfo[8], NPCInfo[6])
      self.Slot_NPC:K2_SetActorRotation(npcRot, false)
      if isNPC then
        self.NPCAnimFrame = NPCInfo[9]
      end
    end
  end
  local lightInfoIndex = 10
  for i = 4, #SaveJsonInfoList do
    local petInfo = SaveJsonInfoList[i]
    if petInfo[12] and "isPetInfo" ~= petInfo[12] then
      lightInfoIndex = i
      break
    end
    if petInfo and #petInfo >= 3 then
      local petIndex = i - 3
      self.PetAnim[petIndex] = petInfo[2]
      self.PetBody[petIndex] = petInfo[3]
      if #petInfo >= 9 then
        local petPos = UE4.FVector(petInfo[4], petInfo[5], petInfo[6])
        self.slotActors[petIndex]:Abs_K2_SetActorLocation_WithoutHit(petPos)
        local petRot = UE4.FRotator(petInfo[8], petInfo[9], petInfo[7])
        self.slotActors[petIndex]:K2_SetActorRotation(petRot, false)
        self:CalcuPetNumberUIPos(nil, petIndex)
        self:ShowNumberUI(petIndex)
        if isNPC then
          self.petAnimFrame[petIndex] = petInfo[10] or 0
        end
        local DebugData = {"\231\169\186\228\184\173"}
        self.petPosInfo[petIndex] = petInfo[11] or DebugData[1]
      end
    end
  end
  for i = lightInfoIndex, #SaveJsonInfoList do
    local lightIndex = i - lightInfoIndex + 1
    if not self.EnvSpotLightActorList[lightIndex] then
      break
    end
    local LightInfo = SaveJsonInfoList[i]
    local LightPos = UE4.FVector(LightInfo[1], LightInfo[2], LightInfo[3])
    local LightRot = UE4.FRotator(LightInfo[5], LightInfo[6], LightInfo[4])
    self.EnvSpotLightActorList[lightIndex]:Abs_K2_SetActorLocation_WithoutHit(LightPos)
    self.EnvSpotLightActorList[lightIndex]:K2_SetActorRotation(LightRot, false)
    local Intensity = LightInfo[7]
    self.EnvSpotLightActorList[lightIndex]:SetIntensity(Intensity)
    local LightColor = UE.FColor(LightInfo[8], LightInfo[9], LightInfo[10], LightInfo[11])
    self.EnvSpotLightActorList[lightIndex]:SetLightColor(LightColor)
    local AttenuationRadius = LightInfo[12]
    self.EnvSpotLightActorList[lightIndex]:SetAttenuationRadius(AttenuationRadius)
    local InnerConeAngle = LightInfo[13]
    self.EnvSpotLightActorList[lightIndex]:SetInnerConeAngle(InnerConeAngle)
    local OuterConeAngle = LightInfo[14]
    self.EnvSpotLightActorList[lightIndex]:SetOuterConeAngle(OuterConeAngle)
    local UseInverseSquaredFalloff
    if "true" == LightInfo[15] then
      UseInverseSquaredFalloff = true
    else
      UseInverseSquaredFalloff = false
    end
    self.EnvSpotLightActorList[lightIndex]:SetUseInverseSquaredFalloff(UseInverseSquaredFalloff)
    local LightFalloffExponent = LightInfo[16]
    self.EnvSpotLightActorList[lightIndex]:SetLightFalloffExponent(LightFalloffExponent)
  end
  return true
end

function UMG_StarLightWorldView_C:LoadBattleConf(battleID)
  local BattleConf = DataConfigManager:GetBattleConf(battleID)
  if not BattleConf then
    return
  end
  local battle_model = BattleConf.npc_battle_list[1].battle_model_1st
  if 0 == battle_model then
    battle_model = 12123
  end
  self:CreateNPC(battle_model, true)
  local posFields = {
    "pos1_1st",
    "pos2_1st",
    "pos3_1st",
    "pos4_1st",
    "pos5_1st",
    "pos6_1st"
  }
  for i = 1, 6 do
    local posData = BattleConf.npc_battle_list[1][posFields[i]]
    local monsterID = posData and posData[1]
    if monsterID then
      local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterID)
      local petBaseID = monsterConf.base_id
      self.petFullIDData[i] = {}
      self.petFullIDData[i].petID = petBaseID
      self.petMonsterIDs[i] = monsterID
      self.petMutationDatas[i] = self:BuildMutationDataFromMonsterConf(monsterConf, petBaseID)
    end
  end
  self:UpdateSlotActors(nil, true)
end

function UMG_StarLightWorldView_C:GetPetAnimFrame()
  local petAnimFrame = {}
  for i, pet in pairs(self.petList) do
    local Frame = pet.actor:GetCurrentAnimPercent()
    Frame = math.floor(Frame * 1000)
    petAnimFrame[i] = Frame
  end
  for i = 1, 6 do
    if not petAnimFrame[i] then
      petAnimFrame[i] = 0
    end
  end
  local npcFrame = 0
  if self.PlayerAnimComponent then
    npcFrame = self.PlayerAnimComponent:GetCurrentAnimPercent()
  end
  petAnimFrame[7] = math.floor(npcFrame * 1000) or 0
  return petAnimFrame
end

function UMG_StarLightWorldView_C:CheckIsSky(petIndex, actor)
  if petIndex > 6 then
    return
  end
  actor = actor or self.petList[petIndex].actor
  if not actor then
    Log.Error("UMG_StarLightWorldView_C:CheckIsSky actor is nil")
    return "Idle"
  end
  local AnimNameLengthMap = actor:GetAnimNameLengthMap()
  self.PetAnimLengthMap[petIndex] = {}
  for AnimName, AnimLength in pairs(AnimNameLengthMap) do
    self.PetAnimLengthMap[petIndex][AnimName] = AnimLength
  end
  local petID = self.petFullIDData[petIndex].petID
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petID)
  local type
  if petBaseConf then
    type = petBaseConf.move_type
  end
  local isGroundPet = true
  local DebugData = {"\230\181\174\230\184\184"}
  if type and type == DebugData[1] then
    isGroundPet = false
  end
  local isInSky = false
  if self.petPosInfo[petIndex] == "air" then
    isInSky = true
  end
  if isGroundPet and isInSky and self.PetAnimLengthMap[petIndex] and self.PetAnimLengthMap[petIndex].JumpFall then
    return "JumpFall"
  end
  local AnimName = self.PetAnim[petIndex]
  if not self.PetAnimLengthMap[petIndex][AnimName] then
    AnimName = "Idle"
  end
  return AnimName
end

function UMG_StarLightWorldView_C:ShowNumberUI(i)
  if i > 6 then
    return
  end
  local PetNumberUIItem = self:GetCurrModePetNumberUIItem(i)
  if not PetNumberUIItem then
    return
  end
  PetNumberUIItem.Slot:SetPosition(self.PetNumberUIViewportPos[i])
  PetNumberUIItem.NumberText:SetText(i)
  PetNumberUIItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_StarLightWorldView_C:ShowAllNumberUI()
  for i = 1, 6 do
    if 0 ~= self.PetNumberUIItem[i].petGID then
      local PetNumberUIItem = self:GetCurrModePetNumberUIItem(i)
      if PetNumberUIItem then
        PetNumberUIItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function UMG_StarLightWorldView_C:HideAllNumberUI()
  for i = 1, 6 do
    if 0 ~= self.PetNumberUIItem[i].petGID then
      local PetNumberUIItem = self:GetCurrModePetNumberUIItem(i)
      if PetNumberUIItem then
        PetNumberUIItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_StarLightWorldView_C:UpdateNumberUIVisibility()
  for i, petData in pairs(self.petFullIDData) do
    local PetNumberUIItem = self:GetCurrModePetNumberUIItem(i)
    if not PetNumberUIItem or 0 == self.petFullIDData[i].petGID then
    else
      PetNumberUIItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_StarLightWorldView_C:StarLightPetItemTouchStarted(i)
  local PetNumberUIItem = self:GetCurrModePetNumberUIItem(i)
  if PetNumberUIItem then
    PetNumberUIItem:PlayAnimation(PetNumberUIItem.select)
  end
end

function UMG_StarLightWorldView_C:GetCurrModePetNumberUIItem(index)
  if self.Parent and (self.Parent.currentOpenPanelType == self.Parent.PanelType.EditLocation_History or self.Parent.currentOpenPanelType == self.Parent.PanelType.HistoryTeam or self.Parent.currentOpenPanelType == self.Parent.PanelType.Shoot_History or self.Parent.currentOpenPanelType == self.Parent.PanelType.ChangeHistoryTeamPanel) then
    return self.PetNumberUIItemHistory[index]
  elseif self.PetNumberUIItem then
    return self.PetNumberUIItem[index]
  end
  return nil
end

function UMG_StarLightWorldView_C:BuildMutationDataFromMonsterConf(monsterConf, petBaseID)
  local mutationType = _G.Enum.MutationDiffType.MDT_NONE
  local glassInfo = {
    glass_type = _G.ProtoEnum.GlassType.GT_NULL,
    glass_value = 0
  }
  if monsterConf.shining_prob and monsterConf.shining_prob > 0 then
    mutationType = mutationType | _G.Enum.MutationDiffType.MDT_SHINING
  end
  if monsterConf.glass_prob and monsterConf.glass_prob > 0 then
    mutationType = mutationType | _G.Enum.MutationDiffType.MDT_GLASS
    local customGlass = monsterConf.custom_glass
    if customGlass and customGlass.glass_type then
      local glassType = customGlass.glass_type
      local glassParam1 = customGlass.glass_param_1 or 0
      local glassParam2 = customGlass.glass_param_2 or 0
      if glassType > 0 and glassParam1 > 0 then
        if glassType == _G.ProtoEnum.GlassType.GT_COMMON then
          local colorIdBitNum = 20
          local glassValue = glassParam1 + (glassParam2 << colorIdBitNum)
          glassInfo = {
            glass_type = _G.ProtoEnum.GlassType.GT_COMMON,
            glass_value = glassValue
          }
        elseif glassType == _G.ProtoEnum.GlassType.GT_HIDDEN then
          glassInfo = {
            glass_type = _G.ProtoEnum.GlassType.GT_HIDDEN,
            glass_value = glassParam1
          }
        end
      end
    end
  end
  local isNightmare = monsterConf.is_nightmare or 0
  if 1 == isNightmare then
    mutationType = mutationType | _G.Enum.MutationDiffType.MDT_CHAOS_THREE
  elseif 2 == isNightmare then
    mutationType = mutationType | _G.Enum.MutationDiffType.MDT_CHAOS_TWO
  elseif monsterConf.chaos_prob and monsterConf.chaos_prob > 0 then
    mutationType = mutationType | _G.Enum.MutationDiffType.MDT_CHAOS
  end
  local petData = {
    mutation_type = mutationType,
    glass_info = glassInfo,
    base_conf_id = petBaseID,
    nature = 0
  }
  return petData
end

function UMG_StarLightWorldView_C:LoadPhotoToImage(filePath, targetImage)
  if not filePath or not UE.UNRCStatics.FileExists(filePath) then
    Log.Error("[UMG_StarLightWorldView_C] LoadPhotoToImage: \230\150\135\228\187\182\228\184\141\229\173\152\229\156\168, filePath=", filePath)
    return false
  end
  if not targetImage or not UE.UObject.IsValid(targetImage) then
    targetImage = self.captureImage
  end
  if self.PhotoTextureRef and UE.UObject.IsValid(self.PhotoTextureRef) then
    UnLua.Unref(self.PhotoTextureRef)
  end
  self.PhotoTexture = UE.UKismetRenderingLibrary.ImportFileAsTexture2D(UE4Helper.GetCurrentWorld(), filePath)
  if self.PhotoTexture and UE.UObject.IsValid(self.PhotoTexture) then
    self.PhotoTextureRef = UnLua.Ref(self.PhotoTexture)
    targetImage:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(self.PhotoTexture))
    targetImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    Log.Debug("[UMG_StarLightWorldView_C] LoadPhotoToImage: \229\138\160\232\189\189\230\136\144\229\138\159")
    return true
  else
    Log.Error("[UMG_StarLightWorldView_C] LoadPhotoToImage: \229\138\160\232\189\189\231\186\185\231\144\134\229\164\177\232\180\165")
    return false
  end
end

function UMG_StarLightWorldView_C:GetPhotoTexture()
  return self.PhotoTexture
end

function UMG_StarLightWorldView_C:ReleasePhotoResources()
  if self.PhotoTextureRef and UE.UObject.IsValid(self.PhotoTextureRef) then
    UnLua.Unref(self.PhotoTextureRef)
  end
  self.PhotoTextureRef = nil
  self.PhotoTexture = nil
end

function UMG_StarLightWorldView_C:PlayCurtainAnim()
  if not self.BGAsset then
    return
  end
  local meshComponent = self.BGAsset:GetComponentByClass(UE4.USkeletalMeshComponent)
  if not meshComponent then
    Log.Error("[UMG_StarLightWorldView_C] PlayCurtainAnim: \230\151\160\230\179\149\232\142\183\229\143\150\231\170\151\229\184\152\231\154\132 SkeletalMeshComponent")
    return
  end
  if not self.CurtainAnimAsset then
    Log.Warning("[UMG_StarLightWorldView_C] PlayCurtainAnim: \231\170\151\229\184\152\229\138\168\231\148\187\232\181\132\230\186\144\229\176\154\230\156\170\229\138\160\232\189\189\229\174\140\230\136\144")
    return
  end
  meshComponent:SetAnimationMode(UE4.EAnimationMode.AnimationAsset)
  meshComponent:PlayAnimation(self.CurtainAnimAsset, true)
end

function UMG_StarLightWorldView_C:StopCurtainAnim()
  if not self.BGAsset then
    return
  end
  local meshComponent = self.BGAsset:GetComponentByClass(UE4.USkeletalMeshComponent)
  if meshComponent then
    meshComponent:Stop()
    meshComponent:SetAnimationMode(UE4.EAnimationMode.AnimationSingleNode)
  end
end

function UMG_StarLightWorldView_C:GetPhotoMode()
  return self.PhotoMode
end

function UMG_StarLightWorldView_C:IsPlayAtStartMode()
  return self.PhotoMode == WeeklyChallengeBattleModuleEnum.PhotoMode.PlayAtStart
end

return UMG_StarLightWorldView_C

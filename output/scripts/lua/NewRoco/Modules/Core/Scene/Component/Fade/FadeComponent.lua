local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local FadeComponent = Base:Extend("FadeComponent")

function FadeComponent:Ctor()
  self._fadeRules = {}
  self._commonfadeInfo = {}
  self._fadeMeshAlpha = {}
  self._commonFadeMesh = {}
  self._enableCommonFade = true
  self._commonFadeMinDistance = 100
  self._commonFadeMaxDistance = 150
  self._commonDistance = self._commonFadeMaxDistance - self._commonFadeMinDistance
  self._petFadeMinDistance = 100
  self._petFadeMaxDistance = 200
  self._petDistance = self._petFadeMaxDistance - self._petFadeMinDistance
  self._defaultLerpSpeed = 2
  self._lerpSpeed = self._defaultLerpSpeed
  self.ID = 1
end

function FadeComponent:Attach(owner)
  Base.Attach(self, owner)
  self.PlayerCameraManager = self.owner:GetUEController().PlayerCameraManager
  ARocoPlayerCameraManager_ApplyDefaultFadeRuleLua(self.PlayerCameraManager)
  self:AddCommonMesh(self.owner.viewObj)
  _G.NRCEventCenter:RegisterEvent("FadeComponent", self, MainUIModuleEvent.OnLobbyMainInnerOpened, self.OnLobbyMainInnerOpened)
  _G.NRCEventCenter:RegisterEvent("FadeComponent", self, MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnLobbyMainInnerClosed)
end

function FadeComponent:DeAttach()
  self._fadeRules = {}
  self._fadeMeshAlpha = {}
  self._commonFadeMesh = {}
  self._enableCommonFade = true
  self.ID = 1
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerOpened, self.OnLobbyMainInnerOpened)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnLobbyMainInnerClosed)
end

function FadeComponent:Update(deltaTime)
  ARocoPlayerCameraManager_FadeCompUpdate(self.PlayerCameraManager, deltaTime)
  return
end

function FadeComponent:Update2(deltaTime)
  if not self.owner or not self.owner.viewObj then
    return
  end
  local targetFade = {}
  local tempTarget
  local lastFadeAlpha = {}
  table.deepCopy(self._fadeMeshAlpha, lastFadeAlpha)
  for _, func in pairs(self._fadeRules) do
    local fadeContext = {}
    tempTarget = func(fadeContext)
    if tempTarget then
      for mesh, alpha in pairs(tempTarget) do
        if not mesh:IsA(UE.AActor) and not mesh:IsA(UE.UMeshComponent) then
        elseif targetFade[mesh] then
          targetFade[mesh] = math.min(targetFade[mesh], alpha)
        else
          targetFade[mesh] = alpha
        end
      end
    end
  end
  for mesh, alpha in pairs(targetFade) do
    if mesh then
      local cur = 1
      if self._fadeMeshAlpha[mesh] then
        cur = self._fadeMeshAlpha[mesh]
      end
      self._fadeMeshAlpha[mesh] = self:LerpAlpha(cur, alpha, deltaTime)
    end
  end
  local maskRemove = {}
  for mesh, alpha in pairs(self._fadeMeshAlpha) do
    if nil == targetFade[mesh] then
      self._fadeMeshAlpha[mesh] = self:LerpAlpha(alpha, 1, deltaTime)
      if 1 == self._fadeMeshAlpha[mesh] then
        maskRemove[mesh] = true
      end
    end
  end
  for mesh, alpha in pairs(self._fadeMeshAlpha) do
    if nil == lastFadeAlpha[mesh] or lastFadeAlpha[mesh] ~= alpha then
      self:SetMeshFade(mesh, alpha)
    end
  end
  for mesh, _ in pairs(maskRemove) do
    self._fadeMeshAlpha[mesh] = nil
  end
end

function FadeComponent:ForceUpdate()
  for mesh, alpha in pairs(self._fadeMeshAlpha) do
    self:SetMeshFade(mesh, alpha)
  end
end

function FadeComponent:UpdateCommonMesh()
  if self._enableCommonFade then
    local meshList = {}
    if self.PlayerCameraManager.ViewTarget.Target:IsA(UE.ACameraActor) then
      return nil
    end
    local CameraPos = self.PlayerCameraManager:GetCameraLocation()
    local effectMesh = {}
    for mesh, _ in pairs(self._commonFadeMesh) do
      if UE.UKismetSystemLibrary.IsValid(mesh) then
        effectMesh[mesh] = 1
      end
    end
    self._commonFadeMesh = effectMesh
    for mesh, _ in pairs(self._commonFadeMesh) do
      local MeshPos
      if mesh:IsA(UE.AActor) then
        MeshPos = mesh:K2_GetActorLocation()
      elseif mesh:IsA(UE.UMeshComponent) then
        MeshPos = mesh:K2_GetComponentLocation()
      end
      local distance = UE.UKismetMathLibrary.Vector_Distance(CameraPos, MeshPos)
      local alpha = (distance - self._commonFadeMinDistance) / self._commonDistance
      alpha = math.min(1, alpha)
      alpha = math.max(0, alpha)
      meshList[mesh] = alpha
    end
    local TraceObject = {
      UE4.ECollisionChannel.ECC_Pawn
    }
    local HitActors
    local bHit = true
    HitActors, bHit = UE.UKismetSystemLibrary.SphereOverlapActors(self.PlayerCameraManager, CameraPos, self._commonFadeMaxDistance, TraceObject)
    local petMesh = {}
    HitActors = HitActors:ToTable()
    for _, Hit in pairs(HitActors) do
      if Hit.sceneCharacter and Hit.sceneCharacter.luaObj and Hit.sceneCharacter.luaObj.name == "Lua_NPCCharacter" then
        petMesh[Hit.Mesh] = 1
      end
    end
    for mesh, _ in pairs(petMesh) do
      local MeshPos
      if mesh:IsA(UE.AActor) then
        MeshPos = mesh:K2_GetActorLocation()
      elseif mesh:IsA(UE.UMeshComponent) then
        MeshPos = mesh:K2_GetComponentLocation()
      end
      local distance = UE.UKismetMathLibrary.Vector_Distance(CameraPos, MeshPos)
      local alpha = (distance - self._petFadeMinDistance) / self._petDistance
      alpha = math.min(0.8, alpha)
      alpha = math.max(0, alpha)
      if meshList[mesh] then
        meshList[mesh] = math.min(meshList[mesh], alpha)
      else
        meshList[mesh] = alpha
      end
    end
    return meshList
  end
  return nil
end

function FadeComponent:LerpAlpha(cur, tar, deltaTime)
  if cur == tar then
    return cur
  end
  if tar < cur then
    cur = cur - deltaTime * self._lerpSpeed
    cur = math.max(cur, tar, 0)
    return cur
  end
  if tar > cur then
    cur = cur + deltaTime * self._lerpSpeed
    cur = math.min(cur, tar, 1)
    return cur
  end
end

function FadeComponent:ApplyFadeRule(func)
  local id = self.ID
  self.ID = self.ID + 1
  self._fadeRules[id] = func
  return id
end

function FadeComponent:RemoveFadeRule(id)
  if self._fadeRules[id] then
    self._fadeRules[id] = nil
  end
end

function FadeComponent:SetFadeSpeed(fadeSpeed)
  self._lerpSpeed = fadeSpeed
end

function FadeComponent:ResetFadeSpeed()
  self._lerpSpeed = self._defaultLerpSpeed
end

function FadeComponent:AddCommonMesh(mesh)
  if not mesh:IsA(UE.AActor) and not mesh:IsA(UE.UMeshComponent) then
    Log.Error("\230\179\168\229\134\140\231\154\132\229\141\138\233\128\143\231\137\169\228\189\147\233\157\158actor\230\136\150meshComponent\231\177\187\229\158\139")
    return
  end
  if self.PlayerCameraManager and self.PlayerCameraManager.CommonFadeMesh then
    self.PlayerCameraManager.CommonFadeMesh:Add(mesh)
  end
  if not self._commonFadeMesh[mesh] then
    self._commonFadeMesh[mesh] = 1
  end
end

function FadeComponent:RemoveCommonMesh(mesh)
  if not mesh:IsA(UE.AActor) and not mesh:IsA(UE.UMeshComponent) then
    Log.Error("\230\179\168\229\134\140\231\154\132\229\141\138\233\128\143\231\137\169\228\189\147\233\157\158actor\230\136\150meshComponent\231\177\187\229\158\139")
    return
  end
  self.PlayerCameraManager.CommonFadeMesh:RemoveItem(mesh)
  if self._commonFadeMesh[mesh] then
    self._commonFadeMesh[mesh] = nil
  end
end

function FadeComponent:EnableCommonFade(isEnable)
  self._enableCommonFade = isEnable
end

function FadeComponent:SetFadeRange(minDis, maxDis)
  self._commonFadeMinDistance = minDis
  self._commonFadeMaxDistance = maxDis
  self._commonDistance = self._commonFadeMaxDistance - self._commonFadeMinDistance
end

function FadeComponent:SetMeshFade(mesh, alpha)
  self._fadeMeshAlpha[mesh] = alpha
  if mesh.SetFadeAlpha then
    mesh:SetFadeAlpha(1 - alpha)
  elseif mesh.SetMeshAlpha then
    mesh:SetMeshAlpha(1 - alpha)
  else
    UE.URocoPlayerBlueprintFunctionLibrary.SetCharacterAlpha(mesh, 1 - alpha)
  end
end

function FadeComponent:OnLobbyMainInnerOpened()
  self._lobbyMainInnerFadeId = ARocoPlayerCameraManager_ApplyOnLobbyMainInnerOpenedRuleLua(self.PlayerCameraManager)
  Log.Debug("###jayzhong FadeComponent:OnLobbyMainInnerOpened ", self._lobbyMainInnerFadeId)
end

function FadeComponent:OnLobbyMainInnerOpened2()
  self._lobbyMainInnerFadeMesh = {}
  self._lobbyMainInnerFadeId = self:ApplyFadeRule(function()
    local cameraLocation = self.PlayerCameraManager:GetCameraLocation()
    local playerLocation = self.owner.viewObj:K2_GetActorLocation()
    local TraceObject = {
      UE4.ECollisionChannel.ECC_WorldStatic,
      UE4.ECollisionChannel.ECC_WorldDynamic,
      UE4.ECollisionChannel.ECC_Pawn
    }
    local HitActors = {
      self.owner.viewObj
    }
    local HitMeshs = {}
    local HitResults
    local bHit = true
    while bHit do
      bHit = false
      HitResults, bHit = UE.UKismetSystemLibrary.SphereTraceMultiForObjects(self.PlayerCameraManager, playerLocation, cameraLocation, 50, TraceObject, false, HitActors, UE.EDrawDebugTrace.None)
      HitResults = HitResults:ToTable()
      for _, Hit in pairs(HitResults) do
        bHit = true
        if not HitMeshs[Hit.Actor] then
          table.insert(HitActors, Hit.Actor)
          HitMeshs[Hit.Actor] = Hit.Component
        end
      end
    end
    local FadeMesh = {}
    for _, actor in pairs(HitActors) do
      if actor:IsA(UE.ACharacter) and actor ~= self.owner.viewObj then
        local target = actor.Mesh
        if actor.SetFadeAlpha or actor.SetMeshAlpha then
          target = actor
        end
        FadeMesh[target] = 0
      end
    end
    for actor, mesh in pairs(HitMeshs) do
      if self._lobbyMainInnerFadeMesh[actor] == nil and self._lobbyMainInnerFadeMesh[mesh] == nil and (FadeMesh[actor] or FadeMesh[mesh]) then
        if actor.IgnoreCameraCollision then
          actor:IgnoreCameraCollision()
          self._lobbyMainInnerFadeMesh[actor] = 1
        else
          local OldType = mesh:GetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera)
          mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Ignore)
          self._lobbyMainInnerFadeMesh[mesh] = OldType
        end
      end
    end
    return FadeMesh
  end)
end

function FadeComponent:OnLobbyMainInnerClosed()
  Log.Debug("###jayzhong FadeComponent:OnLobbyMainInnerClosed ", self._lobbyMainInnerFadeId)
  if self._lobbyMainInnerFadeId then
    ARocoPlayerCameraManager_RemoveFadeRuleLua(self._lobbyMainInnerFadeId, self.PlayerCameraManager)
    self._lobbyMainInnerFadeId = nil
  end
end

function FadeComponent:OnLobbyMainInnerClosed2()
  if self._lobbyMainInnerFadeId then
    self:RemoveFadeRule(self._lobbyMainInnerFadeId)
    self._lobbyMainInnerFadeId = nil
    for target, type in pairs(self._lobbyMainInnerFadeMesh) do
      if target.RecoverCameraCollision then
        target:RecoverCameraCollision()
      else
        target:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, type)
      end
    end
    self._lobbyMainInnerFadeMesh = {}
  end
end

return FadeComponent

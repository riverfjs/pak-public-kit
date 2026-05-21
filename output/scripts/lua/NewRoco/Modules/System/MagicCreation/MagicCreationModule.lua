local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MagicCreationUtils = require("NewRoco.Modules.System.MagicCreation.MagicCreationUtils")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local MagicCreateEnumType = ProtoEnum.SceneMagicType.SMT_CREATE
local MagicCreationModule = NRCModuleBase:Extend("MagicCreationModule")

function MagicCreationModule:OnConstruct()
  _G.MagicCreationModuleCmd = reload("NewRoco.Modules.System.MagicCreation.MagicCreationModuleCmd")
  self.bDrawDebugFlag = false
  self.creations = {}
  self.bornTimeDiffAsFirstAppearance = 6
  self.preperformStatus = {}
  self.distancePairNpc = 50
  local angle = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "planeness_allowance_angle", "num", 10)
  self.PlanenessNormalCosineAllowance = math.cos(angle * math.pi / 180.0)
  self.PlanenessCheckCircleNum = 2
  self.PlanenessCheckPointEachCircle = 3
  self.PlanenessCheckAngleEachPoint = 360.0 / self.PlanenessCheckPointEachCircle
  self.PlanenessHeightDifference = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "planeness_allowance_height", "num", 25)
  self.PlanenessInvalidTolerance = tonumber(MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "planeness_allowance_failed_point_ratio", "str", 0.2)) or 0.2
  self.NexusMaxDifferenceHeightWithPlayer = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "nexus_overlap_land_height_allowance", "num", 100)
  self.NexusMaxDifferenceHeightWithPlayer = math.abs(self.NexusMaxDifferenceHeightWithPlayer)
  self.EavesCheckExtraHeightBottom = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "nexus_overlap_interactive_topcheck_start", "num", 200)
  self.EavesCheckExtraHeightTop = MagicCreationUtils.TryGetGlobalConfig(_G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG, "nexus_overlap_interactive_topcheck_end", "num", 600)
  self.EavesCheckExtent = (self.EavesCheckExtraHeightTop - self.EavesCheckExtraHeightBottom) / 2.0
end

function MagicCreationModule:OnActive()
  self:RegPanel("TransferNpcPanel", "UMG_MagicCreationPanel", _G.Enum.UILayerType.UI_LAYER_MAIN, "In", "Out")
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function MagicCreationModule:OnDeactive()
  if self.creations then
    for _, creation in pairs(self.creations) do
      if creation and creation.magicCreationDelayHandle then
        _G.DelayManager:CancelDelayById(creation.magicCreationDelayHandle)
        creation.magicCreationDelayHandle = nil
      end
    end
  end
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function MagicCreationModule:RegPanel(name, path, layer, openAnimName, closeAnimName)
  local MainPanelData = _G.NRCPanelRegisterData()
  MainPanelData.panelName = name
  MainPanelData.panelPath = string.format("/Game/NewRoco/Modules/System/MagicCreation/Res/%s", path)
  MainPanelData.panelLayer = layer
  if openAnimName then
    MainPanelData.openAnimName = openAnimName
  end
  if closeAnimName then
    MainPanelData.closeAnimName = closeAnimName
  end
  self:RegisterPanel(MainPanelData)
end

function MagicCreationModule:OpenTransferNpcPanel(action)
  if not self:HasPanel("TransferNpcPanel") then
    self:OpenPanel("TransferNpcPanel", action)
  end
end

function MagicCreationModule:CloseTransferNpcPanel()
  if self:HasPanel("TransferNpcPanel") or self:IsPanelInOpening("TransferNpcPanel") then
    self:ClosePanel("TransferNpcPanel")
  end
end

function MagicCreationModule:RegisterCreation(npc)
  if nil == npc then
    return
  end
  local actor_id = npc:GetServerId()
  if nil == self.creations[actor_id] then
    self.creations[actor_id] = npc
  else
    return
  end
  for _, status in pairs(self.preperformStatus) do
    if status.networkId == npc:GetServerId() then
      status.networkNpc = npc
      break
    end
    if self:CheckNpcIsPair(status.localNpc, npc) then
      status.networkNpc = npc
      break
    end
  end
  npc:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnNetworkViewObjLoaded)
end

function MagicCreationModule:UnregisterCreation(npc)
  if nil == npc then
    return
  end
  local actor_id = npc:GetServerId()
  if nil ~= self.creations[actor_id] then
    table.removeKey(self.creations, actor_id)
  end
end

function MagicCreationModule:RegisterPreperform(npc)
  if nil == npc then
    return
  end
  local bHasRegistered = false
  for _, status in pairs(self.preperformStatus) do
    if status.localNpc == npc then
      bHasRegistered = true
      break
    end
  end
  if false == bHasRegistered then
    table.insert(self.preperformStatus, {
      localNpc = npc,
      networkNpc = nil,
      localReady = false,
      networkReady = false
    })
  end
  self:SetNpcAppearance(npc, MagicCreationUtils.NpcValidType.Normal)
  local viewObj = npc.viewObj
  if viewObj then
    viewObj.bSkipOverlapCheck = true
  end
end

function MagicCreationModule:UnregisterPreperform(npc)
  if nil == npc then
    return
  end
  for _, status in pairs(self.preperformStatus) do
    if status.localNpc == npc then
      table.removeValue(self.preperformStatus, status)
      break
    end
  end
  MagicCreationUtils.StopNpcSkill(npc)
  npc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
  npc:Destroy()
  npc = nil
end

function MagicCreationModule:MakePreperformPair(localNpc, networkId)
  for _, status in pairs(self.preperformStatus) do
    if status.localNpc == localNpc then
      local networkNpc = self.creations[networkId]
      if networkNpc then
        status.networkReady = true
        status.networkNpc = networkNpc
        self:TryCompleteLocalPrePerformance(status)
        break
      end
      status.networkId = networkId
      break
    end
  end
end

function MagicCreationModule:CheckNpcIsPair(npcA, npcB)
  if nil == npcA or nil == npcB then
    return false
  end
  if npcA.config.id ~= npcB.config.id then
    return false
  end
  local positionA = npcA:GetActorLocation()
  local positionB = LuaMathUtils.ConvPositionToVector(npcB.serverData.base.pt.pos)
  local distance = (positionA - positionB):Size()
  if distance > self.distancePairNpc then
    return false
  end
  return true
end

function MagicCreationModule:PreperformLocalReady(npc)
  for _, status in pairs(self.preperformStatus) do
    if status.localNpc == npc then
      status.localReady = true
      self:TryCompleteLocalPrePerformance(status)
      break
    end
  end
end

function MagicCreationModule:OnNetworkViewObjLoaded(npc)
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnNetworkViewObjLoaded)
  for _, status in pairs(self.preperformStatus) do
    if status.networkNpc == npc then
      status.networkReady = true
      if not self:TryCompleteLocalPrePerformance(status) then
        npc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
      end
      return
    end
  end
  self:CompleteNetworkNpc(npc)
end

function MagicCreationModule:TryCompleteLocalPrePerformance(status)
  if nil == status then
    return false
  end
  if status.localReady == false or false == status.networkReady then
    return false
  end
  local localNpc = status.localNpc
  if localNpc then
    local blockActor = localNpc.tempBlockActor
    if blockActor then
      blockActor:K2_DestroyActor()
    end
    localNpc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
    localNpc:Destroy()
  end
  if status.networkNpc then
    self:CompleteNetworkNpc(status.networkNpc)
  end
  table.removeValue(self.preperformStatus, status)
  return true
end

function MagicCreationModule:CompleteNetworkNpc(npc)
  if nil == npc then
    return
  end
  if not npc.viewObj then
    return
  end
  local viewObj = npc.viewObj
  if viewObj.PlayLoopSound then
    viewObj:PlayLoopSound()
  end
  if viewObj.Activate then
    viewObj:Activate()
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    npc:AddEventListener(self, NPCModuleEvent.OptActionNotify, self.OnCreationCreateActionNotify)
    npc:AddEventListener(self, NPCModuleEvent.On_NPC_Die, self.OnCreationDieInVisitMode)
    if npc:IsFirstAppearance() then
      local currentTimeStamp = _G.ZoneServer:GetServerTime() / 1000.0
      local serverBornTimeStamp = npc.serverData.base.born_time
      if currentTimeStamp - serverBornTimeStamp > self.bornTimeDiffAsFirstAppearance then
        Log.Debug("MagicCreationModule:IsFirstAppearance Not Real First", npc:DebugNPCNameAndID(), currentTimeStamp, serverBornTimeStamp)
        return
      end
      Log.Debug("MagicCreationModule:IsFirstAppearance", npc:DebugNPCNameAndID(), currentTimeStamp, serverBornTimeStamp)
      npc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
      MagicCreationUtils.PlayCreatingSkill(npc)
      npc.magicCreationDelayHandle = _G.DelayManager:DelaySeconds(0.05, function()
        npc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
        npc.magicCreationDelayHandle = nil
      end)
      return
    end
  end
  npc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.MagicCreationPerform)
end

function MagicCreationModule:SetNpcAppearance(npc, validType)
  local viewObj = npc.viewObj
  if not UE4.UObject.IsValid(viewObj) then
    return
  end
  if nil == validType or validType == MagicCreationUtils.NpcValidType.Valid then
    if viewObj.MagicTrue then
      viewObj:MagicTrue()
    end
  elseif validType == MagicCreationUtils.NpcValidType.Normal then
    if viewObj.Appear then
      viewObj:Appear()
    end
    if not npc:IsLocal() and not npc:IsFirstAppearance() and viewObj.Activate then
      viewObj:Activate()
    end
  elseif viewObj.MagicFalse then
    viewObj:MagicFalse()
  end
end

function MagicCreationModule:ApplySuitEffect(npc)
  if not npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    npc:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.ReadyToApplySuitEffect)
    return
  end
  self:ApplySuitEffectInternal(npc)
end

function MagicCreationModule:GetMagicResource(wandId)
  local magicId
  if wandId then
    local wandConf = _G.DataConfigManager:GetFashionWandConf(wandId, true)
    if wandConf then
      magicId = wandConf.magic_list[MagicCreateEnumType]
    end
  end
  if nil == magicId or 0 == magicId then
    magicId = 1
  end
  if not magicId then
    return nil
  end
  local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
  local AvatarConfig = avatarSystem:GetAvatarConfig()
  if not AvatarConfig then
    return nil
  end
  local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, MagicCreateEnumType)
  if not RowKey then
    return nil
  end
  local wandData = UE4.FAvatarWandInfo_Create()
  UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(MagicCreateEnumType), RowKey, wandData)
  return wandData.CreateMagicResource
end

function MagicCreationModule:ApplySuitEffectInternal(npc)
  local wandId
  if npc.WandId then
    wandId = npc.WandId
  else
    if npc:IsLocal() then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player then
        wandId = player:GetCurWandId()
      end
    else
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player then
        wandId = self:GetNpcWandId(player, npc)
      end
    end
    npc.WandId = wandId
  end
  local magicConfig = self:GetMagicResource(wandId)
  if not magicConfig then
    Log.Warning("MagicCreationModule:ApplySuitEffectInternal: magicConfig is nil", npc:DebugNPCNameAndID(), npc:IsLocal())
    return
  end
  local viewObj = npc.viewObj
  if UE4.UObject.IsValid(viewObj) and viewObj.ApplySuitEffect then
    if wandId then
      local wandConf = _G.DataConfigManager:GetFashionWandConf(wandId, true)
      if wandConf then
        _G.NRCAudioManager:SetEmitterSwitch("Suit", wandConf.WandName, viewObj, "")
      end
    end
    viewObj:ApplySuitEffect(magicConfig)
  end
end

function MagicCreationModule:ReadyToApplySuitEffect(npc)
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.ReadyToApplySuitEffect)
  self:ApplySuitEffectInternal(npc)
end

function MagicCreationModule:GetNpcWandId(player, npc)
  if not player or not npc then
    return
  end
  local serverData = player.serverData
  if not serverData then
    return
  end
  local magicCreateNpcInfo = serverData.magic_create_npc_info
  if not magicCreateNpcInfo then
    return
  end
  local magicCreateNpcs = magicCreateNpcInfo.magic_create_npcs
  if not magicCreateNpcs then
    return
  end
  local npcId = npc:GetServerId()
  for _, creationInfo in pairs(magicCreateNpcs) do
    if creationInfo and creationInfo.npc_obj_id == npcId then
      return creationInfo.wand_id
    end
  end
  return
end

function MagicCreationModule:OnCreationCreateActionNotify(npc, action)
  if not npc then
    return
  end
  local actionType = action.action_type
  if actionType == Enum.ActionType.ACT_NPC_MAGIC_TRANSFER_BY_SUBMIT_ITEM then
    MagicCreationUtils.DoRecycleBp(npc)
  elseif actionType == Enum.ActionType.ACT_RETRIEVE_MAGIC_CREATURE then
    MagicCreationUtils.PlayDeletingSkill(npc)
  end
end

function MagicCreationModule:OnCreationDieInVisitMode(npc, action)
  if not npc then
    return
  end
  npc:RemoveEventListener(self, NPCModuleEvent.OptActionNotify, self.OnCreationCreateActionNotify)
  npc:RemoveEventListener(self, NPCModuleEvent.On_NPC_Die, self.OnCreationDieInVisitMode)
end

function MagicCreationModule:OnReconnect()
  for _, status in pairs(self.preperformStatus) do
    MagicCreationUtils.StopNpcSkill(status.localNpc)
    status.localNpc:Destroy()
    if status.networkNpc then
      self:CompleteNetworkNpc(status.networkNpc)
    end
  end
  table.clear(self.preperformStatus)
end

function MagicCreationModule:CheckLandValid(center, extent, centerInfo)
  local totalCheckPoints = self.PlanenessCheckCircleNum * self.PlanenessCheckPointEachCircle + 1
  local invalidTolerance = math.round(totalCheckPoints * self.PlanenessInvalidTolerance)
  local currentInvalidPoints = 0
  
  local function checkInvalidReachLimit()
    currentInvalidPoints = currentInvalidPoints + 1
    if currentInvalidPoints > invalidTolerance then
      return true
    end
    return false
  end
  
  local maxLandHeight, minLandHeight
  
  local function drawDebugSummary(position, differenceToMin, differenceToMax)
    if self:GetCanDrawDebug() ~= true then
      return
    end
    if nil == minLandHeight or nil == maxLandHeight then
      return
    end
    local debugLocation = UE4.FVector(center.X, center.Y, center.Z)
    debugLocation.Z = debugLocation.Z + 20
    local info = string.format("\232\140\131\229\155\180[%f, %f]", minLandHeight, maxLandHeight)
    local color = UE4.FLinearColor(0, 1, 0.1, 1)
    if nil ~= position and nil ~= differenceToMin and nil ~= differenceToMax then
      color = UE4.FLinearColor(1, 0.1, 0, 1)
      info = info .. string.format(";\230\138\165\233\148\153\231\130\185%f->%f", position.Z, math.max(differenceToMin, differenceToMax))
    else
      info = info .. string.format(";\233\171\152\229\186\166\229\183\174%f", maxLandHeight - minLandHeight)
    end
    UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), debugLocation, info, nil, color, 0.03333333333333333)
  end
  
  local function checkPlaneness(position, inLandInfo)
    if nil == inLandInfo then
      self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Planeness_NoLand, position, nil, nil, true)
      return MagicCreationUtils.NpcValidType.Planeness_NoLand
    end
    if not inLandInfo.position or not inLandInfo.normal then
      self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Planeness_NoLand, position, nil, nil, true)
      return MagicCreationUtils.NpcValidType.Planeness_NoLand
    end
    if nil == maxLandHeight and nil == minLandHeight then
      maxLandHeight = inLandInfo.position.Z
      minLandHeight = inLandInfo.position.Z
      self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Valid, center, inLandInfo, nil)
    else
      local differenceToMin = math.abs(inLandInfo.position.Z - minLandHeight)
      local differenceToMax = math.abs(inLandInfo.position.Z - maxLandHeight)
      if differenceToMin > self.PlanenessHeightDifference or differenceToMax > self.PlanenessHeightDifference then
        self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Planeness_Height, center, inLandInfo, nil, false)
        drawDebugSummary(inLandInfo.position, differenceToMin, differenceToMax)
        return MagicCreationUtils.NpcValidType.Planeness_Height
      else
        maxLandHeight = math.max(maxLandHeight, inLandInfo.position.Z)
        minLandHeight = math.min(minLandHeight, inLandInfo.position.Z)
        self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Valid, center, inLandInfo, nil)
      end
    end
    local normalDifference = UE4.UKismetMathLibrary.Dot_VectorVector(_G.UE4Helper.UpVector, inLandInfo.normal)
    if normalDifference < self.PlanenessNormalCosineAllowance then
      if checkInvalidReachLimit() then
        self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Planeness_Angle, center, inLandInfo, nil, false)
        return MagicCreationUtils.NpcValidType.Planeness_Angle
      end
      self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Planeness_Angle, center, inLandInfo, nil, true)
    end
    return MagicCreationUtils.NpcValidType.Valid
  end
  
  local function checkIsOnWater(landInfo)
    if nil == landInfo then
      return false
    end
    if landInfo.bIsWater then
      self:DrawDebugValidCheck(MagicCreationUtils.NpcValidType.Water, center, landInfo)
      return true
    end
    return false
  end
  
  if checkIsOnWater(centerInfo) then
    return MagicCreationUtils.NpcValidType.Water
  end
  local centerCheckResult = checkPlaneness(center, centerInfo)
  if centerCheckResult ~= MagicCreationUtils.NpcValidType.Valid then
    return centerCheckResult
  end
  local checkCircleSpacing = math.max(extent.X, extent.Y) / self.PlanenessCheckCircleNum
  for circleIdx = 1, self.PlanenessCheckCircleNum do
    local checkRadius = circleIdx * checkCircleSpacing
    for pointIdx = 0, self.PlanenessCheckPointEachCircle - 1 do
      local angle = pointIdx * self.PlanenessCheckAngleEachPoint
      local radian = angle * math.pi / 180
      local checkPosition = UE4.FVector(center.X + checkRadius * math.cos(radian), center.Y + checkRadius * math.sin(radian), center.Z)
      local positionInfo = MagicCreationUtils.GetSurfaceInfo(checkPosition)
      local checkResult = checkPlaneness(checkPosition, positionInfo)
      if checkIsOnWater(positionInfo) then
        return MagicCreationUtils.NpcValidType.Water
      end
      if checkResult ~= MagicCreationUtils.NpcValidType.Valid then
        return checkResult
      end
    end
  end
  drawDebugSummary()
  return MagicCreationUtils.NpcValidType.Valid
end

function MagicCreationModule:CheckNpcHeightDifferenceWithPlayer(center, centerInfo)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil == player then
    return MagicCreationUtils.NpcValidType.Invalid
  end
  if nil == centerInfo then
    if self:GetCanDrawDebug() then
      Log.Debug("MagicCreationModule:CheckNpcHeightDifferenceWithPlayer no land info", center.X, center.Y, center.Z)
    end
    return MagicCreationUtils.NpcValidType.Pit
  end
  local landHeight = centerInfo.position.Z
  local playerAbsOrigin = player:GetActorLocation()
  local playerOrigin = SceneUtils.ConvertAbsoluteToRelative(playerAbsOrigin)
  local playerHalfHeight = player:GetScaledHalfHeight()
  local playerHeight = playerOrigin.Z - playerHalfHeight
  local heightDifference = landHeight - playerHeight
  if heightDifference > self.NexusMaxDifferenceHeightWithPlayer then
    if self:GetCanDrawDebug() then
      UE4.UKismetSystemLibrary.DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), UE4.FVector(playerOrigin.X, playerOrigin.Y, playerHeight), centerInfo.position, 10, UE.FLinearColor(1, 0, 0, 1), 0.03333333333333333, 2)
      Log.Debug("MagicCreationModule:CheckNpcHeightDifferenceWithPlayer Cliff", landHeight, playerOrigin.Z, playerHalfHeight, playerHeight, heightDifference)
    end
    return MagicCreationUtils.NpcValidType.Cliff
  end
  if heightDifference < -self.NexusMaxDifferenceHeightWithPlayer then
    if self:GetCanDrawDebug() then
      UE4.UKismetSystemLibrary.DrawDebugArrow(_G.UE4Helper.GetCurrentWorld(), UE4.FVector(playerOrigin.X, playerOrigin.Y, playerHeight), centerInfo.position, 10, UE.FLinearColor(1, 0, 0, 1), 0.03333333333333333, 2)
      Log.Debug("MagicCreationModule:CheckNpcHeightDifferenceWithPlayer Pit", landHeight, playerOrigin.Z, playerHalfHeight, playerHeight, heightDifference)
    end
    return MagicCreationUtils.NpcValidType.Pit
  end
  return MagicCreationUtils.NpcValidType.Valid
end

function MagicCreationModule:CheckEavesExisted(center, extent, rotation, actorsToIgnore, duration)
  local world = _G.UE4Helper.GetCurrentWorld()
  local checkCenterHeight = center.Z + self.EavesCheckExtraHeightBottom + self.EavesCheckExtent
  local checkCenter = UE4.FVector(center.X, center.Y, checkCenterHeight)
  local checkExtent = UE4.FVector(extent.X, extent.Y, self.EavesCheckExtent)
  local traceObjectTypes = {
    UE4.EObjectTypeQuery.WorldDynamic,
    UE4.EObjectTypeQuery.WorldStatic
  }
  local drawDebugType = UE4.EDrawDebugTrace.None
  local traceColor, traceHitColor, drawTime
  if self:GetCanDrawDebug() then
    drawDebugType = UE4.EDrawDebugTrace.ForDuration
    traceColor = UE4.FLinearColor(0.2, 0.8, 0.2, 1)
    traceHitColor = UE4.FLinearColor(0.9, 0.6, 0.3, 1)
    drawTime = duration or 0.1
  end
  if nil == actorsToIgnore then
    actorsToIgnore = {}
  end
  local queryParams = UE4.FNRCollisionQueryParams()
  queryParams.OwnerTag = "MagicCreationModule"
  queryParams.TraceTag = "Eaves"
  local components = UE4.UNRCTraceLibrary.BoxOverlapComponents(_G.UE4Helper.GetCurrentWorld(), checkCenter, checkExtent, rotation, traceObjectTypes, UE4.UStaticMeshComponent, queryParams, nil, drawDebugType, traceColor, traceHitColor, drawTime)
  local ignoreActorClass = {
    UE4.ARocoVehicleCharacter,
    UE4.ANPCBaseActor,
    UE4.ARocoCharacter
  }
  
  local function judgeComponent(component)
    if not UE4.UObject.IsValid(component) then
      return false
    end
    local actor = component:GetOwner()
    if not UE4.UObject.IsValid(actor) then
      return false
    end
    for _, class in pairs(ignoreActorClass) do
      if actor:IsA(class) then
        return false
      end
    end
    local collisionEnabled = component:GetCollisionEnabled()
    if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
      return false
    end
    return true
  end
  
  for _, component in tpairs(components) do
    if judgeComponent(component) then
      if self:GetCanDrawDebug() then
        UE4.UKismetSystemLibrary.DrawDebugString(world, checkCenter + UE4.FVector(0, 0, 50), UE4.UKismetSystemLibrary.GetDisplayName(component), nil, UE4.FLinearColor(0.2, 0.4, 0.8, 1), duration)
      end
      return true
    end
  end
  return false
end

function MagicCreationModule:GetCanDrawDebug()
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bDrawDebugFlag == true
end

function MagicCreationModule:DrawDebugValidCheck(type, center, landInfo, isTolerated)
  if self:GetCanDrawDebug() ~= true then
    return
  end
  local world = _G.UE4Helper.GetCurrentWorld()
  local duration = 0.03333333333333333
  local color = UE4.FLinearColor(1, 0.1, 0, 1)
  if isTolerated then
    color = UE4.FLinearColor(0.6, 0.4, 0, 1)
  end
  if type == MagicCreationUtils.NpcValidType.Planeness_NoLand then
    UE4.UKismetSystemLibrary.DrawDebugString(world, center, "\230\151\160\229\156\176\233\157\162", nil, color, duration)
  elseif type == MagicCreationUtils.NpcValidType.Planeness_Angle then
    local arrowLength = 300
    if isTolerated then
      arrowLength = 150
    end
    local startPosition = UE4.FVector(landInfo.position.X, landInfo.position.Y, landInfo.position.Z)
    local endPosition = startPosition + UE4.FVector(landInfo.normal.X, landInfo.normal.Y, landInfo.normal.Z) * arrowLength
    UE4.UKismetSystemLibrary.DrawDebugArrow(world, startPosition, endPosition, 10, color, duration, 2)
  elseif type == MagicCreationUtils.NpcValidType.Planeness_Height then
    UE4.UKismetSystemLibrary.DrawDebugString(world, landInfo.position, landInfo.position.Z, nil, color, duration)
  elseif type == MagicCreationUtils.NpcValidType.Valid then
    UE4.UKismetSystemLibrary.DrawDebugString(world, landInfo.position, landInfo.position.Z, nil, UE4.FLinearColor(0.2, 1, 0, 1), duration)
  elseif type == MagicCreationUtils.NpcValidType.Water and nil ~= landInfo then
    local point = UE4.FVector(landInfo.position.X, landInfo.position.Y, landInfo.position.Z)
    UE4.UKismetSystemLibrary.DrawDebugSphere(world, point, 20, 8, UE4.FLinearColor(0, 0, 1, 1), duration, 2)
  end
end

return MagicCreationModule

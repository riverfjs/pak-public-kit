local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ResonanceComponent = Base:Extend("ResonanceComponent")
local DefaultTotalTime = 6.43
local BGMName = "Music_Season_Pet_Ride"
local HeartBeatInterval = 0.2
local VisibleRadiusSquared = 16000000

local function SyncOtherPlayerFrequency(OtherPlayer, TargetTime)
  if OtherPlayer then
    local ResComp = OtherPlayer.ResonanceComponent
    if ResComp then
      ResComp:SynchronizeFrequency(TargetTime)
    end
  end
end

local EveryNearbyExecute = function(ExSet, uid, Func, ...)
  if not Func then
    return
  end
  local CurrentPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, uid)
  if not CurrentPlayer then
    return
  end
  Func(CurrentPlayer, ...)
  local curComp = CurrentPlayer.ResonanceComponent
  if not curComp or not curComp.directlyAssociatedPlayers then
    return
  end
  for otherId in pairs(curComp.directlyAssociatedPlayers) do
    if not ExSet[otherId] then
      ExSet[otherId] = true
      EveryNearbyExecute(ExSet, otherId, Func, ...)
    end
  end
end

local function FindNearByPartners(RadiusSquared, SpecificPets, Constraint)
  local Result = {}
  if not RadiusSquared or RadiusSquared <= 0 then
    return Result
  end
  local allPlayers = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_ALL_PLAYER)
  if not allPlayers then
    return Result
  end
  local OnlyDoubleRide
  for _, v in pairs(allPlayers) do
    local player = v
    if not (player and UE.UObject.IsValid(player.viewObj)) or player.viewObj:GetActorHidden() then
    elseif player.isLocal then
    elseif player.squaredDis2Local and RadiusSquared < player.squaredDis2Local then
    elseif Constraint and not Constraint(player) then
    elseif not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    else
      local rideComp = player.viewObj.BP_RideComponent
      if rideComp and rideComp:IsInDoubleRide() then
        local anotherTogetherPlayer = player:GetAnotherTogetherMovePlayer()
        if rideComp.bIsDoubleRide2p then
          rideComp = anotherTogetherPlayer and anotherTogetherPlayer.viewObj.BP_RideComponent or nil
        end
        if anotherTogetherPlayer then
          if not anotherTogetherPlayer.isLocal then
            OnlyDoubleRide = false
          elseif nil == OnlyDoubleRide then
            OnlyDoubleRide = true
          end
        end
      else
        OnlyDoubleRide = false
      end
      if nil == rideComp or nil == rideComp.ScenePet then
      elseif SpecificPets[rideComp.ScenePet.config.id] then
        Result[player:GetServerId()] = true
      end
    end
  end
  return Result, OnlyDoubleRide
end

local function UnionTable(Src, Dst)
  for v in pairs(Src) do
    if not Dst[v] then
      Src[v] = nil
    end
  end
  for v in pairs(Dst) do
    if not Src[v] then
      Src[v] = true
    end
  end
end

function ResonanceComponent:Ctor()
  self.directlyAssociatedPlayers = {}
  self._radiusSquared = 0
  self._associatedPlayers = {}
  self._specificPets = {}
  self._activated = false
  self._statusBlock = false
  self.dancing = false
  self._lastSyncDance = false
  self._danceTime = 0
  self._autoSyncTime = 0
  self._totalTime = DefaultTotalTime
  self._curRate = 1
end

function ResonanceComponent:Attach(owner)
  self.owner = owner
  self.statusComponent = owner.statusComponent
  self._activated = false
  self:SetEnable(true)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnPlayerStatusRefresh)
  local config = DataConfigManager:GetRidePassiveSkill(7001)
  local pet_ids = string.split(config.param_2, ";")
  for _, v in ipairs(pet_ids) do
    self._specificPets[tonumber(v)] = true
  end
end

function ResonanceComponent:DeAttach()
  self._activated = false
  self:SetEnable(false)
  if self.owner then
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
    self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnPlayerStatusRefresh)
  end
  self.owner = nil
  self.statusComponent = nil
end

function ResonanceComponent:ActivateByPassiveSkill(RadiusSquared, AnimName, Enable)
  self._activated = Enable
  self._radiusSquared = RadiusSquared or 0
  table.clear(self.directlyAssociatedPlayers)
  if Enable then
    local uePlayer = self.owner.viewObj
    if UE4.UObject.IsValid(uePlayer) then
      local AnimInstance = uePlayer.Mesh and uePlayer.Mesh:GetAnimInstance()
      if AnimInstance then
        self.RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
        if "" ~= AnimName then
          local AnimPath = string.format("AnimSequence'/Game/ArtRes/AnimSequence/Human/PC/PC%d/Animation/%s.%s'", self.owner.gender, AnimName, AnimName)
          if string.EndsWith(AnimName, "L") then
            self.RideAllAnimInstance.bDLCDoubleHand = false
            self.RideAllAnimInstance.bDLCLeftHand = true
          elseif string.EndsWith(AnimName, "R") then
            self.RideAllAnimInstance.bDLCDoubleHand = false
            self.RideAllAnimInstance.bDLCLeftHand = false
          else
            self.RideAllAnimInstance.bDLCDoubleHand = true
            self.RideAllAnimInstance.bDLCLeftHand = false
          end
          local Anim = _G.PlayerResourceManager:GetStaticResource(AnimPath)
          if Anim then
            self.Anim = Anim
            self.RideAllAnimInstance.Anim_Resonance = self.Anim
            self._totalTime = self.Anim:GetPlayLength()
          else
            Log.ErrorFormat("ResonanceComponent:ActivateByPassiveSkill Anim %s Load Failed: ", AnimPath)
          end
        end
      end
    end
  end
  self:OnDanceChanged(false)
end

function ResonanceComponent:Update(deltaTime)
  if self.dancing then
    self._danceTime = self._danceTime + deltaTime * self._curRate
    if self._danceTime >= self._totalTime then
      self._danceTime = self._danceTime - self._totalTime
    end
    if self.RideAllAnimInstance then
      self.RideAllAnimInstance.ResonanceTime = self._danceTime
    end
  end
  if self.owner.isLocal then
    if self._activated and not self._statusBlock then
      local CurrentNearby, OnlyDoubleRide = FindNearByPartners(self._radiusSquared, self._specificPets)
      UnionTable(self.directlyAssociatedPlayers, CurrentNearby)
      table.clear(self._associatedPlayers)
      if next(self.directlyAssociatedPlayers) ~= nil then
        for uid, _ in pairs(self.directlyAssociatedPlayers) do
          self._associatedPlayers[uid] = true
          EveryNearbyExecute(self._associatedPlayers, uid, SyncOtherPlayerFrequency, self._danceTime)
        end
        self:OnDanceChanged(not OnlyDoubleRide)
      else
        self:OnDanceChanged(false)
      end
      self._autoSyncTime = self._autoSyncTime + deltaTime
      if self._autoSyncTime >= HeartBeatInterval then
        self._autoSyncTime = self._autoSyncTime - HeartBeatInterval
        self:SyncDanceData(true)
      end
    end
    local VisibleOthers = FindNearByPartners(VisibleRadiusSquared, self._specificPets, function(player)
      return not self._associatedPlayers[player:GetServerId()] and player.ResonanceComponent and player.ResonanceComponent.dancing
    end)
    local HasSynced = {}
    if next(VisibleOthers) ~= nil then
      for uid, _ in pairs(VisibleOthers) do
        if not HasSynced[uid] then
          HasSynced[uid] = true
          local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, uid)
          if player then
            EveryNearbyExecute(HasSynced, uid, SyncOtherPlayerFrequency, player.ResonanceComponent._danceTime)
          end
        end
      end
    end
  end
  if GlobalConfig.DrawDebugResonance then
    local names = {}
    for uid, _ in pairs(self.directlyAssociatedPlayers) do
      local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, uid)
      if player then
        table.insert(names, player.serverData.base.name)
      end
    end
    UE4.UKismetSystemLibrary.Abs_DrawDebugString(UE4Helper.GetCurrentWorld(), self.owner:GetActorLocation() + UE.FVector(0, 0, 100), string.format([=[
%.2f / %.2f (%.2fx)
[Player In Area]]=], self._danceTime, self._totalTime, self._curRate) .. "\n" .. table.concat(names, "\n"), nil, UE4.FLinearColor(1, 0.8, 0, 1), deltaTime)
    UE4.UKismetSystemLibrary.Abs_DrawDebugCircle(UE4Helper.GetCurrentWorld(), self.owner:GetActorLocation() - UE.FVector(0, 0, 100), math.sqrt(self._radiusSquared), 100, UE4.FLinearColor(0, 1, 0, 1), deltaTime, 10, UE.FVector(1, 0, 0), UE.FVector(0, 1, 0))
  end
end

function ResonanceComponent:OnStatusChanged(status)
  if not self._activated then
    return
  end
  if self.statusComponent then
    self._statusBlock = self.statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING)
    if self._statusBlock then
      self:OnDanceChanged(false)
    end
    if self.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
      self._totalTime = DefaultTotalTime
    else
      self._totalTime = self.Anim and self.Anim:GetPlayLength() or DefaultTotalTime
    end
  end
end

function ResonanceComponent:OnDanceChanged(bEnable)
  if nil == bEnable or self.dancing == bEnable then
    return
  end
  Log.Debug("ResonanceComponent:OnDanceChanged", bEnable, self.owner.serverData.base.actor_id)
  self.dancing = bEnable
  self._danceTime = 0
  self._curRate = 1
  if self.RideAllAnimInstance then
    self.RideAllAnimInstance.bResonance = bEnable
    self.RideAllAnimInstance.ResonanceTime = 0
  end
  if self.owner.isLocal then
    if bEnable then
      self.LoopSoundSessionID = NRCAudioManager:PlaySound2DByEventNameAuto(BGMName, "Resonance")
    elseif self.LoopSoundSessionID then
      NRCAudioManager:ReleaseSession(self.LoopSoundSessionID, true, "Resonance")
      self.LoopSoundSessionID = nil
    end
    self:SyncDanceData()
  end
end

function ResonanceComponent:SyncDanceData(auto)
  if self.dancing == self._lastSyncDance and not auto then
    return
  end
  self._lastSyncDance = self.dancing
  Log.Debug("ResonanceComponent:SyncDanceData", self._lastSyncDance, self.owner.serverData.base.actor_id)
  local customParams = self.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  local resonance_info = customParams.ride_param.resonance_info
  resonance_info.dancing = self._lastSyncDance
  if not resonance_info.player_id then
    resonance_info.player_id = {}
  else
    table.clear(resonance_info.player_id)
  end
  for k in pairs(self.directlyAssociatedPlayers) do
    table.insert(resonance_info.player_id, k)
  end
  Log.Debug(self.owner.serverData.base.name, "ResonanceComponent:SyncDanceData Players:", resonance_info.player_id and table.concat(resonance_info.player_id, ",") or "")
  self.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
end

function ResonanceComponent:OnPlayerStatusRefresh(status, value, opCode)
  if self.enabled and status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    local resonance_info = customParams.ride_param.resonance_info
    self:OnReceiveDanceData(resonance_info)
  end
end

function ResonanceComponent:OnReceiveDanceData(ResonanceInfo)
  if ResonanceInfo and next(ResonanceInfo) then
    self:OnDanceChanged(ResonanceInfo.dancing)
    Log.Debug(self.owner.serverData.base.name, "ResonanceComponent:OnReceiveDanceData Player Enter:", ResonanceInfo.player_id and table.concat(ResonanceInfo.player_id, ",") or "")
    if ResonanceInfo.player_id then
      table.clear(self.directlyAssociatedPlayers)
      for _, v in ipairs(ResonanceInfo.player_id) do
        self.directlyAssociatedPlayers[v] = true
      end
    end
  end
end

function ResonanceComponent:SynchronizeFrequency(TargetTime)
  if TargetTime then
    self._curRate = math.clamp((self._totalTime - self._danceTime + 0.001) / (self._totalTime - TargetTime + 0.001), 0.5, 2)
  end
end

return ResonanceComponent

require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.Character.Player.BP_WorldPlayer_C")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local MainUICmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local BitSwitch = require("Utils.BitSwitch")
local StringCache = require("Utils.StringCache")
local BP_WorldLocalPlayer_C = Base:Extend("BP_WorldLocalPlayer_C")

function BP_WorldLocalPlayer_C:ReceiveBeginPlay()
  self._characterMoveTickSwitch = BitSwitch.new("CharacterMovementComponentTickDisable")
  self:CallOverriddenFunc("ReceiveBeginPlay", self)
  if self:IsLocalMode() then
    local World = _G.UE4Helper.GetCurrentWorld()
    if World and World:GetName() == "BattleCraneCamMap" then
      NRCModeManager:ActiveMode("BattleTestMapMode")
    else
      NRCModeManager:ActiveMode("LocalMode")
    end
  else
    self:SetCharacterMovementTickEnabled(false, "ReceiveBeginPlay")
  end
  if self.SetActorId then
    self:SetActorId(-1)
  end
end

function BP_WorldLocalPlayer_C:ReceiveEndPlay(EndPlayReason)
end

function BP_WorldLocalPlayer_C:SetCharacterMovementTickEnabled(enable, flag)
  local label = flag or StringCache.intern("default")
  if not enable then
    self._characterMoveTickSwitch:open(label)
  else
    self._characterMoveTickSwitch:reset()
  end
  local tickEnable = not self._characterMoveTickSwitch:is_open()
  self.CharacterMovement:SetTickEnabled(tickEnable)
end

function BP_WorldLocalPlayer_C:IsLocalMode()
  return NRCEnv:IsLocalMode()
end

function BP_WorldLocalPlayer_C:ReceiveTick(DeltaSeconds)
  self:CallOverriddenFunc("ReceiveTick", self, DeltaSeconds)
  self:CheckWillLanding()
end

function BP_WorldLocalPlayer_C:CheckWillLanding()
  if self.AirHeight > 0 and self.CharacterMovement.MovementMode ~= UE4.EMovementMode.MOVE_Swimming and self.AirHeight <= 50 and self.CharacterMovement.Velocity.Z < 0 then
    local player = self.sceneCharacter
    if player then
      player:OnWillLand()
    end
  end
end

function BP_WorldLocalPlayer_C:LuaOnEnvInfoWaterStateChanged(newStatus, oldStatus)
  local player = self.sceneCharacter
  if player then
    player:SendEvent(PlayerModuleEvent.ON_WATER_STATUS_CHANGE, newStatus, oldStatus)
  end
end

function BP_WorldLocalPlayer_C:OnLand(Hit)
  if self.BP_RideComponent and self.BP_RideComponent.RideType == UE.ERideType.RIDE_FLY then
    self.BP_RideComponent:StopRide()
  end
  Base.OnLand(self, Hit)
  UE4.URocoPlayerBlueprintFunctionLibrary.PlayTouchSound(self, 42300102)
end

function BP_WorldLocalPlayer_C:K2_OnMovementModeChanged(PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  self:CallOverriddenFunc("K2_OnMovementModeChanged", self, PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  if NewMovementMode == UE4.EMovementMode.MOVE_Swimming then
    self.CacheIsSwimming = true
  else
    self.CacheIsSwimming = false
  end
  local player = self.sceneCharacter
  if player then
    if self.CacheIsSwimming then
      if not player.buffComponent:HasBuff("RideDieshaBuff") and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
        player:StopRide()
        self:SetAnimMode(0)
      end
    elseif PrevMovementMode == UE4.EMovementMode.MOVE_Swimming then
    end
    player:SendEvent(PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  end
end

function BP_WorldLocalPlayer_C:MoveComponent(Component, TargetRelativeLocation, TargetRelativeRotation, bEaseOut, bEaseIn, OverTime, bForceShortestRotationPath)
  coroutine.resume(coroutine.create(self._LatentMoveComponentTo), self, Component, TargetRelativeLocation, TargetRelativeRotation, bEaseOut, bEaseIn, OverTime, bForceShortestRotationPath)
end

function BP_WorldLocalPlayer_C:_LatentMoveComponentTo(Component, TargetRelativeLocation, TargetRelativeRotation, bEaseOut, bEaseIn, OverTime, bForceShortestRotationPath, Callback)
  local conversion = UE4.FRotator(TargetRelativeRotation.x, TargetRelativeRotation.y, TargetRelativeRotation.z)
  UE4.UKismetSystemLibrary.MoveComponentTo(Component, TargetRelativeLocation, conversion, bEaseOut, bEaseIn, OverTime, bForceShortestRotationPath)
  if Callback then
    Callback()
  end
end

function BP_WorldLocalPlayer_C:SetEnableInput(Value)
  local player = self.sceneCharacter
  if player and player.inputComponent then
    player.inputComponent:SetInputEnable(self, Value, "BP_WorldLocalPlayer")
  end
end

function BP_WorldLocalPlayer_C:LocalThrow()
  self.sceneCharacter.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, Enum.WPST_OpCode.WPST_OPCODE_REMOVE, nil, true)
end

function BP_WorldLocalPlayer_C:CanClimb()
  local player = self.sceneCharacter
  if player and player.ClimbComponent then
    local canClimb, Reason = player.ClimbComponent:CanClimb()
    return Reason, canClimb
  end
  return "", true
end

function BP_WorldLocalPlayer_C:TiredCheck()
  self.bShouldTriggleTired = false
  self.bShouldStopTired = true
  local player = self.sceneCharacter
  if player and player.vitalityComponent then
    self.bShouldTriggleTired, self.bShouldStopTired = player.vitalityComponent:TiredCheck()
  end
  return self.bShouldTriggleTired, self.bShouldStopTired
end

function BP_WorldLocalPlayer_C:RefreshTired()
  self:TiredCheck()
end

function BP_WorldLocalPlayer_C:OnCtrlKey(action_type)
  local player = self.sceneCharacter
  local bInBattle = _G.BattleManager.isInBattle
  if player and (player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DASHING) or player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SPECIALMOVE)) or bInBattle then
    return
  end
  if player and player.inputComponent and player.inputComponent:GetPlayDialogueVideo() then
    return
  end
  if _G.CinematicModuleCmd and _G.NRCModeManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) then
    return
  end
  if self:IsInMiniGamePerform() then
    return
  end
  if 0 == action_type then
    if self.bWalkRun then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\183\178\229\136\135\230\141\162\228\184\186\232\183\145\230\173\165\231\138\182\230\128\129")
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\183\178\229\136\135\230\141\162\228\184\186\232\161\140\232\181\176\231\138\182\230\128\129")
    end
    self.bWalkRun = not self.bWalkRun
    if FriendModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    end
  end
end

function BP_WorldLocalPlayer_C:SetWalkRun(walkRun)
  if walkRun ~= self.bWalkRun then
    self.focusSetWalkRun = true
    self.bWalkRun = walkRun
  end
end

function BP_WorldLocalPlayer_C:RecoverWalkRun()
  if self.focusSetWalkRun then
    self.bWalkRun = false
    self.focusSetWalkRun = nil
  end
end

function BP_WorldLocalPlayer_C:IsInMiniGamePerform()
  if MiniGameModuleCmd then
    local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
    if "Perform" == miniGameStage then
      return true
    end
  end
  return false
end

function BP_WorldLocalPlayer_C:RandomPlayPerformAnim()
end

function BP_WorldLocalPlayer_C:SendIdleRelaxID(RelaxID)
  if not self.sceneCharacter or not self.sceneCharacter.serverData then
    return
  end
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  req.operation.operator_id = self.sceneCharacter.serverData.base.actor_id
  req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
  req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_IDLE
  req.operation.player_perform_info.idle_perform_id = RelaxID
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
end

function BP_WorldLocalPlayer_C:TrySuitRelax()
  local player = self.sceneCharacter
  if not player then
    return false
  end
  local success, result = pcall(player.PlaySuitRelax, player)
  return success and result
end

function BP_WorldLocalPlayer_C:SetFadeAlpha(alpha)
  UE.URocoPlayerBlueprintFunctionLibrary.SetCharacterAlpha(self.Mesh, alpha)
end

function BP_WorldLocalPlayer_C:IgnoreCameraCollision()
  self.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Ignore)
end

function BP_WorldLocalPlayer_C:RecoverCameraCollision()
  self.Mesh:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Block)
end

function BP_WorldLocalPlayer_C:OnHomeAnimEnd()
  if self.sceneCharacter then
    self.sceneCharacter.playerHomeInteractionComponent:OnHomeAnimEnd()
  end
end

function BP_WorldLocalPlayer_C:TestRide()
  local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
  local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
  local helper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL)
  if self.BP_RideComponent.bDebugRide then
    local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local ScenePet = ScenePlayerPet(nil, helper:GetIDByName(self.BP_RideComponent.DebugRidePetName), -ProtoEnum.SceneRideAllCustomGid.SRCG_LocalTest, player)
    helper:HandleStatus(self.sceneCharacter, ScenePet)
  elseif self.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    self.sceneCharacter.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  else
    local gid = NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
    local pet = self.sceneCharacter:GetPetByGid(gid)
    if pet and 0 == helper:CanCastAbility(self.sceneCharacter, pet) then
      helper:HandleStatus(self.sceneCharacter, pet)
    end
  end
end

function BP_WorldLocalPlayer_C:CallLuaInEditor(Params)
  if not UE4.UNRCStatics.IsEditor() then
    return
  end
  local func, err = load(Params, "BP_WorldLocalPlayer_C.lua", "t")
  if not func then
    print("Error loading string: " .. err)
  else
    func()
  end
end

function BP_WorldLocalPlayer_C:GetPanel(Name)
  return NRCModuleManager:GetModule("MainUIModule"):GetPanel(Name)
end

function BP_WorldLocalPlayer_C:ChangeGenderLocal()
  local player = self.sceneCharacter
  local gender = 1
  if 1 == player.gender then
    gender = 2
  end
  local AppearanceLocalUtils = require("NewRoco.Modules.System.Appearance.AppearanceLocalUtils")
  AppearanceLocalUtils.UpdateFashionInfo(player, gender)
  GlobalConfig.ForceLocalMode = true
  player:SetCharacterGender(gender)
  GlobalConfig.ForceLocalMode = false
end

function BP_WorldLocalPlayer_C:CallOverriddenFunc(functionName, ...)
  if self.Overridden == self then
    local warning = string.format("BP_WorldLocalPlayer_C\232\176\131\231\148\168Overridden(%s)\230\150\185\230\179\149\232\167\166\229\143\145\228\186\134\230\160\136\230\186\162\229\135\186,\232\175\183\228\191\157\231\149\153\231\142\176\229\156\186\229\185\182\232\129\148\231\179\187sio\229\164\132\231\144\134", functionName)
    if TipsModuleCmd and NRCModuleManager:GetModuleType("TipsModule") then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, warning)
    else
      UE4Helper.PrintScreenMsg(warning)
    end
    Log.Debug(warning)
    return
  end
  self.Overridden[functionName](...)
end

function BP_WorldLocalPlayer_C:OnJumped()
  self:CallOverriddenFunc("OnJumped", self)
  self.sceneCharacter:SendEvent(PlayerModuleEvent.ON_PLAYER_JUMPED)
end

function BP_WorldLocalPlayer_C:TrySyncJump()
  if not self.sceneCharacter or not self.sceneCharacter.serverData then
    Log.Error("sceneCharacter\229\176\154\230\156\170\229\136\155\229\187\186\229\174\140\230\136\144\239\188\140\230\151\160\230\179\149\229\174\140\230\136\144\229\144\140\230\173\165")
    return
  end
  if self._lastSyncJumpTime and _G.ZoneServer:GetServerTime() - self._lastSyncJumpTime < 50 then
    Log.Debug("\232\183\179\232\183\131\233\128\154\231\159\165\232\167\166\229\143\145\229\164\170\233\162\145\231\185\129\239\188\140\231\155\180\230\142\165\229\144\158\230\142\137\239\188\140\228\184\141\229\135\134\229\144\140\230\173\165")
    return
  end
  local JumpType = 1
  if self.Speed > 10 then
    JumpType = self.bIsDashing and 3 or 2
  end
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  req.operation.operator_id = self.sceneCharacter.serverData.base.actor_id
  req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
  req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_JUMP
  req.operation.player_perform_info.idle_perform_id = JumpType
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  self._lastSyncJumpTime = _G.ZoneServer:GetServerTime()
  if UE.UObject.IsValid(self.LinkComponent.Child) and UE.UObject.IsValid(self.LinkComponent.Child.RocoPlayer) then
    self.LinkComponent.Child.RocoPlayer:PerformJump(JumpType)
  end
end

function BP_WorldLocalPlayer_C:OnLinkMove(MoveVector)
  local player = self.sceneCharacter
  if player then
    player:OnLinkMove(MoveVector)
  end
end

function BP_WorldLocalPlayer_C:OnLinkBreak(OtherPlayer)
  local player = self.sceneCharacter
  if player then
    player:OnLinkBreak(OtherPlayer)
  end
end

function BP_WorldLocalPlayer_C:ReceiveActorBeginOverlap(OtherActor)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.isLocal ~= nil and self.sceneCharacter then
    local player = self.sceneCharacter
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO) then
      local isInSameRide = false
      local otherCharacter = OtherActor.sceneCharacter
      local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
      local customParams = player.statusComponent:GetCustomParams(statusId)
      if customParams and customParams.ride_param and 0 ~= (customParams.ride_param.double_ride_1p_id or 0) and customParams.ride_param.double_ride_1p_id == otherCharacter.serverData.base.actor_id then
        isInSameRide = true
      end
      if customParams and customParams.ride_param and 0 ~= (customParams.ride_param.double_ride_2p_id or 0) and customParams.ride_param.double_ride_2p_id == otherCharacter.serverData.base.actor_id then
        isInSameRide = true
      end
      if not isInSameRide then
        local bPlayerOnly = false
        local otherCustomParams = otherCharacter.statusComponent:GetCustomParams(statusId)
        if otherCustomParams and otherCustomParams.ride_param and (0 ~= (otherCustomParams.ride_param.double_ride_1p_id or 0) or 0 ~= (otherCustomParams.ride_param.double_ride_2p_id or 0)) then
          bPlayerOnly = true
        end
        OtherActor.sceneCharacter:SetVisible(false, true, bPlayerOnly, true)
      end
    end
  end
  self:CallOverriddenFunc("ReceiveActorBeginOverlap", self, OtherActor)
end

function BP_WorldLocalPlayer_C:ReceiveActorEndOverlap(OtherActor)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.isLocal ~= nil and self.sceneCharacter then
    local player = self.sceneCharacter
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO) then
      OtherActor.sceneCharacter:SetVisible(true, true, true, true)
    end
  end
  self:CallOverriddenFunc("ReceiveActorEndOverlap", self, OtherActor)
end

function BP_WorldLocalPlayer_C:SetLuaIsMovingFlag(Flag)
  if self.sceneCharacter and self.sceneCharacter.movementComponent then
    self.sceneCharacter.movementComponent:SetIsMovingTagOnce(Flag)
  end
end

function BP_WorldLocalPlayer_C:OnSetActorHiddenInGame(isHidden)
  if self.sceneCharacter then
    self.sceneCharacter:OnVisibleChanged(not isHidden, nil)
  end
end

function BP_WorldLocalPlayer_C:OnResolvePenetrationFinished()
  Log.Debug("[DebugMove1P]BP_WorldLocalPlayer_C:OnResolvePenetrationFinished")
  local player = self.sceneCharacter
  if player then
    player:ForceSendMoveReq(true, nil)
  end
end

function BP_WorldLocalPlayer_C:OnCharacterStuckInGeometry(Hit)
  if UE.UObject.IsValid(Hit.Actor) then
    Log.Debug("BP_WorldLocalPlayer_C:OnCharacterStuckInGeometry ", Hit.Actor:GetName())
    local sceneNpc = Hit.Actor.sceneCharacter
    if sceneNpc and sceneNpc.ResolveNPCOverlap then
      sceneNpc:ResolveNPCOverlap()
      Log.Debug("BP_WorldLocalPlayer_C:OnCharacterStuckInGeometry:sceneNpc ResolveNPCOverlap")
    end
  end
end

return BP_WorldLocalPlayer_C

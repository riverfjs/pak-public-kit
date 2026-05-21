require("UnLuaEx")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local MainUICmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local ScenePlayer = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayer")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local BP_WorldPlayer_C = NRCClass()

function BP_WorldPlayer_C:RandomPlayPerformAnim()
end

function BP_WorldPlayer_C:IsMale()
  if not self.sceneCharacter then
    return true
  end
  return 1 == self.sceneCharacter.gender
end

function BP_WorldPlayer_C:IsLocalMode()
  return NRCEnv:IsLocalMode()
end

function BP_WorldPlayer_C:IsMoving()
  local moveComponent = self:GetMovementComponent()
  if not moveComponent then
    return false
  end
  local velocity = moveComponent.Velocity
  return velocity:SizeSquared2D() > 10
end

function BP_WorldPlayer_C:OnLand(Hit)
  local player = self.sceneCharacter
  if player then
    player:OnLanded()
  end
end

function BP_WorldPlayer_C:IsInVisit()
  return _G.DataModelMgr.PlayerDataModel:IsVisitState()
end

function BP_WorldPlayer_C:ReceiveDestroyed()
  if self.sceneCharacter then
    Log.Warning("BP_WorldPlayer is destroyed by engine")
    self.sceneCharacter:OnDestroyedByEngine()
  end
end

function BP_WorldPlayer_C:CastAbility(abilityId)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local abilityHelper = AbilityHelperManager.GetHelper(abilityId)
    if abilityHelper:CanCastAbility(localPlayer) then
      localPlayer.inputComponent:CastAbility(abilityId)
    end
  end
end

function BP_WorldPlayer_C:StopAbility(abilityId)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer.inputComponent:StopAbility(abilityId)
  end
end

function BP_WorldPlayer_C:HandleStatus(status, subStatus, forceRemove)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    if forceRemove then
      localPlayer.statusComponent:RemoveStatus(status, nil, subStatus)
      return
    end
    if not localPlayer.statusComponent:HasStatus(status, subStatus) then
      localPlayer.statusComponent:ApplyStatus(status, nil, subStatus)
    else
      localPlayer.statusComponent:RemoveStatus(status, nil, subStatus)
    end
  end
end

function BP_WorldPlayer_C:GetAnimComponent()
  return self.AnimComponent
end

function BP_WorldPlayer_C:OnPlaySyncPerform(ActionInfo)
  local ActionType = ActionInfo.player_perform_info.perform_type
  if ActionType == ProtoEnum.PlayerPerformType.PPT_IDLE then
    self:PlayIdleRelax(ActionInfo.player_perform_info.idle_perform_id)
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_HIT then
    self:PerformHited(ActionInfo.player_perform_info.hit_type, SceneUtils.ServerPos2ClientPos(ActionInfo.player_perform_info.hit_direction, 10000))
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_JUMP then
    self:PerformJump(ActionInfo.player_perform_info.idle_perform_id)
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_HELLO then
    self:PerformHello(true)
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_TOGETHER_FX then
    self:PlayTogetherFx(ActionInfo.player_perform_info.idle_perform_id)
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_HELLO_STOP then
    self:PerformHello(false)
  end
  if ActionType == ProtoEnum.PlayerPerformType.PPT_PHOTO_ANIM then
    self:PerformTakePhotoAnim(ActionInfo.photo_info)
  end
end

function BP_WorldPlayer_C:SetFadeAlpha(alpha)
  if UE.UObject.IsValid(self.Mesh) then
    UE.URocoPlayerBlueprintFunctionLibrary.SetCharacterAlpha(self.Mesh, alpha)
  end
end

function BP_WorldPlayer_C:IgnoreCameraCollision()
end

function BP_WorldPlayer_C:RecoverCameraCollision()
end

function BP_WorldPlayer_C:TestRide(PetID)
  PetID = PetID or 3012
  local rideComponent = self.BP_RideComponent
  if rideComponent then
    local PetName
    local PetConf = DataConfigManager:GetAllRidePet(PetID)
    PetName = PetConf.animation_name
    local PetABP = string.format("/Game/ArtRes/AnimSequence/Pets/%s/ABP_RideAll_%s.ABP_RideAll_%s_C", PetName, PetName, PetName)
    local PetMesh = string.format("/Game/ArtRes/AnimSequence/Pets/%s/SKM_%s_Skin.SKM_%s_Skin", PetName, PetName, PetName)
    local ScenePet = ScenePlayerPet(nil, PetID, -ProtoEnum.SceneRideAllCustomGid.SRCG_Pressure, ScenePlayer())
    rideComponent:StopRide()
    rideComponent:BindScenePet(ScenePet)
    local Scale = PetConf.model_scale / 100
    if rideComponent:StartRide(PetMesh, PetABP, Scale) then
      ScenePet:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE)
    else
    end
  end
end

function BP_WorldPlayer_C:PerformJump(jumpType)
  self.Overridden.PerformJump(self, jumpType)
  if UE.UObject.IsValid(self.LinkComponent.Child) and UE.UObject.IsValid(self.LinkComponent.Child.RocoPlayer) then
    self.LinkComponent.Child.RocoPlayer:PerformJump(jumpType)
  end
end

function BP_WorldPlayer_C:PerformHello(isPlay)
  local player = self.sceneCharacter
  if isPlay then
    if player and player.viewObj and player.statusComponent then
      if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
        local AnimInstance = player.viewObj.Mesh:GetAnimInstance()
        local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
        if RideAllAnimInstance then
          local ScenePet = player.viewObj.BP_RideComponent.ScenePet
          local Config = ScenePet and ScenePet.config and _G.DataConfigManager:GetAllRidePet(ScenePet.config.id)
          if Config and not Config.throw_switch then
            RideAllAnimInstance.isHello = true
          end
        end
        return
      end
      player:PlayAnim("RlttHello", 1, 0, 0.1, 0.1, 1)
    end
  elseif player then
    player:StopAnim("RlttHello", 0.1)
  end
end

local BagCharmFxMax = 4
local BagCharmFxCount = BagCharmFxMax

function BP_WorldPlayer_C:RemoveTogetherFx(event)
  if "End" == event or "Interrupt" == event or "LoadFailed" == event or "PreEnd" == event then
    BagCharmFxCount = BagCharmFxCount + 1
    Log.Debug("BagCharmFxCount+++", BagCharmFxCount)
    if BagCharmFxCount > BagCharmFxMax then
      BagCharmFxCount = BagCharmFxMax
      Log.Error("BP_WorldPlayer_C:RemoveTogetherFx FxCount Error")
    end
  end
end

function BP_WorldPlayer_C:AddTogetherFx(Player, Path, bCheck)
  if next(self.TogetherFxs) then
    for k, v in ipairs(self.TogetherFxs) do
      v:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
      v:Destroy()
    end
    self.TogetherFxs = {}
  end
  if bCheck and BagCharmFxCount <= 0 then
    return
  end
  local RocoSkillProxy = Player:CastG6AbilityAsync(Path, nil, nil, nil, true)
  table.insert(self.TogetherFxs, RocoSkillProxy)
  if bCheck then
    BagCharmFxCount = BagCharmFxCount - 1
    Log.Debug("BagCharmFxCount---", BagCharmFxCount)
    RocoSkillProxy:RegisterRawCallback(self, self.RemoveTogetherFx)
  end
end

function BP_WorldPlayer_C:PlayTogetherFx(FxID)
  local player = self.sceneCharacter
  local bPlay = false
  if not (player and player.serverData) or not player.serverData.wearing_item then
    return bPlay
  end
  local BagCharmID
  for k, v in ipairs(player.serverData.wearing_item) do
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
    if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
      BagCharmID = v.wearing_item_id
      break
    end
  end
  if BagCharmID then
    local BagcharmConf = _G.DataConfigManager:GetFashionBagcharmConf(BagCharmID)
    if BagcharmConf then
      if not self.TogetherFxs then
        self.TogetherFxs = {}
      end
      if 1 == FxID then
        if BagcharmConf.invite_effect then
          bPlay = true
          self:AddTogetherFx(player, BagcharmConf.invite_effect, not player.isLocal)
        end
      elseif 2 == FxID and BagcharmConf.accept_effect then
        bPlay = true
        local bCheck = not player.isLocal
        if bCheck then
          local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
          local TargetUin
          if localPlayer then
            TargetUin = localPlayer.InviteComponent.otherUin
            if not TargetUin and localPlayer.InviteComponent._interactType == Enum.InteractInviteType.IIT_DOUBLE_ACTION then
              local customParam = localPlayer.statusComponent:GetCustomParams(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM)
              if customParam then
                TargetUin = customParam.player_interact_param.player_uin1 == localPlayer:GetLogicId() and customParam.player_interact_param.player_uin2 or customParam.player_interact_param.player_uin1
              end
            end
          end
          if TargetUin == player:GetLogicId() then
            bCheck = false
          end
        end
        self:AddTogetherFx(player, BagcharmConf.accept_effect, bCheck)
      end
      if bPlay then
        local BagCharmEffect = _G.DataConfigManager:GetRoleGlobalConfig("fashion_bagcharm_normal_effect").str
        local Decorator = UE4.TArray(UE4.AActor)
        self.AvatarComponent:GetDecorator(UE4.EAvatarBodyType.Bags, Decorator)
        for i, v in ipairs(Decorator:ToTable()) do
          local characters = {
            [UE4.EBattleStaticActorType.Player_1] = v
          }
          local RocoSkillProxy = player:CastG6AbilityAsync(BagCharmEffect, nil, characters, nil, true)
          table.insert(self.TogetherFxs, RocoSkillProxy)
        end
      end
    end
  end
  return bPlay
end

function BP_WorldPlayer_C:SetActorHiddenInGame(bNewHidden)
  self.Overridden.SetActorHiddenInGame(self, bNewHidden)
end

function BP_WorldPlayer_C:SetForceHidden(bNewHidden)
  self.Overridden.SetForceHidden(self, bNewHidden)
end

function BP_WorldPlayer_C:OnHomeAnimEnd()
  if self.sceneCharacter then
    self.sceneCharacter.playerHomeInteractionComponent:OnHomeAnimEnd()
  end
end

function BP_WorldPlayer_C:UnLoadAvatarBySignificance()
  Log.Debug("BP_WorldPlayer_C UnloadAvatar by significance")
  if self.sceneCharacter and self.sceneCharacter.UnLoadAvatar then
    self.sceneCharacter:UnLoadAvatar(PlayerModuleCmd.AvatarUnloadReason.Significance)
  end
end

function BP_WorldPlayer_C:LoadAvatarBySignificance()
  Log.Debug("BP_WorldPlayer_C LoadAvatar by significance")
  if self.sceneCharacter and self.sceneCharacter.LoadAvatar then
    self.sceneCharacter:LoadAvatar(PlayerModuleCmd.AvatarUnloadReason.Significance)
  end
end

function BP_WorldPlayer_C:OnSetActorHiddenInGame(isHidden)
  if self.sceneCharacter then
    self.sceneCharacter:OnVisibleChanged(not isHidden, nil)
  end
end

function BP_WorldPlayer_C:K2_OnMovementModeChanged(PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  self.Overridden.K2_OnMovementModeChanged(self, PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  local player = self.sceneCharacter
  if player then
    player:SendEvent(PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
  end
end

function BP_WorldPlayer_C:PerformTakePhotoAnim(info)
  if not info then
    Log.Error("BP_WorldPlayer_C:PerformTakePhotoAnim nil info")
    return
  end
  local player = self.sceneCharacter
  if not player then
    Log.Error("BP_WorldPlayer_C:PerformTakePhotoAnim nil ScenePlayer")
  end
  local conf
  if UE.UObject.IsValid(player.viewObj) then
    player.viewObj.SettingLeftHand = info.is_mirror
  end
  if info.photo_pose_id then
    conf = _G.DataConfigManager:GetTakePhotoPoseConf(info.photo_pose_id, true)
    if info.is_end then
      player.PosePlayer:StopAnim()
    else
      player.PosePlayer:PlayAnim(conf, info.is_mirror)
    end
  else
    conf = _G.DataConfigManager:GetTakePhotoEmojiConf(info.photo_emoji_id, true)
    if info.is_end then
      player.EmojiPlayer:StopAnim()
    else
      player.EmojiPlayer:PlayAnim(conf, info.is_mirror)
    end
  end
end

return BP_WorldPlayer_C

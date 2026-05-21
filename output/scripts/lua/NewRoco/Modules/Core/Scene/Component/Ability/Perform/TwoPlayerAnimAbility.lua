local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local RelationTreeEvent = require("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TwoPlayerAnimAbility = Base:Extend("TwoPlayerAnimAbility")

function TwoPlayerAnimAbility:Start(OnFinished, custom_params, InteractType)
  Base.Start(self, OnFinished)
  self.custom_params = custom_params
  local player = self.caster
  local hasStatus = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM)
  if hasStatus then
    local Param = custom_params.player_interact_param
    local bInviter = player:GetLogicId() == Param.player_uin1
    local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, bInviter and Param.player_uin2 or Param.player_uin1)
    if TargetPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE) then
      local ability = TargetPlayer.abilityComponent:GetAbilityByStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE, true, 1)
      ability:StopAnim()
    end
    if player.isLocal then
      if player.viewObj:IsAirWallBetweenDestination(TargetPlayer:GetActorLocationFrameCache()) then
        self.ResumeLocation = player:GetActorLocation()
      end
      _G.NRCEventCenter:RegisterEvent("TwoPlayerAnimAbility", self, SceneEvent.OnTeleportNotify, self.ExitInteract)
      _G.NRCEventCenter:RegisterEvent("TwoPlayerAnimAbility", self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
      _G.NRCEventCenter:RegisterEvent("TwoPlayerAnimAbility", self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
      _G.NRCEventCenter:RegisterEvent("TwoPlayerAnimAbility", self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
      if self:IsGivePetEgg() then
        _G.FunctionBanManager:AddPlayerConditionType(_G.Enum.PlayerConditionType.PCT_PET_BLESSING_PERFORM, "PetBlessing")
      end
      if player.inputComponent then
        player.inputComponent:SetIgnoreMoveInput(self, true)
      end
    else
      player.viewObj.Mesh.bEabledAuxiliaryAnimGraphThread = false
    end
    if TargetPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM) then
      if self:IsGivePetEgg() then
        self:StarGivePetEgg(custom_params)
      else
        self:StarG6(custom_params)
      end
    end
    self.state = ABEnum.AbilityState.Casting
    self.InteractType = InteractType
  else
    self:Recover(self.caster)
  end
end

function TwoPlayerAnimAbility:IsGivePetEgg()
  if self.custom_params and self.custom_params.player_interact_param and self.custom_params.player_interact_param.pet_egg_id and self.custom_params.player_interact_param.pet_egg_id > 0 then
    return true
  end
  return false
end

function TwoPlayerAnimAbility:StarGivePetEgg(custom_params)
  local pet_egg_id = 0
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(custom_params.player_interact_param.pet_egg_id)
  if bagItemConf and bagItemConf.item_behavior[1] and bagItemConf.item_behavior[1].use_action == Enum.ItemBehavior.IB_PET_EGG_HATCH then
    pet_egg_id = bagItemConf.item_behavior[1].ratio[1] or 0
  end
  local petEggConf = _G.DataConfigManager:GetPetEggConf(pet_egg_id)
  local model_id = petEggConf and petEggConf.model_id or 0
  local modelConf = _G.DataConfigManager:GetModelConf(model_id)
  if modelConf then
    local ResQueue = require("NewRoco.Utils.ResQueue")
    self.Queue = ResQueue()
    self.Queue:InsertModel("PetEgg", modelConf.id)
    self.Queue:StartLoad(self, function()
      if not (self and self.caster) or not self.caster.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM, 1) then
        return
      end
      local ModelObject = self.Queue:GetResObject("PetEgg")
      if ModelObject then
        Log.Debug("TwoPlayerAnimAbility:StarGivePetEgg _ on load pet egg success, player name : ", self.caster.viewObj:GetName())
        self.PetEggModel = ModelObject.Model
        if self.PetEggModel and UE4.UObject.IsValid(self.PetEggModel) then
          self.PetEggModel:SetVisibleInternal(false)
          self.PetEggModel:SetCollisionEnable(false)
        end
        ModelObject.Model = nil
      end
      self:StarG6(custom_params)
    end)
  else
    Log.Error("TwoPlayerAnimAbility:StarGivePetEgg pet_egg_id:" .. custom_params.player_interact_param.pet_egg_id .. ", model_id:" .. model_id .. ", modelConf is nil")
    self:StarG6(custom_params)
  end
end

function TwoPlayerAnimAbility:StarG6(custom_params)
  local player = self.caster
  local status = ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM
  local Param = custom_params.player_interact_param
  local bInviter = player:GetLogicId() == Param.player_uin1
  self.TargetUin = bInviter and Param.player_uin2 or Param.player_uin1
  local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.TargetUin)
  local AnimPath
  if TargetPlayer then
    local Conf = _G.DataConfigManager:GetRelationtreeAnimConf(Param.interact_id)
    AnimPath = Conf and Conf.accept_key
  end
  if not string.IsNilOrEmpty(AnimPath) then
    Log.Debug("TwoPlayerAnimAbility StartG6", player.viewObj:GetName())
    self.bPlayG6 = true
    local Characters = {}
    if self.PetEggModel then
      Characters[UE4.EBattleStaticActorType.Pet_2_1] = self.PetEggModel
    end
    local Player_1, Player_2
    if bInviter then
      Player_1 = self.caster
      Player_2 = TargetPlayer
      self.ReceivePlayer = TargetPlayer
    else
      Player_1 = TargetPlayer
      Player_2 = self.caster
      self.ReceivePlayer = self.caster
    end
    Characters[UE4.EBattleStaticActorType.Player_1] = Player_1.viewObj
    Characters[UE4.EBattleStaticActorType.Player_2] = Player_2.viewObj
    self:CastG6AbilityAsync(Characters, {}, AnimPath)
    if self.PetEggModel and self.ReceivePlayer and self.skillProxy then
      self.skillProxy.BattleGenderType = self.ReceivePlayer.serverData.base.gender
    end
  end
end

function TwoPlayerAnimAbility:OnPlayerVisibleChange(Visible)
  if self.PetEggModel and not Visible then
    self.PetEggModel:SetVisibleInternal(false)
  end
end

function TwoPlayerAnimAbility:OnActionStart()
  Base.OnActionStart(self)
  if self.PetEggModel and self.caster:IsVisible() then
    self.PetEggModel:SetVisibleInternal(true)
  end
  local Character = self.caster and self.caster.viewObj
  if Character then
    local Root = Character:K2_GetRootComponent()
    self.LastCollisionResponse = Root:GetCollisionResponseToChannel(UE.ECollisionChannel.ECC_GameTraceChannel7)
    Root:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_GameTraceChannel7, UE.ECollisionResponse.ECR_Ignore)
    Log.Debug("TwoPlayerAnimAbility Set Collision Response", Character:GetName())
  end
end

function TwoPlayerAnimAbility:OnG6AbilityAsync(skillProxy, result)
  Base.OnG6AbilityAsync(self, skillProxy, result)
  if self.custom_params then
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.custom_params.player_interact_param.player_uin2)
    if Player then
      Player:PausePlayerMovement(self, true)
    end
  end
end

function TwoPlayerAnimAbility:ReActive()
  local hasInviteStatus = self.caster.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM)
  if not hasInviteStatus then
    self:Recover(self.caster)
    self:Finish(true)
  end
end

function TwoPlayerAnimAbility:Interrupt()
  self:Recover(self.caster)
  Base.Interrupt(self)
end

function TwoPlayerAnimAbility:Recover(owner)
  if self.ResumeLocation then
    self.caster:SetActorLocation(self.ResumeLocation)
    self.ResumeLocation = nil
  end
  if self.bPlayG6 then
    Log.Debug("TwoPlayerAnimAbility StopG6", owner.viewObj:GetName())
    self:CancelAsyncG6Ability()
    self:FinishG6Ability()
    self.bPlayG6 = nil
    if self.custom_params then
      local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.custom_params.player_interact_param.player_uin2)
      if Player then
        Player:PausePlayerMovement(self, false)
        if Player.isLocal then
          Player:ForceSendMoveReq()
        end
        local Inviter = self.caster
        if Inviter == Player then
          Inviter = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.custom_params.player_interact_param.player_uin1)
        end
        if Inviter and UE.UObject.IsValid(Inviter.viewObj) and UE.UObject.IsValid(Player.viewObj) then
          local ParentActor = Player.viewObj:GetAttachParentActor()
          if ParentActor == Inviter.viewObj then
            Log.Debug("TwoPlayerAnimAbility StopG6 Detach")
            Player.viewObj:DetachRootComponentFromParent(true)
          else
            Log.Warning("TwoPlayerAnimAbility StopG6 Player2 Has New AttachParentActor", ParentActor and ParentActor.GetName and ParentActor:GetName())
          end
        end
      end
    end
    if self.LastCollisionResponse then
      local Character = self.caster and self.caster.viewObj
      if Character then
        local Root = Character:K2_GetRootComponent()
        Root:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_GameTraceChannel7, self.LastCollisionResponse)
        Log.Debug("TwoPlayerAnimAbility Recover Collision Response", Character:GetName())
      end
    end
  else
    self.caster.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM)
  end
  if UE.UObject.IsValid(self.PetEggModel) then
    self.PetEggModel:K2_DestroyActor()
    self.PetEggModel = nil
  end
  if self.caster.isLocal then
    if self.caster.inputComponent then
      self.caster.inputComponent:SetIgnoreMoveInput(self, false)
    end
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.TwoPeopleActionPlayCompleted, self.custom_params)
    _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnTeleportNotify, self.ExitInteract)
    _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerDespawn, self.OnNetPlayerDespawn)
    _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.NpcActionExecute, self.OnNpcActionExecute)
    _G.NRCEventCenter:UnRegisterEvent(self, PlayerModuleEvent.ON_PLAYER_VISIBLE_CHANGE, self.OnPlayerVisibleChange)
    _G.FunctionBanManager:RemovePlayerConditionType(_G.Enum.PlayerConditionType.PCT_PET_BLESSING_PERFORM, "PetBlessing")
    if self.InteractType == ProtoEnum.InteractInviteType.IIT_BATTLE then
      _G.BattleNetManager:OpenPVP_PreparePanelByCache()
    end
  else
    self.caster.viewObj.Mesh.bEabledAuxiliaryAnimGraphThread = true
  end
  self.custom_params = nil
  self.TargetUin = nil
  self.LastCollisionResponse = nil
  self.InteractType = nil
  self.state = ABEnum.AbilityState.Finished
  self:ExitInteract()
end

function TwoPlayerAnimAbility:OnSkillEvent(event)
  Base.OnSkillEvent(self, event)
  if "End" == event or "Interrupt" == event or "LoadFailed" == event or "PreEnd" == event then
    self:ExitInteract()
  end
end

function TwoPlayerAnimAbility:OnNetPlayerDespawn(player)
  if player:GetLogicId() ~= self.TargetUin then
    return
  end
  self:ExitInteract()
end

function TwoPlayerAnimAbility:OnTargetApplyStatus(status, statusValue, opCode, customParam)
  if status == Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM then
    return
  end
  local TargetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.TargetUin)
  if TargetPlayer then
  end
end

function TwoPlayerAnimAbility:OnNpcActionExecute(NPCAction)
  local InviteComponent = self.caster.InviteComponent
  if InviteComponent and InviteComponent:IsNPCActionCanInterrupt(NPCAction) then
    self:ExitInteract()
  end
end

function TwoPlayerAnimAbility:ExitInteract()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local player = self.caster
  if player.isLocal or localPlayer and self.TargetUin == localPlayer:GetLogicId() then
    local InviteComponent = localPlayer:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    InviteComponent:InteractCancel()
  end
end

return TwoPlayerAnimAbility

local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local ABEnum = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local IdleRelaxAbility = Base:Extend("IdleRelaxAbility")

function IdleRelaxAbility:Start(OnFinished, custom_params, bPlay)
  local player = self.caster
  local hasStatus = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
  if hasStatus then
    if bPlay then
      if not self:Play(custom_params.role_play_param) then
        self:Stop()
        return
      end
      self.state = ABEnum.AbilityState.Casting
    end
  else
    self:Stop()
  end
end

function IdleRelaxAbility:Recover(owner)
  self:Stop()
end

function IdleRelaxAbility:Interrupt()
  Base.Interrupt(self)
  self:Stop()
end

function IdleRelaxAbility:Play(params)
  local player = self.caster
  local skill_type = params.skill_type
  self.skillType = skill_type
  if skill_type == ProtoEnum.RolePlaySkillType.RPST_IDLE_OTHER then
    local conf = _G.DataConfigManager:GetSkillResConf(params.skill_interact_id)
    local path = conf and conf.res_id
    if not path then
      Log.Error("IdleRelaxAbility:Play path is nil", params.skill_interact_id)
      return
    end
    self.AnimLinkTag = conf.linktype or player.isLocal and "RM_Locomotion" or "Locomotion"
    self.ResReq = _G.NRCResourceManager:LoadResAsync(self, path, player.isLocal and _G.PriorityEnum.Local_Player_Logic or _G.PriorityEnum.Other_Player_Logic, 10, self.OnAnimLoadSuccess, self.Stop)
  elseif skill_type == ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND and player.PlaySuitRelax then
    local pet_serverid
    local petNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, params.pet_serverid)
    if petNpc then
      if not petNpc:CanInteract() then
        return false
      end
      pet_serverid = params.pet_serverid
    end
    self.pet_serverid = pet_serverid
    player:PlaySuitRelax(params.skill_interact_id, params.pet_id, pet_serverid, params.mutation_type, params.glass_info, params.nature, params.ball_id)
    if petNpc then
      petNpc:AddEventListener(self, NPCModuleEvent.OnInteractionEnableChanged, self.OnPetInteractionEnableChanged)
    end
  end
  if player.isLocal then
    local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnInputMove)
    end
    player:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  else
    player:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
  end
  return true
end

function IdleRelaxAbility:OnAnimLoadSuccess(req, Anim)
  local bSucc
  local Obj = self.caster.viewObj
  local AnimInstance = Obj and Obj.AnimComponent and Obj.AnimComponent:GetAnimInstance(self.AnimLinkTag)
  if AnimInstance then
    local Montage = AnimInstance:PlaySlotAnimationAsDynamicMontage(Anim, "DefaultIdle", 0.3, 0.3, 1, 1, -1, 0)
    if Montage then
      bSucc = true
      self.playingMontage = Montage
      self:AddOrRemoveMontageListener(true)
    end
  end
  if not bSucc then
    Log.Warning("IdleRelaxAbility:OnAnimLoadSuccess Failed")
    self:Stop()
  end
end

function IdleRelaxAbility:AddOrRemoveMontageListener(bAdd)
  local Obj = self.caster.viewObj
  if not UE4.UObject.IsValid(Obj) then
    return
  end
  if bAdd then
    local AnimInstance = Obj.AnimComponent:GetAnimInstance(self.AnimLinkTag)
    if not AnimInstance then
      Log.Error("IdleRelaxAbility:AddOrRemoveMontageListener AnimInstance is nil", UE.UObject.IsValid(Obj), self.AnimLinkTag)
      return
    end
    local This = self
    if not self.OnMontageStarted then
      function self.OnMontageStarted(viewObj, montage)
        if montage ~= This.playingMontage then
          This:Stop()
        end
      end
    end
    if not self.OnMontageEnded then
      function self.OnMontageEnded(viewObj, montage, bInterrupted)
        if montage == This.playingMontage then
          This:Stop()
        end
      end
    end
    AnimInstance.OnMontageStarted:Add(Obj, self.OnMontageStarted)
    AnimInstance.OnMontageEnded:Add(Obj, self.OnMontageEnded)
    self.AnimInst = AnimInstance
  else
    local AnimInstance = self.AnimInst
    if not UE4.UObject.IsValid(AnimInstance) then
      return
    end
    AnimInstance.OnMontageStarted:Remove(Obj, self.OnMontageStarted)
    AnimInstance.OnMontageEnded:Remove(Obj, self.OnMontageEnded)
  end
end

function IdleRelaxAbility:Stop()
  local player = self.caster
  if not player then
    Log.Error("IdleRelaxAbility:Stop player is nil")
    return
  end
  if self.ResReq then
    _G.NRCResourceManager:UnLoadRes(self.ResReq)
  end
  if self.skillType == ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND and player.BreakSuitRelax then
    player:BreakSuitRelax()
  end
  if self.playingMontage then
    local AnimInstance = self.AnimInst
    if UE4.UObject.IsValid(AnimInstance) then
      self:AddOrRemoveMontageListener(false)
      AnimInstance:Montage_Stop(0.2, self.playingMontage)
    end
    self.playingMontage = nil
  end
  if self.pet_serverid then
    local petNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.pet_serverid)
    if petNpc then
      petNpc:RemoveEventListener(self, NPCModuleEvent.OnInteractionEnableChanged, self.OnPetInteractionEnableChanged)
    end
    self.pet_serverid = nil
  end
  self.state = ABEnum.AbilityState.Finished
  self.AnimLinkTag = nil
  self.ResReq = nil
  self.skill_type = nil
  if player.isLocal then
    local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
    end
    player:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  else
    player:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
  end
  player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
end

function IdleRelaxAbility:OnApplyStatus(status, statusValue, opCode, customParam)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX then
    return
  end
  self:Stop()
end

function IdleRelaxAbility:OnInputMove()
  self:Stop()
end

function IdleRelaxAbility:OnLogicStatusUpdated(owner, ChangeInfo)
  if ChangeInfo.changed_status.status == Enum.SpaceActorLogicStatus.SALS_PLAYER_IDLE and ChangeInfo.op_type == ProtoEnum.LogicStatusOpType.LSOT_REMOVE then
    self:Stop()
  end
end

function IdleRelaxAbility:OnPetInteractionEnableChanged(Pet, bEnable)
  if not bEnable then
    self:Stop()
  end
end

return IdleRelaxAbility

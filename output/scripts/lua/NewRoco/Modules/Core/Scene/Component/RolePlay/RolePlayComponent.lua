local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local DebugModuleEvent
if _G.AppMain:HasDebug() then
  DebugModuleEvent = require("NewRoco.Modules.System.Debug.DebugModuleEvent")
end
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local RolePlayComponent = Base:Extend("RolePlayComponent")

function RolePlayComponent:Ctor()
  Base.Ctor(self)
  self.rpResReq = nil
  self.playingRpSkillObj = nil
  self.playingRpBehaviorId = nil
  self.startRpBehaviorFailedDelayId = nil
  self.statusValue = nil
  self.customParam = nil
  self.isLoopAnim = false
end

function RolePlayComponent:Attach(owner)
  Base.Attach(self, owner)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnRemoveStatus)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnClearStatus)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnRefreshStatus)
end

function RolePlayComponent:DeAttach()
  self:StopRpBehavior(true)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_REMOVE_STATUS, self.OnRemoveStatus)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_CLEAR_STATUS, self.OnClearStatus)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_REFRESH, self.OnRefreshStatus)
  Base.DeAttach(self)
end

function RolePlayComponent:GetPlayingRpBehaviorId()
  return self.playingRpBehaviorId
end

function RolePlayComponent:CheckMoveCanInterruptRpBehavior()
  local interruptType = RolePlayModuleDef.InterruptType.CanInterrupt
  local playingRpId = self:GetPlayingRpBehaviorId()
  local RpCfg = playingRpId and _G.DataConfigManager:GetRoleplayBehaviorConf(playingRpId)
  if RpCfg then
    if not RpCfg.is_movable then
      if self:TryInterruptLoopAnim() then
        interruptType = RolePlayModuleDef.InterruptType.CanNotInterrupt
      end
    else
      interruptType = RolePlayModuleDef.InterruptType.CanParallel
    end
  end
  return nil ~= playingRpId, interruptType
end

function RolePlayComponent:TryInterruptLoopAnim()
  local isPerformLoop = false
  local player = self.owner
  if player and player.isLocal then
    local customParam = self.customParam
    local roleplayParams = customParam and customParam.role_play_param
    isPerformLoop = self.isLoopAnim or roleplayParams and roleplayParams.is_stop_loop
    if self.isLoopAnim and roleplayParams and not roleplayParams.is_stop_loop then
      roleplayParams.is_stop_loop = true
      self:SetInfiniteLoop(false)
      if player.statusComponent then
        player.statusComponent:RefreshStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR, self.statusValue, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParam)
      end
    end
  end
  return isPerformLoop
end

function RolePlayComponent:OnApplyStatus(status, statusValue, opCode, customParam)
  if status ~= Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    if status == Enum.WorldPlayerStatusType.WPST_TRANSFORM or status == Enum.WorldPlayerStatusType.WPST_SWIMMING then
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.CloseMainPanel)
    end
    return
  end
  self.statusValue = statusValue
  self.customParam = customParam
  local conf
  local role_play_param = customParam and customParam.role_play_param
  local role_play_id = role_play_param and role_play_param.role_play_id
  local skill_interact_id = role_play_param and role_play_param.skill_interact_id
  local bDisablePerfEffectStage = false
  if role_play_id and 0 ~= role_play_id then
    conf = _G.DataConfigManager:GetRoleplayBehaviorConf(customParam.role_play_param.role_play_id)
    if conf then
      local rpConf = conf
      local star = rpConf.star and rpConf.star[2]
      if 1 == star then
        bDisablePerfEffectStage = true
      end
      local skillReId = conf.male_skill_id or conf.female_skill_id
      conf = _G.DataConfigManager:GetSkillResConf(skillReId)
    else
      Log.Warning("RolePlayComponent:OnApplyStatus No Conf", role_play_id)
    end
  elseif skill_interact_id and 0 ~= skill_interact_id then
    conf = _G.DataConfigManager:GetSkillResConf(skill_interact_id)
  else
    conf = _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.GetConfByBehaviorType, statusValue)
    if conf then
      local skillResId = conf.male_skill_id or conf.female_skill_id
      conf = _G.DataConfigManager:GetSkillResConf(skillResId)
    else
      Log.Warning("RolePlayComponent:OnApplyStatus No Conf", statusValue)
    end
  end
  self:StartRpBehavior(conf, customParam, bDisablePerfEffectStage)
end

function RolePlayComponent:OnRemoveStatus(status, statusValue, opCode)
  if status ~= Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    return
  end
  self:StopRpBehavior(false)
end

function RolePlayComponent:OnClearStatus(status, statusValue, opCode)
  if status ~= Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    return
  end
  self:StopRpBehavior(true)
end

function RolePlayComponent:OnRefreshStatus(status, statusValue, opCode, customParam)
  if status ~= Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR then
    return
  end
  if customParam and customParam.role_play_param and customParam.role_play_param.is_stop_loop then
    self:SetInfiniteLoop(false)
  end
end

function RolePlayComponent:StartRpBehavior(conf, executeParam, bDisablePerfEffectStage)
  Log.Debug("RolePlayComponent:StartRpBehavior", conf.id, bDisablePerfEffectStage)
  if self.owner.isLocal then
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_ROLEPLAY_EMOTE)
  end
  local startFailed = true
  if conf and self.owner.viewObj then
    local role_play_param = executeParam.role_play_param
    local rpSkillResPath = conf.res_id
    if not role_play_param or string.IsNilOrEmpty(rpSkillResPath) then
      Log.Error("RolePlayComponent:StartRpBehavior No Play", conf.id, role_play_param)
      return
    end
    local skill_type = role_play_param.skill_type or ProtoEnum.RolePlaySkillType.RPST_NONE
    self.playingRpBehaviorId = role_play_param.role_play_id
    self.skillType = skill_type
    if skill_type == ProtoEnum.RolePlaySkillType.RPST_NONE then
      local function OnSkillLoadSuccessWrapper(_, Req, SkillClass)
        return self:OnSkillLoadSuccess(Req, SkillClass, bDisablePerfEffectStage)
      end
      
      self.rpResReq = _G.NRCResourceManager:LoadResAsync(self, rpSkillResPath, self.owner.isLocal and PriorityEnum.Active_World_PlayerRolePlay or PriorityEnum.Active_World_PlayerNet_RolePlay, 10, OnSkillLoadSuccessWrapper, self.OnSkillLoadFail)
      if self.rpResReq then
        startFailed = false
      end
    elseif skill_type == ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND or skill_type == ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE then
      local player = self.owner
      local statusParams = executeParam and executeParam.role_play_param
      if statusParams and player.PlaySuitRelax then
        player:PlaySuitRelax(statusParams.skill_interact_id, statusParams.pet_id, statusParams.pet_serverid, statusParams.mutation_type, statusParams.glass_info, statusParams.nature)
        startFailed = false
      end
    end
  end
  if startFailed then
    self.startRpBehaviorFailedDelayId = _G.DelayManager:DelayFrames(1, self.DelayHandlerForStartRpBehaviorFailed, self)
  end
end

function RolePlayComponent:StopRpBehavior(abortFlag)
  Log.Debug("RolePlayComponent:StopRpBehavior", abortFlag)
  if self.owner.isLocal then
    _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_ROLEPLAY_EMOTE)
  end
  if not self.owner.isLocal or abortFlag then
    self:CancelLoadingRpSkill()
    self:CancelPlayingRpSkill()
    self:CancelDelayProcesses()
    if self.skillType == ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE or ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND then
      local player = self.owner
      if player.BreakSuitRelax then
        player:BreakSuitRelax()
      end
    end
  end
  local isSuitRelaxSkill = self.skillType == ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE or self.skillType == ProtoEnum.RolePlaySkillType.RPST_IDLE_BOND
  if isSuitRelaxSkill then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer == self.owner and _G.RelationTreeCmd then
      local bondId, petGid, OwnerActorId = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetPlayingCloseBondId)
      local bondItem = _G.DataModelMgr.PlayerDataModel:GetFashionBondItem(bondId)
      local PetDataForCheck = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
      local isPetShiny = PetDataForCheck and (PetMutationUtils.GetMutationValue(PetDataForCheck.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(PetDataForCheck.mutation_type) or PetUtils.CheckIsHiddenShiningGlass(PetDataForCheck.mutation_type, PetDataForCheck.glass_info) or PetUtils.CheckIsShiningChaos(PetDataForCheck.mutation_type))
      if bondItem and bondItem.pet_tree_interacted and bondItem.color_suit_state == _G.Enum.FashionBondColorSuitState.FBCSS_CLAIMABLE and isPetShiny then
        Log.Warning("\228\186\178\230\152\181\229\138\168\228\189\156RolePlay\231\187\147\230\157\159\239\188\140\232\167\166\229\143\145\229\188\130\232\137\178\229\165\151\232\163\133\232\142\183\229\143\150 bondId: %s", bondId)
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.ClaimHeterochromeSuitReq, bondId, petGid)
      else
        local localPlayerUin = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
        if localPlayerUin == OwnerActorId then
          local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
          if PetData then
            local GlassInfo = PetData.glass_info or nil
            local IsYiSe = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(PetData.mutation_type) or PetUtils.CheckIsHiddenShiningGlass(PetData.mutation_type, PetData.glass_info) or PetUtils.CheckIsShiningChaos(PetData.mutation_type)
            local isClanmable = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckPetGlassTintIsClaimableByBondID, bondId, GlassInfo, IsYiSe)
            if isClanmable then
              Log.Warning("\228\186\178\230\152\181\229\138\168\228\189\156RolePlay\231\187\147\230\157\159\239\188\140\232\167\166\229\143\145\231\130\171\229\189\169\229\165\151\232\163\133\232\142\183\229\143\150 bondId: %s", bondId)
              _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SendClaimGlassTintReq, bondId, IsYiSe, GlassInfo, nil, PetData)
            end
          end
        end
      end
      _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.ResetCloseRolePlayFromRelationTree)
    end
  end
  if self.playingRpBehaviorId then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ApplyRpBehavior, self.playingRpBehaviorId, abortFlag and UE.EDotsStatusType.Abort or UE.EDotsStatusType.Finish, self.owner)
  end
  if _G.AppMain:HasDebug() then
    _G.NRCEventCenter:DispatchEvent(DebugModuleEvent.StopRpBehavior, abortFlag)
  end
  self:ClearPlayingRpSkill()
  self.rpResReq = nil
  self.playingRpBehaviorId = nil
  self.startRpBehaviorFailedDelayId = nil
  self.skillType = nil
  self.statusValue = nil
  self.customParam = nil
  self.isLoopAnim = false
end

function RolePlayComponent:CancelLoadingRpSkill()
  local req = self.rpResReq
  if req then
    self.rpResReq = nil
    _G.NRCResourceManager:UnLoadRes(req)
  end
end

function RolePlayComponent:CancelPlayingRpSkill()
  local skillObj = self.playingRpSkillObj
  self:ClearPlayingRpSkill()
  if skillObj then
    local view = self.owner.viewObj
    if view then
      local animComp = view:GetComponentByClass(UE4.URocoAnimComponent)
      if animComp then
        animComp:StopAllMontage(0.1)
      end
      local skillComp = view:GetComponentByClass(UE4.URocoSkillComponent)
      if skillComp then
        skillComp:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
    end
  end
end

function RolePlayComponent:CancelDelayProcesses()
  if self.startRpBehaviorFailedDelayId then
    _G.DelayManager:CancelDelayById(self.startRpBehaviorFailedDelayId)
    self.startRpBehaviorFailedDelayId = nil
  end
end

function RolePlayComponent:DelayHandlerForStartRpBehaviorFailed()
  self.startRpBehaviorFailedDelayId = nil
  self:SetRpSkillStatus(false)
end

function RolePlayComponent:SetRpSkillStatus(success)
  Log.Debug("RolePlayComponent:SetRpSkillStatus", success)
  local player = self.owner
  if player and player.isLocal and player.statusComponent then
    if success then
      player.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
    else
      player.statusComponent:ClearStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
    end
  end
end

function RolePlayComponent:SetInfiniteLoop(infiniteLoop, inSkillObj)
  local skillObj = inSkillObj or self.playingRpSkillObj
  if UE4.UObject.IsValid(skillObj) then
    local skillBlackboard = skillObj:GetBlackboard()
    if UE4.UObject.IsValid(skillBlackboard) then
      skillBlackboard:SetValueAsInt("Looping", infiniteLoop and -1 or 0)
    end
  end
end

function RolePlayComponent:OnSkillLoadSuccess(req, skillClass, bDisablePerfEffectStage)
  Log.Debug("RolePlayComponent:OnSkillLoadSuccess", self.playingRpBehaviorId)
  self.rpResReq = nil
  local playSuccess = false
  local view = self.owner.viewObj
  if view then
    local skillComp = view:GetComponentByClass(UE4.URocoSkillComponent)
    if skillComp then
      local skillObj = view.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
      if skillObj then
        if not bDisablePerfEffectStage then
          skillObj:GetBlackboard():SetValueAsString("Stage2", "Stage2")
        end
        skillObj:SetCaster(view)
        skillObj:RegisterEventCallback("End", self, self.OnSkillEnd)
        skillObj:RegisterEventCallback("PreEnd", self, self.OnSkillEnd)
        skillObj:RegisterEventCallback("PreEndAnim", self, self.OnSkillEnd)
        skillObj:RegisterEventCallback("Interrupt", self, self.OnSkillInterrupt)
        local RpCfg = _G.DataConfigManager:GetRoleplayBehaviorConf(self.playingRpBehaviorId)
        if RpCfg and RpCfg.is_loop then
          skillObj:RegisterEventCallback("LoopStart", self, self.OnSkillLoopStart)
          self:SetInfiniteLoop(true, skillObj)
        end
        local playRet = skillComp:PlaySkill(skillObj)
        if playRet == UE.ESkillStartResult.Success then
          self.playingRpSkillObj = skillObj
          playSuccess = true
        end
      end
    end
  end
  if playSuccess then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ApplyRpBehavior, self.playingRpBehaviorId, UE.EDotsStatusType.Start, self.owner)
  else
    self:SetRpSkillStatus(false)
  end
end

function RolePlayComponent:ClearPlayingRpSkill()
  local skillObj = self.playingRpSkillObj
  self.playingRpSkillObj = nil
  if skillObj then
    skillObj:ClearDelegates()
  end
end

function RolePlayComponent:OnSkillLoadFail(req, msg)
  self.rpResReq = nil
  Log.Error("[RolePlayComponent] load skill failed. ", msg, self.playingRpBehaviorId)
  self:SetRpSkillStatus(false)
end

function RolePlayComponent:OnSkillEnd(event, skillObj)
  if self.playingRpSkillObj ~= skillObj then
    return
  end
  Log.Debug("RolePlayComponent:OnSkillEnd", event, self.playingRpBehaviorId)
  self.isLoopAnim = false
  self:ClearPlayingRpSkill()
  self:SetRpSkillStatus(true)
end

function RolePlayComponent:OnSkillInterrupt(event, skillObj)
  if self.playingRpSkillObj ~= skillObj then
    return
  end
  Log.Debug("RolePlayComponent:OnSkillInterrupt", event, self.playingRpBehaviorId)
  self.isLoopAnim = false
  self:ClearPlayingRpSkill()
  self:SetRpSkillStatus(false)
end

function RolePlayComponent:OnSkillLoopStart(event, skillObj)
  if self.playingRpSkillObj ~= skillObj then
    return
  end
  Log.Debug("RolePlayComponent:OnSkillLoopStart", event, self.playingRpBehaviorId)
  self.isLoopAnim = true
end

return RolePlayComponent

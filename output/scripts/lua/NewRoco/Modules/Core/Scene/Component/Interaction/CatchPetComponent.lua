local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEnum = require("NewRoco.Modules.Core.Scene.Common.SceneEnum")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local StunComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.StunComponent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local Base = ActorComponent
local FakeFailed = false
local CatchPetComponent = Base:Extend("CatchPetComponent")
local PET_BALL_KEY = "_ID_AUTOGENERATE_BALL0"

function CatchPetComponent:Ctor()
  Base.Ctor(self)
  self.bIsSending = false
  self.bIsCatching = false
  self.SeqId = nil
end

function CatchPetComponent:Attach(owner)
  Base.Attach(self, owner)
end

function CatchPetComponent:DeAttach()
  self.d_HudRestore = DelayManager:CancelDelayByIdEx(self.d_HudRestore)
  self.d_FakeFail = DelayManager:CancelDelayByIdEx(self.d_FakeFail)
  self.d_FakeCatchRsp = DelayManager:CancelDelayByIdEx(self.d_FakeCatchRsp)
end

function CatchPetComponent:GetSession()
  return self.owner.ThrowSession
end

function CatchPetComponent:IsDisableByPetLevel(NPCLevel)
  local level_ban_conf = _G.DataConfigManager:GetGlobalConfig("excced_level_ban_bigword_catch", true)
  local level_ban_conf_numList = level_ban_conf and level_ban_conf.numList
  local enable_level_ban = level_ban_conf_numList and 2 == #level_ban_conf_numList and 1 == level_ban_conf_numList[1]
  local level_ban_offset = level_ban_conf_numList and 2 == #level_ban_conf_numList and level_ban_conf_numList[2]
  if not enable_level_ban then
    return false
  end
  local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() + 1
  local petTopLevelConf = _G.DataConfigManager:GetWorldLevelConf(worldLevel)
  local petTopLevel = 0
  if petTopLevelConf and petTopLevelConf.pet_top_level then
    petTopLevel = petTopLevelConf.pet_top_level
  end
  petTopLevel = petTopLevel + level_ban_offset
  return NPCLevel > petTopLevel
end

function CatchPetComponent:StartCatchPet(CatchTarget)
  Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: BP_NPCCharacter_C OnThrowItemEnter OnCatchPet:")
  local BallView = self:GetOwnerView()
  local Session = self:GetSession()
  local TargetView = CatchTarget and CatchTarget.viewObj
  if not TargetView or not UE.UObject.IsValid(TargetView) then
    BallView:MakeCollectable()
    Log.Error("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \231\178\190\231\129\181\231\154\132\230\168\161\229\158\139\233\131\189\230\178\161\228\186\134...\230\138\149\230\142\183\229\164\177\230\149\136", Session and Session.SeqID or "nil")
    return
  end
  if not BallView or not UE.UObject.IsValid(BallView) then
    Log.Error("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \229\146\149\229\153\156\231\144\131\231\154\132\230\168\161\229\158\139\233\131\189\230\178\161\228\186\134...\230\138\149\230\142\183\229\164\177\230\149\136", Session and Session.SeqID or "nil")
    return
  end
  if not CatchTarget.canTriggerInteraction then
    BallView:MakeCollectable()
    Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \231\178\190\231\129\181\229\135\134\229\164\135\232\191\155\229\133\165\229\140\191\232\184\170\231\138\182\230\128\129\228\186\134...\230\138\149\230\142\183\229\164\177\230\149\136", CatchTarget.config.name, CatchTarget.config.id, CatchTarget.InteractionComponent and CatchTarget.InteractionComponent.DisableFlag, CatchTarget.InteractionComponent and CatchTarget.InteractionComponent.DisableFlagTemp)
    return
  end
  local LogicComp = CatchTarget.LogicStatusComponent
  if LogicComp then
    local IsNightmare, Msg = ThrowUtils.IsDisableByMutation(CatchTarget, BallView and BallView.BallId)
    if IsNightmare then
      BallView:MakeCollectable()
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Msg, -1, nil, 5)
      return
    end
  end
  local HiddenComp = CatchTarget.HiddenComponent
  if HiddenComp and HiddenComp:IsResistCapture(Session and Session:GetBallId()) then
    BallView:MakeCollectable()
    Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \231\178\190\231\129\181\229\140\191\232\184\170\228\186\134...\230\138\149\230\142\183\229\164\177\230\149\136", CatchTarget.config.name, CatchTarget.config.id)
    return
  end
  local AIComp = CatchTarget.AIComponent
  if AIComp and AIComp:IsResistCapture() then
    BallView:MakeCollectable()
    Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \231\178\190\231\129\181AI\230\138\151\230\139\146\228\186\134\230\141\149\230\141\137", CatchTarget.config.name, CatchTarget.config.id)
    return
  end
  local BallId = Session:GetBallId()
  local StaticRate
  if BallId then
    local BallConf = _G.DataConfigManager:GetBallConf(BallId)
    if BallConf then
      StaticRate = BallConf.static_catch_rate
    end
  end
  if not StaticRate or StaticRate < 10000 then
    local NPCLevel = CatchTarget.serverData.base.lv
    if self:IsDisableByPetLevel(NPCLevel) then
      local TextConf = _G.DataConfigManager:GetLocalizationConf("exccedlevel_ban_bigwordcatch")
      if TextConf and TextConf.msg then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, TextConf.msg)
      end
      BallView:MakeCollectable()
      Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:StartCatchPet \231\178\190\231\129\181\231\173\137\231\186\167\232\191\135\233\171\152...\230\138\149\230\142\183\229\164\177\230\149\136", CatchTarget.config.name, CatchTarget.config.id)
      return
    end
  end
  CatchTarget:SendEvent(NPCModuleEvent.CatchStart)
  self.CurrentCatchPet = CatchTarget
  CatchTarget.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.WAIT_CATCH_RSP)
  BallView:SetThrowFuncInValid()
  BallView:TogglePhysics(false)
  local PetBaseConf = CatchTarget:GetConfPetData()
  if PetBaseConf then
    Session.CatchPetBaseID = PetBaseConf.id
  end
  Session:SetStatus(ThrowSessionStatusEnum.Catching)
  Session.endThrowSendDone = true
  local endThrowReq = _G.ProtoMessage:newZoneSceneEndThrowReq()
  endThrowReq.throw_type = _G.ProtoEnum.ThrowType.THROW_BAGITEM
  endThrowReq.gid = Session:GetGID()
  endThrowReq.throw_id = Session:GetThrowID()
  endThrowReq.fly_distance = math.round(math.sqrt(Session:GetFlyDistance()))
  endThrowReq.end_throw_pos = SceneUtils.ClientPos2ServerPos(CatchTarget.viewObj:Abs_K2_GetActorLocation())
  endThrowReq.item_conf_id = Session:GetItemID()
  local targetInfo = _G.ProtoMessage:newThrowTargetNpcInfo()
  targetInfo.npc_id = CatchTarget.serverData.base.actor_id
  targetInfo.npc_conf_id = CatchTarget.config.id
  targetInfo.npc_ai_status = 0
  targetInfo.npc_logic_id = CatchTarget.serverData.base.logic_id
  if AIComp and AIComp:GetPerceptionLevel() then
    targetInfo.npc_ai_status = targetInfo.npc_ai_status + _G.ProtoEnum.ThrowTargetNpcAIStatus.DETECTED_AVATAR
  end
  targetInfo.npc_ai_behavior = AIComp and AIComp.battleState or 0
  local Ball = self:GetOwner()
  local actDir = CatchTarget:GetActorLocation() - Ball:GetActorLocation()
  actDir:Normalize()
  targetInfo.is_back_stab = SceneUtils.TriggerBackwardCatch(CatchTarget, actDir) or false
  table.insert(endThrowReq.throw_target_npc_infos, targetInfo)
  endThrowReq.throw_effect = _G.ProtoEnum.ThrowEffect.CATCH
  CatchTarget:SetNotDestroyFlag(true)
  if AIComp then
    AIComp:ForceLockForReason(true, false, AIDefines.LockReason.INTERACT)
  end
  local bIsSent = false
  if FakeFailed then
    bIsSent = true
    self.d_FakeFail = _G.DelayManager:DelayFramesEx(self.d_FakeFail, 5, self.FakeFail, self, CatchTarget)
  else
    bIsSent = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, endThrowReq, self, self.OnCatchRsp, false, true)
  end
  if AIComp then
    self:SendDotsEvent(CatchTarget, nil, Enum.DotsAIWorldEventType.DAWET_THROW_CATCH_START)
  end
  local player = SceneUtils.GetPlayer()
  player.ThrowManagementComponent:StartCatch(Session)
  self.owner:FaceTo(player)
  if bIsSent then
    self.bIsSending = true
  else
    self.d_FakeCatchRsp = _G.DelayManager:DelayFramesEx(self.d_FakeCatchRsp, 1, self.FakeCatchRsp, self)
  end
end

function CatchPetComponent:FakeFail(CatchTarget)
  self.d_FakeFail = nil
  local ThrowNotify = _G.ProtoMessage:newSpaceAct_DeleteThrowNotify()
  local Player = SceneUtils.GetPlayer()
  local Session = self:GetSession()
  ThrowNotify.caster_id = Player:GetServerId()
  ThrowNotify.throw_id = Session:GetThrowID()
  ThrowNotify.npc_id = CatchTarget:GetServerId()
  ThrowNotify.is_catch = true
  ThrowNotify.is_catch_success = false
  ThrowNotify.is_tech_satisfied = false
  ThrowNotify.shake_times = 3
  ThrowNotify.glass_info = nil
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ThrowCatchNotify, ThrowNotify)
  local Rsp = _G.ProtoMessage:newZoneSceneEndThrowRsp()
  Rsp.ret_info.ret_code = 0
  self:OnCatchRsp(Rsp)
end

function CatchPetComponent:FakeCatchRsp()
  self.d_FakeCatchRsp = nil
  Log.Error("\230\141\149\230\141\137\229\141\143\232\174\174\230\178\161\230\156\137\229\143\145\233\128\129\230\136\144\229\138\159\230\136\150\232\128\133\229\143\145\233\128\129\232\191\135\231\168\139\228\184\173\230\150\173\231\186\191\233\135\141\232\191\158\228\186\134\239\188\140\232\161\165\229\133\133\228\184\128\228\184\170\229\129\135\231\154\132\230\141\149\230\141\137\229\164\177\232\180\165\228\191\161\230\129\175")
  local rsp = _G.ProtoMessage:newZoneSceneEndThrowRsp()
  rsp.ret_info.ret_code = -1
  self:OnCatchRsp(rsp)
end

function CatchPetComponent:OnDisConnect()
  if not self.bIsSending then
    return
  end
  self:FakeCatchRsp()
end

function CatchPetComponent:OnCatchRsp(rsp)
  self.bIsSending = false
  Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:OnCatchRsp", self.owner.ThrowSession.SeqID)
  Log.Dump(rsp, 5, "BP_NPCCharacter_C OnThrowItemEnter rsp:")
  local CatchTarget = self.CurrentCatchPet
  local TargetAIComp = CatchTarget.AIComponent
  local TargetInterComp = CatchTarget.InteractionComponent
  local Session = self:GetSession()
  TargetInterComp:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.WAIT_CATCH_RSP)
  local ret_code = rsp.ret_info.ret_code
  if 0 ~= ret_code then
    if 50735 == ret_code then
      local tip, ownerName = UIUtils.GetHighValuePetTipsAndOwnerName(CatchTarget.serverData)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    elseif 1126 == ret_code then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.onlinemodule_12)
    end
    if TargetAIComp then
      TargetAIComp:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
    end
    Log.Error("catch failed with ret_code", ret_code)
    CatchTarget:SetNotDestroyFlag(false)
    local player = SceneUtils.GetPlayer()
    player.ThrowManagementComponent:EndCatch(Session)
    self:RecycleBall()
    return
  end
  local CatchSuccess = rsp.catch_result.is_catched
  if CatchSuccess then
  elseif TargetAIComp then
    TargetAIComp:ForceLockForReason(false, false, AIDefines.LockReason.INTERACT)
  end
  CatchTarget.hideTrackMark = true
  _G.DataModelMgr.PlayerDataModel:UpdatePetCatchInfo(Session.CatchPetBaseID, CatchSuccess)
  Session.CatchPetBaseID = 0
  TargetInterComp:OnPlayerTeleportStart()
end

function CatchPetComponent:PlayCaughtSkill(Caster, CatchTarget, Success, ShakeTimes, UseTechnique, IsBack, glass_info, is_quick_catch)
  Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:PlayCaughtSkill")
  if glass_info.glass_type == _G.ProtoEnum.GlassType.GT_HIDDEN then
    local glass_conf = _G.DataConfigManager:GetHiddenGlassConf(glass_info.glass_value, true)
    local ball_fx = glass_conf and glass_conf.ball_fx or ""
    Caster.viewObj:SetResGroup(ball_fx)
  end
  self.bIsCatching = true
  self.CurrentCatchPet = CatchTarget
  local TargetView = CatchTarget.viewObj
  local TargetAIComp = CatchTarget.AIComponent
  local WorldPlayer = SceneUtils.GetPlayer()
  Caster = Caster or WorldPlayer
  local SkillComp = TargetView.RocoSkill
  local SkillObj
  SkillObj = RocoSkillProxy.Create(_G.UEPath.CATCH_SKILL_WORLD, SkillComp, _G.PriorityEnum.Active_Player_Action)
  SkillObj:SetPassive(true)
  SkillObj:SetCaster(Caster.viewObj)
  SkillObj:SetTargets({
    TargetView,
    WorldPlayer.viewObj
  })
  SkillObj:RegisterEventCallback("PreStart", self, self.PreStart)
  SkillObj:RegisterEventCallback("Start", self, self.OnCatchStart)
  SkillObj:RegisterEventCallback("End", self, self.OnCatchPetAnimFinishCallback)
  SkillObj:RegisterEventCallback("PreEnd", self, self.OnCatchPetAnimFinishCallback)
  SkillObj:RegisterEventCallback("PreEndAnim", self, self.OnCatchPetAnimFinishCallback)
  SkillObj:RegisterEventCallback("Interrupt", self, self.OnCatchPetAnimFinishCallback)
  SkillObj:SetAdditions("CatchSuccess", Success)
  SkillObj:SetAdditions("ShakeTimes", ShakeTimes)
  SkillObj:SetAdditions("UseTechnique", UseTechnique)
  SkillObj:SetAdditions("is_quick_catch", is_quick_catch)
  SkillObj:SetAdditions("glass_info", glass_info)
  SkillObj:SetAdditions("IsBack", true == IsBack)
  SkillObj:SetForcePlayPassive(true)
  SkillObj:PlaySkill(self, self.OnSkillStartCallback)
  if TargetAIComp then
    TargetAIComp:ForceLockForReason(true, false, AIDefines.LockReason.CATCH)
  end
  local TargetInteractionComponent = CatchTarget.InteractionComponent
  if TargetInteractionComponent then
    TargetInteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.WAIT_CATCH_PERFORM)
  end
  CatchTarget:Stop()
  local MoveComp = TargetView.CharacterMovement
  MoveComp:Deactivate()
  TargetView:SetActorEnableCollision(false)
  if CatchTarget.HiddenComponent and CatchTarget.HiddenComponent:IsHidden() then
    CatchTarget.HiddenComponent:ResetHide(true, false)
  end
  local Session = self:GetSession()
  Session.bCatchSuccess = Success
  self.SeqId = Session.SeqID
end

function CatchPetComponent:PreStart(Event, SkillObj)
  if not UE.UObject.IsValid(SkillObj) then
    return
  end
  local Success = SkillObj:GetAddition("CatchSuccess")
  local ShakeTimes = SkillObj:GetAddition("ShakeTimes")
  local UseTechnique = SkillObj:GetAddition("UseTechnique")
  local glass_info = SkillObj:GetAddition("glass_info")
  local IsBack = SkillObj:GetAddition("IsBack")
  local is_quick_catch = SkillObj:GetAddition("is_quick_catch")
  local blackboard = SkillObj:GetBlackboard()
  if not blackboard then
    return
  end
  local throwSession = self.owner and self.owner.ThrowSession
  local itemData = throwSession and throwSession.itemData
  local ball_id = itemData and itemData.id or 0
  if is_quick_catch then
    blackboard:SetValueAsString("World_BuZhuo_HX", "World_BuZhuo_HX")
  else
    blackboard:SetValueAsString("World_BuZhuo", "World_BuZhuo")
    if Success then
      blackboard:SetValueAsInt("Seg0", 0)
      blackboard:SetValueAsInt("Seg1", 0)
    else
      blackboard:SetValueAsInt("Seg0", 0 == ShakeTimes and 1 or 0)
      blackboard:SetValueAsInt("Seg1", ShakeTimes <= 1 and 1 or 0)
    end
  end
  if Success then
    blackboard:SetValueAsInt("Success", 1)
  else
    blackboard:SetValueAsInt("Fail", 1)
  end
  blackboard:SetValueAsObject(PET_BALL_KEY, self:GetOwnerView())
  if UseTechnique then
    blackboard:SetValueAsString("BaoJi", "BaoJi")
  end
  blackboard:SetValueAsString("IsBack", IsBack and "True" or "False")
  local BallConfig = _G.DataConfigManager:GetBallConf(ball_id)
  local effectBlackboard = BallConfig and BallConfig.catch_effect_blackboard or "Normal"
  if glass_info then
    if glass_info.glass_type == ProtoEnum.GlassType.GT_COMMON then
      local glassInfoDetails = PetMutationUtils.DecodeShineColorId(glass_info)
      self.colorA = nil
      self.colorB = nil
      if glassInfoDetails and glassInfoDetails.colorInfo then
        local conf = _G.DataConfigManager:GetColorRandomConf(glassInfoDetails.colorInfo.colorId)
        if nil ~= conf then
          self.colorA = PetMutationUtils.GetShineColor(conf.mat_color_1)
          self.colorB = PetMutationUtils.GetShineColor(conf.mat_color_2)
        end
        self.particleId = glassInfoDetails.colorInfo.particle
      end
      SkillObj:RegisterEventCallback("SpawnBuZhuoFx", self, self.SpawnBallEffectBP)
    elseif glass_info.glass_type == ProtoEnum.GlassType.GT_HIDDEN then
      local hiddenGlass = DataConfigManager:GetHiddenGlassConf(glass_info.glass_value, true)
      if hiddenGlass then
        effectBlackboard = hiddenGlass.ball_fx or "Normal"
      end
    end
  end
  blackboard:SetValueAsString(effectBlackboard, effectBlackboard)
  local actionBlackboard = "NoColorFul"
  if BallConfig and not string.IsNilOrEmpty(BallConfig.catch_action) then
    actionBlackboard = BallConfig.catch_action
  end
  blackboard:SetValueAsString(actionBlackboard, actionBlackboard)
  blackboard:SetValueAsBool("catchSucc", Success)
  Log.DebugFormat("Setup Catch Params: SeqID: %d, Success=%s, ShakeTimes=%d, UseTechnique=%s, IsBack=%s is_quick_catch=%s", throwSession.SeqID, Success, ShakeTimes, UseTechnique, IsBack, is_quick_catch)
end

function CatchPetComponent:SpawnBallEffectBP(Event, Skill)
  local EffectBp = self:GetBlackboardValue(Skill, "Buzhuo_Fx_Zhuti")
  if EffectBp and self.CurrentCatchPet and self.colorA and self.colorB then
    EffectBp.Color1 = self.colorA
    EffectBp.Color2 = self.colorB
    EffectBp.Icon = self.particleId
    EffectBp:ReceiveBeginPlay()
    self.colorA = nil
    self.colorB = nil
  end
end

function CatchPetComponent:GetBlackboardValue(Skill, blackboardKey, remove)
  if not Skill then
    return
  end
  local blackboard = Skill:GetBlackboard()
  if not blackboard then
    return
  end
  local obj = blackboard:GetValueAsObject(blackboardKey)
  if remove then
    blackboard:RemoveObjectValue(blackboardKey)
  end
  return obj
end

function CatchPetComponent:OnSkillStartCallback(Proxy, Result)
  Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: CatchPetComponent:OnSkillStartCallback")
  if Result ~= UE4.ESkillStartResult.Success then
    Log.Error("failed to play skill!", Result, _G.UEPath.CATCH_SKILL_WORLD)
    local TargetInteractionComponent = self.CurrentCatchPet and self.CurrentCatchPet.InteractionComponent
    if TargetInteractionComponent then
      TargetInteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.WAIT_CATCH_PERFORM)
    end
    self.bIsCatching = false
    return
  end
  local CatchTarget = self.CurrentCatchPet
  local TargetHudComp = CatchTarget.PetHUDComponent
  if TargetHudComp then
    self.tmpHudPerception = TargetHudComp:GetCurrentHudPerception()
    TargetHudComp:SetMainHudPerception(SceneEnum.PerceptionHudType.None, true)
  end
  local stunComponent = CatchTarget:GetComponent(StunComponent)
  if stunComponent then
    stunComponent:SetHidden(true)
  end
  self.d_HudRestore = _G.DelayManager:DelayFramesEx(self.d_HudRestore, 4, self.FixHudRestore, self)
end

function CatchPetComponent:FixHudRestore()
  self.d_HudRestore = nil
  local CatchTarget = self.CurrentCatchPet
  if not CatchTarget then
    return
  end
  local TargetView = CatchTarget.viewObj
  if not TargetView then
    return
  end
  local HeadWidget = TargetView.HeadWidget
  if HeadWidget:IsValidLowLevel() then
    HeadWidget:SetHiddenInGame(true, true)
  end
end

function CatchPetComponent:RecycleBall(Blend)
  local BallView = self:GetOwnerView()
  if BallView then
    BallView:SetActorScale3D(_G.FVectorOne)
    BallView:ThrowRecycle(Blend)
  end
end

function CatchPetComponent:OnCatchStart(Event, Skill)
end

function CatchPetComponent:OnCatchPetAnimFinishCallback(Event, SkillObj)
  local Blackboard = SkillObj and SkillObj:GetBlackboard()
  local ball = Blackboard and Blackboard:GetValueAsObject(PET_BALL_KEY)
  if ball and ball == self:GetOwnerView() then
    Blackboard:RemoveObjectValue(PET_BALL_KEY)
  end
  local CatchTarget = self.CurrentCatchPet
  local stunComponent = CatchTarget:GetComponent(StunComponent)
  if stunComponent then
    stunComponent:SetHidden(true)
  end
  self.bIsCatching = false
  local TargetView = CatchTarget.viewObj
  if not TargetView then
    Log.Warning("Model of pet being caught has been destroyed!")
    local player = SceneUtils.GetPlayer()
    if player then
      player.ThrowManagementComponent:EndCatch(self:GetSession())
    end
    self:RecycleBall(true)
    return
  end
  local HeadWidget = TargetView.HeadWidget
  CatchTarget:AdjustModelHeight()
  local TargetHudComp = CatchTarget.PetHUDComponent
  if TargetHudComp then
    TargetHudComp:RestoreHeadWidgetLocation()
    TargetHudComp:SetMainHudPerception(self.tmpHudPerception)
    self.tmpHudPerception = SceneEnum.PerceptionHudType.None
  end
  HeadWidget:SetHiddenInGame(false, true)
  Log.Debug("CatchPetComponent OnCatchPetAnimFinishCallback:", SkillObj)
  local CatchSuccess = Blackboard and Blackboard:GetValueAsBool("catchSucc")
  local BallView = self:GetOwnerView()
  if BallView then
    BallView:SetActorScale3D(_G.FVectorOne)
  end
  local TargetAIComp = CatchTarget.AIComponent
  local Session = self:GetSession()
  if CatchSuccess then
    self:RecycleBall(true)
    if TargetAIComp then
      self:SendDotsEvent(CatchTarget, nil, Enum.DotsAIWorldEventType.DAWET_THROW_CATCH_SUCCESS)
    end
    TargetView:OnRemoveSelf()
  else
    if BallView then
      BallView:RemoveItem()
    end
    local MoveComp = TargetView.CharacterMovement
    MoveComp:Activate(true)
    TargetView:SetActorEnableCollision(true)
    if TargetAIComp then
      TargetAIComp:ForceLockForReasonDelay(false, false, AIDefines.LockReason.CATCH, 1)
      self:SendDotsEvent(CatchTarget, 0, Enum.DotsAIWorldEventType.DAWET_RUNAWAY, 2)
      self:SendDotsEvent(CatchTarget, nil, Enum.DotsAIWorldEventType.DAWET_THROW_CATCH_FAIL)
      self:SendDotsEvent(CatchTarget, 0, Enum.DotsAIWorldEventType.DAWET_THROW_CATCH_FAIL_SELF, Session and Session:GetBallId() or 1)
    end
    CatchTarget:SetNotDestroyFlag(false)
    local TargetInteractionComponent = CatchTarget.InteractionComponent
    if TargetInteractionComponent then
      TargetInteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.WAIT_CATCH_PERFORM)
    end
    CatchTarget.hideTrackMark = false
  end
  local player = SceneUtils.GetPlayer()
  if player then
    player.ThrowManagementComponent:EndCatch(Session)
  else
    Log.Error("player\230\178\161\228\186\134\239\188\140\232\191\153\229\190\136\228\184\165\233\135\141\228\186\134...")
  end
  if Session then
    Session:SendCatchFinishReq()
  else
    Log.Error("Session\228\184\162\228\186\134\239\188\140\229\133\182\229\174\158\232\155\174\228\184\165\233\135\141\231\154\132\239\188\140\233\157\160\229\144\142\229\143\176\232\182\133\230\151\182\233\128\187\232\190\145\228\186\134", self.SeqId)
  end
end

local SceneAIManager

local function GetAIManager()
  if not SceneAIManager then
    local Module = _G.NRCModuleManager:GetModule("NPCModule")
    SceneAIManager = Module and Module.SceneAIManager
  end
  return SceneAIManager
end

function CatchPetComponent:SendDotsEvent(...)
  local AIManager = GetAIManager()
  if not AIManager then
    return
  end
  AIManager:SendDotsEvent(...)
end

function CatchPetComponent:CheckCanCatchPet(CatchTarget)
  local equipItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetCurEquipItemInfo)
  local IsDisableByMutation = ThrowUtils.IsDisableByMutation(CatchTarget, equipItem and equipItem.id)
  if IsDisableByMutation then
    return false
  end
  local HiddenComp = CatchTarget.HiddenComponent
  if HiddenComp and HiddenComp:IsHidden() and HiddenComp.hiddenType then
    local hideType = HiddenComp.hiddenType
    local isBan = false
    local isEmpty = false
    local banExecuteTable = self:GetHideExecuteTable("ban_catch_pet_world_hide_type")
    local emptyExecuteTable = self:GetHideExecuteTable("mimic_aim_dispaly_null")
    local allowHideList = {}
    if equipItem and equipItem.id then
      local ballActConf = _G.DataConfigManager:GetBallAct(equipItem.id, true)
      if ballActConf and ballActConf.ball_wh_mimic then
        allowHideList = ballActConf.ball_wh_mimic
      end
    end
    if table.contains(banExecuteTable, hideType) and not table.contains(allowHideList, hideType) then
      isBan = true
    end
    if table.contains(emptyExecuteTable, hideType) and not table.contains(allowHideList, hideType) then
      isEmpty = true
    end
    if isEmpty then
      return false, true
    end
    if isBan then
      return false
    end
  end
  local AIComp = CatchTarget.AIComponent
  if AIComp and AIComp:IsResistCapture() then
    return false
  end
  local mutationType = CatchTarget.serverData.npc_base.mutation_type
  local isGlass = mutationType and (0 ~= mutationType & _G.Enum.MutationDiffType.MDT_GLASS or PetUtils.CheckIsShiningGlass(mutationType))
  local ForbidBallsConf = _G.DataConfigManager:GetNpcGlobalConfig("catch_pet_world_cant_colorpet_ball")
  local ForbidBalls = ForbidBallsConf and ForbidBallsConf.numList
  if equipItem and ForbidBalls and table.contains(ForbidBalls, equipItem.id) and isGlass then
    return false
  end
  local isFighting = CatchTarget:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
  if isFighting then
    return false
  end
  local npcLevel = CatchTarget.serverData.base.lv
  if self:CheckIsBeyondLevel(equipItem, npcLevel) then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if playerUin ~= _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() then
      local isNightmare = mutationType and (0 ~= mutationType & _G.Enum.MutationDiffType.MDT_CHAOS or 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_CHAOS_TWO or 0 ~= mutationType & _G.Enum.MutationDiffType.MDT_CHAOS_THREE)
      if isGlass or isNightmare then
        return false
      end
    end
  end
  return true
end

function CatchPetComponent:CheckIsBeyondLevel(equipItem, npcLevel)
  local levelLimitList = _G.DataConfigManager:GetGlobalConfigByKey("excced_level_ban_bigword_catch").numList
  if levelLimitList then
    local isLimit = levelLimitList[1]
    if 1 == isLimit then
      local levelRange = levelLimitList[2]
      if equipItem and equipItem.id then
        local ballConf = _G.DataConfigManager:GetBallConf(equipItem.id)
        if ballConf then
          local staticRate = ballConf.static_catch_rate
          if not staticRate or staticRate < 10000 then
            local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() + 1
            local petTopLevelConf = _G.DataConfigManager:GetWorldLevelConf(worldLevel)
            local petTopLevel = 0
            if petTopLevelConf and petTopLevelConf.pet_top_level then
              petTopLevel = petTopLevelConf.pet_top_level
            end
            petTopLevel = petTopLevel + levelRange
            if levelRange >= 0 then
              if npcLevel > petTopLevel then
                return true
              end
            elseif npcLevel < petTopLevel then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function CatchPetComponent:GetHideExecuteTable(key)
  local hideExecuteTable = {}
  local npcGlobalConf = _G.DataConfigManager:GetNpcGlobalConfig(key, true)
  if npcGlobalConf and npcGlobalConf.str then
    local WHEnumNames = string.split(npcGlobalConf.str, ";")
    for _, WHEnumName in ipairs(WHEnumNames) do
      table.insert(hideExecuteTable, Enum.WorldHide[WHEnumName])
    end
  end
  return hideExecuteTable
end

return CatchPetComponent

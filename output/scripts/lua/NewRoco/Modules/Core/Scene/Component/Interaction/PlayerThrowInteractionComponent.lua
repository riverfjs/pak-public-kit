local BubbleType = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleType")
local BubbleComponent = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleComponent")
local PetActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PetActionFactory")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local BattleField = require("NewRoco.Modules.Core.Battle.Common.BattleField")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ActionUtils = require("NewRoco.Modules.Core.NPC.Actions.ActionUtils")
local TimeoutEventListener = require("Common.TimeoutEventListener")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local Base = ActorComponent
local PlayerThrowInteractionComponent = Base:Extend("PlayerThrowInteractionComponent")

function PlayerThrowInteractionComponent:Ctor()
  Base.Ctor(self)
  self.TimeoutEventListener = TimeoutEventListener()
end

function PlayerThrowInteractionComponent:Attach(owner)
  self.Submitted = false
  self.RequestSent = false
  _G.NRCEventCenter:RegisterEvent("PlayerThrowInteractionComponent:Attach", self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLogin)
  Base.Attach(self, owner)
end

function PlayerThrowInteractionComponent:OnLogin()
end

function PlayerThrowInteractionComponent:SubmitBattle(Session, SceneCharacter, WeakPointName)
  BattleProfiler:CheckPoint(BattleProfilerCheckPoint.ThrowBallHitMonster)
  if SceneCharacter.AIComponent then
    SceneCharacter.AIComponent:LockForBattleReason(true)
  end
  self.Session = Session
  self.SceneCharacter = SceneCharacter
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetThrowHitTestInvisible, true)
  self:SendThrowEnd(WeakPointName)
end

function PlayerThrowInteractionComponent:SendThrowEnd(WeakPointName)
  self.Is1vN = false
  local Ball = self.Session.Ball
  local BallView = Ball and Ball.viewObj
  if UE4.UObject.IsValid(BallView) then
    BallView:SetActorHiddenInGame(true)
  end
  if self.owner:IsInTogetherMove() and self.owner.viewObj then
    local rideComp = self.owner.viewObj.BP_RideComponent
    if rideComp then
      rideComp:TryChangeToLink()
      if rideComp:TryChangeToLink() then
        self.owner:StopRide(true, nil)
      end
    end
  end
  local req = _G.ProtoMessage:newZoneSceneEndThrowReq()
  req.gid = self.Session:GetGID()
  req.throw_id = self.Session:GetThrowID()
  req.throw_type = _G.ProtoEnum.ThrowType.THROW_PET
  req.throw_effect = _G.ProtoEnum.ThrowEffect.TRIG_PET_INTERACT
  req.item_conf_id = self.Session:GetItemID()
  local targetInfo = _G.ProtoMessage:newThrowTargetNpcInfo()
  targetInfo.npc_id = self.SceneCharacter.serverData.base.actor_id
  targetInfo.npc_conf_id = self.SceneCharacter.config.id
  local Option = self.SceneCharacter.InteractionComponent:GetBattleOption()
  if Option then
    targetInfo = Option:GetThrowTargetNpcInfo()
    targetInfo.gain_expose_pos_name = WeakPointName
    table.insert(req.throw_target_npc_infos, targetInfo)
  else
    Log.Error("PlayerThrowInteractionComponent:SendThrowEnd \229\176\157\232\175\149\232\191\155\230\136\152\230\150\151\229\164\177\232\180\165\239\188\140\232\175\183\230\138\138\230\151\165\229\191\151\229\146\140\228\185\139\229\137\141\229\143\145\231\148\159\231\154\132\230\131\133\229\134\181\229\143\145\231\187\153marvynwang", table.tostring(req))
    req.throw_effect = _G.ProtoEnum.ThrowEffect.TE_NONE
  end
  req.throw_battle_info.radius = _G.BattleConst.Define.BattleFieldRange
  local EntryLocation = self.SceneCharacter:GetServerPoint()
  req.throw_battle_info.npc_pt = EntryLocation
  req.throw_battle_info.avatar_pt = EntryLocation
  req.throw_battle_info.is_battle_action = true
  local isSleeping = 0
  if self.SceneCharacter.AIComponent then
    req.throw_battle_info.npc_ai_blackboard.ai_status = self.SceneCharacter.AIComponent.battleState
    req.throw_battle_info.npc_ai_blackboard.pre_act_tag = self.SceneCharacter.AIComponent.PreAttackTag
    req.throw_battle_info.npc_ai_blackboard.pre_act_param = self.SceneCharacter.AIComponent.PreAttackCount
    if req.throw_battle_info.npc_ai_blackboard.ai_status & 1 << ProtoEnum.BattleAIStatus.BAS_SLEEP > 0 then
      isSleeping = 1
    end
  end
  req.throw_battle_info.npc_ai_blackboard.sleeping = isSleeping
  local npcModule = self.SceneCharacter.module
  if SceneUtils.EnableBattleExtraMemberFetching then
    local specialBattle = npcModule.SceneAIManager:FillBattleExtraMemberData(req.throw_battle_info.cheer_monster_init_info, req.throw_battle_info.onlooker_obj_id, self.SceneCharacter, 1)
    if specialBattle then
      req.throw_battle_info.battle_type = specialBattle
      if specialBattle == Enum.BattleType.BT_1VN then
        self.is1VN = true
      end
    end
  end
  if req.throw_effect ~= _G.ProtoEnum.ThrowEffect.TE_NONE then
    local actDir = self.SceneCharacter:GetActorLocation() - self.owner:GetActorLocation()
    actDir:Normalize()
    local isBack, isTalent = SceneUtils.TriggerBackwardBattle(self.SceneCharacter, actDir, 1, Ball.ThrowSession.ScenePet)
    if isBack then
      req.throw_battle_info.npc_ai_blackboard.back_of_head = true
      local alterStatus
      if isTalent then
        alterStatus = 1 << Enum.BattleAIStatus.BAS_BACK_OF_HEAD_TALENT
      else
        alterStatus = 1 << Enum.BattleAIStatus.BAS_BACK_OF_HEAD
      end
      req.throw_battle_info.npc_ai_blackboard.ai_status = req.throw_battle_info.npc_ai_blackboard.ai_status | alterStatus
    end
    if self.SceneCharacter.config.genre ~= Enum.ClientNpcType.CNT_PETBOSS then
      BattleManager:StartFocus(self.SceneCharacter, isBack, req.throw_battle_info.npc_ai_blackboard.ai_status)
      local stunComp = self.SceneCharacter.StunComponent
      if stunComp and stunComp then
        stunComp:StopStun(true)
      end
    end
  end
  local EnvSystem = _G.NRCModuleManager:GetModule("EnvSystemModule")
  local envTod = 0
  if EnvSystem then
    envTod = math.floor(EnvSystem:GetCurrentTime() / 3600.0)
  else
    Log.Error("EnvSystem\232\142\183\229\143\150\229\164\177\232\180\165\239\188\140\230\136\152\230\150\151tod\229\183\178\231\166\129\231\148\168")
  end
  req.throw_battle_info.npc_ai_blackboard.tod = envTod
  req.throw_battle_info.npc_ai_blackboard.new_skill = nil
  if self.owner.viewObj and self.owner.viewObj.BP_RideComponent and self.owner.viewObj.BP_RideComponent.ScenePet then
    req.throw_battle_info.ride_id = self.owner.viewObj.BP_RideComponent.ScenePet.gid
  end
  self.Submitted = false
  self.Session.endThrowSendDone = true
  _G.BattleManager.isSendWaiting = true
  local Sent = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, self, self.OnSubmitBattle, false, false)
  if Sent then
    self.TimeoutEventListener:Stop()
    self.TimeoutEventListener:StartGlobalEventListener(5, self.name, self, TaskModuleEvent.BattleStart, self.OnBattleStartOrTimeout)
  else
    self:SendFakeEnd()
  end
end

function PlayerThrowInteractionComponent:OnReConnect()
  if not self.Session then
    return
  end
  if self.Submitted then
    return
  end
  self:SendFakeEnd()
end

function PlayerThrowInteractionComponent:SendFakeEnd()
  local rsp = _G.ProtoMessage:newZoneSceneEndThrowRsp()
  rsp.ret_info.ret_code = -1
  self:OnSubmitBattle(rsp)
end

function PlayerThrowInteractionComponent:OnBattleStartOrTimeout()
  _G.BattleManager.isSendWaiting = false
  if self.Session then
    self.Session:RecycleAllRes()
  end
  if _G.BattleManager:IsInBattle() then
    return
  end
  if self.SceneCharacter and self.SceneCharacter.AIComponent then
    self.SceneCharacter.AIComponent:UnlockForBattleReason()
  end
end

function PlayerThrowInteractionComponent:OnSubmitBattle(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.BattleManager.isSendWaiting = false
    _G.BattleManager:StopFocus()
    if self.Session then
      self.Session:RecycleAllRes()
    end
    if self.SceneCharacter and self.SceneCharacter.AIComponent then
      self.SceneCharacter.AIComponent:UnlockForBattleReason()
    end
    if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_CATCH_FORBID and self.SceneCharacter.serverData then
      local tip, ownerName = UIUtils.GetHighValuePetTipsAndOwnerName(self.SceneCharacter.serverData)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tip)
    end
  else
    local BallView = self.Session and self.Session:GetBallView()
    if BallView then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, BallView, false)
    end
  end
  self.Submitted = true
  self.Session = nil
end

function PlayerThrowInteractionComponent:IsPlaying()
  return self.Session ~= nil
end

function PlayerThrowInteractionComponent:RunOptions(Runner, Infos)
  local Count = 0
  local AnyNPC
  for _, Info in ipairs(Infos) do
    local NPC = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, Info.npc_id)
    if not NPC then
    else
      local InterComp = NPC.InteractionComponent
      if not InterComp then
      else
        local Option = InterComp:GetOptionByID(Info.option_id)
        if not Option then
        else
          local Conf = _G.DataConfigManager:GetPetInteractionConf(Info.interact_id)
          if not Conf then
          else
            local Action = PetActionFactory:GetAction(Option, Conf)
            if Action then
              AnyNPC = AnyNPC or NPC
              Count = Count + 1
              Action:SetNextSubmissionMode(ActionUtils.ActionSubmissionMode.Local)
              Action:Execute(Runner)
            end
          end
        end
      end
    end
  end
  if Count <= 0 then
    return
  end
  local BubbleComp = Runner:EnsureComponent(BubbleComponent)
  if Runner.AIComponent then
    Runner.AIComponent:OnDistanceOptimize(0, 0, 0, 2)
  end
  BubbleComp:Play(AnyNPC, BubbleType.PetHappy, self, self.OnBubbleFinish, Runner)
end

function PlayerThrowInteractionComponent:OnBubbleFinish(Success, Runner)
  if not Runner then
    return
  end
  if Runner.AIComponent then
    Runner.AIComponent:OnDistanceOptimize(0, 0, 0, 0)
  end
end

function PlayerThrowInteractionComponent:Destroy()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLogin)
  self.TimeoutEventListener:Stop()
  Base.Destroy(self)
end

return PlayerThrowInteractionComponent

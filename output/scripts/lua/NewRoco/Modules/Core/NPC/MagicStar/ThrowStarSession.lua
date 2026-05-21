local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local Base = require("NewRoco.Modules.Core.NPC.ThrowSessionBase")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DummyTable = require("Common.DummyTable")
local ThrowStarSession = Base:Extend("ThrowStarSession")
ThrowStarSession.ShowTrajectory = false
ThrowStarSession.ActiveStarSessions = {}
ThrowStarSession.LastCriticalHitTime = -1
ThrowStarSession.LastCriticalHitSeq = nil

function ThrowStarSession:Ctor()
  Base.Ctor(self)
  self.StarNPC = nil
  self.charge_level = 0
  self.status = ThrowSessionStatusEnum.InHand
  if self.ShowTrajectory then
    _G.UpdateManager:Register(self)
  end
end

function ThrowStarSession:OnTick(DeltaTime)
  if not ThrowStarSession.ShowTrajectory then
    _G.UpdateManager:UnRegister(self)
    return
  end
  if not self.StarNPC then
    _G.UpdateManager:UnRegister(self)
    return
  end
  local CurrentPos
  if self.StarNPC and self.StarNPC.viewObj then
    CurrentPos = self.StarNPC:GetActorLocation()
  end
  if not CurrentPos then
    return
  end
  if not self.PrevPos then
    self.PrevPos = CurrentPos
  end
  local Color = UE4.FLinearColor(1, 1, 1)
  if self.StarNPC.viewObj.collisionEnabled then
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.PrevPos, CurrentPos, Color, 30, 2)
  elseif self.StarNPC.viewObj.throwStarted then
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.PrevPos, CurrentPos, UE4.FLinearColor(1, 0, 0), 30, 2)
  else
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.PrevPos, CurrentPos, UE4.FLinearColor(0, 0, 0), 30, 2)
  end
  self.PrevPos = CurrentPos
end

function ThrowStarSession:Recycle()
  local viewObj = self.StarNPC and self.StarNPC.viewObj
  if self.StarNPC then
    self.StarNPC:Destroy()
    self.StarNPC = nil
  end
end

function ThrowStarSession:OnHit()
  if not self.CollisionReq then
    self.CollisionReq = _G.ProtoMessage:newZoneSceneThrowCollisionReq()
    self.CollisionReq.throw_id = self.SeqID
    self.CollisionReq.throw_type = ProtoEnum.ThrowType.THROW_MAGIC
    self.CollisionReq.item_conf_id = 100701
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  UE.UNRCStatics.BatchShakeTrees(World, self.StarNPC.viewObj:K2_GetActorLocation(), self.StarNPC.viewObj.BoomRange)
end

function ThrowStarSession:CreateStar()
  local session = ThrowStarSession()
  table.insert(ThrowStarSession.ActiveStarSessions, session)
  return session
end

function ThrowStarSession:SetInAir()
  return true
end

function ThrowStarSession:OnBeginThrow()
  local req = ProtoMessage:newZoneSceneBeginThrowReq()
  local data = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100701)
  if data and data.gid then
    req.gid = data.gid
    req.item_conf_id = data.id or 0
  else
    Log.Error("\233\135\138\230\148\190\233\173\148\230\179\149\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129", table.tostring(data))
  end
  req.throw_id = self.SeqID
  req.throw_type = ProtoEnum.ThrowType.THROW_MAGIC
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEGIN_THROW_REQ, req, self, self.OnBeginThrowRsp, false, true)
  self.status = ThrowSessionStatusEnum.InAir
  local minSeqID
  local minStar = 0
  local InAirNum = 0
  for index, star in ipairs(ThrowStarSession.ActiveStarSessions or DummyTable) do
    InAirNum = InAirNum + 1
    Log.Debug("Active star session with status ", star.SeqID, star.status)
    if nil == minSeqID or minSeqID > star.SeqID then
      minSeqID = star.SeqID
      minStar = star
    end
  end
  local MagicBaseConf = _G.DataConfigManager:GetMagicBaseConf(1)
  if InAirNum > MagicBaseConf.maxcount then
    minStar:Abandon()
  end
end

function ThrowStarSession:OnBeginThrowRsp(rsp)
  if rsp and rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\152\159\230\152\159\233\173\148\230\179\149\230\138\149\230\142\183\229\143\145\232\181\183\229\164\177\232\180\165\239\188\140\233\148\153\232\175\175\231\160\129\230\152\175", rsp.ret_info.ret_code)
  end
end

local StarChargeLevelEventMap = {
  [1] = Enum.DotsAIWorldEventType.DAWET_STAR_DROP,
  [2] = Enum.DotsAIWorldEventType.DAWET_STAR_DROP,
  [3] = Enum.DotsAIWorldEventType.DAWET_STAR_DROP,
  [4] = Enum.DotsAIWorldEventType.DAWET_STAR_DROP
}

local function StarMagicNpcFilter(npc)
  if npc.AIComponent then
    local DisabledStar = npc.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_MAGIC_STAR)
    if DisabledStar then
      return false
    end
  end
  if npc.InteractionComponent and 0 ~= npc.InteractionComponent.DisableFlag & 1 << NPCModuleEnum.NpcInteractDisableFlag.HIDDEN_COMP and npc:IsPet() and npc.config.genre ~= Enum.ClientNpcType.CNT_PETBOSS and npc.config.genre ~= Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
    return false
  end
  return true
end

function ThrowStarSession:OnEndThrow(hitActor, hitBone)
  if self.status ~= ThrowSessionStatusEnum.InAir then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MAGIC_OPTION, false, false)
  if Ban then
    Log.Debug("\228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170\233\173\148\230\179\149\228\186\164\228\186\146")
    return
  end
  local _NRCModuleManager = _G.NRCModuleManager
  local _NPCModuleCmd = _G.NPCModuleCmd
  local req = ProtoMessage:newZoneSceneEndThrowReq()
  req.throw_type = ProtoEnum.ThrowType.THROW_MAGIC
  local data = _NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100701)
  if data and data.gid then
    req.gid = data.gid
    req.item_conf_id = data.id or 0
  else
    Log.Error("\233\135\138\230\148\190\233\173\148\230\179\149\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129", table.tostring(data))
  end
  req.throw_id = self.SeqID
  if ThrowStarSession.ShowTrajectory then
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(UE4Helper.GetCurrentWorld(), self.StarNPC.viewObj:Abs_K2_GetActorLocation(), self.StarNPC.viewObj.BoomRange, 12, UE4.FLinearColor(0, 1, 0, 1), 15, 5)
  end
  local StarNpcView = self.StarNPC and self.StarNPC.viewObj
  local Range = StarNpcView and StarNpcView.BoomRange or 0
  local ChargeLevel = StarNpcView and StarNpcView.charge_level or 0
  local RelativeLocation = StarNpcView:K2_GetActorLocation()
  local TreePosArray = UE.TArray(UE.FVector)
  ThrowUtils.ShakeTrees(RelativeLocation, StarNpcView.BoomRange, TreePosArray)
  local Actions, TargetInfos, Players
  Actions, TargetInfos, Players = ThrowUtils.GatherMagicActions(self.StarNPC, RelativeLocation, 1, ChargeLevel, Range, StarMagicNpcFilter, hitActor, hitBone)
  if Actions and TargetInfos then
    req.throw_effect = ProtoEnum.ThrowEffect.TRIG_MAGIC_INTERACT
    req.throw_magic_info.strength_level = ChargeLevel
    self.actionToInteract = Actions
    req.throw_target_npc_infos = TargetInfos
    for _, Action in pairs(Actions) do
      if Action.CurrHorizontalAngle and type(Action.CurrHorizontalAngle) == "number" then
        req.params[1] = math.ceil(Action.CurrHorizontalAngle)
      end
      if Action.CurrVerticalAngle and "number" == type(Action.CurrVerticalAngle) then
        req.params[2] = math.ceil(Action.CurrVerticalAngle)
      end
    end
  elseif TreePosArray:Length() > 0 then
    req.throw_effect = ProtoEnum.ThrowEffect.TRIG_MAGIC_INTERACT_SCENE_OBJ
    req.throw_magic_info.strength_level = ChargeLevel
    self.actionToInteract = {}
    for Index, Pos in tpairs(TreePosArray) do
      local NPCInfo = ProtoMessage:newThrowTargetNpcInfo()
      NPCInfo.npc_pos.x = Pos.X
      NPCInfo.npc_pos.y = Pos.Y
      NPCInfo.npc_pos.z = Pos.Z
      table.insert(req.throw_target_npc_infos, NPCInfo)
      Log.Error("\230\137\147\229\136\176\230\160\145\228\186\134", Index, string.format("%d;%d;%d", Pos.X, Pos.Y, Pos.Z))
    end
  else
    req.throw_effect = ProtoEnum.ThrowEffect.TRIG_MAGIC_INTERACT
    self.actionToInteract = {}
    req.throw_target_npc_infos = {}
  end
  if StarNpcView then
    req.end_throw_pos = SceneUtils.ClientPos2ServerPos(StarNpcView:Abs_K2_GetActorLocation())
  end
  if StarNpcView and StarNpcView.charge_percent then
    req.throw_magic_info.charge_percentage = math.round(StarNpcView.charge_percent * 10000)
  else
    req.throw_magic_info.charge_percentage = 0
  end
  if Players then
    req.throw_magic_info.target_avatar_uins = Players
  end
  local Character = hitActor and hitActor.sceneCharacter
  if Character and hitActor:Cast(UE4.ARocoPlayerBase) then
    self.hitPlayerUin = Character.serverData.base.logic_id
  end
  local starSource = StarNpcView:Abs_K2_GetActorLocation()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.owner_id)
  if player and player.IsMagicReplayActor and player:IsMagicReplayActor() then
  else
    _NRCModuleManager:DoCmd(_NPCModuleCmd.SendSenseEvent, starSource, Enum.DotsAIWorldEventType.DAWET_STAR_DROP, nil, ChargeLevel)
  end
  local SpecificEvent = StarChargeLevelEventMap[ChargeLevel]
  if not SpecificEvent or player.IsMagicReplayActor and player:IsMagicReplayActor() then
  else
    _NRCModuleManager:DoCmd(_NPCModuleCmd.SendSenseEvent, starSource, SpecificEvent, 0, ChargeLevel)
  end
  _NRCModuleManager:DoCmd(_NPCModuleCmd.CacheLastThrowStarInfo, starSource, ChargeLevel, StarNpcView and StarNpcView.charge_percent or 0)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, self, self.OnEndThrowRsp, false, true)
  self:SetStatus(ThrowSessionStatusEnum.Interacting)
end

function ThrowStarSession:OnEndThrowRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("ThrowStarSession:OnEndThrowRsp", rsp.ret_info.ret_code)
  end
  for _, action in ipairs(self.actionToInteract or DummyTable) do
    action:OnSubmit(rsp)
  end
  table.clear(self.actionToInteract)
  if self.hitPlayerUin and rsp.throw_star_magic_result then
    for _, uin in ipairs(rsp.throw_star_magic_result.star_magic_fail_avatar_uins or DummyTable) do
      if uin == self.hitPlayerUin then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.abnormal_status_fobid_tips)
        break
      end
    end
    self.hitPlayerUin = nil
  end
end

function ThrowStarSession:SetStatus(Status)
  if nil == Status then
    return
  end
  if self.status == Status then
    return
  end
  if self.status == ThrowSessionStatusEnum.Destroyed then
    return
  end
  self.status = Status
  if self.status == ThrowSessionStatusEnum.Destroyed then
    self:OnSessionDestroyed()
  end
end

function ThrowStarSession:OnSessionDestroyed()
  local Found
  for Index, Session in pairs(ThrowStarSession.ActiveStarSessions) do
    if Session == self then
      Found = Index
    end
  end
  if Found then
    table.remove(ThrowStarSession.ActiveStarSessions, Found)
    Log.Debug("Remove star session from active session list, ", self.SeqID)
  end
end

function ThrowStarSession:Abandon()
  if self.status == ThrowSessionStatusEnum.InAir then
    self.status = ThrowSessionStatusEnum.Abandon
  elseif self.status == ThrowSessionStatusEnum.Destroyed then
    return
  else
    self.status = ThrowSessionStatusEnum.Abandon
    return
  end
  if self.StarNPC and UE4.UObject.IsValid(self.StarNPC.viewObj) then
    self.StarNPC.viewObj:StarBounceEnd()
    self.StarNPC.viewObj:BreakItself()
  end
end

return ThrowStarSession

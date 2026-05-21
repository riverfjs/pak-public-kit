local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local Base = NPCActionBase
local NPCActionSit = Base:Extend("NPCActionSit")

function NPCActionSit:Execute(PlayerID, NeedSendReq)
  if not self.Owner or not self.OwnerNpc then
    return
  end
  local Player = self:GetPlayer()
  if Player.statusComponent:HasAnyStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM, Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING) then
    self.Owner:SetNeedStatusNotify(false)
    local Msg = LuaText.relationtree_abnormal_status_tip
    if Msg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Msg)
    end
    return
  end
  if Player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND) then
    Player.InviteComponent:InteractCancel()
  end
  local bIsRiding = Player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL)
  if bIsRiding then
    Player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  end
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
  self.OwnerNpc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnDisConnect)
  Base.Execute(self, PlayerID, NeedSendReq)
end

function NPCActionSit:Submit()
  if self.SkipSubmit then
    return
  end
  if not self.Owner and not self.OwnerNpc then
    Log.Error("NPCActionSit:Submit\231\154\132\230\151\182\229\128\153Owner\230\136\150\232\128\133OwnerNpc\228\184\141\229\173\152\229\156\168\239\188\129")
  end
  local Player = self:GetPlayer()
  if Player then
    local req = ProtoMessage:newZoneSceneNpcNextActReq()
    req.option_id = self.Owner.config.id
    req.npc_id = self.OwnerNpc.serverData.base.actor_id
    req.first_act = true
    req.battle_radius = BattleConst.Define.BattleFieldRange
    req.sit_npc_seat_idx = tonumber(string.match(self.Config.action_param1, "Seat_(%d+)")) - 1
    self.before_sit_point = nil
    local playerTransform = Player:GetActorTransform()
    if playerTransform then
      req.before_sit_point = SceneUtils.ConvertTransformToPoint(playerTransform)
      self.before_sit_point = req.before_sit_point
    end
    self:FillRequest(req)
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, req, self, self.CheckOnSubmit, false, false)
  end
end

function NPCActionSit:UpdateInfo(Info, Reconnect, InteractingAvatarID)
  if Reconnect then
    return
  end
  if not InteractingAvatarID then
    return
  end
  if Info.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commited then
    local Player = self:GetPlayer()
    if Player then
      local SeatSlot = self.Config.action_param1 or "Seat_1"
      local SeatIdx = tonumber(string.match(SeatSlot, "Seat_(%d+)"))
      local Owner = self:GetOwnerNPC()
      if InteractingAvatarID ~= Player.serverData.base.actor_id then
        return
      end
      local Conf = _G.DataConfigManager:GetRoleplayPropConf(Owner.config.id)
      if not Conf then
        return
      end
      local OwnerView = self:GetOwnerNPCView()
      if OwnerView then
        local SitInfo = {}
        SitInfo.seat_idx = SeatIdx - 1
        SitInfo.sit_npc_id = Owner.serverData.base.actor_id
        local SeatArray = {}
        local SeatInfo = {}
        if Player and Player.serverData then
          SeatInfo.seat_idx = SeatIdx - 1
          SeatInfo.interact_avatar_id = Player.serverData.base.actor_id
        end
        table.insert(SeatArray, SeatInfo)
        Player.playerToyComponent:SaveSeatNPCServerData(Player, Owner, SitInfo, SeatArray)
        self.ImmediatelySit = Conf["special_start_" .. SeatIdx]
        self:StartSit(SeatSlot, Conf.scene_sit_blur_type)
        self.LastInputTime = _G.ZoneServer:GetServerTime()
        self.OwnerNpc.InteractionComponent:TryDisableInteraction()
        local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
        if PlayerModule then
          PlayerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnPlayerInputMove)
        end
        _G.NRCEventCenter:RegisterEvent("NPCActionSit", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnDisConnect)
      end
    end
  end
end

function NPCActionSit:StartSit(SeatSlot, FadeType)
  local Player = self:GetPlayer()
  if Player and Player.playerToyComponent then
    Player.playerToyComponent:PlayerSitToSceneSeat(self:GetOwnerNPC(), SeatSlot, self.ImmediatelySit, nil, FadeType)
  end
end

function NPCActionSit:OnPlayerInputMove(Dir, Axis)
  if Axis and 0 == Axis then
    return
  end
  if self.bSendLeaveReq then
    return
  end
  local CurrentTime = _G.ZoneServer:GetServerTime()
  local Interval = self.ImmediatelySit and 1000 or 1700
  if Interval > CurrentTime - (self.LastInputTime or 0) then
    return
  end
  self.LastInputTime = CurrentTime
  local Player = self:GetPlayer()
  if Player then
    local SeatNpcID = self.OwnerNpc.serverData.base.actor_id
    local SeatSlot = self.Config.action_param1 or "Seat_1"
    local SeatIdx = tonumber(string.match(SeatSlot, "Seat_(%d+)"))
    if SeatNpcID and SeatIdx then
      local Request = _G.ProtoMessage:newZoneSceneOpSeatReq()
      Request.op_type = ProtoEnum.OpSeatType.OST_LEAVE
      Request.npc_id = SeatNpcID
      Request.seat_idx = SeatIdx - 1
      Request.normal_leave_seat = true
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_OP_SEAT_REQ, Request, self, self.OnZoneSceneOpSeatRsp)
      self.bSendLeaveReq = true
    end
  end
end

function NPCActionSit:OnZoneSceneOpSeatRsp(Response)
  if 0 == Response.ret_info.ret_code then
    local Player = self:GetPlayer()
    if Player then
      local SitInfo = {}
      SitInfo.seat_idx = -1
      SitInfo.sit_npc_id = 0
      local SeatArray = {}
      local SeatInfo = {}
      if Player and Player.serverData and Player.serverData.avatar_interact then
        SeatInfo.seat_idx = Player.serverData.avatar_interact.sit_info.seat_idx
        SeatInfo.interact_avatar_id = 0
      end
      table.insert(SeatArray, SeatInfo)
      Player.playerToyComponent:SaveSeatNPCServerData(Player, self:GetOwnerNPC(), SitInfo, SeatArray)
      local Conf = _G.DataConfigManager:GetRoleplayPropConf(self.OwnerNpc.config.id)
      if not Conf then
        return
      end
      local SeatIdx = SeatInfo.seat_idx + 1
      local SpecialG6 = Conf["special_end_" .. SeatIdx]
      if SpecialG6 then
        Player.playerToyComponent:PlayerFlashSkillForSceneSeat(self:GetOwnerNPCView(), SpecialG6, function()
          Player.playerToyComponent:PlayerInterruptSceneSeat()
          Player.playerToyComponent:PlayerFlashToPoint(self.before_sit_point)
        end)
      else
        Player.playerToyComponent:PlayerLeaveSceneSeat()
      end
      local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
      if PlayerModule then
        PlayerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
      end
    end
  end
  self.bSendLeaveReq = false
  self:Finish(true)
end

function NPCActionSit:OnDisConnect()
  self.bSendLeaveReq = false
  local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
  if PlayerModule then
    PlayerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
  end
  local SitInfo = {}
  SitInfo.seat_idx = -1
  SitInfo.sit_npc_id = 0
  local SeatArray = {}
  local SeatInfo = {}
  local Player = self:GetPlayer()
  if Player and Player.serverData and Player.serverData.avatar_interact then
    SeatInfo.seat_idx = Player.serverData.avatar_interact.sit_info.seat_idx
    SeatInfo.interact_avatar_id = 0
  end
  table.insert(SeatArray, SeatInfo)
  Player.playerToyComponent:SaveSeatNPCServerData(Player, self:GetOwnerNPC(), SitInfo, SeatArray)
  Player.playerToyComponent:PlayerInterruptSceneSeat(self:GetOwnerNPCView())
  self:Finish(false)
end

function NPCActionSit:Finish(success, data, param)
  self.OwnerNpc.InteractionComponent:TryEnableInteraction()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnDisConnect)
  self.OwnerNpc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnDisConnect)
  Base.Finish(self, success, data, param)
end

return NPCActionSit

local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local HomeUtils = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCActionHomePlayerSitDown = Base:Extend("NPCActionHomePlayerSitDown")

function NPCActionHomePlayerSitDown:Execute(PlayerID, NeedSendReq)
  if not (self.Owner and self.OwnerNpc) or not self.OwnerNpc.FurnitureID then
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
  local SeatConf = _G.DataConfigManager:GetSeatConf(self.OwnerNpc.config.id)
  if SeatConf then
    self.bIsBed = SeatConf.is_home_lie
  end
  Base.Execute(self, PlayerID, NeedSendReq)
end

function NPCActionHomePlayerSitDown:Submit()
  local Owner = self.OwnerNpc
  local FurnitureID = Owner and Owner.FurnitureID
  if not FurnitureID then
    return
  end
  local FurnitureView = Owner.viewObj
  if not FurnitureView then
    return
  end
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local Player = self:GetPlayer()
  if Player then
    self.NearestSeatIdx = HomeUtils.FindNearestSeatIndex(Player:GetActorLocation(), self.OwnerNpc.viewObj, AvailableData)
    local req = ProtoMessage:newZoneSceneNpcNextActReq()
    req.option_id = self.Owner.config.id
    req.npc_id = self.OwnerNpc.serverData.base.actor_id
    req.first_act = true
    req.battle_radius = BattleConst.Define.BattleFieldRange
    req.sit_npc_seat_idx = self.NearestSeatIdx - 1
    self:FillRequest(req)
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NPC_NEXT_ACT_REQ, req, self, self.CheckOnSubmit, false, false)
  end
end

function NPCActionHomePlayerSitDown:OnSubmit(Rsp)
  Base.OnSubmit(self, Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local Player = self:GetPlayer()
    if Player then
      local SitInfo = {}
      SitInfo.seat_idx = self.NearestSeatIdx - 1
      SitInfo.sit_npc_id = self.OwnerNpc.serverData.base.actor_id
      local SeatInfo = {}
      local SeatOne = {}
      SeatOne.seat_idx = self.NearestSeatIdx - 1
      SeatOne.interact_avatar_id = Player.serverData.base.actor_id
      table.insert(SeatInfo, SeatOne)
      Player.playerToyComponent:SaveSeatNPCServerData(Player, self.OwnerNpc, SitInfo, SeatInfo)
      local OwnerView = self:GetOwnerNPCView()
      if OwnerView then
        HomeUtils.PlayerSitToHomeSeat(Player, OwnerView, self.NearestSeatIdx, self.bIsBed)
        self.LastInputTime = _G.ZoneServer:GetServerTime()
        self.OwnerNpc.InteractionComponent:TryDisableInteraction()
        local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
        if PlayerModule then
          PlayerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnPlayerInputMove)
        end
        if Player.IsMagicReplayActor and Player:IsMagicReplayActor() then
        else
          _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, OwnerView:Abs_K2_GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_HOME_PLAYER_SIT, nil, Player.isLocal and 1 or 2)
        end
        _G.NRCEventCenter:RegisterEvent("NPCActionSit", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnDisConnect)
      end
    end
  end
end

function NPCActionHomePlayerSitDown:OnPlayerInputMove(Dir, Axis)
  if Axis and 0 == Axis then
    return
  end
  if self.bSendLeaveReq then
    return
  end
  local CurrentTime = _G.ZoneServer:GetServerTime()
  if CurrentTime - (self.LastInputTime or 0) < 1700 then
    return
  end
  self.LastInputTime = CurrentTime
  self:TryExitSeat(Dir, Axis)
end

function NPCActionHomePlayerSitDown:OnZoneSceneOpSeatRsp(Response)
  if 0 == Response.ret_info.ret_code then
    if Response.op_type == ProtoEnum.OpSeatType.OST_CHANGE then
      local Player = self:GetPlayer()
      if Player then
        local SitInfo = {}
        SitInfo.seat_idx = Response.seat_idx
        SitInfo.sit_npc_id = self.OwnerNpc.serverData.base.actor_id
        local SeatInfo = {}
        local SeatOne = {}
        SeatOne.seat_idx = self.NearestSeatIdx - 1
        SeatOne.interact_avatar_id = 0
        local SeatTwo = {}
        SeatTwo.seat_idx = Response.seat_idx
        SeatTwo.interact_avatar_id = Player.serverData.base.actor_id
        table.insert(SeatInfo, SeatOne)
        table.insert(SeatInfo, SeatTwo)
        Player.playerToyComponent:SaveSeatNPCServerData(Player, self.OwnerNpc, SitInfo, SeatInfo)
        self.NearestSeatIdx = Response.seat_idx + 1
        local OwnerView = self:GetOwnerNPCView()
        if OwnerView then
          HomeUtils.PlayerChangeHomeSeat(Player, OwnerView, Response.seat_idx + 1)
        end
      end
    elseif Response.op_type == ProtoEnum.OpSeatType.OST_LEAVE then
      local Player = self:GetPlayer()
      if Player then
        local OwnerView = self:GetOwnerNPCView()
        if OwnerView and Response.leave_point_idx then
          HomeUtils.PlayerLeaveHomeSeat(Player, OwnerView, Response.leave_point_idx, self.bIsBed)
        end
        local SitInfo = {}
        SitInfo.seat_idx = -1
        SitInfo.sit_npc_id = 0
        local SeatInfo = {}
        local SeatOne = {}
        SeatOne.seat_idx = self.NearestSeatIdx - 1
        SeatOne.interact_avatar_id = 0
        table.insert(SeatInfo, SeatOne)
        Player.playerToyComponent:SaveSeatNPCServerData(Player, self.OwnerNpc, SitInfo, SeatInfo)
        local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
        if PlayerModule then
          PlayerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
        end
      end
      self:Finish(true)
    end
  end
  self.bSendLeaveReq = false
end

function NPCActionHomePlayerSitDown:TryExitSeat(Dir, Axis)
  local FurnitureView = self:GetOwnerNPCView()
  if not FurnitureView then
    return
  end
  local InteractData = FurnitureView.InteractData
  if not InteractData then
    return
  end
  local AvailableData = InteractData.AvailableData
  if not AvailableData then
    return
  end
  local Player = self:GetPlayer()
  if not (Player and Player.serverData and Player.serverData.avatar_interact) or not Player.serverData.avatar_interact.sit_info then
    return
  end
  if not self.NearestSeatIdx then
    return
  end
  local CurData = AvailableData:Get(self.NearestSeatIdx)
  if not CurData then
    return
  end
  local WorldTransform = FurnitureView:Abs_GetTransform()
  local Controller = Player:GetUEController()
  local CurSeatWorldPos = WorldTransform:TransformPositionNoScale(CurData.Location)
  local CurSeatScreenPos = Controller:Abs_ProjectWorldLocationToScreen(CurSeatWorldPos)
  local MoveDir = UE4.FVector(Dir.X * Axis, Dir.Y * Axis, 0)
  local MoveIndex
  if self.bIsBed then
    for i, Data in tpairs(AvailableData) do
      if i ~= self.NearestSeatIdx then
        local NextSeatWorldPos = WorldTransform:TransformPositionNoScale(Data.Location)
        local NextSeatScreenPos = Controller:Abs_ProjectWorldLocationToScreen(NextSeatWorldPos)
        local SeatDir = NextSeatScreenPos - CurSeatScreenPos
        SeatDir:Normalize()
        local Result = MoveDir:Dot(SeatDir)
        if Result > 0.7 then
          MoveIndex = i
          break
        end
      end
    end
  end
  if not MoveIndex then
    local ExitIndex
    local ExitData = InteractData.ExitData
    if not ExitData then
      return
    end
    if ExitData:Length() == AvailableData:Length() then
      ExitIndex = self.NearestSeatIdx
    else
      local MaxResult = -1
      for i, Data in tpairs(ExitData) do
        local ExitWorldPos = WorldTransform:TransformPositionNoScale(Data.Location)
        local ExitScreenPos = Controller:Abs_ProjectWorldLocationToScreen(ExitWorldPos)
        local ExitDir = ExitScreenPos - CurSeatScreenPos
        ExitDir:Normalize()
        local Result = MoveDir:Dot(ExitDir)
        if MaxResult < Result then
          ExitIndex = i
          MaxResult = Result
        end
      end
    end
    if ExitIndex then
      local Data = ExitData:Get(ExitIndex)
      if not Data then
        return
      end
      if self.bIsBed then
        local ExitWorldPos = WorldTransform:TransformPositionNoScale(Data.Location)
        local ExitDir = ExitWorldPos - CurSeatWorldPos
        ExitDir:Normalize()
        local SwitchIndex, MinSeatDistance
        for i, SeatData in tpairs(AvailableData) do
          if i ~= self.NearestSeatIdx then
            local TargetSeatWorldPos = WorldTransform:TransformPositionNoScale(SeatData.Location)
            local SeatDir = TargetSeatWorldPos - CurSeatWorldPos
            SeatDir:Normalize()
            local Result = SeatDir:Dot(ExitDir)
            local SeatDistance = TargetSeatWorldPos:Dist(CurSeatWorldPos)
            if Result > 0.7 and (not MinSeatDistance or MinSeatDistance > SeatDistance) then
              MinSeatDistance = SeatDistance
              SwitchIndex = i
            end
          end
        end
        if SwitchIndex then
          Log.Debug("NPCActionHomePlayerSitDown:TryExitSeat Exact SwitchSeat", ExitIndex, SwitchIndex, MinSeatDistance)
          self:SendSwitchSeatReq(SwitchIndex)
          return
        end
      end
      local Position = WorldTransform:TransformPositionNoScale(Data.Location)
      if not _G.HomeIndoorSandbox.World:TestPlayerLandPosIsValid(Position, FurnitureView) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.no_exit_bed)
        return
      end
      local SeatNpcID = self.OwnerNpc.serverData.base.actor_id
      if SeatNpcID and self.NearestSeatIdx then
        local Request = _G.ProtoMessage:newZoneSceneOpSeatReq()
        Request.op_type = ProtoEnum.OpSeatType.OST_LEAVE
        Request.npc_id = SeatNpcID
        Request.seat_idx = self.NearestSeatIdx - 1
        Request.leave_point_idx = ExitIndex
        Request.normal_leave_seat = true
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_OP_SEAT_REQ, Request, self, self.OnZoneSceneOpSeatRsp)
        self.bSendLeaveReq = true
      end
    end
  else
    if not (self.OwnerNpc and self.OwnerNpc.serverData and self.OwnerNpc.serverData.npc_interact) or not self.OwnerNpc.serverData.npc_interact.seat_info then
      return
    end
    local SeatInfo = self.OwnerNpc.serverData.npc_interact.seat_info.seat_info
    if SeatInfo then
      for i, Info in ipairs(SeatInfo) do
        if Info.seat_idx == MoveIndex - 1 and 0 == Info.interact_avatar_id then
          local SeatNPCID = self.OwnerNpc.serverData.base.actor_id
          if SeatNPCID then
            local Request = _G.ProtoMessage:newZoneSceneOpSeatReq()
            Request.op_type = ProtoEnum.OpSeatType.OST_CHANGE
            Request.npc_id = SeatNPCID
            Request.seat_idx = MoveIndex - 1
            _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_OP_SEAT_REQ, Request, self, self.OnZoneSceneOpSeatRsp)
            self.bSendLeaveReq = true
          end
        end
      end
    end
  end
end

function NPCActionHomePlayerSitDown:SendSwitchSeatReq(SeatIndex)
  if not (self.OwnerNpc and self.OwnerNpc.serverData and self.OwnerNpc.serverData.npc_interact) or not self.OwnerNpc.serverData.npc_interact.seat_info then
    return
  end
  local SeatInfo = self.OwnerNpc.serverData.npc_interact.seat_info.seat_info
  if SeatInfo then
    for i, Info in ipairs(SeatInfo) do
      if Info.seat_idx == SeatIndex - 1 and 0 == Info.interact_avatar_id then
        local SeatNPCID = self.OwnerNpc.serverData.base.actor_id
        if SeatNPCID then
          local Request = _G.ProtoMessage:newZoneSceneOpSeatReq()
          Request.op_type = ProtoEnum.OpSeatType.OST_CHANGE
          Request.npc_id = SeatNPCID
          Request.seat_idx = SeatIndex - 1
          _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_OP_SEAT_REQ, Request, self, self.OnZoneSceneOpSeatRsp)
          self.bSendLeaveReq = true
        end
      end
    end
  end
end

function NPCActionHomePlayerSitDown:OnDisConnect()
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
  HomeUtils.PlayerInterruptSceneSeat(Player, self.bIsBed)
  self:Finish(false)
end

function NPCActionHomePlayerSitDown:Finish(success, data, param)
  self.OwnerNpc.InteractionComponent:TryEnableInteraction()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnDisConnect)
  Base.Finish(self, success, data, param)
end

return NPCActionHomePlayerSitDown

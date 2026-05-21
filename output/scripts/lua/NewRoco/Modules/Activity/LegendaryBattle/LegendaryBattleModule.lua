local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local LegendaryBattleModuleEnum = require("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local TeamBattleModuleEnum = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local LegendaryBattleModule = NRCModuleBase:Extend("LegendaryBattleModule")

function LegendaryBattleModule:OnConstruct()
  _G.LegendaryBattleModuleCmd = reload("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleCmd")
  self.data = self:SetData("LegendaryBattleModuleData", "NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleData")
  self:RegPanel("LegendaryBattleMatchPanel", "UMG_LegendaryBattle_Match", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true)
  self:RegPanel("LegendaryStarSortTip", "UMG_LegendaryBattle_Sort", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LegendaryBattleCatchSucc", "UMG_LegendaryBattleCatchSucc", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, true)
  self:RegPanel("LegendaryBattleClosePanel", "UMG_LegendaryBattle_Close", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetCatchConfirmRsp, self.OnGetCatchConfirmRsp)
  self:RegisterCmd(LegendaryBattleModuleCmd.OpenLegendaryBattleClosePanel, self.OnOpenLegendaryBattleClosePanel)
  self:RegisterCmd(LegendaryBattleModuleCmd.OpenLegendaryBattleCatchSuccPanel, self.OnOpenLegendaryBattleCatchSuccPanel)
  self:RegisterCmd(LegendaryBattleModuleCmd.CloseLegendaryBattleCatchSuccPanel, self.OnCloseLegendaryBattleCatchSuccPanel)
  self:RegisterCmd(LegendaryBattleModuleCmd.OpenLegendaryBattleClosePanelByRsp, self.OnOpenLegendaryBattleClosePanelByRsp)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetBattleId, self.GetBattleId)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetBattlePetBaseId, self.GetBattlePetBaseId)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, self.GetLegendaryTicketIDAndNum)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetSeasonLegendaryID, self.GetSeasonLegendaryID)
  self:RegisterCmd(LegendaryBattleModuleCmd.SetTicketID, self.OnCmdSetTicketID)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetTicketName, self.OnCmdGetTicketName)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetLegendaryBattlePetBaseID, self.GetLegendaryBattlePetBaseID)
  self:RegisterCmd(LegendaryBattleModuleCmd.GetLegendaryBattleStar, self.GetLegendaryBattleStar)
  self.resonanceTotalTime = _G.DataConfigManager:GetLegendaryGlobalConfig("resonance_duration").num
  self.curMatchStage = LegendaryBattleModuleEnum.CurStage.Waiting
  self.curState = LegendaryBattleModuleEnum.CurState.None
  self.npcAction = nil
  self.npcTempAction = nil
  self:AddEventListener()
  self.curChooseStarNum = 0
  self.curShowStarNum = 0
  self.StarList = {}
  self.startStarNum = 0
  self.unLockLevel = 0
  self.RomanNumList = {}
  self:SetCurChooseStarNum(_G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel(), false)
  self.startResonanceTime = 0
  self.resonanceInfos = {}
  self.curTitle = nil
  self.matchStartTime = 0
  self.startMatchTime = 0
  self.matchTime = 0
  self.resonanceLeftTime = 0
  self.timeInterval = 1
  self.beastPos = UE4.FVector()
  self.battleId = 0
  self.curShowBattleId = 0
  self.CameraActor = nil
  self.CameraActorMesh = nil
  self.leftStarChallengeTimes = 0
  self.totalStarChallengeTimes = 0
  self.bReceiveBeastChallengeRsp = true
  self.ticketID = nil
end

function LegendaryBattleModule:OnActive()
end

function LegendaryBattleModule:OnRelogin()
end

function LegendaryBattleModule:OnDeactive()
end

function LegendaryBattleModule:OnDestruct()
  self.npcAction = nil
  self.StarList = {}
  self:RemoveEventListener()
end

function LegendaryBattleModule:AddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_CANCEL_MATCH_NOTIFY, self.OnZoneBeastCancelMatchNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_LEAVE_ONLINE_VISIT_NOTIFY, self.GetZoneLeaveOnlineVisitNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_CHECK_NOTIFY, self.OnZoneBeastCheckNotify)
  _G.NRCEventCenter:RegisterEvent("LegendaryBattleModule", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:RegisterEvent("LegendaryBattleModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("LegendaryBattleModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function LegendaryBattleModule:RemoveEventListener()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_CANCEL_MATCH_NOTIFY, self.OnZoneBeastCancelMatchNotify)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_LEAVE_ONLINE_VISIT_NOTIFY, self.GetZoneLeaveOnlineVisitNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_CHECK_NOTIFY, self.OnZoneBeastCheckNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function LegendaryBattleModule:OnReconnect()
  local bHasPanel = self:HasPanel("LegendaryBattleMatchPanel")
  if bHasPanel then
    local panel = self:GetPanel("LegendaryBattleMatchPanel")
    panel:DoClose()
  end
  local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
  if false == bVisit then
    self:CancelMatch()
  end
  if false == self.bReceiveBeastChallengeRsp then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    self.bReceiveBeastChallengeRsp = true
  end
end

function LegendaryBattleModule:OnTick(deltaTime)
  if 0 == self.matchStartTime and 0 == self.startResonanceTime then
    UpdateManager:UnRegister(self)
  end
  self.timeInterval = self.timeInterval + deltaTime
  if self.timeInterval > 1 then
    if 0 ~= self.matchStartTime then
      self.matchTime = _G.ZoneServer:GetServerTime() / 1000 - self.matchStartTime
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLegendaryMatchState, nil, self.curShowBattleId, self.curShowStarNum, self.matchTime)
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.SetLegendaryMatchTime, self.matchTime)
    end
    if self.startResonanceTime and 0 ~= self.startResonanceTime then
      self.resonanceLeftTime = self.resonanceTotalTime * 60 - (_G.ZoneServer:GetServerTime() / 1000 - self.startResonanceTime)
    end
    self.timeInterval = 0
  end
end

function LegendaryBattleModule:OnReceiveTeamBattleInviteNotify(notify)
  if notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or notify.challenge_type == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    self.battleId = 0
    self.curChooseStarNum = 0
    self:SetCurShowBattleId(0)
    self:SetCurShowStarNum(0)
  else
    self.battleId = notify.battle_cfg_id
    self.curChooseStarNum = notify.select_star or 0
    self:SetCurShowBattleId(notify.battle_cfg_id)
    self:SetCurShowStarNum(notify.select_star)
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLegendaryMatchState, nil, self.curShowBattleId, self.curShowStarNum, self.matchTime)
end

function LegendaryBattleModule:GetCurMatchInfo()
  local star = self.curShowStarNum
  local battle = self.curShowBattleId
  local logicId = 0
  local actorId = 0
  if self.npcAction then
    logicId = self.npcAction.OwnerNpc.serverData.base.logic_id
    actorId = self.npcAction.OwnerNpc.serverData.base.actor_id
  end
  return self.curMatchStage, {
    starNum = star,
    battleId = battle,
    LogicId = logicId,
    ActorId = actorId
  }
end

function LegendaryBattleModule:OnOpenMatchMainPanel(Event, Skill)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  self:InitStarList(self.npcAction.Config.action_param1)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
  self:OpenPanel("LegendaryBattleMatchPanel", self.npcAction)
  self.CameraActor = Skill.BlackBoard:GetValueAsObject("camActor_0001")
  self.CameraActorMesh = Skill.BlackBoard:GetValueAsObject("camActor_0001_SA")
end

function LegendaryBattleModule:OnOpenStarSortTip()
  self:OpenPanel("LegendaryStarSortTip")
end

function LegendaryBattleModule:GetCamera(Event, Skill)
  self.CameraActor = Skill.BlackBoard:GetValueAsObject("camActor_0001")
  self.CameraActorMesh = Skill.BlackBoard:GetValueAsObject("camActor_0001_SA")
  Skill.Blackboard:RemoveObjectValue("camActor_0001")
  Skill.Blackboard:RemoveObjectValue("camActor_0001_SA")
end

function LegendaryBattleModule:ClearCamera()
  if self.CameraActor then
    self.CameraActor:K2_DestroyActor()
    self.CameraActor = nil
  end
  if self.CameraActorMesh then
    self.CameraActorMesh:K2_DestroyActor()
    self.CameraActorMesh = nil
  end
end

function LegendaryBattleModule:OnSetupBlackboard(Name, Skill)
  local Blackboard = Skill.BlackBoard
  if Blackboard then
    local CameraCurTrans = self:GetCameraCurTrans()
    Blackboard:SetValueAsTransform("StartTransform", CameraCurTrans)
  end
end

function LegendaryBattleModule:GetCameraCurTrans()
  local CurTrans = UE4.FTransform()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:GetUEController() and player:GetUEController().PlayerCameraManager then
    local PlayerCameraLoc = player:GetUEController().PlayerCameraManager:GetCameraLocation()
    local PlayerCameraRot = player:GetUEController().PlayerCameraManager:GetCameraRotation()
    CurTrans.Translation = PlayerCameraLoc
    CurTrans.Rotation = PlayerCameraRot:ToQuat()
  end
  return CurTrans
end

function LegendaryBattleModule:GetCameraFinalTransform()
  local FinalTrans = UE4.FTransform()
  local npc = self.npcAction.OwnerNpc.viewObj
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if npc and player and player.viewObj and player:GetUEController() and player:GetUEController().PlayerCameraManager then
    local npcLoc = npc:Abs_K2_GetActorLocation()
    local PlayerCameraLoc = player:GetUEController().PlayerCameraManager:Abs_GetCameraLocation()
    local alpha = 90
    local beta = 15
    local length = 600
    local Z = 200
    local FinalLoc = self:GetCameraFinalLoc(PlayerCameraLoc, npcLoc, length, alpha, npcLoc.Z + Z)
    local FinalRot = self:GetCameraFinalRot(npcLoc.X, npcLoc.Y, FinalLoc.X, FinalLoc.Y, beta)
    FinalTrans.Translation = FinalLoc
    FinalTrans.Rotation = FinalRot
  end
  return FinalTrans
end

function LegendaryBattleModule:GetCameraFinalLoc(PointA, PointB, length, alpha, Z)
  local VectorAB = UE4.FVector2D(PointB.X - PointA.X, PointB.Y - PointA.Y)
  local LengthAB = math.sqrt(VectorAB.X ^ 2 + VectorAB.Y ^ 2)
  local AB_normalized = UE4.FVector2D(VectorAB.X / LengthAB, VectorAB.Y / LengthAB)
  local AC_normalized = UE4.UKismetMathLibrary.GetRotated2D(AB_normalized, alpha)
  local VectorAC = UE4.FVector2D(AC_normalized.X * length, AC_normalized.Y * length)
  local FinalLoc = UE4.FVector(PointA.X + VectorAC.X, PointA.Y + VectorAC.Y, Z)
  return FinalLoc
end

function LegendaryBattleModule:GetCameraFinalRot(x1, y1, x2, y2, beta)
  local direction_x = x1 - x2
  local direction_y = y1 - y2
  local magnitude = math.sqrt(direction_x ^ 2 + direction_y ^ 2)
  local dir_x = direction_x / magnitude
  local dir_y = direction_y / magnitude
  local Dir2D = UE4.FVector2D(dir_x, dir_y)
  local FinalDir2D = UE4.UKismetMathLibrary.GetRotated2D(Dir2D, beta)
  local FinalDir = UE4.FVector(FinalDir2D.X, FinalDir2D.Y, 0)
  local Rotator = FinalDir:ToRotator()
  local Quat = Rotator:ToQuat()
  return Quat
end

function LegendaryBattleModule:SetCurShowStarNum(num)
  self.curShowStarNum = num
end

function LegendaryBattleModule:SetCurShowBattleId(battleId)
  self.curShowBattleId = battleId
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLegendaryMatchState, self.curMatchStage, battleId, self.curShowStarNum, self.matchTime)
end

function LegendaryBattleModule:SetCurChooseStarNum(num, bStarNum)
  if 0 == #self.StarList then
    if self.npcAction and self.npcAction.Config.action_param1 then
      self:InitStarList(self.npcAction.Config.action_param1)
    else
      self:InitStarList("fanying_battle")
    end
  end
  local finalStarNum = num
  if bStarNum then
    finalStarNum = num
  else
    finalStarNum = self:GetMaxStarNum()
  end
  self.curChooseStarNum = finalStarNum or 0
end

function LegendaryBattleModule:GetMaxStarNum(playerLv)
  local maxStarNum = 0
  local playerWorldLv = 0
  if playerLv then
    playerWorldLv = playerLv
  else
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    playerWorldLv = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    if visitorList and #visitorList > 0 then
      playerWorldLv = visitorList[1].world_lv
    end
  end
  local maxLevel = self.unLockLevel + #self.StarList
  if playerWorldLv >= maxLevel then
    maxStarNum = self.startStarNum + #self.StarList - 1
  else
    maxStarNum = self.startStarNum + (playerWorldLv - self.unLockLevel)
  end
  return maxStarNum
end

function LegendaryBattleModule:GetCurChooseStarNum()
  return self.curChooseStarNum
end

function LegendaryBattleModule:GetUnLockLevelByBattleKey(battleKey, seasonLegendaryID)
  local isFind = false
  local LegendaryBattleEventCfg
  if seasonLegendaryID then
    LegendaryBattleEventCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT):GetAllDatas()
  else
    LegendaryBattleEventCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT):GetAllDatas()
  end
  for k, v in pairs(LegendaryBattleEventCfg or {}) do
    if v.battle_key == battleKey then
      local ActivityConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ACTIVITY_CONF):GetAllDatas()
      for _, value in pairs(ActivityConf) do
        if value.base_id and #value.base_id > 0 and value.base_id[1] == k then
          self.unLockLevel = value.world_level_required or 0
        end
      end
      self.unLockLevel = v.world_level or 0
      isFind = true
    end
  end
  if not isFind then
    self.unLockLevel = 0
  end
end

function LegendaryBattleModule:GetBattleIdByStarNum(starNum)
  local index = starNum - self.startStarNum + 1
  local battleId = 0
  if index > 0 and index <= #self.StarList then
    battleId = self.StarList[index]
    return battleId
  end
  return nil
end

function LegendaryBattleModule:SetCurMatchStage(stage)
  self.curMatchStage = stage
end

function LegendaryBattleModule:GetCurMatchStage()
  return self.curMatchStage
end

function LegendaryBattleModule:UpdateCurMatchStage(stage)
  if stage == LegendaryBattleModuleEnum.CurStage.Full then
    _G.NRCAudioManager:PlaySound2DAuto(1220002091, "LegendaryBattleModule:UpdateCurMatchStage")
  end
  self:SetCurMatchStage(stage)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.MatchStateChanged, stage)
  local isOpening, _ = self:HasPanel("LegendaryBattleMatchPanel")
  if isOpening then
    local panel = self:GetPanel("LegendaryBattleMatchPanel")
    if panel then
      panel:UpdateMatchStage(stage)
    end
  end
  local starNum = self.curShowStarNum
  local battleId = self.curShowBattleId
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLegendaryMatchState, stage, battleId, starNum, self.matchTime)
end

function LegendaryBattleModule:InitStarList(battleKey)
  self.StarList = {}
  local seasonLegendaryID = self:GetSeasonLegendaryID()
  local LegendaryBattleEventConf
  if seasonLegendaryID then
    LegendaryBattleEventConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT):GetAllDatas()
  else
    LegendaryBattleEventConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT):GetAllDatas()
  end
  for k, v in pairs(LegendaryBattleEventConf or {}) do
    if v.battle_key == battleKey then
      self.StarList = v.battle_id
      self.startStarNum = v.start_difficulty
      self.curTitle = v.title
    end
  end
  local LegendaryGlobalCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_GLOBAL_CONFIG):GetAllDatas()
  for k, v in pairs(LegendaryGlobalCfg) do
    local level_num = string.split(v.key, "_")
    if 2 == #level_num and "level" == level_num[1] then
      table.insert(self.RomanNumList, {
        num = tonumber(level_num[2]),
        romanNum = v.str
      })
    end
  end
  self:GetUnLockLevelByBattleKey(battleKey, seasonLegendaryID)
end

function LegendaryBattleModule:GetLegendaryPetNameFromBattleKey(battleKey)
  local battleId = 0
  local seasonLegendaryID = self:GetSeasonLegendaryID()
  local LegendaryGlobalCfg
  if seasonLegendaryID then
    LegendaryGlobalCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT):GetAllDatas()
  else
    LegendaryGlobalCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT):GetAllDatas()
  end
  for k, v in pairs(LegendaryGlobalCfg or {}) do
    if v.battle_key == battleKey then
      battleId = v.battle_id[1]
      break
    end
  end
  return self:GetLegendaryPetName(battleId)
end

function LegendaryBattleModule:OnCmdGetLegendaryBattleAwards(starNum, petBaseId)
  return self.data:GetLegendaryBattleAwards(starNum, petBaseId)
end

function LegendaryBattleModule:GetLegendaryBattlePetBaseID(content_cfg_id)
  return self.data:GetLegendaryBattlePetBaseID(content_cfg_id)
end

function LegendaryBattleModule:GetLegendaryBattleStar(content_cfg_id)
  return self.data:GetLegendaryBattleStar(content_cfg_id)
end

function LegendaryBattleModule:OnVisitorChanged(notify)
  Log.Dump(notify, 4, "LegendaryBattleModule:OnVisitorChanged")
  local visitorList = notify.visitors
  self.visitorList = visitorList
  if visitorList and #visitorList > 0 then
    if 4 == #visitorList then
      self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Full)
    else
      local owner = visitorList[1]
      if owner.beast_start_match_time and 0 ~= owner.beast_start_match_time then
        self.matchStartTime = owner.beast_start_match_time
        UpdateManager:Register(self)
        self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Matching)
      end
    end
    if notify.beast_star > 0 then
      self:SetCurChooseStarNum(notify.beast_star, true)
      self:SetCurShowStarNum(notify.beast_star)
    else
      local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      if playerUin ~= visitorList[1].uin then
        self:SetCurChooseStarNum(visitorList[1].world_lv, false)
      end
    end
    local starNum = self.curChooseStarNum
    local battleId = self:GetBattleIdByStarNum(starNum) or notify.battle_cfg_id
    self:OnSetStarNum(starNum)
    if notify.battle_cfg_id and notify.battle_cfg_id > 0 and visitorList[1].beast_start_match_time > 0 then
      battleId = notify.battle_cfg_id
      self.battleId = battleId
      self:SetCurShowBattleId(battleId)
    else
      battleId = 0
      self.battleId = 0
    end
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLegendaryMatchState, self.curMatchStage, self.curShowBattleId, self.curShowStarNum, self.matchTime)
  end
  self:UpdateCurMatchStage(self.curMatchStage)
  if self:HasPanel("LegendaryBattleMatchPanel") then
    local panel = self:GetPanel("LegendaryBattleMatchPanel")
    if panel then
      panel:UpdatePlayerList(notify.visitors)
    end
  end
end

function LegendaryBattleModule:OnEnterVisit()
  Log.Error("LegendaryBattleModule:OnEnterVisit")
  if self.curMatchStage ~= LegendaryBattleModuleEnum.CurStage.Matching or self.npcAction then
  end
end

function LegendaryBattleModule:OnSendZoneBeastStartMatchReq(battleCfgId, starNum)
  local req = _G.ProtoMessage:newZoneSceneBeastStartMatchReq()
  req.battle_cfg_id = battleCfgId
  req.beast_logic_id = self.npcAction.OwnerNpc.serverData.base.logic_id
  req.beast_obj_id = self.npcAction.OwnerNpc.serverData.base.actor_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_START_MATCH_REQ, req, self, self.OnZoneBeastStartMatchRsp, true)
end

function LegendaryBattleModule:OnZoneBeastStartMatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.beastPos = rsp.beast_pos
    self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Matching)
    self.matchStartTime = rsp.start_match_time
    UpdateManager:Register(self)
    self:UpdateCurMatchStage(self.curMatchStage)
    if 1 == rsp.result then
    elseif 2 == rsp.result then
      local title = LuaText.teambattlemodule_6
      local leftText = LuaText.teambattlemodule_7
      local rightText = LuaText.teambattlemodule_8
      local timeCountDown = _G.DataConfigManager:GetLegendaryGlobalConfig("confirm_duration").num
      local Context = DialogContext()
      Context:SetTitle(title):SetContent(_G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_6").msg):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnSendZoneBeastJoinVisitReq):SetCloseOnCancel(true):SetButtonText(rightText, leftText):SetCountdown(DialogContext.Mode.CANCEL, timeCountDown)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function LegendaryBattleModule:OnSendZoneBeastJoinVisitReq(bAgree)
  local req = _G.ProtoMessage:newZoneSceneBeastJoinVisitReq()
  req.agree = bAgree
  if bAgree then
    local Pos = _G.ProtoMessage:newPosition()
    local checkPos = UE4.FVector(self.beastPos.x, self.beastPos.y, self.beastPos.z)
    local VisitorPos = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.FindVisitorPos, checkPos, nil, nil, nil, self.npcAction.OwnerNpc) or self.beastPos
    Pos.x = math.round(VisitorPos.X or VisitorPos.x)
    Pos.y = math.round(VisitorPos.Y or VisitorPos.y)
    Pos.z = math.round(VisitorPos.Z or VisitorPos.z)
    req.pos = Pos
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_JOIN_VISIT_REQ, req, self, self.OnZoneBeastJoinVisitRsp, true)
end

function LegendaryBattleModule:OnZoneBeastJoinVisitRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:UpdateCurMatchStage(self.curMatchStage)
  else
    self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
    self:UpdateCurMatchStage(self.curMatchStage)
  end
end

function LegendaryBattleModule:OnZoneBeastCancelMatchReq()
  local req = _G.ProtoMessage:newZoneSceneBeastCancelMatchReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_BEAST_CANCEL_MATCH_REQ, req, self, self.OnZoneBeastCancelMatchRsp)
end

function LegendaryBattleModule:OnZoneBeastCancelMatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:CancelMatch()
  end
end

function LegendaryBattleModule:CancelMatch()
  self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
  self.matchStartTime = 0
  self:UpdateCurMatchStage(self.curMatchStage)
end

function LegendaryBattleModule:OnZoneBeastCheckNotify(notify)
  if _G.BattleManager.isInBattle == false and notify.check_result.start_resonance_time and notify.check_result.start_resonance_time > 0 then
    local tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_8").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  end
end

function LegendaryBattleModule:OnZoneBeastCancelMatchNotify(notify)
  Log.Error("LegendaryBattleModule:OnZoneBeastCancelMatchNotify")
end

function LegendaryBattleModule:OnCancelMatchNotify(notify)
  Log.Error("\229\156\186\230\153\175\233\128\154\231\159\165\229\143\150\230\182\136\229\140\185\233\133\141\239\188\129", notify.start_or_cancel)
  local visitors = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if notify.start_or_cancel == false then
    self.matchTime = 0
    self.matchStartTime = 0
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.SetLegendaryMatchTime, 0)
    if visitors and #visitors > 0 then
      for k, v in ipairs(visitors) do
        if v.uin == notify.caster_uin then
          local tips = string.format(_G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_17").msg, v.name)
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
        end
      end
    end
    if self.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching then
      self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
    end
  else
    self.matchStartTime = notify.cast_time
    UpdateManager:Register(self)
    Log.Debug("\229\140\185\233\133\141\230\151\182\233\151\180\230\136\179", notify.cast_time, _G.ZoneServer:GetServerTime() / 1000)
    self.matchTime = 0
    self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Matching)
    self:OnSetStarNum(notify.select_hard)
    self.battleId = notify.battle_cfg_id
    self:SetCurShowStarNum(notify.select_hard)
    self:SetCurShowBattleId(notify.battle_cfg_id)
  end
  self:UpdateCurMatchStage(self.curMatchStage)
end

function LegendaryBattleModule:OnChangeCurMatchState(stage)
  self:SetCurMatchStage(stage)
  self:UpdateCurMatchStage(self.curMatchStage)
end

function LegendaryBattleModule:OnCmdChallengeCheck(npcAction)
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local owner
  if self.visitorList then
    owner = self.visitorList[1]
  end
  local lastBattleId = self.data:GetActionParamByBattleId(self.battleId)
  if (self.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching or self.curMatchStage == LegendaryBattleModuleEnum.CurStage.Full) and npcAction.Config.action_param1 ~= lastBattleId and not string.IsNilOrEmpty(lastBattleId) then
    if owner and owner.uin and uin ~= owner.uin then
      self.npcAction = npcAction
      self:OnZoneQueryBeastChallengeReq()
    else
      local title = "\230\143\144\231\164\186"
      local des = string.format("\230\140\145\230\136\152%s\229\176\134\228\184\173\230\150\173\229\189\147\229\137\141\229\140\185\233\133\141\232\191\155\231\168\139\239\188\140\230\152\175\229\144\166\231\161\174\232\174\164", self:GetLegendaryPetNameFromBattleKey(npcAction.Config.action_param1) or "")
      local leftText = LuaText.teambattlemodule_7
      local rightText = LuaText.teambattlemodule_8
      local Context = DialogContext()
      Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.CheckConfirm):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
      self.npcTempAction = npcAction
    end
  else
    self.npcAction = npcAction
    self:OnZoneQueryBeastChallengeReq()
  end
end

function LegendaryBattleModule:CheckConfirm(bOK)
  if bOK then
    self.npcAction = self.npcTempAction
    self.npcTempAction = nil
    self:OnZoneBeastCancelMatchReq()
    self:OnZoneQueryBeastChallengeReq()
  else
    self.npcTempAction:EndAction()
  end
end

function LegendaryBattleModule:OnCmdCheckLegendaryBattleMatchState(caller, callbackFun)
  if self.curMatchStage == LegendaryBattleModuleEnum.CurStage.Matching then
    local title = LuaText.umg_plane_teamitem_1
    local des = string.format(_G.DataConfigManager:GetLocalizationConf("Error_Code_50223").msg)
    local leftText = LuaText.teambattlemodule_7
    local rightText = LuaText.teambattlemodule_8
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
      if result then
        self:OnZoneBeastCancelMatchReq()
      end
      callbackFun(caller, result)
    end):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    callbackFun(caller, true)
  end
end

function LegendaryBattleModule:OnZoneQueryBeastChallengeReq(actorId, logicId)
  NRCProfilerLog:NRCClickBtn(true, "LegendaryBattleMatchPanel")
  self.bReceiveBeastChallengeRsp = false
  _G.NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  self.ticketID = nil
  local req = _G.ProtoMessage:newZoneSceneQueryBeastChallengeReq()
  if self.npcAction then
    logicId = logicId or self.npcAction.OwnerNpc.serverData.base.logic_id
    actorId = actorId or self.npcAction.OwnerNpc.serverData.base.actor_id
  end
  req.npc_obj_id = actorId
  req.npc_logic_id = logicId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BEAST_CHALLENGE_REQ, req, self, self.OnZoneQueryBeastChallengeRsp)
end

function LegendaryBattleModule:OnZoneQueryBeastChallengeRsp(rsp)
  self.bReceiveBeastChallengeRsp = true
  if 0 == rsp.ret_info.ret_code then
    local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if rsp.resonance_infos then
      for _, v in pairs(rsp.resonance_infos) do
        if v.uin == myUin then
          self.startResonanceTime = v.start_resonance_time or 0
          self.ticketID = v.ticket_id or 0
          break
        end
      end
    end
    self.resonanceInfos = rsp.resonance_infos
    UpdateManager:Register(self)
    self.leftStarChallengeTimes = rsp.available_challenge_num_via_star
    self.totalStarChallengeTimes = rsp.available_challenge_num_via_star_max
    if self.startResonanceTime > 0 then
      self:UpdateCurMatchStage(self.curMatchStage)
      self:SetCurChooseStarNum(rsp.select_star or 0, true)
    end
    self:PlayOpenMatchPanelSkill()
  end
end

function LegendaryBattleModule:OnOnlyZoneQueryBeastChallengeReq(actorId, logicId)
  local req = _G.ProtoMessage:newZoneSceneQueryBeastChallengeReq()
  if self.npcAction then
    logicId = logicId or self.npcAction.OwnerNpc.serverData.base.logic_id
    actorId = actorId or self.npcAction.OwnerNpc.serverData.base.actor_id
  end
  req.npc_obj_id = actorId
  req.npc_logic_id = logicId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BEAST_CHALLENGE_REQ, req, self, self.OnOnlyZoneQueryBeastChallengeRsp)
end

function LegendaryBattleModule:OnUpdatePetCollectTagRsp(partner_mark)
  if self:HasPanel("LegendaryBattleCatchSucc") then
    local panel = self:GetPanel("LegendaryBattleCatchSucc")
    if panel then
      panel:UpdateCollect(partner_mark)
    end
  end
end

function LegendaryBattleModule:OnOnlyZoneQueryBeastChallengeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.leftStarChallengeTimes = rsp.available_challenge_num_via_star
    self.totalStarChallengeTimes = rsp.available_challenge_num_via_star_max
  end
end

function LegendaryBattleModule:OnZoneQuitBeastCatchReq(npcObjId, npcLogicId)
  local req = _G.ProtoMessage:newZoneSceneQuitBeastCatchReq()
  req.npc_obj_id = npcObjId
  req.npc_logic_id = npcLogicId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUIT_BEAST_CATCH_REQ, req, self, self.OnZoneQuitBeastCatchRsp)
end

function LegendaryBattleModule:OnZoneQuitBeastCatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
    self.startResonanceTime = 0
    self.resonanceInfos = {}
    self:UpdateCurMatchStage(self.curMatchStage)
  end
end

function LegendaryBattleModule:OnZoneReentrantBeastCatchReq(actorId, logicId)
  local req = _G.ProtoMessage:newZoneSceneReentrantBeastCatchReq()
  req.npc_logic_id = logicId
  req.npc_obj_id = actorId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_REENTRANT_BEAST_CATCH_REQ, req, self, self.OnZoneReentrantBeastCatchRsp)
end

function LegendaryBattleModule:OnZoneReentrantBeastCatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:SetCurMatchStage(LegendaryBattleModuleEnum.CurStage.Waiting)
    self:UpdateCurMatchStage(self.curMatchStage)
  end
end

function LegendaryBattleModule:OnOpenLegendaryBattleClosePanel(arg)
  self:OpenPanel("LegendaryBattleClosePanel", arg)
end

function LegendaryBattleModule:OnOpenLegendaryBattleCatchSuccPanel(arg, PetLevel)
  self:OpenPanel("LegendaryBattleCatchSucc", arg, PetLevel)
end

function LegendaryBattleModule:OnCloseLegendaryBattleCatchSuccPanel()
  self:ClosePanel("LegendaryBattleCatchSucc")
end

function LegendaryBattleModule:OnSetStarNum(num)
  self:SetCurChooseStarNum(num, true)
  local bHasPanel = self:HasPanel("LegendaryBattleMatchPanel")
  if bHasPanel then
    local panel = self:GetPanel("LegendaryBattleMatchPanel")
    panel:SetStarNum(self.curChooseStarNum)
  end
end

function LegendaryBattleModule:PlayOpenMatchPanelSkill()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj then
    local caster = player.viewObj
    local skillComponent = caster.RocoSkill
    if skillComponent then
      local skillProxy
      if BigMapUtils.IsBigWorldMap(SceneUtils.GetSceneResId()) then
        skillProxy = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_Transmit_Start.G6_ShenShou_Transmit_Start", skillComponent)
      else
        skillProxy = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/ShenShou/G6_ShenShou_Transmit_Start_ShiNei.G6_ShenShou_Transmit_Start_ShiNei", skillComponent)
      end
      if skillProxy then
        local targets = {}
        table.insert(targets, self.npcAction.OwnerNpc.viewObj)
        skillProxy:SetCaster(caster)
        skillProxy:SetTargets(targets)
        skillProxy:SetPassive(true)
        skillProxy:RegisterEventCallback("PreStart", self, self.OnSetupBlackboard)
        skillProxy:RegisterEventCallback("OpenMatchPanel", self, self.OnOpenMatchMainPanel)
        skillProxy:RegisterEventCallback("End", self, self.GetCamera)
        skillProxy:PlaySkill()
      end
    end
  end
end

function LegendaryBattleModule:OnEnterBattleLoading()
  local bHasPanel = self:HasPanel("LegendaryBattleMatchPanel")
  if bHasPanel then
    local panel = self:GetPanel("LegendaryBattleMatchPanel")
    panel:DoClose()
  end
end

function LegendaryBattleModule:RegPanel(name, path, layer, OpenAnimName, CloseAnimName, customDisableRendering)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/Activity/LegendaryBattle/Res/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = OpenAnimName
  registerData.closeAnimName = CloseAnimName
  registerData.customDisableRendering = customDisableRendering or false
  self:RegisterPanel(registerData)
end

function LegendaryBattleModule:OnOpenLegendaryBattleClosePanelByRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetCatchSuccReward(rsp)
    self:OpenPanel("LegendaryBattleClosePanel")
  end
end

function LegendaryBattleModule:OnGetCatchConfirmRsp()
  if self.data then
    return self.data:GetCatchSuccReward()
  end
end

function LegendaryBattleModule:OnBattleEnd()
end

function LegendaryBattleModule:OnCmdGetActivityTimeByContentId(npcContentId)
  local seasonLegendaryID = self:GetSeasonLegendaryID()
  local LegendaryBattleActivityTable
  if seasonLegendaryID then
    LegendaryBattleActivityTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT)
    if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
      return ""
    end
  else
    LegendaryBattleActivityTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT)
  end
  local TeamBattleAwardDatas = LegendaryBattleActivityTable:GetAllDatas()
  for k, v in pairs(TeamBattleAwardDatas or {}) do
    if tonumber(v.refresh_content_id_2) == tonumber(npcContentId) or tonumber(v.pet_base_id) == tonumber(npcContentId) then
      if v.start_time and v.duration then
        local endTimeStamp = self:GetLegendaryBattleEndTimeStamp(v.start_time, v.duration)
        local leftTimeStamp = endTimeStamp - ActivityUtils.GetSvrTimestamp()
        local text = self:GetTimeStr(leftTimeStamp)
        return text
      else
        return ""
      end
    end
  end
  return ""
end

function LegendaryBattleModule:GetTimeStr(seconds)
  if seconds > 0 then
    local day = seconds // 86400
    local hour = (seconds - 86400 * day) // 3600
    local minute = (seconds - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      return string.format(LuaText.activity_RTS1, day, hour)
    elseif hour > 0 or minute > 0 then
      return string.format(LuaText.activity_RTS2, hour, minute)
    else
      return LuaText.activity_RTS3
    end
  else
    return _G.LuaText.activity_expired_show_tip
  end
end

function LegendaryBattleModule:GetLegendaryBattleEndTimeStamp(startTime, duration)
  if not startTime or not duration then
    return 0
  end
  local startStamp = ActivityUtils.ToTimestamp(startTime)
  if not startStamp then
    return 0
  end
  local param = string.Split(duration, " ")
  if not param or #param < 2 then
    return 0
  end
  local param1 = string.Split(param[2], ":")
  if not param1 or #param1 < 3 then
    return 0
  end
  local days = tonumber(param[1]) or 0
  local hours = tonumber(param1[1]) or 0
  local minutes = tonumber(param1[2]) or 0
  local seconds = tonumber(param1[3]) or 0
  local durationSec = days * 24 * 60 * 60 + hours * 60 * 60 + minutes * 60 + seconds
  local endStamp = startStamp + durationSec
  return endStamp
end

function LegendaryBattleModule:GetZoneLeaveOnlineVisitNotify(notify)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ClearTipsList)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
end

function LegendaryBattleModule:GetLegendaryPetName(battleId)
  if battleId and battleId > 0 then
    local battleConf = _G.DataConfigManager:GetBattleConf(battleId)
    if battleConf then
      local npcBattleList = battleConf.npc_battle_list
      if npcBattleList and #npcBattleList > 0 then
        local pos1_1st = npcBattleList[1].pos1_1st
        if pos1_1st and #pos1_1st > 0 then
          local monsterConfId = pos1_1st[1]
          local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
          return petBaseConf.name
        end
      end
    end
  end
end

function LegendaryBattleModule:GetBattlePetBaseId()
  local battleId = self:GetBattleIdByStarNum(self.curChooseStarNum)
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    battleId = self.battleId
  end
  local BattleConf = _G.DataConfigManager:GetBattleConf(battleId)
  local monsterConfId = BattleConf and BattleConf.npc_battle_list[1].pos1_1st[1]
  local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
  local BaseId = monsterConf and monsterConf.base_id
  return BaseId
end

function LegendaryBattleModule:GetBattleId()
  return self.battleId
end

function LegendaryBattleModule:OnCmdGetChallengeTimes()
  return self.leftStarChallengeTimes, self.totalStarChallengeTimes
end

function LegendaryBattleModule:CheckCanStartLegendaryBattle(conditionEnum)
  local tips = ""
  local costItemId, _ = self:GetLegendaryTicketIDAndNum()
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId)
  local name = ""
  if bagItemConf then
    name = bagItemConf.name
  end
  if self.leftStarChallengeTimes > 0 then
    if conditionEnum == TeamBattleModuleEnum.EnterConditionState.BothOK or conditionEnum == TeamBattleModuleEnum.EnterConditionState.OnlyStarChainOK then
      return true, tips
    elseif conditionEnum == TeamBattleModuleEnum.EnterConditionState.OnlyBallOK then
      tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_12").msg
      local finalTips = string.format(tips, name)
      return false, finalTips
    else
      tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_13").msg
      local finalTips = string.format(tips, name)
      return false, finalTips
    end
  elseif conditionEnum == TeamBattleModuleEnum.EnterConditionState.BothOK or conditionEnum == TeamBattleModuleEnum.EnterConditionState.OnlyBallOK then
    tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_11").msg
    local finalTips = string.format(tips, name)
    return false, finalTips
  else
    tips = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_5").msg
    local finalTips = string.format(tips, name)
    return false, finalTips
  end
  return false
end

function LegendaryBattleModule:OnEnterBattle()
  self.data:Reset()
  self.npcAction = nil
end

function LegendaryBattleModule:GetSeasonLegendaryID(npc_content_cfg_id)
  if not npc_content_cfg_id and self.npcAction and self.npcAction.OwnerNpc and self.npcAction.OwnerNpc.serverData and self.npcAction.OwnerNpc.serverData.npc_base then
    npc_content_cfg_id = self.npcAction.OwnerNpc.serverData.npc_base.npc_content_cfg_id
  end
  if npc_content_cfg_id then
    local SeasonLegendaryBattleEventCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_LEGENDARY_BATTLE_EVENT):GetAllDatas()
    for _, v in pairs(SeasonLegendaryBattleEventCfg or {}) do
      if v.refresh_content_id_1 == npc_content_cfg_id or v.refresh_content_id_2 == npc_content_cfg_id or v.refresh_content_id_3 == npc_content_cfg_id then
        return v.id
      end
    end
  else
    return BattleUtils.GetSeasonLegendaryID()
  end
  return nil
end

function LegendaryBattleModule:TryGetLegendaryBattleEventID(npc_content_cfg_id)
  if not npc_content_cfg_id and self.npcAction and self.npcAction.OwnerNpc and self.npcAction.OwnerNpc.serverData and self.npcAction.OwnerNpc.serverData.npc_base then
    npc_content_cfg_id = self.npcAction.OwnerNpc.serverData.npc_base.npc_content_cfg_id
  end
  if npc_content_cfg_id then
    local legendaryBattleEventCfg = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT):GetAllDatas()
    for _, v in pairs(legendaryBattleEventCfg or {}) do
      if v.refresh_content_id_2 == npc_content_cfg_id then
        return v.id
      end
    end
  else
    return BattleUtils.GetLegendaryBattleID()
  end
  return nil
end

function LegendaryBattleModule:GetLegendaryTicketIDAndNum(npc_content_cfg_id, bIgnoreSpecialTicket)
  local seasonLegendaryID = self:GetSeasonLegendaryID(npc_content_cfg_id)
  if seasonLegendaryID then
    local seasonPveBaseConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.SEASON_PVE_BASE_CONF):GetAllDatas()
    for _, v in pairs(seasonPveBaseConf or {}) do
      if v.legendary_id == seasonLegendaryID then
        return v.ticket, v.season_ticket_cost
      end
    end
  else
    if not bIgnoreSpecialTicket then
      local ticket, ticketCost
      local legendaryBattleEventId = self:TryGetLegendaryBattleEventID(npc_content_cfg_id)
      if legendaryBattleEventId then
        local legendaryBattleEventConf = _G.DataConfigManager:GetLegendaryBattleEvent(legendaryBattleEventId)
        if legendaryBattleEventConf and legendaryBattleEventConf.token_id and legendaryBattleEventConf.ticket_cost then
          ticket = legendaryBattleEventConf.token_id
          ticketCost = legendaryBattleEventConf.ticket_cost
        end
      end
      if ticket and 0 ~= ticket and ticketCost and 0 ~= ticketCost then
        return ticket, ticketCost
      end
    end
    return _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num, _G.DataConfigManager:GetLegendaryGlobalConfig("ticket_cost").num
  end
  return 0, 0
end

function LegendaryBattleModule:OnCmdSetTicketID(ticketId)
  self.ticketID = ticketId
end

function LegendaryBattleModule:OnCmdGetTicketName()
  if not self.ticketID or 0 == self.ticketID then
    self.ticketID = BattleUtils.GetLegendaryTicketID()
  end
  if self.ticketID and 0 ~= self.ticketID then
    if self.ticketID == _G.Enum.VisualItem.VI_STAR then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
      return vItemConf.displayName
    end
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.ticketID)
    if bagItemConf then
      return bagItemConf.name
    end
  end
  return ""
end

return LegendaryBattleModule

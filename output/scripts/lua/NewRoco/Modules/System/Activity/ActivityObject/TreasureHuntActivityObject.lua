local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local BigMapModuleEvent = reload("NewRoco.Modules.System.BigMap.BigMapModuleEvent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local TreasureHuntActivityObject = Base:Extend("TreasureHuntActivityObject")

function TreasureHuntActivityObject:OnConstruct(_conf)
  self.isPrepareTaskFinished = false
  self.tickElapsedTime = 0
  self.tickInterval = 0.1
  self.showProtectTime = 0
  self.showProtectDuration = 5
  self.playerStandLocation = UE4.FVector(0, 0, 0)
  self.playerStandDuration = 0
  self.triggerG6TimeThreshold = 0.5
  self.showContentDistanceThreshold = 1
  self.hasEverBeenReceiveServerUpdate = false
  self.inAreaData = {}
  self.EnteringTaskId = nil
  self.DigForTreasure = nil
  self.EnterColdDown = false
  self.ShowTipColdDown = false
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ENTER_OR_LEAVE_TREASURE_HUNT_AREA_NTY, self.OnEnterOrLeaveActivityArea)
  if self.DelayID then
    _G.DelayManager:CancelDelayById(self.DelayID)
    self.DelayID = nil
  end
  self.DelayID = _G.DelayManager:DelayFrames(10, self.ReqGetPlayerActivityData, self)
end

function TreasureHuntActivityObject:OnDestruct()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_ENTER_OR_LEAVE_TREASURE_HUNT_AREA_NTY, self.OnEnterOrLeaveActivityArea)
  if self.DelayID then
    _G.DelayManager:CancelDelayById(self.DelayID)
    self.DelayID = nil
  end
end

function TreasureHuntActivityObject:getSubActivityCount()
  return #self:GetPartIds()
end

function TreasureHuntActivityObject:getTreasureConf(_index)
  local partIds = self:GetPartIds()
  for i, id in ipairs(partIds) do
    if id == _index then
      return _G.DataConfigManager:GetActivityTreasureHuntConf(_index)
    end
  end
  return nil
end

function TreasureHuntActivityObject:getTreasureDataFromServer(_activitySubID)
  for i, data in ipairs(self.treasureHuntDataSRV.treasure_data) do
    if data and data.activity_sub_id == _activitySubID then
      return data
    end
  end
  return nil
end

function TreasureHuntActivityObject:IsSubActivityUnlocked(_conf)
  if not _conf or not _conf.lock_time then
    return false
  end
  local srvTime = ActivityUtils.GetSvrTimestamp()
  local unlockTime = ActivityUtils.ToTimestamp(_conf.lock_time)
  return srvTime >= unlockTime
end

function TreasureHuntActivityObject:GetDaysBeforeSubActivityBegin(_conf)
  if not _conf or not _conf.lock_time then
    return false
  end
  local srvTime = ActivityUtils.GetSvrTimestamp()
  local unlockTime = ActivityUtils.ToTimestamp(_conf.lock_time)
  return math.ceil((unlockTime - srvTime) / 86400)
end

function TreasureHuntActivityObject:IsSubActivityAppear(_conf)
  if not _conf or not _conf.appear_time then
    return false
  end
  local srvTime = ActivityUtils.GetSvrTimestamp()
  local appearTime = ActivityUtils.ToTimestamp(_conf.appear_time)
  return srvTime >= appearTime
end

function TreasureHuntActivityObject:GetRemainedContentsInDebris(_conf)
  if not _conf then
    return 0
  end
  local TaskMap = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
  if TaskMap then
    local taskObj = TaskMap[_conf.task_id]
    if taskObj then
      local desc, now, need = taskObj:GetGoalDetail(1)
      return now
    end
  end
  return 0
end

function TreasureHuntActivityObject:GetContentIDs(_conf)
  return _conf and _conf.content_id
end

function TreasureHuntActivityObject:GetEffectGroups(_conf)
  return _conf and _conf.effect_group
end

function TreasureHuntActivityObject:GetEffectGroupCount(_conf)
  if nil == _conf then
    return 0
  end
  return #_conf.effect_group
end

function TreasureHuntActivityObject:GetRewardsFromContent(_conf)
  if not _conf then
    return
  end
  if _conf.content_id and #_conf.content_id > 0 then
    local rewards = {}
    for _, content in ipairs(_conf.content_id) do
      local contentCfg = _G.DataConfigManager:GetNpcRefreshContentConf(content, true)
      if contentCfg and contentCfg.npc_id and 0 ~= contentCfg.npc_id then
        local npcCfg = _G.DataConfigManager:GetNpcConf(contentCfg.npc_id, true)
        if npcCfg and npcCfg.option_id then
          for _, option in ipairs(npcCfg.option_id) do
            local optionCfg = _G.DataConfigManager:GetNpcOptionConf(option, true)
            if optionCfg and optionCfg.action and optionCfg.action.action_type == Enum.ActionType.ACT_REWARD_BY_CONGRA_PANEL then
              local rewardId = tonumber(optionCfg.action.action_param1 or "0")
              if 0 ~= rewardId then
                table.insert(rewards, rewardId)
              end
            end
          end
        end
      end
    end
    return rewards
  end
end

function TreasureHuntActivityObject:IsEffectGroupMatch(_group, _dist2DSquare)
  return _group and _dist2DSquare <= _group.dis2D_less * _group.dis2D_less and _dist2DSquare > _group.dis2D_over * _group.dis2D_over
end

function TreasureHuntActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  if _cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    local _activityData = _updateData
    self.treasureHuntDataSRV = _activityData and _activityData.treasure_hunt_data
    if self.treasureHuntDataSRV then
      self.hasEverBeenReceiveServerUpdate = true
      if self.treasureHuntDataSRV.unlock then
        self.isPrepareTaskFinished = true
      end
      for i, v in ipairs(self.treasureHuntDataSRV.treasure_data) do
        local activityConf = self:getTreasureConf(v.activity_sub_id)
        if self.isPrepareTaskFinished and self:IsSubActivityUnlocked(activityConf) then
          local worldMapActivityConf = _G.DataConfigManager:GetWorldMapActivityConf(activityConf.world_map_activity_conf_id)
          if not worldMapActivityConf then
          else
            local worldMapConf = _G.DataConfigManager:GetWorldMapConf(worldMapActivityConf.world_map_id)
            rawset(worldMapConf, "IconRadius", worldMapActivityConf.radius)
            local conf = self:getTreasureConf(v.activity_sub_id)
            local TaskMap = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
            self.inAreaData[v.activity_sub_id] = {TaskObject = nil}
            for k, taskObject in pairs(TaskMap) do
              if taskObject.Config.id == conf.task_id then
                local areaCfg = _G.DataConfigManager:GetAreaConf(worldMapConf.name_area_id)
                if areaCfg then
                  taskObject.StaticPosition = {
                    x = areaCfg.center_xyz[1],
                    y = areaCfg.center_xyz[2],
                    z = areaCfg.center_xyz[3]
                  }
                  taskObject.ActivityTaskIcon = worldMapConf.npcicon_unlock
                  self.inAreaData[v.activity_sub_id] = {TaskObject = taskObject}
                  if v.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT or v.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
                    _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.RemoveMapActivityIconByWorldMapConf, ActivityEnum.MapActivityIconGroup.TreasureDig, conf.task_id)
                    break
                  end
                  _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.AddMapActivityIconByWorldMapConf, ActivityEnum.MapActivityIconGroup.TreasureDig, worldMapConf, conf.task_id)
                end
                break
              end
            end
            if v.is_enter then
              self.inAreaData[v.activity_sub_id].TaskObject.UseStaticPosition = false
              self.enterLeaveActivityAreaData = {}
              self.enterLeaveActivityAreaData.activity_id = self:GetActivityId()
              self.enterLeaveActivityAreaData.activity_sub_id = v.activity_sub_id
              self.enterLeaveActivityAreaData.is_enter = true
              self.triggerG6TimeThreshold = _G.DataConfigManager:GetActivityTreasureHuntConf(v.activity_sub_id).G6_show_time / 1000
              _G.UpdateManager:Register(self)
              _G.DelayManager:DelayFrames(150, self.OnEnterOrLeaveActivityArea, self, self.enterLeaveActivityAreaData)
            elseif self.inAreaData[v.activity_sub_id] and self.inAreaData[v.activity_sub_id].TaskObject then
              local taskObject = self.inAreaData[v.activity_sub_id].TaskObject
              taskObject.UseStaticPosition = not taskObject:IsFinish()
            end
          end
        else
          local conf = self:getTreasureConf(v.activity_sub_id)
          if conf then
            _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.RemoveMapActivityIconByWorldMapConf, ActivityEnum.MapActivityIconGroup.TreasureDig, conf.task_id)
          end
        end
      end
      local bigMapModule = NRCModuleManager:GetModule("BigMapModule")
      bigMapModule:DispatchEvent(BigMapModuleEvent.WorldMapInfoChangeEvent)
    end
  end
end

function TreasureHuntActivityObject:OnEnterOrLeaveActivityArea(_protoData)
  if not _protoData then
    return
  end
  self.enterLeaveActivityAreaData = _protoData
  local taskId, taskObj, conf
  local activitySubId = self.enterLeaveActivityAreaData.activity_sub_id
  if activitySubId then
    conf = self:getTreasureConf(activitySubId)
    if conf then
      taskId = conf.task_id
    else
      return
    end
  end
  if self.enterLeaveActivityAreaData.is_enter and self.treasureHuntDataSRV ~= nil then
    if taskId then
      self.EnteringTaskId = taskId
      for i, v in ipairs(self.treasureHuntDataSRV.treasure_data) do
        if v.activity_sub_id == activitySubId and v.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNFINISH then
          if self.inAreaData[v.activity_sub_id] then
            taskObj = self.inAreaData[v.activity_sub_id].TaskObject
            if taskObj.Config.id == self:getTreasureConf(activitySubId).task_id then
              taskObj.UseStaticPosition = false
            end
            local desc, now, need = taskObj:GetGoalDetail(1)
            self.CachedGoalNow = now
          end
          self.triggerG6TimeThreshold = _G.DataConfigManager:GetActivityTreasureHuntConf(v.activity_sub_id).G6_show_time / 1000
          _G.UpdateManager:Register(self)
          self.tickElapsedTime = 0
          self.showProtectTime = 0
          if not self.EnterColdDown then
            self:ScheduleSwitchActivityTraceTask(true, taskId, 50)
            self:ScheduleSwitchActivityTraceTask(true, taskId, 200)
            self.EnterColdDown = true
          end
          if not self.ShowTipColdDown then
            self.ShowTipColdDown = true
            _G.DelayManager:DelayFrames(20, self.OnDelayShowActivityTip, self, conf.top_up_text)
          end
          return
        end
      end
    end
    return
  end
  self.EnteringTaskId = nil
  taskObj = self.inAreaData[_protoData.activity_sub_id].TaskObject
  if taskObj then
    taskObj.UseStaticPosition = not taskObj:IsFinish()
  end
  self:ScheduleSwitchActivityTraceTask(false, taskId, 0)
  _G.UpdateManager:UnRegister(self)
end

function TreasureHuntActivityObject:ScheduleSwitchActivityTraceTask(_on, _id, _delayFrames)
  if self.EnterColdDown then
    _G.DelayManager:DelayFrames(_delayFrames + 50, self.ScheduleSwitchActivityTraceTask, self, _on, _id, _delayFrames)
    return
  end
  self.EnterColdDown = true
  _G.DelayManager:DelayFrames(_delayFrames, function()
    if _on and self.EnteringTaskId == _id or not _on then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.SwitchActivityTraceTask, _on, _id)
    end
    self.EnterColdDown = false
  end)
end

function TreasureHuntActivityObject:OnDelayShowActivityTip(_text)
  self.ShowTipColdDown = false
  if self.EnteringTaskId then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowActivityZoneTip, _text)
  end
end

function TreasureHuntActivityObject:OnTick(deltaTime)
  if self.treasureHuntDataSRV == nil then
    return
  end
  if self.tickElapsedTime < self.tickInterval then
    self.tickElapsedTime = self.tickElapsedTime + deltaTime
    return
  end
  self.tickElapsedTime = 0
  if self.showProtectTime < self.showProtectDuration and self.EnteringTaskId then
    self.showProtectTime = self.showProtectTime + self.tickInterval
    self:ScheduleSwitchActivityTraceTask(true, self.EnteringTaskId, 110)
  end
  local treasureAreaConf = self:getTreasureConf(self.enterLeaveActivityAreaData.activity_sub_id)
  if nil == treasureAreaConf then
    return nil
  end
  local TaskMap = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTaskMap)
  if TaskMap then
    local taskObj = TaskMap[treasureAreaConf.task_id]
    if taskObj then
      local desc, now, need = taskObj:GetGoalDetail(1)
      if now == need then
        _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.RemoveMapActivityIconByWorldMapConf, ActivityEnum.MapActivityIconGroup.TreasureDig, treasureAreaConf.task_id)
        _G.UpdateManager:UnRegister(self)
        return
      end
      if self.CachedGoalNow ~= now then
        self.CachedGoalNow = now
        self:ScheduleSwitchActivityTraceTask(true, treasureAreaConf.task_id, 50)
      end
    end
  end
  if nil == self.enterLeaveActivityAreaData or not self.enterLeaveActivityAreaData.is_enter then
    _G.UpdateManager:UnRegister(self)
    return
  end
  local bestNPC
  for i, contentID in ipairs(treasureAreaConf.content_id) do
    local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, contentID)
    if nil ~= NPC then
      NPC:CalSquaredDis2Local()
      if nil == bestNPC or bestNPC.squaredDis2LocalIgnoreZ > NPC.squaredDis2LocalIgnoreZ then
        bestNPC = NPC
      end
    end
  end
  if nil == bestNPC then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.playerStandLocation ~= player:GetActorLocation() then
    if nil ~= self.SkillProxy then
      self.SkillProxy = nil
    end
    self.playerStandLocation = player:GetActorLocation()
    self.playerStandDuration = 0
    return
  end
  self.playerStandDuration = self.playerStandDuration + self.tickInterval
  if self.playerStandDuration < self.triggerG6TimeThreshold then
    return
  end
  if not (player.viewObj and player.viewObj.BP_RideComponent) or not player.viewObj.BP_RideComponent.RidePet then
    return
  end
  local currentTreasureDataFromServer
  for i, data in ipairs(self.treasureHuntDataSRV.treasure_data) do
    if data.activity_sub_id == self.enterLeaveActivityAreaData.activity_sub_id then
      currentTreasureDataFromServer = data
    end
  end
  local bFindPet = false
  for i, petBaseID in ipairs(treasureAreaConf.limit_pet) do
    if player and player.viewObj and player.viewObj.BP_RideComponent and player.viewObj.BP_RideComponent.ScenePet and player.viewObj.BP_RideComponent.ScenePet.config and petBaseID == player.viewObj.BP_RideComponent.ScenePet.config.id then
      bFindPet = true
    end
  end
  if not bFindPet then
    return
  end
  local bestMatchGroup
  for i, effectGroup in ipairs(treasureAreaConf.effect_group) do
    if self:IsEffectGroupMatch(effectGroup, bestNPC.squaredDis2LocalIgnoreZ) and (not bestMatchGroup or effectGroup.dis2D_over < bestMatchGroup.dis2D_over) then
      bestMatchGroup = effectGroup
    end
  end
  if nil == bestMatchGroup then
    return
  end
  if not string.IsNilOrEmpty(bestMatchGroup.play_G6) and nil == self.SkillProxy then
    self.SkillProxy = {}
    self.view = player.viewObj
    self.playingG6 = bestMatchGroup.play_G6
    self.req = _G.NRCResourceManager:LoadResAsync(self, self.playingG6, 255, 10, self.SkillLoadSucc, self.SkillLoadFail)
    if bestMatchGroup.if_show_content and not bestNPC:IsVisibleForServerReason() then
      bestNPC:SetVisibleForServerReason(true)
    end
  end
end

function TreasureHuntActivityObject:OnActiveHideOrShowContentRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("TreasureHuntActivityObject:OnActiveHideOrShowContentRsp", table.tostring(rsp))
  end
end

function TreasureHuntActivityObject:SkillLoadSucc(req, skillClass)
  if self.view then
    local skillComp = self.view:GetComponentByClass(UE4.URocoSkillComponent)
    if skillComp and self.SkillProxy ~= nil then
      self.SkillProxy = RocoSkillProxy.Create(self.playingG6, skillComp)
      self.SkillProxy:SetCaster(self.view)
      self.SkillProxy:SetPassive(true)
      self.SkillProxy:PlaySkill()
    end
  end
end

function TreasureHuntActivityObject:SkillLoadFail(req, msg)
  self.SkillProxy = nil
  self.req = nil
  Log.Error("[TreasureHuntActivityObject] load skill failed. ", msg)
end

return TreasureHuntActivityObject

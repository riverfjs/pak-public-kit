local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local PreDownloadActivityObject = Base:Extend("PreDownloadActivityObject")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local PreDownloadEvent = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEvent")

function PreDownloadActivityObject:OnConstruct(_conf, _briefInfo)
  self.preDownloadConf = _conf
  self.bStoppedByUser = false
  self.bAutoStart = false
  _G.NRCEventCenter:RegisterEvent("PreDownloadProgressNotify", self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
end

function PreDownloadActivityObject:OnPreDownloadFinished(bSuccess)
  if bSuccess then
    if self.preDownloadConf then
      local req = _G.ProtoMessage:newZoneActivityPredownloadReadyReq()
      req.activity_id = self.preDownloadConf.id
      req.resource_prepared = true
      req.already_download = true
      ActivityUtils.SendMsgToSvr(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PREDOWNLOAD_READY_REQ, req, self, self.OnTryJoinActivityRsp)
    end
  else
    Log.Error("PreDownloadActivityObject OnPreDownloadFinished failed")
  end
end

function PreDownloadActivityObject:NotifyDownloadFinished()
  if self.preDownloadConf then
    local req = _G.ProtoMessage:newZoneActivityPredownloadReadyReq()
    req.activity_id = self.preDownloadConf.id
    req.resource_prepared = true
    req.already_download = true
    ActivityUtils.SendMsgToSvr(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PREDOWNLOAD_READY_REQ, req, self, self.OnTryJoinActivityRsp)
  end
end

function PreDownloadActivityObject:SyncActivityDataOnAvailable()
  Log.Debug("PreDownloadActivityObject", "SyncActivityDataOnAvailable", self.preDownloadConf.id)
  self:ReqGetPlayerActivityData()
  if self.preDownloadConf then
    local isResourceReady = _G.NRCPreDownloadManager:IsPreDownloadResEnabled()
    local req = _G.ProtoMessage:newZoneActivityPredownloadReadyReq()
    req.activity_id = self.preDownloadConf.id
    req.resource_prepared = isResourceReady
    if isResourceReady then
      req.already_download = not _G.NRCPreDownloadManager:IfNeedToDownload()
    end
    Log.Dump(req, 3, "SyncActivityDataOnAvailable")
    ActivityUtils.SendMsgToSvr(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PREDOWNLOAD_READY_REQ, req, self, self.OnTryJoinActivityRsp)
  end
end

function PreDownloadActivityObject:GetActivityShowStatus()
  return ActivityEnum.ActivityShowStatus.Disable_AdditionalCond
end

function PreDownloadActivityObject:OnSvrUpdateActivityData(_cmdId, _updateData, _initUpdate)
  Log.Dump(_updateData, 3, "OnSvrUpdateActivityData")
  if _updateData and _updateData.pre_download_data then
    self.preDownloadData = _updateData.pre_download_data
    if _updateData then
      self:SendEvent(ActivityModuleEvent.PreDownloadActivityDataUpdate, _updateData.pre_download_data)
    end
  else
    Log.Error("PreDownloadActivityObject OnSvrUpdateActivityData updateData is nil")
  end
  if not self.bAutoStart and not _G.NRCPreDownloadManager:IsDownloading() and not self.bStoppedByUser then
    self.bAutoStart = true
    local wifiStatus = UE.UNetworkStatics.GetNetworkState()
    if 2 ~= wifiStatus then
      return
    end
    if self.preDownloadData and self.preDownloadData.book_download then
      _G.NRCPreDownloadManager:StartDownload()
      return
    end
  end
end

function PreDownloadActivityObject:OnTryJoinActivity()
  if self.preDownloadConf then
    local req = _G.ProtoMessage:newZoneActivityPredownloadReadyReq()
    req.activity_id = self.preDownloadConf.id
    req.resource_prepared = _G.NRCPreDownloadManager:IsPreDownloadResEnabled()
    req.already_download = false
    req.book_download = true
    ActivityUtils.SendMsgToSvr(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PREDOWNLOAD_READY_REQ, req, self, self.OnTryJoinActivityRsp)
    return ActivityEnum.ActivityJoinStatus.Available
  end
  return ActivityEnum.ActivityJoinStatus.Unsatisfied
end

function PreDownloadActivityObject:OnTryJoinActivityRsp(rsp)
  Log.Debug("PreDownloadActivityObject", "OnTryJoinActivityRsp", rsp)
end

function PreDownloadActivityObject:OnTryGetReward()
  if self.preDownloadConf then
    local req = ProtoMessage:newZoneActivityCommonRewardsReq()
    req.activity_id = self.preDownloadConf.id
    ActivityUtils.SendMsgToSvr(ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.OnTryGetRewardRsp)
  end
end

function PreDownloadActivityObject:OnTryGetRewardRsp(rsp)
  Log.Dump(rsp, 3, "OnTryGetRewardRsp")
  if 0 == rsp.ret_info.ret_code then
    self:ReqGetPlayerActivityData()
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.GlobalChallengeActivityGetReward)
    if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, table.deepCopy(rsp.ret_info.goods_reward.rewards))
    end
  end
end

function PreDownloadActivityObject:OnReconnectFinish()
  self:ReqGetPlayerActivityData()
end

function PreDownloadActivityObject:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
end

return PreDownloadActivityObject

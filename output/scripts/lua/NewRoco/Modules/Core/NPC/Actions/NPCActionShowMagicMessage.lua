local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local NPCActionShowMagicMessage = Base:Extend("NPCActionShowMagicMessage")
local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")

function NPCActionShowMagicMessage:Execute(playerId, needSendReq)
  Base.Execute(self, playerId, false)
  local messageNpc = self.Owner.owner
  if messageNpc and messageNpc.serverData and messageNpc.serverData.MagicFeedInfo then
    self.actor_id = messageNpc.serverData.base.actor_id
    self.feedInfo = messageNpc.serverData.MagicFeedInfo
    if self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or self.feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
      local reqMsg = _G.ProtoMessage:newZoneGetFeedDetailReq()
      reqMsg.feed_id = self.feedInfo.feed_id
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_FEED_DETAIL_REQ, reqMsg, self, self.OnGetFeedDetailRsp, nil, false)
    elseif self.feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
      local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MARK_VIDEO_WATCH, true, true, false)
      if Ban then
        self:Finish(true, nil)
        return
      end
      local reqMsg = _G.ProtoMessage:newZoneGetFeedDetailReq()
      reqMsg.feed_id = self.feedInfo.feed_id
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_FEED_DETAIL_REQ, reqMsg, self, self.OnGetFeedDetailRsp, nil, false)
    end
  end
end

function NPCActionShowMagicMessage:OnGetFeedDetailRsp(rsp)
  if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FeedSvrErr.ERR_FEEDSVR_FEED_NOT_EXIST or rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.FeedSvrErr.ERR_FEEDSVR_VIDEO_FILE_FASHION_OR_PET_ID_INVALID then
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcByGridAndFeedId, self.feedInfo.grid_id, self.feedInfo.feed_id, self.feedInfo.category)
    self:Finish(true, nil)
    return
  end
  if 0 == rsp.ret_info.ret_code then
    local feedInfo = rsp.feed_info
    if feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE or feedInfo.category == ProtoEnum.MarkGameplay.MK_FAKE_MAGIC_MESSAGE then
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenShowMagicMessage, rsp, self)
    elseif feedInfo.category == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
      local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
      if mainUIModule:HasPanel("MagicMessageMusicToolbar") then
        local musicToolbar = mainUIModule:GetPanel("MagicMessageMusicToolbar")
        if musicToolbar then
          musicToolbar:OnClickCloseBtn()
        end
      end
      _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StopMagicReplay)
      _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.SetReplayFeedDetail, rsp, self.actor_id)
      _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StartMagicReplay, MagicReplayModuleEnum.ModuleOpType.Replay)
      self:Finish(true, nil)
    end
    _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.UpdateNpcByGridAndFeedId, feedInfo.grid_id, feedInfo.feed_id, feedInfo)
  end
end

return NPCActionShowMagicMessage

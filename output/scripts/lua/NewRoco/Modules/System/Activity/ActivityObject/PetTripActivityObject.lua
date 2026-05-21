local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local PetTripActivityObject = Base:Extend("PetTripActivityObject")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
PetTripActivityObject.ActivityShowStatus = {
  TripIng = 1,
  DrawTheWinner = 2,
  DrawOver = 3
}

function PetTripActivityObject:OnConstruct(_conf, ...)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_GET_LOTTERY_RESULT_RSP, self.OnZoneActivityPetTripGetLotteryResultRsp)
  self:ReqGetActivityGetLotteryResultData()
  self.ActivityPetTripConf = _conf and _conf.base_id and _G.DataConfigManager:GetActivityPetTripConf(_conf.base_id[1])
  self.PetTripAwardConf = self.ActivityPetTripConf and self.ActivityPetTripConf.award_id and _G.DataConfigManager:GetActivityWishLotterAward(self.ActivityPetTripConf.award_id)
end

function PetTripActivityObject:OnDestruct()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_GET_LOTTERY_RESULT_RSP, self.OnZoneActivityPetTripGetLotteryResultRsp)
end

function PetTripActivityObject:OnZoneActivityPetTripGetLotteryResultRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    self.PetTripLotteryResult = Rsp.lottery_records
  end
end

function PetTripActivityObject:GetPetTripLotteryResult()
  if self.PetTripLotteryResult then
    if #self.PetTripLotteryResult > 1 then
      return self.PetTripLotteryResult
    elseif self.PetTripLotteryResult[1] and self.PetTripLotteryResult[1].activity_id ~= self:GetActivityId() then
      return self.PetTripLotteryResult
    end
  end
  return nil
end

function PetTripActivityObject:OnSvrUpdateActivityData(cmdId, _updateData, _initUpdate)
  if cmdId == _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PLAYER_ACTIVITY_DATA_RSP then
    if _updateData.pet_trip_data then
      self.activity_data = _updateData.pet_trip_data
      self:ReqGetActivityGetLotteryResultData()
    end
    self:SendEvent(ActivityModuleEvent.RefreshActivityPetTripData, self:GetActivityData())
  end
end

function PetTripActivityObject:SendReceiveLotteryRewardReq()
  local req = _G.ProtoMessage:newZoneActivityPetTripReceiveLotteryRewardReq()
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_RECEIVE_LOTTERY_REWARD_REQ, req, self, self.OnZoneActivityPetTripReceiveLotteryRewardRsp)
end

function PetTripActivityObject:OnZoneActivityPetTripReceiveLotteryRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:SyncActivityDataOnAvailable()
    self:SendEvent(ActivityModuleEvent.GetActivityPetTripDataRewardSuccess)
    local CurRewardConf = rsp.ret_info.goods_reward
    if CurRewardConf and CurRewardConf.rewards and #CurRewardConf.rewards > 0 then
      local newRewards = CurRewardConf.rewards
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
    end
  end
end

function PetTripActivityObject:SendGetPetTripHappyRewardReq(itemList)
  local req = _G.ProtoMessage:newZoneActivityCommonRewardsReq()
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.OnZoneGetPetTripHappyRewardRsp)
end

function PetTripActivityObject:OnZoneGetPetTripHappyRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.ret_info.goods_reward and rsp.ret_info.goods_reward.rewards and #rsp.ret_info.goods_reward.rewards > 0 then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards)
    end
    self:SyncActivityDataOnAvailable()
  end
end

function PetTripActivityObject:SendAutoTripReq(Is_auto)
  local req = _G.ProtoMessage:newZoneActivityPetTripAutoTripReq()
  req.activity_id = self:GetActivityId()
  req.auto_trip = Is_auto
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_AUTO_TRIP_REQ, req, self, self.OnZoneActivityPetTripAutoTripRsp)
end

function PetTripActivityObject:OnZoneActivityPetTripAutoTripRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:SyncActivityDataOnAvailable()
  end
end

function PetTripActivityObject:SendPetTripReq(pet_gids)
  local req = _G.ProtoMessage:newZoneActivityPetTripAddPetReq()
  req.activity_id = self:GetActivityId()
  req.pet_gids = pet_gids
  self.lastAddPetGids = pet_gids
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_ADD_PET_REQ, req, self, self.OnZoneActivityPetTripAddPetRsp)
end

function PetTripActivityObject:OnZoneActivityPetTripAddPetRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.NRCAudioManager:PlaySound2DAuto(1177, "PetTripActivityObject:OnZoneActivityPetTripAddPetRsp")
    self:SyncActivityDataOnAvailable()
    self:ShowPetTripAddTips()
  else
    self.lastAddPetGids = nil
  end
end

function PetTripActivityObject:SendSelectWishReq(SelectWish)
  local req = _G.ProtoMessage:newZoneActivityPetTripSetWishChoiceReq()
  req.wish_choice = SelectWish
  req.activity_id = self:GetActivityId()
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_SET_WISH_CHOICE_REQ, req, self, self.OnZoneActivityPetTripSetWishChoiceRsp)
end

function PetTripActivityObject:OnZoneActivityPetTripSetWishChoiceRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:SyncActivityDataOnAvailable()
  end
end

function PetTripActivityObject:GetActivityPetTripConf()
  return self.ActivityPetTripConf or {}
end

function PetTripActivityObject:GetPetTripAwardConf()
  return self.PetTripAwardConf or {}
end

function PetTripActivityObject:GetShowActivityTime()
  if self.ActivityPetTripConf then
    local stop_time = ActivityUtils.ToTimestamp(self.ActivityPetTripConf.stop_time)
    local draw_time = ActivityUtils.ToTimestamp(self.ActivityPetTripConf.draw_time)
    local svrTime = ActivityUtils.GetSvrTimestamp()
    if stop_time > svrTime then
      return PetTripActivityObject.ActivityShowStatus.TripIng, self.ActivityPetTripConf.stop_time
    elseif draw_time > svrTime then
      return PetTripActivityObject.ActivityShowStatus.DrawTheWinner, self.ActivityPetTripConf.draw_time
    else
      return PetTripActivityObject.ActivityShowStatus.DrawOver, LuaText.pet_trip_38
    end
  end
end

function PetTripActivityObject:GetActivityData()
  return self.activity_data or {}
end

function PetTripActivityObject:ReqGetActivityGetLotteryResultData()
  local req = _G.ProtoMessage:newZoneActivityPetTripGetLotteryResultReq()
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PET_TRIP_GET_LOTTERY_RESULT_REQ, req)
end

function PetTripActivityObject:SyncActivityDataOnAvailable()
  Log.Info(string.format("PetTripActivityObject:SyncActivityDataOnAvailable \232\175\183\230\177\130\230\180\187\229\138\168\230\149\176\230\141\174 id: %s", self:GetActivityId()))
  self:ReqGetPlayerActivityData()
end

function PetTripActivityObject:ShowPetTripAddTips()
  if not self.lastAddPetGids or 0 == #self.lastAddPetGids then
    return
  end
  local tips = ""
  local petCount = #self.lastAddPetGids
  if 1 == petCount then
    local petGid = self.lastAddPetGids[1]
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
    if petData and petData.name then
      tips = string.format(LuaText.pet_trip_44, petData.name or "")
    end
  else
    tips = string.format(LuaText.pet_trip_45, petCount)
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
end

return PetTripActivityObject

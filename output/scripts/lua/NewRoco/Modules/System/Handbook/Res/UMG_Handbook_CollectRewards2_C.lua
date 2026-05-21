local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_Handbook_CollectRewards2_C = _G.NRCPanelBase:Extend("UMG_Handbook_CollectRewards2_C")

function UMG_Handbook_CollectRewards2_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, true)
end

function UMG_Handbook_CollectRewards2_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = LuaText.photo_collect_reward_text_1
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_Handbook_CollectRewards2_C:OnClose()
  self:LoadAnimation(2)
end

function UMG_Handbook_CollectRewards2_C:OnActive(seasonId)
  self.seasonId = seasonId
  self.petTypeList = {
    ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW
  }
  self:InitPanel()
end

function UMG_Handbook_CollectRewards2_C:InitPanel()
  self:LoadAnimation(0)
  self:SetCommonPopUpInfo()
  self:UpdateSubjectList()
end

function UMG_Handbook_CollectRewards2_C:UpdateSubjectList()
  local rewardInfoList = {}
  for _, petType in pairs(self.petTypeList or {}) do
    local rewardInfo = self:GetRewardInfo(petType)
    if rewardInfo then
      table.insert(rewardInfoList, rewardInfo)
    end
  end
  self.SubjectList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SubjectList:InitList(rewardInfoList)
end

function UMG_Handbook_CollectRewards2_C:GetRewardInfo(petType)
  local rewardInfo = {}
  local _, collectNormalPetNum, rewardPetNum = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonPetCount, self.seasonId, petType)
  local rewardId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetSeasonRewardID, self.seasonId, petType)
  local isGotReward = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.CheckHandbookSeasonIsGotReward, self.seasonId, petType)
  rewardInfo.season_id = self.seasonId
  rewardInfo.max_cnt = rewardPetNum
  rewardInfo.finish_cnt = collectNormalPetNum
  rewardInfo.reward_id = rewardId
  rewardInfo.is_getaward = isGotReward
  rewardInfo.pet_type = petType
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonId)
  if seasonConf then
    local seasonName = seasonConf.s_title
    if petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
      rewardInfo.topic_desc = string.format(LuaText.photo_collect_reward_text_2, seasonName)
    elseif petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING then
      rewardInfo.topic_desc = string.format(LuaText.photo_collect_reward_text_3, seasonName)
    elseif petType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING then
      rewardInfo.topic_desc = string.format(LuaText.photo_collect_reward_text_4, seasonName)
    end
  end
  return rewardInfo
end

function UMG_Handbook_CollectRewards2_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Handbook_CollectRewards2_C:OnDeactive()
end

function UMG_Handbook_CollectRewards2_C:OnDestruct()
  self:DispatchEvent(HandbookModuleEvent.OnIsShowRegionalBtnMask, false)
end

function UMG_Handbook_CollectRewards2_C:OnAddEventListener()
end

return UMG_Handbook_CollectRewards2_C

local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Activity_TreasureSpot_C = _G.NRCPanelBase:Extend("UMG_Activity_TreasureSpot_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_TreasureSpot_C:InvalidWaitingRewardIds()
  self.RewardId = nil
  self.RewardSubId = nil
end

local redDotPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_red_liwu_png.img_red_liwu_png'"

function UMG_Activity_TreasureSpot_C:OnActive(_activeObject)
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    UE4Helper.SetEnableWorldRendering(false)
    self:OnAddEventListener()
    return
  end
  self.CurrentFocusedDebrisId = 1
  self.activityInst = _activeObject
  self:OnAddEventListener()
  self:SetCommonTitle()
  self:InitUIElements()
  self:FocusDebris(self.CurrentFocusedDebrisId)
  self.SelectedBGSwitcher = self.Switcher_BG1
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  self:OnSwitcherSwitcher_BG1(1)
  self:PlayAnimation(self.Open)
end

function UMG_Activity_TreasureSpot_C:OnDeactive()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    UE4Helper.SetEnableWorldRendering(true)
    return
  end
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.TreasureHuntTracePet, self.TracePet)
  self:PlayAnimation(self.Close)
end

function UMG_Activity_TreasureSpot_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickCloseBtn)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_TreasureSpot_C", self, ActivityModuleEvent.TreasureHuntTracePet, self.TracePet)
end

function UMG_Activity_TreasureSpot_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_Activity_TreasureSpot_C:OnClickCloseBtn")
  self:PlayAnimation(self.Close)
  self:DelaySeconds(0.1, self.DoClose, self)
end

function UMG_Activity_TreasureSpot_C:InitUIElements()
  local partIDs = self.activityInst:GetPartIds()
  for i, partID in ipairs(partIDs) do
    local conf = self.activityInst:getTreasureConf(partID)
    if conf then
      local treasureDataFromServer = self.activityInst:getTreasureDataFromServer(partID)
      if 1 == partID then
        self.redPointNew1:SetupKey(215, {
          self.activityInst:GetActivityId(),
          1
        })
        if treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self:AddButtonListener(self.NRCButton1, self.OnClickNRCButton1)
        elseif treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self:OnSwitcherSwitcherContent1(2)
          self:AddButtonListener(self.NRCButton1, self.OnClickNRCButton1)
        elseif self.activityInst:IsSubActivityUnlocked(conf) then
          self:OnSwitcherSwitcherContent1(0)
          self:AddButtonListener(self.NRCButton1, self.OnClickNRCButton1)
        elseif self.activityInst:IsSubActivityAppear(conf) then
          self:OnSwitcherSwitcherContent1(2)
          local countDownFmtText = _G.DataConfigManager:GetLocalizationConf("Trearsure_Hunt_MapTime")
          local countDownText = string.format(countDownFmtText.msg, self.activityInst:GetDaysBeforeSubActivityBegin(conf))
          self.CountDown1:SetText(countDownText)
        else
          self:OnSwitcherSwitcherContent1(1)
        end
      end
      if 2 == partID then
        self.redPointNew2:SetupKey(215, {
          self.activityInst:GetActivityId(),
          2
        })
        if treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self:AddButtonListener(self.NRCButton2, self.OnClickNRCButton2)
        elseif treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self:OnSwitcherSwitcherContent2(2)
          self:AddButtonListener(self.NRCButton2, self.OnClickNRCButton2)
        elseif self.activityInst:IsSubActivityUnlocked(conf) then
          self:OnSwitcherSwitcherContent2(0)
          self:AddButtonListener(self.NRCButton2, self.OnClickNRCButton2)
        elseif self.activityInst:IsSubActivityAppear(conf) then
          self:OnSwitcherSwitcherContent2(1)
          local countDownFmtText = _G.DataConfigManager:GetLocalizationConf("Trearsure_Hunt_MapTime")
          local countDownText = string.format(countDownFmtText.msg, self.activityInst:GetDaysBeforeSubActivityBegin(conf))
          self.CountDown2:SetText(countDownText)
        else
          self:OnSwitcherSwitcherContent2(2)
        end
      end
      if 3 == partID then
        self.redPointNew3:SetupKey(215, {
          self.activityInst:GetActivityId(),
          3
        })
        if treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self:AddButtonListener(self.NRCButton3, self.OnClickNRCButton3)
        elseif treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self:OnSwitcherSwitcherContent3(2)
          self:AddButtonListener(self.NRCButton3, self.OnClickNRCButton3)
        elseif self.activityInst:IsSubActivityUnlocked(conf) then
          self:OnSwitcherSwitcherContent3(0)
          self:AddButtonListener(self.NRCButton3, self.OnClickNRCButton3)
        elseif self.activityInst:IsSubActivityAppear(conf) then
          self:OnSwitcherSwitcherContent3(1)
          local countDownFmtText = _G.DataConfigManager:GetLocalizationConf("Trearsure_Hunt_MapTime")
          local countDownText = string.format(countDownFmtText.msg, self.activityInst:GetDaysBeforeSubActivityBegin(conf))
          self.CountDown3:SetText(countDownText)
        else
          self:OnSwitcherSwitcherContent3(2)
        end
      end
      if 4 == partID then
        self.redPointNew4:SetupKey(215, {
          self.activityInst:GetActivityId(),
          4
        })
        if treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self:AddButtonListener(self.NRCButton4, self.OnClickNRCButton4)
        elseif treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self:OnSwitcherSwitcherContent4(2)
          self:AddButtonListener(self.NRCButton4, self.OnClickNRCButton4)
        elseif self.activityInst:IsSubActivityUnlocked(conf) then
          self:OnSwitcherSwitcherContent4(0)
          self:AddButtonListener(self.NRCButton4, self.OnClickNRCButton4)
        elseif self.activityInst:IsSubActivityAppear(conf) then
          self:OnSwitcherSwitcherContent4(1)
          local countDownFmtText = _G.DataConfigManager:GetLocalizationConf("Trearsure_Hunt_MapTime")
          local countDownText = string.format(countDownFmtText.msg, self.activityInst:GetDaysBeforeSubActivityBegin(conf))
          self.CountDown3_1:SetText(countDownText)
        else
          self:OnSwitcherSwitcherContent4(2)
        end
      end
      if 5 == partID then
        self.redPointNew5:SetupKey(215, {
          self.activityInst:GetActivityId(),
          5
        })
        if treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self:AddButtonListener(self.NRCButton5, self.OnClickNRCButton5)
        elseif treasureDataFromServer and treasureDataFromServer.reward_state == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self:OnSwitcherSwitcherContent5(2)
          self:AddButtonListener(self.NRCButton5, self.OnClickNRCButton5)
        elseif self.activityInst:IsSubActivityUnlocked(conf) then
          self:OnSwitcherSwitcherContent5(0)
          self:AddButtonListener(self.NRCButton5, self.OnClickNRCButton5)
        elseif self.activityInst:IsSubActivityAppear(conf) then
          self:OnSwitcherSwitcherContent5(1)
          local countDownFmtText = _G.DataConfigManager:GetLocalizationConf("Trearsure_Hunt_MapTime")
          local countDownText = string.format(countDownFmtText.msg, self.activityInst:GetDaysBeforeSubActivityBegin(conf))
          self.CountDown3_2:SetText(countDownText)
        else
          self:OnSwitcherSwitcherContent5(2)
        end
      end
    end
  end
end

function UMG_Activity_TreasureSpot_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Activity_TreasureSpot_C:FocusDebris(_debrisIndex)
  self.CurrentFocusedDebrisId = _debrisIndex
  local partIDs = self.activityInst:GetPartIds()
  for i, partID in ipairs(partIDs) do
    if partID == _debrisIndex then
      self.SelectedPartId = _debrisIndex
      local conf = self.activityInst:getTreasureConf(partID)
      self.FocusedDebrisConf = conf
      if conf and self.activityInst:IsSubActivityUnlocked(conf) then
        self.TextAreadescribe:SetText(conf.text1)
        self.TextRiddledescribe:SetText(conf.text2)
        self.TextExploredescribe_1:SetText(conf.text4)
        self.TextPetHint:SetText(conf.text3)
        local treasureDataFromServer = self.activityInst:getTreasureDataFromServer(partID)
        if not treasureDataFromServer then
          return
        end
        self.BtnExplore.redPointNew:SetupKey(215, {
          self.activityInst:GetActivityId(),
          partID
        })
        if treasureDataFromServer.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
          self.BtnExplore:SetBtnText(_G.LuaText.Treasure_Hunt_GetReward_Button)
          self.BtnExplore:SetVisibility(UE4.ESlateVisibility.Visible)
          self:RemoveButtonListener(self.BtnExplore.btnLevelUp)
          self.RewardId = self.activityInst:GetActivityId()
          self.RewardSubId = conf.id
          self:AddButtonListener(self.BtnExplore.btnLevelUp, self.OnClickBtnAcquireReward)
        elseif treasureDataFromServer.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
          self.BtnExplore:SetVisibility(UE4.ESlateVisibility.Hidden)
          self:RemoveButtonListener(self.BtnExplore.btnLevelUp)
        else
          self.BtnExplore:SetVisibility(UE4.ESlateVisibility.Visible)
          self.BtnExplore:SetBtnText(_G.LuaText.Treasure_Hunt_Guide_Button)
          self:RemoveButtonListener(self.BtnExplore.btnLevelUp)
          self:AddButtonListener(self.BtnExplore.btnLevelUp, self.OnClickBtnExplore)
        end
        self.PetList:InitGridView(conf.limit_pet)
        local totalContentCount = #self.activityInst:GetContentIDs(conf)
        local remainedContentCount = 0
        if treasureDataFromServer.reward_state < 2 then
          remainedContentCount = self.activityInst:GetRemainedContentsInDebris(conf)
        else
          remainedContentCount = totalContentCount
        end
        local quantityString = tostring(remainedContentCount) .. "/" .. tostring(totalContentCount)
        self.TextQuantity:SetText(quantityString)
        local rewardConf = conf.reward and _G.DataConfigManager:GetRewardConf(conf.reward)
        if rewardConf then
          local rewardsTable = {}
          for k, v in ipairs(rewardConf.RewardItem) do
            local rewards = _G.NRCCommonItemIconData()
            rewards.itemType = v.Type
            rewards.itemId = v.Id
            rewards.itemNum = v.Count
            rewards.bShowNum = true
            rewards.bShowTip = true
            rewards.bShowGetTag = treasureDataFromServer.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
            table.insert(rewardsTable, rewards)
          end
          self.AwardList:InitGridView(rewardsTable)
        end
      end
    end
  end
end

function UMG_Activity_TreasureSpot_C:OnConstruct()
end

function UMG_Activity_TreasureSpot_C:OnDestruct()
end

function UMG_Activity_TreasureSpot_C:OnClickNRCButton1()
  self.SelectedBGSwitcher:SetActiveWidgetIndex(0)
  self.SelectedBGSwitcher = self.Switcher_BG1
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  _G.NRCAudioManager:PlaySound2DAuto(1236, "UMG_Activity_TreasureSpot_C:OnClickNRCButton1")
  self:FocusDebris(1)
end

function UMG_Activity_TreasureSpot_C:OnClickNRCButton2()
  self.SelectedBGSwitcher:SetActiveWidgetIndex(0)
  self.SelectedBGSwitcher = self.Switcher_BG2
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  _G.NRCAudioManager:PlaySound2DAuto(1236, "UMG_Activity_TreasureSpot_C:OnClickNRCButton1")
  self:FocusDebris(2)
end

function UMG_Activity_TreasureSpot_C:OnClickNRCButton3()
  self.SelectedBGSwitcher:SetActiveWidgetIndex(0)
  self.SelectedBGSwitcher = self.Switcher_BG3
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  _G.NRCAudioManager:PlaySound2DAuto(1236, "UMG_Activity_TreasureSpot_C:OnClickNRCButton1")
  self:FocusDebris(3)
end

function UMG_Activity_TreasureSpot_C:OnClickNRCButton4()
  self.SelectedBGSwitcher:SetActiveWidgetIndex(0)
  self.SelectedBGSwitcher = self.Switcher_BG4
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  _G.NRCAudioManager:PlaySound2DAuto(1236, "UMG_Activity_TreasureSpot_C:OnClickNRCButton1")
  self:FocusDebris(4)
end

function UMG_Activity_TreasureSpot_C:OnClickNRCButton5()
  self.SelectedBGSwitcher:SetActiveWidgetIndex(0)
  self.SelectedBGSwitcher = self.Switcher_BG5
  self.SelectedBGSwitcher:SetActiveWidgetIndex(1)
  _G.NRCAudioManager:PlaySound2DAuto(1236, "UMG_Activity_TreasureSpot_C:OnClickNRCButton1")
  self:FocusDebris(5)
end

function UMG_Activity_TreasureSpot_C:OnClickBtnAcquireReward()
  _G.NRCAudioManager:PlaySound2DAuto(1075, "UMG_Activity_TreasureSpot_C:OnClickBtnAcquireReward")
  local Req = _G.ProtoMessage:newZoneReceivePlayerActivityTreasureHuntRewardReq()
  Req.activity_id = self.RewardId
  Req.activity_sub_id = self.RewardSubId
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_PLAYER_ACTIVITY_TREASURE_HUNT_REWARD_REQ, Req, self, self.OnAcquireRewardRsp, false, false)
end

function UMG_Activity_TreasureSpot_C:OnAcquireRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    for i = 1, self.AwardList:GetItemCount() do
      local item = self.AwardList:GetItemByIndex(i - 1)
      item:SetAlreadyReceived(true)
    end
    self.BtnExplore:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:RemoveButtonListener(self.BtnExplore.btnLevelUp)
    local treasureDataFromServer = self.activityInst:getTreasureDataFromServer(self.RewardSubId)
    treasureDataFromServer.reward_state = _G.ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE
    self:InitUIElements()
    self:FocusDebris(self.CurrentFocusedDebrisId)
    if self.activityInst.DigForTreasure then
      self.activityInst.DigForTreasure.RewardBtn.RedDot:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    ActivityUtils.ShowRewardGetTips(self.FocusedDebrisConf.reward)
  end
end

function UMG_Activity_TreasureSpot_C:OnClickBtnExplore()
  _G.NRCAudioManager:PlaySound2DAuto(1325, "UMG_Activity_TreasureSpot_C:OnClickBtnAcquireReward")
  if self.activityInst and self.activityInst:IsInProgress() then
    self:FocusMapBySelectedId()
    _G.GEMPostManager:SendActivityTLog(self.activityInst:GetActivityId())
  end
end

function UMG_Activity_TreasureSpot_C:FocusMapBySelectedId()
  if self.FocusedDebrisConf then
    local activityMapConfId = self.FocusedDebrisConf.world_map_activity_conf_id
    local activityMapConf = _G.DataConfigManager:GetWorldMapActivityConf(activityMapConfId)
    local worldMapConfig = _G.DataConfigManager:GetWorldMapConf(activityMapConf.world_map_id)
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap, {
      centerNPCRefreshId = worldMapConfig.npc_refresh_ids[1]
    })
  end
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcherContent2(SwitcherIndex)
  self.SwitcherContent2:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcherContent3(SwitcherIndex)
  self.SwitcherContent3:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcherContent4(SwitcherIndex)
  self.SwitcherContent4:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcherContent5(SwitcherIndex)
  self.SwitcherContent5:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcherContent1(SwitcherIndex)
  self.SwitcherContent1:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcher_BG1(SwitcherIndex)
  self.Switcher_BG1:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcher_BG2(SwitcherIndex)
  self.Switcher_BG2:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcher_BG3(SwitcherIndex)
  self.Switcher_BG3:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcher_BG4(SwitcherIndex)
  self.Switcher_BG4:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:OnSwitcherSwitcher_BG5(SwitcherIndex)
  self.Switcher_BG5:SetActiveWidgetIndex(SwitcherIndex)
end

function UMG_Activity_TreasureSpot_C:TracePet(petBase_id)
  if self.activityInst:IsInProgress() then
    ActivityUtils.RequestTracePet({petBase_id}, self.activityInst)
  end
end

return UMG_Activity_TreasureSpot_C

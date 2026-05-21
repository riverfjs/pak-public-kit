local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_BPBadge_C = Base:Extend("UMG_Activity_BPBadge_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_BPBadge_C:BindUIElements()
  local uiElements = {}
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.loopAnimName = "Loop"
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  return uiElements
end

function UMG_Activity_BPBadge_C:OnConstruct()
  Base.OnConstruct(self)
  self.index = 1
  local _activityInst = self.activityInst
  local activityGoodsConf = _G.DataConfigManager:GetActivityGoodsConf(_activityInst:GetSinglePartId())
  local goods_group = activityGoodsConf.goods_group
  if #goods_group > 1 then
    local initData = {}
    for _, v in ipairs(goods_group) do
      local data = {
        text = v.option_name,
        caller = self,
        handler = self.OnItemSelected
      }
      table.insert(initData, data)
    end
    self.TabList1:InitGridView(initData)
    self.TabList1:SelectItemByIndex(0)
  else
    self.TabList1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TabBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:OnItemSelected(1)
  end
  if 0 ~= activityGoodsConf.task_id then
    local req = _G.ProtoMessage:newZoneTaskQueryReq()
    req.task_list = {
      activityGoodsConf.task_id
    }
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.InitRewardState)
    local reward_id = _G.DataConfigManager:GetTaskConf(activityGoodsConf.task_id).Reward
    local reward = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem[1]
    local rewardData = {}
    local data = _G.NRCCommonItemIconData()
    data.itemType = reward.Type
    data.itemId = reward.Id
    data.itemNum = reward.Count
    data.bShowNum = true
    data.bShowTip = true
    data.Key = 215
    data.extraKey = tostring(_activityInst:GetActivityId())
    table.insert(rewardData, data)
    self.AwardList:InitList(rewardData)
    self.ContractText_62:SetText(_G.LuaText.activity_goods_task_tips)
  end
  self:AddButtonListener(self.Btn_Claimable.btnLevelUp, self.OnClickJoinActivity)
  self:AddButtonListener(self.ClickButton, self.ReqGetReward)
end

function UMG_Activity_BPBadge_C:InitRewardState(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.task_info_list[1].state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      self.ClickButton:SetVisibility(UE4.ESlateVisibility.Visible)
    elseif rsp.task_info_list[1].state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      self.AwardList:GetItemByIndex(0):SetAlreadyReceived(true)
    end
  end
end

function UMG_Activity_BPBadge_C:ReqGetReward()
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = {
    _G.DataConfigManager:GetActivityGoodsConf(self.activityInst:GetSinglePartId()).task_id
  }
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.GetReward)
end

function UMG_Activity_BPBadge_C:GetReward(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.ClickButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local item = self.AwardList:GetItemByIndex(0)
    item:SetAlreadyReceived(true)
    item:PlayAnimation(item.Receive)
    local activityGoodsConf = _G.DataConfigManager:GetActivityGoodsConf(self.activityInst:GetSinglePartId())
    local reward_id = _G.DataConfigManager:GetTaskConf(activityGoodsConf.task_id).Reward
    local reward = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem[1]
    local popupInitData = {}
    local popupData = _G.ProtoMessage:newGoodsItem()
    popupData.id = reward.Id
    popupData.num = reward.Count
    popupData.type = reward.Type
    table.insert(popupInitData, popupData)
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData)
  end
end

function UMG_Activity_BPBadge_C:OnClickJoinActivity()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Activity_BPBadge_C:OnClickJoinActivity")
  self:DelaySeconds(0.1, function()
    local _activityInst = self.activityInst
    if _activityInst then
      local activityGoodConf = _G.DataConfigManager:GetActivityGoodsConf(_activityInst:GetActivityId()).goods_group
      local _itemObject
      if RocoEnv.PLATFORM_WINDOWS then
        _itemObject = _activityInst:CreateWebSiteItem(activityGoodConf[self.index].website_id_pc)
      elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
        _itemObject = _activityInst:CreateWebSiteItem(activityGoodConf[self.index].website_id)
      end
      return _itemObject and _activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Join, _itemObject)
    end
  end)
end

function UMG_Activity_BPBadge_C:OnItemSelected(index)
  local activityGoodConf = _G.DataConfigManager:GetActivityGoodsConf(self.activityInst:GetActivityId()).goods_group
  self.index = index
  self.Bg:SetPath(activityGoodConf[index].bg_path)
  self.ReverseSide:SetPath(activityGoodConf[index].goods_back)
  self.ReverseSide_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:LoadPanelRes(activityGoodConf[index].back_ae_img, 255, function(_, _, asset)
    self.ReverseSide_1:SetBrushFromMaterial(asset)
    self.ReverseSide_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
  self.Front:SetPath(activityGoodConf[index].goods_front)
  self.Front_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:LoadPanelRes(activityGoodConf[index].ae_img1, 255, function(_, _, asset)
    self.Front_1:SetBrushFromMaterial(asset)
    self.Front_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
  self.Front_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:LoadPanelRes(activityGoodConf[index].ae_img2, 255, function(_, _, asset)
    self.Front_2:SetBrushFromMaterial(asset)
    self.Front_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
end

function UMG_Activity_BPBadge_C:OnDestruct()
  self:RemoveButtonListener(self.Btn_Claimable.btnLevelUp)
  self:RemoveButtonListener(self.ClickButton)
end

return UMG_Activity_BPBadge_C

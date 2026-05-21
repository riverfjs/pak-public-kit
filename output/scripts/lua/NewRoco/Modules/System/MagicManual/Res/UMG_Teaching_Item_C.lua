local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ModuleData = require("NewRoco/Modules/System/MagicManual/MagicManualModuleData")
local UMG_Teaching_Item_C = Base:Extend("UMG_Teaching_Item_C")

function UMG_Teaching_Item_C:OnConstruct()
  self.Btn.btnLevelUp.OnClicked:Add(self, self.OnBtnPressed)
  self.Btn_1.btnLevelUp.OnClicked:Add(self, self.OnBtnTracePressed)
  self.Btn_2.btnLevelUp.OnClicked:Add(self, self.OnBtnTracePressed)
end

function UMG_Teaching_Item_C:OnDestruct()
end

function UMG_Teaching_Item_C:OnBtnTracePressed()
  if self.type == ModuleData.TeachType.Restraint then
    NRCModuleManager:DoCmd(RedPointModuleCmd.EraseRedPoint, 436, {
      self.confId
    })
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.online_task_unable_text)
    return
  end
  if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.IsPlaying) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2331)
    return
  end
  if _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_PROP_BLINDBOX) then
    local banConf = _G.DataConfigManager:GetFunctionBanConf(_G.Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, banConf and banConf.ban_desc)
    return
  end
  local req = _G.ProtoMessage:newZoneTriggerTeachingBattleReq()
  req.id = self.data.id
  req.teaching_type = self.type == ModuleData.TeachType.Restraint and ProtoEnum.TeachingType.TT_TYPE_ADVANTAGE or ProtoEnum.TeachingType.TT_COMBAT_MECHANISM
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TRIGGER_TEACHING_BATTLE_REQ, req, self, self.OnZoneTriggerTeachingBattleRsp)
end

function UMG_Teaching_Item_C:OnZoneTriggerTeachingBattleRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function UMG_Teaching_Item_C:OnBtnPressed()
  local req = _G.ProtoMessage:newZoneClaimTeachingRewardReq()
  req.id = self.data.id
  req.teaching_type = self.type == ModuleData.TeachType.Restraint and ProtoEnum.TeachingType.TT_TYPE_ADVANTAGE or ProtoEnum.TeachingType.TT_COMBAT_MECHANISM
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLAIM_TEACHING_REWARD_REQ, req, self, self.OnZoneClaimTeachingRewardRsp)
  self.Switcher:SetActiveWidgetIndex(2)
end

function UMG_Teaching_Item_C:MergeRewards(_rspRewards)
  local newRewards = {}
  for _, goodsItem in ipairs(_rspRewards) do
    if goodsItem.reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_LEVEL_REWARD then
      table.insert(newRewards, goodsItem)
    end
  end
  return newRewards
end

function UMG_Teaching_Item_C:OnZoneClaimTeachingRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local CurRewardConf = rsp.ret_info.goods_reward
    if #CurRewardConf.rewards > 0 then
      local newRewards = self:MergeRewards(CurRewardConf.rewards)
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
    end
    self.state = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
    self.Switcher:SetActiveWidgetIndex(2)
    if self.type == ModuleData.TeachType.Restraint and self.conf then
      self:SetRewardList(self.conf and self.conf.train_show_reward)
    elseif self.type == ModuleData.TeachType.Battle and self.conf then
      self:SetRewardList(self.conf and self.conf.combat_show_reward)
    end
    _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.UpdateMagicTeachingPanel)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function UMG_Teaching_Item_C:OnRefresh(_data)
  self.data = _G.NRCModuleManager:GetModule("MagicManualModule"):GetBattleTaskInfoById(self.type, self.confId, self.data.id)
  local is_complish = self.data and self.data.is_complish
  local is_reward = self.data and self.data.is_reward
  if is_complish and is_reward then
    self.state = ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
    self.Switcher:SetActiveWidgetIndex(2)
  elseif is_complish and not is_reward then
    self.state = ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
    self.Switcher:SetActiveWidgetIndex(1)
  else
    self.state = ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN
    self.Switcher:SetActiveWidgetIndex(0)
  end
  if self.type == ModuleData.TeachType.Restraint and self.conf then
    self.Btn.RedDot:SetupKey(456, {
      Enum.TeachingType.TT_TYPE_ADVANTAGE,
      self.confId,
      self.data.id
    })
    self.Describe:SetText(self.conf.train_display)
    self:SetRewardList(self.conf and self.conf.train_show_reward)
  elseif self.type == ModuleData.TeachType.Battle and self.conf then
    self.Btn.RedDot:SetupKey(456, {
      Enum.TeachingType.TT_COMBAT_MECHANISM,
      self.confId,
      self.data.id
    })
    self.Describe:SetText(self.conf.combat_train_display)
    self:SetRewardList(self.conf and self.conf.combat_show_reward)
  end
end

function UMG_Teaching_Item_C:OnItemUpdate(_data, datalist, index)
  self.type = _data.type
  self.data = _data.data
  self.confId = _data.ConfId
  self.conf = self.data and self.data.conf
  self:OnRefresh()
end

function UMG_Teaching_Item_C:SetRewardList(RewardIds)
  local RewardList = {}
  local rewardsTable = {}
  if RewardIds and #RewardIds > 0 then
    for i, RewardId in ipairs(RewardIds) do
      local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
      local RewardItem = RewardConf.RewardItem
      for _, _RewardConf in ipairs(RewardItem) do
        if (_RewardConf.Type ~= _G.Enum.GoodsType.GT_CARD_ICON or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_SKIN or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_LABEL) and _RewardConf.Type ~= _G.Enum.GoodsType.GT_REWARD then
          table.insert(RewardList, {
            RewardConf = _RewardConf,
            state = self.state
          })
        end
      end
      for k, v in ipairs(RewardList) do
        local rewards = _G.NRCCommonItemIconData()
        rewards.itemType = v.RewardConf.Type
        rewards.itemId = v.RewardConf.Id
        rewards.itemNum = v.RewardConf.Count
        rewards.bShowNum = true
        rewards.bShowTip = true
        if self.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
          rewards.bShowGetTag = true
        else
          rewards.bShowGetTag = false
        end
        table.insert(rewardsTable, rewards)
      end
    end
  end
  self.List:InitGridView(rewardsTable)
end

function UMG_Teaching_Item_C:OnItemSelected(_bSelected)
end

function UMG_Teaching_Item_C:OnDeactive()
end

return UMG_Teaching_Item_C

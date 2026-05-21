local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Handbook_Subject_List_C = Base:Extend("UMG_Handbook_Subject_List_C")

function UMG_Handbook_Subject_List_C:OnConstruct()
  self.Btn6.btnLevelUp.OnClicked:Add(self, self.OnGetAwardBtn)
end

function UMG_Handbook_Subject_List_C:OnDestruct()
end

function UMG_Handbook_Subject_List_C:OnItemUpdate(_data, datalist, index)
  self.NRCText_56:SetText(_data.topic_desc)
  self.data = _data
  local max_cnt = _data.max_cnt
  local finish_cnt = _data.finish_cnt
  local is_getaward = _data.is_getaward
  if _data.season_id and _data.pet_type then
    self.Btn6.RedDot:SetupKey(480, {
      _data.season_id,
      _data.pet_type
    })
  else
    local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 1, 4)
    self.Btn6.RedDot:SetupKey(redId, {
      _data.handbook_id,
      _data.id
    })
  end
  self.NRCText_1:SetText(string.format("%s/%s", finish_cnt, max_cnt))
  self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if max_cnt > finish_cnt then
    self.NRCSwitcher_1:SetActiveWidgetIndex(1)
  elseif is_getaward then
    self.NRCSwitcher_1:SetActiveWidgetIndex(2)
    self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher_1:SetActiveWidgetIndex(0)
  end
  local reward_id = _data.reward_id
  local reward_lst = {}
  if reward_id and reward_id > 0 then
    local rewardConf = _G.DataConfigManager:GetRewardConf(reward_id)
    if nil == rewardConf then
      return
    end
    local rewards = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem
    for i = 1, #rewards do
      local reward = rewards[i]
      local item = {}
      item.itemType = reward.Type
      item.itemId = reward.Id
      item.bShowNum = true
      item.itemNum = reward.Count
      item.bShowGetTag = is_getaward
      table.insert(reward_lst, item)
    end
  end
  self.NRCGridView_95:InitGridView(reward_lst)
end

function UMG_Handbook_Subject_List_C:OnItemSelected(_bSelected)
end

function UMG_Handbook_Subject_List_C:OnGetAwardBtn()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK_REWARD, true)
  if isBan then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Handbook_Subject_List_C:OnGetAwardBtn")
  local isClick = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.SetClickTime)
  if self.data and isClick then
    if self.data.season_id and self.data.pet_type then
      _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.SendGetHandbookSeasonAwardReq, self.data.season_id, self.data.pet_type)
    else
      _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetHandbookTopicAward, self.data.handbook_id, self.data.id)
    end
  end
end

function UMG_Handbook_Subject_List_C:OnDeactive()
end

return UMG_Handbook_Subject_List_C

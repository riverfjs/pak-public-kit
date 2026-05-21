local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_OrdinaryReward_Item_C = Base:Extend("UMG_OrdinaryReward_Item_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_OrdinaryReward_Item_C:OnConstruct()
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.TraceSeed)
end

function UMG_OrdinaryReward_Item_C:OnDestruct()
  self:RemoveButtonListener(self.TraceBtn.btnLevelUp)
end

function UMG_OrdinaryReward_Item_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  local rewardItems = _G.DataConfigManager:GetRewardConf(_data.reward_id).RewardItem
  local initData = {}
  for _, rewardItem in ipairs(rewardItems) do
    local data = _G.NRCCommonItemIconData()
    data.itemType = rewardItem.Type
    data.itemId = rewardItem.Id
    data.itemNum = rewardItem.Count
    data.bShowNum = true
    table.insert(initData, data)
  end
  self.IconList:InitGridView(initData)
  if _data.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_OPEN then
    self.Switcher:SetActiveWidgetIndex(1)
  elseif _data.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
    self.Switcher:SetActiveWidgetIndex(2)
  elseif _data.reward_state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_CLOSE then
    self.Switcher:SetActiveWidgetIndex(3)
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_data.pet_base_id)
  self.Array:SetText(string.format(_G.DataConfigManager:GetTaskConf(_data.task_id).task_des, petBaseConf.name))
  self.Btn3:SetRedDotExtraKey(215, {
    _data.activity_id,
    _data.part_id
  })
end

function UMG_OrdinaryReward_Item_C:TraceSeed()
  ActivityUtils.DoActivityOptionCmd(self.uiData.activity_option_id)
end

return UMG_OrdinaryReward_Item_C

local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local UMG_Activity_Collect_Item_C = Base:Extend("UMG_Activity_Collect_Item_C")

function UMG_Activity_Collect_Item_C:OnConstruct()
  self:AddButtonListener(self.Btn_details.btnLevelUp, self.OnDetailsBtnClick)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTraceBtnClick)
  self:AddButtonListener(self.Btn3.btnLevelUp, self.OnGetRewardBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_Collect_Item_C", self, NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoGlobalTouchEnd)
end

function UMG_Activity_Collect_Item_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoGlobalTouchEnd)
end

function UMG_Activity_Collect_Item_C:OnItemUpdate(_data, datalist, index)
  if not _data then
    Log.Error("_data is nil")
    return
  end
  self.data = _data
  self.tipsParam = nil
  self.go_guide = nil
  self.ProgressText:SetText(string.format("%d/%d", _data.curProgress or 0, _data.totalProgress or 1))
  self.Btn_details:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local conf = _G.DataConfigManager:GetActivityConditionRewardConf(_data.conditionId)
  if conf then
    local conditionConf = conf.condition_group and conf.condition_group[1] or nil
    if conditionConf and conditionConf.condition_enum == Enum.RequiredType.ACTRT_TASK then
      local taskConf = _G.DataConfigManager:GetTaskConf(conditionConf.condition_param)
      if taskConf and taskConf.go_guide then
        self.go_guide = taskConf.go_guide[1]
      end
    end
    self.Text_describe:SetText(conf.part_name)
    self.Array:SetText(conf.part_desc)
    if conf.tips_txt then
      self.tipsParam = {
        title = conf.part_name,
        desc = conf.tips_txt
      }
      self.Btn_details:SetText()
      self.Btn_details:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Title:SetText(conf.tips_txt)
    end
    local rewards = {}
    if conf.reward_group then
      for i, v in ipairs(conf.reward_group) do
        table.insert(rewards, {
          itemId = v.goods_id,
          itemType = v.goods_type,
          itemNum = v.goods_count,
          isDone = _data.rewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE,
          bShowNum = true
        })
      end
    end
    self.IconList:InitGridView(rewards)
  end
  if _data.rewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    self.Switcher:SetActiveWidgetIndex(2)
  elseif _data.rewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_DONE then
    self.Switcher:SetActiveWidgetIndex(1)
  elseif self.go_guide and self.go_guide.text then
    self.Switcher:SetActiveWidgetIndex(3)
  else
    self.Switcher:SetActiveWidgetIndex(0)
  end
end

function UMG_Activity_Collect_Item_C:OnRocoGlobalTouchEnd()
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_Collect_Item_C:OnDetailsBtnClick()
  if self.tipsParam then
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Activity_Collect_Item_C:OnTraceBtnClick()
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.activity_condition_visitor_error_tips)
    return
  end
  if self.go_guide then
    MagicManualUtils.TaskTraceByGoGuide(self.go_guide)
  end
end

function UMG_Activity_Collect_Item_C:OnGetRewardBtnClick()
  if self.data and self.data.rewardState == ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_WAIT then
    local parentCustomData = self:GetParentCustomData()
    if parentCustomData then
      local activityInst = parentCustomData.activityInst
      if activityInst and parentCustomData.groupId then
        activityInst:GetReward(parentCustomData.groupId, self.data.conditionId)
      end
    end
  end
end

function UMG_Activity_Collect_Item_C:OnDeactive()
end

return UMG_Activity_Collect_Item_C

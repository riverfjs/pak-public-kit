local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_ItemBase_C")
local UMG_Activity_StageAwardItem_C = Base:Extend("UMG_Activity_StageAwardItem_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_StageAwardItem_C:OnEnter()
  self:EnableAnimations(true)
  self:PlayInAnimation()
end

function UMG_Activity_StageAwardItem_C:OnLeave()
  self:DisableAnimations()
end

function UMG_Activity_StageAwardItem_C:OnStageAwardItemSelect(_itemInst)
  if not _itemInst then
    return
  end
  local CurStageAwardSelectData = self.CurStageAwardSelectData
  if not CurStageAwardSelectData then
    CurStageAwardSelectData = _G.MakeWeakTable({}, "v")
    self.CurStageAwardSelectData = CurStageAwardSelectData
  end
  local curSelectItemInst = CurStageAwardSelectData.curSelectItemInst
  if curSelectItemInst and UE.UObject.IsValid(curSelectItemInst) then
    curSelectItemInst:SetSelect(false)
  end
  _itemInst:SetSelect(true)
  CurStageAwardSelectData.curSelectItemInst = _itemInst
end

function UMG_Activity_StageAwardItem_C:SetDescribe(desc)
  self.Text_Describe:SetText(desc)
  if self.Text_Describe_Select then
    self.Text_Describe_Select:SetText(desc)
  end
end

function UMG_Activity_StageAwardItem_C:SetTitle(title)
  if self.TitleText then
    self.TitleText:SetText(title)
  end
end

function UMG_Activity_StageAwardItem_C:SetBgImg(normalPath, selectPath)
  if not string.IsNilOrEmpty(normalPath) and not string.IsNilOrEmpty(selectPath) then
    if self.changtai then
      self.changtai:SetPath(normalPath)
    end
    if self.xuanzhong then
      self.xuanzhong:SetPath(selectPath)
    end
  end
end

function UMG_Activity_StageAwardItem_C:SetProgress(cur, total, conditionEnum)
  cur = cur or 0
  total = total or 0
  local progressDec = string.format("%d/%d", cur, total)
  if conditionEnum == Enum.RequiredType.ACTRT_PVP_RANK then
    local rankConf = _G.DataConfigManager:GetPvpRankConf(cur)
    if rankConf then
      progressDec = _G.LuaText.activity_qilaiya_pvprank_tips .. rankConf.name_only
    end
    if cur ~= total then
      total = 0
    end
  end
  self.ProgressText:SetText(progressDec)
  if 0 ~= total then
    self.TaskProgress:SetPercent(cur / total)
  else
    self.TaskProgress:SetPercent(0)
  end
end

function UMG_Activity_StageAwardItem_C:SetupRedPoint(key, extraKey)
  self.redPointNew:EnableAnimation()
  self.redPointNew:SetupKey(key, extraKey)
end

function UMG_Activity_StageAwardItem_C:SetRewardGroup(rewardGroup)
  local rewardIcons = {
    [1] = {
      self.Icon_5
    },
    [2] = {
      self.Icon_3,
      self.Icon_4
    },
    [3] = {
      self.Icon,
      self.Icon_1,
      self.Icon_2
    }
  }
  local rewardCtrl
  local rewardCount = rewardGroup and #rewardGroup or 0
  if rewardCount > 0 then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if rewardCount >= 3 then
      rewardCtrl = rewardIcons[3]
      self.Switcher:SetActiveWidgetIndex(0)
    elseif 2 == rewardCount then
      rewardCtrl = rewardIcons[2]
      self.Switcher:SetActiveWidgetIndex(1)
    elseif 1 == rewardCount then
      rewardCtrl = rewardIcons[1]
      self.Switcher:SetActiveWidgetIndex(2)
    end
  else
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if rewardCtrl then
    for _index, _ctrl in ipairs(rewardCtrl) do
      local rewardConf = rewardGroup[_index]
      local itemData = ActivityUtils.ParseActivityRewardData(rewardConf.goods_type, rewardConf.goods_id, rewardConf.goods_count)
      itemData.callbackWhenSelect = _G.MakeWeakFunctor(self, self.OnStageAwardItemSelect)
      _ctrl:SetData(itemData)
    end
    self.rewardCtrl = rewardCtrl
  end
end

function UMG_Activity_StageAwardItem_C:SetRewardBtn(bShow)
  if self.rewardCtrl then
    local visibility = bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed
    for _, rewardItem in ipairs(self.rewardCtrl) do
      rewardItem.Btn:SetVisibility(visibility)
    end
  end
end

function UMG_Activity_StageAwardItem_C:OnStageAwardItemSelect(_itemInst)
  if not _itemInst then
    return
  end
  local curSelectItemInst = self.curSelectItemInst
  if curSelectItemInst and UE.UObject.IsValid(curSelectItemInst) then
    curSelectItemInst:SetSelect(false)
  end
  _itemInst:SetSelect(true)
  self.curSelectItemInst = _itemInst
end

function UMG_Activity_StageAwardItem_C:SetAlreadyReceived(_received)
  if _received then
    self:TryStopAnimation(self.Reward_ready_loop, true)
  end
  self.Completed:SetVisibility(_received and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Activity_StageAwardItem_C:SetBtnSwitcher(index)
  if self.BtnSwitcher then
    self.BtnSwitcher:SetActiveWidgetIndex(index)
  end
end

function UMG_Activity_StageAwardItem_C:PlayInAnimation()
  self:DelayPlayAnimation(self.In, false)
end

function UMG_Activity_StageAwardItem_C:PlayRewardGetAnimation()
  self:TryStopAnimation(self.Reward_ready_loop, true)
  self:TryPlayAnimation(self.Reward_get, false, 10)
end

function UMG_Activity_StageAwardItem_C:PlayRewardUnAvailableAnimation()
  self:TryPlayAnimation(self.Reward_normal, false, 0)
end

function UMG_Activity_StageAwardItem_C:PlayRewardAvailableAnimation()
  self:TryPlayAnimation(self.Reward_ready_loop, false, 0, true)
end

function UMG_Activity_StageAwardItem_C:PlayRewardReceivedAnimation()
  self:TryStopAnimation(self.Reward_ready_loop, true)
  self:TryPlayAnimation(self.Get)
end

function UMG_Activity_StageAwardItem_C:PlaySelectAnimation(_bSelected)
  self:TryPlayAnimation(self.select, not _bSelected, 0)
end

return UMG_Activity_StageAwardItem_C

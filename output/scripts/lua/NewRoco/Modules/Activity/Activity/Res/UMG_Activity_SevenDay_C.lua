local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_SignInTemplate_C")
local UMG_Activity_SevenDay_C = Base:Extend("UMG_Activity_SevenDay_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_Activity_SevenDay_C:BindUIElements()
  local uiElements = {}
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.timeRemainingRoot = self.shijian
  uiElements.signStages = {}
  if self.List then
    uiElements.signStages[self.List] = {
      1,
      2,
      3,
      4,
      5,
      6
    }
  end
  if self.List_1 then
    uiElements.signStages[self.List_1] = {7}
  end
  return uiElements
end

function UMG_Activity_SevenDay_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.ExamineBtn, self.JumpToPetDesc)
  local _activityInst = self.activityInst
  self.Text_Title:SetText(_activityInst:GetActivityName())
  self.Text_Describe:SetText(_activityInst:GetActivityPromptText())
  local titleIcon = _activityInst:GetTitleIcon()
  if not string.IsNilOrEmpty(titleIcon) then
    self.Label:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Label:SetPath(titleIcon)
  else
    self.Label:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local stageCfg = _activityInst:GetStageRewardsCfg()
  if stageCfg and not string.IsNilOrEmpty(stageCfg.image_path) then
    self.BG:SetPath(stageCfg.image_path)
  end
  local petBaseId = stageCfg.petbase_id
  if petBaseId and 0 ~= petBaseId then
    local petName = ""
    local petBaseData = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if petBaseData then
      petName = petBaseData.name
    end
    self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextName:SetText(petName)
    self.Attr:InitGridView(ActivityUtils.CreatePetCommonAttrListData(petBaseData and petBaseData.unit_type, nil, nil, PetUtils.CreateFakePetData(petBaseId)))
  else
    self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_SevenDay_C:JumpToPetDesc()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_SevenDay_C:JumpToPetDesc")
  local stageCfg = self.activityInst:GetStageRewardsCfg()
  if stageCfg and stageCfg.petbase_id then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, stageCfg.petbase_id, true)
  end
end

function UMG_Activity_SevenDay_C:OnItemSelected(_itemInst, _index, _stage, _bSelected)
  local _activityInst = self.activityInst
  if _bSelected and _activityInst then
    local handled = _activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.Auto, _stage)
    if not handled then
      ActivityUtils.ShowRewardTips(_activityInst:GetStageRewardId(_stage))
    end
  end
end

function UMG_Activity_SevenDay_C:OnItemUpdate(_itemInst, _index, _stage)
  local _itemObject = self.activityInst
  if not _itemObject then
    return
  end
  if _itemInst then
    local rewardData = _itemObject:GetStageRewardData(_stage) or {}
    _itemInst:SetRewardIcon(rewardData.showIcon, rewardData.itemType, rewardData.itemId)
    _itemInst:SetRewardNum(rewardData.itemNum)
    _itemInst:SetQuality(rewardData.itemQuality)
    _itemInst:SetSignStage(_stage)
    _itemInst:SetupRedPoint(_itemObject:GetRewardRedPointData(_stage))
  end
  self:OnItemRefreshView(_itemInst, _index, _stage)
end

function UMG_Activity_SevenDay_C:OnItemRefreshView(_itemInst, _index, _stage)
  local _itemObject = self.activityInst
  if not _itemObject then
    return
  end
  if _itemInst then
    local rewardStatus = _itemObject:GetStageRewardStatus(_stage)
    if rewardStatus == ActivityEnum.RewardStatus.UnAvailable then
      _itemInst:PlayRewardUnAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Available then
      _itemInst:PlayRewardAvailableAnimation()
    elseif rewardStatus == ActivityEnum.RewardStatus.Received then
      _itemInst:PlayRewardReceivedAnimation()
    end
  end
end

return UMG_Activity_SevenDay_C

local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local UMG_Activity_RoyalGriffin_C = Base:Extend("UMG_Activity_RoyalGriffin_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_Activity_RoyalGriffin_C:BindUIElements()
  local uiElements = {}
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.title = self.Text_Title
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.promptText = self.Text_Describe
  uiElements.titleLabelIcon = self.Label
  uiElements.titleLabelText = self.NRCText_61
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_RoyalGriffin_C:OnConstruct()
  Base.OnConstruct(self)
  local _activityInst = self.activityInst
  local flowerDataList = _activityInst:GetFlowerDataList()
  if #flowerDataList > 1 then
    self.List:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local listSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.List)
    local listPosition = listSlot:GetPosition()
    if #flowerDataList > 4 then
      ActivityUtils.AdjustCtrlAutoSize(self.List, false)
      listPosition.X = -144
    else
      ActivityUtils.AdjustCtrlAutoSize(self.List, true)
      listPosition.X = -128
    end
    listSlot:SetPosition(listPosition)
  else
    self.List:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:OnSelectFlowerDataChanged(flowerDataList[1])
  self:OnActivitySvrStateChanged(_activityInst)
  self.RedDot:SetupKey(215, _activityInst:GetActivityId())
  self:AddButtonListener(self.ExamineBtn, self.OnClickShowPetData)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.OnTraceBtnClick)
  self:AddButtonListener(self.NRCButton_43, self.OnClickShowPetNatureTips)
  self:AddButtonListener(self.OrdinaryRewardBtn, self.OpenRewardPanel)
  self:AddButtonListener(self.ButtonClaim, self.OpenMedalRecord)
  self:AddButtonListener(self.Intimacy.NRCButton_43, self.OpenCloseLevelPanel)
  self:RegisterEvent(self, ActivityModuleEvent.ActivitySvrStateChanged, self.OnActivitySvrStateChanged)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshRoyalGriffinActivityData, self.InitPanel)
  self:InitPanel(_activityInst:GetActivityData())
  self.Reminder.btnLevelUp:SetIsEnabled(false)
  self.Image_Icon:SetPath(_G.DataConfigManager:GetActivityGlobalConfig("Activity_Flower_First_Win_Icon").str)
end

function UMG_Activity_RoyalGriffin_C:InitPanel(part_data)
  local _activityInst = self.activityInst
  local flower_group = _activityInst:GetFlowerDataList()
  local bDefaultInit
  if not part_data then
    bDefaultInit = true
    part_data = {}
    for _, v in ipairs(flower_group) do
      for _, task_id in ipairs(v.appear_task_id) do
        local reward_data = {}
        reward_data.activity_part_id = task_id
        reward_data.state = _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_CLOSE
        table.insert(part_data, reward_data)
      end
    end
  end
  local seedCount = #flower_group
  local task1CompCount = 0
  local task2CompCount = 0
  local activity_id = _activityInst:GetActivityId()
  local madelData = {}
  local rewardData = {}
  self.rewardRecord = {}
  for _, reward_data in ipairs(part_data) do
    local data_madel = {}
    local data_reward = {}
    for i = 1, seedCount do
      for _, v in ipairs(flower_group[i].appear_task_id) do
        if v == reward_data.activity_part_id then
          local flowerTaskConf = _G.DataConfigManager:GetActivityFlowerTaskConf(reward_data.activity_part_id)
          if not self.rewardRecord[i] then
            self.rewardRecord[i] = {}
          end
          if flowerTaskConf.task_type == Enum.ACTIVITY_FLOWER_APPEAR_TASK_TYPE.AFATT_FIRST_WIN then
            data_reward.reward_state = reward_data.state
            data_reward.task_id = flowerTaskConf.task_conf_id
            data_reward.reward_id = flowerTaskConf.reward_id
            data_reward.pet_base_id = flower_group[i].petbase_id
            data_reward.activity_id = activity_id
            data_reward.activity_part_id = reward_data.activity_part_id
            data_reward.activity_option_id = flower_group[i].activity_option_id
            data_reward.caller = self
            data_reward.callback = self.refreshRewardShow
            data_reward.seed_index = i
            data_reward.part_id = reward_data.activity_part_id
            if reward_data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
              task1CompCount = task1CompCount + 1
              self.rewardRecord[i].bReward = true
            end
            table.insert(rewardData, data_reward)
            goto lbl_176
          end
          if flowerTaskConf.task_type == Enum.ACTIVITY_FLOWER_APPEAR_TASK_TYPE.AFATT_MEDAL then
            if reward_data.state == _G.ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
              data_madel.bind_pet = reward_data.param.param1
              task2CompCount = task2CompCount + 1
              self.rewardRecord[i].bGetMedal = true
            end
            data_madel.task_id = flowerTaskConf.task_conf_id
            data_madel.pet_base_id = flower_group[i].petbase_id
            data_madel.blood_id = ActivityUtils.GetPetBloodIdBySeedId(flower_group[i].seed_id)
            data_madel.medal_type = flowerTaskConf.reward_type
            data_madel.medal_id = flowerTaskConf.reward_id
            table.insert(madelData, data_madel)
          end
          goto lbl_176
        end
      end
    end
    ::lbl_176::
  end
  self.madelData = madelData
  self.rewardData = rewardData
  self.hasRewardNum = task1CompCount
  self.RewardProgress:SetText(string.format(_G.LuaText.Activity_PlayerCoCreation_task, task1CompCount, seedCount))
  self.ProgressText:SetText(string.format(_G.LuaText.Activity_PlayerCoCreation_task, task2CompCount, seedCount))
  self.TaskProgress:SetPercent(task2CompCount / seedCount)
  if not self.bDefaultInit then
    self.bDefaultInit = not bDefaultInit
    local seedListData = ActivityUtils.CreateActivityItemBaseDataForList(self, flower_group)
    if seedCount > 1 then
      self.List:InitList(seedListData)
      self.OpenSelect = true
      self.List:SelectItemByIndex(0)
    end
  end
end

function UMG_Activity_RoyalGriffin_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.ActivitySvrStateChanged)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshRoyalGriffinActivityData)
end

function UMG_Activity_RoyalGriffin_C:OnActivitySvrStateChanged(activityInst)
  if activityInst ~= self.activityInst then
    return
  end
  if activityInst:IsActivityUnlock() then
    self.Reminder:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TraceBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TraceBtn:SetBtnText(_G.LuaText.Activity_FlowerAppearHard_BtnTxt)
  else
    local listSlot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.List)
    local listPosition = listSlot:GetPosition()
    listPosition.Y = -201
    listSlot:SetPosition(listPosition)
    self.TraceBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Reminder:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local world_level = activityInst:GetWorldLevelRequired()
    local title
    local worldLevelData = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
    for i = 1, #worldLevelData do
      if world_level == worldLevelData[i].world_level then
        title = _G.DataConfigManager:GetWorldLevelConf(i).title
        break
      end
    end
    local btnTitle = string.format(_G.DataConfigManager:GetLocalizationConf("activity_wolrd_level_low").msg, title)
    self.Reminder:SetTitleTextAndIcon(nil, nil, nil, nil, btnTitle)
    self.Reminder:SetTitleTextColor("#c7494aFF")
    self.Reminder:SetShowLockIcon(false)
  end
end

function UMG_Activity_RoyalGriffin_C:OnSelectFlowerDataChanged(flowerData)
  self.curSelectFlowerData = flowerData
  local petName = ""
  local petBaseData = flowerData and _G.DataConfigManager:GetPetbaseConf(flowerData.petbase_id)
  if petBaseData then
    petName = petBaseData.name
  end
  self.TextName:SetText(petName)
  local petBloodId = ActivityUtils.GetPetBloodIdBySeedId(flowerData and flowerData.seed_id)
  local fakePetData
  if petBaseData then
    fakePetData = PetUtils.CreateFakePetData(petBaseData.id)
    fakePetData.blood_id = petBloodId
  end
  self.Attr:InitGridView(ActivityUtils.CreatePetCommonAttrListData(petBaseData and petBaseData.unit_type, petBloodId, nil, fakePetData))
  local petNatureId = ActivityUtils.GetPetNatureIdBySeedId(flowerData and flowerData.seed_id)
  local petNatureConf = petNatureId and _G.DataConfigManager:GetNatureConf(petNatureId)
  self.textPetNature:SetText(petNatureConf and petNatureConf.name or "")
  if flowerData and not string.IsNilOrEmpty(flowerData.img) then
    self.BG:SetPath(flowerData.img)
  end
end

function UMG_Activity_RoyalGriffin_C:OnItemUpdate(_itemInst, _index, _flowerData)
  if _itemInst and _flowerData then
    _itemInst:SetImagePreview(_flowerData.img_preview)
    if self.rewardRecord[_index] then
      _itemInst:SetRewardState(self.rewardRecord[_index].bGetMedal, self.rewardRecord[_index].bReward)
    else
      _itemInst:SetRewardState(false, false)
    end
  end
end

function UMG_Activity_RoyalGriffin_C:OnItemSelected(_itemInst, _index, _flowerData, _bSelected)
  local _itemObject = self.activityInst
  if _bSelected and _itemObject then
    if self.OpenSelect then
      self.OpenSelect = false
    else
      _G.NRCAudioManager:PlaySound2DAuto(40001002, "UMG_Activity_RoyalGriffin_C:OnItemSelected")
    end
    self:OnSelectFlowerDataChanged(_flowerData)
    local pet_info_id = _G.DataConfigManager:GetActivitySpecFlowerSeedConf(_flowerData.seed_id).pet_info_id
    local closeLevel = _G.DataConfigManager:GetPetInfoConf(pet_info_id).close_level
    self.Intimacy:SetBtnText(string.format(_G.LuaText.Activity_FlowerHard_CloseLevel, closeLevel))
  end
end

function UMG_Activity_RoyalGriffin_C:OnClickShowPetData()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_RoyalGriffin_C:OnClickShowPetData")
  local flowerData = self.curSelectFlowerData
  if flowerData then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, flowerData.petbase_id, true)
  end
end

function UMG_Activity_RoyalGriffin_C:OnTraceBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(1077, "UMG_Activity_RoyalGriffin_C:OnTraceBtnClick")
  if self.activityInst and self.activityInst:IsActivityInactive() then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  if self.activityInst:IsInProgress() then
    ActivityUtils.DoActivityOptionCmd(self.curSelectFlowerData.activity_option_id)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
end

function UMG_Activity_RoyalGriffin_C:OnClickShowPetNatureTips()
  self:PlayAnimation(self.click_2)
  _G.NRCAudioManager:PlaySound2DAuto(40008031, "UMG_Activity_RoyalGriffin_C:OnClickShowPetNatureTips")
  local flowerData = self.curSelectFlowerData
  if flowerData then
    local natureId = ActivityUtils.GetPetNatureIdBySeedId(flowerData.seed_id)
    if natureId then
      ActivityUtils.ShowPetNatureTips(natureId, flowerData.petbase_id)
    end
  end
end

function UMG_Activity_RoyalGriffin_C:OpenRewardPanel()
  self:PlayAnimation(self.click_1)
  if self.activityInst:IsInProgress() then
    _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Activity_RoyalGriffin_C:OpenRewardPanel")
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenOrdinaryReward, self.rewardData or {})
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.activity_expired_interaction_tip)
  end
end

function UMG_Activity_RoyalGriffin_C:OpenMedalRecord()
  self:PlayAnimation(self.click_4)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_RoyalGriffin_C:OpenMedalRecord")
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenPredestinedEvidence, self.madelData or {})
end

function UMG_Activity_RoyalGriffin_C:refreshRewardShow(index)
  self.rewardRecord[index].bReward = true
  self.hasRewardNum = self.hasRewardNum + 1
  self.RewardProgress:SetText(string.format(_G.LuaText.Activity_PlayerCoCreation_task, self.hasRewardNum, #self.activityInst:GetFlowerDataList()))
  self.List:GetItemByIndex(index - 1):SetRewardMark()
end

function UMG_Activity_RoyalGriffin_C:OpenCloseLevelPanel()
  self:PlayAnimation(self.click_3)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(_G.LuaText.interactiontree_love_title):SetContent(_G.LuaText.interactiontree_love_tip):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

return UMG_Activity_RoyalGriffin_C

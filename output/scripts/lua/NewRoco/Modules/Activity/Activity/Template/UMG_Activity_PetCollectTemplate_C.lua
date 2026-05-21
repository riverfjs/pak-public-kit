local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_PetCollectTemplate_C = Base:Extend("UMG_Activity_PetCollectTemplate_C")

function UMG_Activity_PetCollectTemplate_C:BindUIElements()
  local uiElements = {}
  uiElements.itemList = self.List
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  return uiElements
end

function UMG_Activity_PetCollectTemplate_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
end

function UMG_Activity_PetCollectTemplate_C:OnDestruct()
  Base.OnDestruct(self)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshPetCollectActivityPetList)
  self:RemoveButtonListener(self.ParticularsBtn, self.OnShowActivityDesc)
end

function UMG_Activity_PetCollectTemplate_C:OnAddEventListener()
  self:RegisterEvent(self, ActivityModuleEvent.RefreshPetCollectActivityPetList, self.OnRefreshCollectPetList)
  self:AddButtonListener(self.ParticularsBtn, self.OnShowActivityDesc)
end

function UMG_Activity_PetCollectTemplate_C:SetRedPoints(UIComponent)
  if self.activityInst then
    local activityId = self.activityInst:GetActivityId()
    UIComponent:SetupKey(ActivityEnum.RedPointKey.DetailReward, {activityId, activityId})
  end
end

function UMG_Activity_PetCollectTemplate_C:GetPetGroup()
  local petCollectionConf = self:GetPetCollectionConf()
  if petCollectionConf then
    return petCollectionConf.pet_group
  end
  return nil
end

function UMG_Activity_PetCollectTemplate_C:GetReturnActivityData()
  return nil
end

function UMG_Activity_PetCollectTemplate_C:InitPetList()
  local collectPetList = {}
  local petGroup = self:GetPetGroup()
  local returnActivityData = self:GetReturnActivityData()
  local collectPetGroup
  if returnActivityData and returnActivityData.collection_pet then
    collectPetGroup = returnActivityData.collection_pet
  end
  if petGroup then
    local activityId
    if self.activityInst then
      activityId = self.activityInst:GetActivityId()
    end
    for _, petData in ipairs(petGroup) do
      local data = {
        petbase_id = petData.petbase_id,
        trail_type = petData.trail_type,
        trail_param = petData.trail_param,
        trail_param2 = petData.trail_param2,
        img = petData.img,
        isCollected = false,
        activityId = activityId
      }
      if collectPetGroup then
        for _, petCollectId in ipairs(collectPetGroup) do
          if petCollectId == petData.petbase_id then
            data.isCollected = true
          end
        end
      end
      table.insert(collectPetList, data)
    end
  end
  if self.uiElements.itemList then
    self.uiElements.itemList:SetCustomData(self.activityInst)
    if self.uiElements.itemList.InitList then
      self.uiElements.itemList:InitList(collectPetList)
    elseif self.uiElements.itemList.InitGridView then
      self.uiElements.itemList:InitGridView(collectPetList)
    end
    if #collectPetList > 4 then
      self.uiElements.itemList.Slot:SetAutoSize(false)
    else
      self.uiElements.itemList.Slot:SetAutoSize(true)
    end
  end
end

function UMG_Activity_PetCollectTemplate_C:ShowPetGroupName(UIComponent)
  local petCollectionConf = self:GetPetCollectionConf()
  if petCollectionConf then
    local petGroupName = petCollectionConf.name
    UIComponent:SetText(petGroupName)
  end
end

function UMG_Activity_PetCollectTemplate_C:ShowActivityTime(CanvasUIComponent)
  if self.activityInst then
    local startTime = self.activityInst:GetActivityStartTime()
    local endTime = self.activityInst:GetActivityEndTime()
    if 0 == startTime or 0 == endTime then
      CanvasUIComponent:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      CanvasUIComponent:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_Activity_PetCollectTemplate_C:ShowRewardIcon(UIComponent)
  local petCollectionConf = self:GetPetCollectionConf()
  if petCollectionConf then
    local rewardId = petCollectionConf.reward_id
    if rewardId then
      local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
      if rewardConf and rewardConf.Icon then
        UIComponent:SetPath(rewardConf.Icon)
      end
    end
  end
end

function UMG_Activity_PetCollectTemplate_C:ShowRewardName(UIComponent)
  UIComponent:SetText(LuaText.Activity_PetCollection_reward_name)
end

function UMG_Activity_PetCollectTemplate_C:GetCurCollectedPetNum()
  local num = 0
  local returnActivityData = self:GetReturnActivityData()
  local collectPetGroup
  if returnActivityData and returnActivityData.collection_pet then
    collectPetGroup = returnActivityData.collection_pet
  end
  if collectPetGroup then
    num = #collectPetGroup
  end
  return num
end

function UMG_Activity_PetCollectTemplate_C:OnRefreshCollectPetList(_activityInst, petCollectData)
end

function UMG_Activity_PetCollectTemplate_C:GetPetCollectionConf()
  if self.activityInst then
    local activityId = self.activityInst:GetActivityId()
    return _G.DataConfigManager:GetActivityPetCollectionConf(activityId)
  end
  return nil
end

function UMG_Activity_PetCollectTemplate_C:GetActivityId()
  if self.activityInst then
    return self.activityInst:GetActivityId()
  end
  return nil
end

function UMG_Activity_PetCollectTemplate_C:OnShowActivityDesc()
  if self.activityInst then
    self.activityInst:OnBtnShowActivityDesc()
  end
end

function UMG_Activity_PetCollectTemplate_C:OnGetAward()
  if self.activityInst then
    local partId = self.activityInst:GetSinglePartId()
    local itemObject = self.activityInst:GetWebSiteItem(partId)
    self.activityInst:PerformActivityInteraction(ActivityEnum.ActivityInteractionType.GetReward, itemObject)
  end
end

function UMG_Activity_PetCollectTemplate_C:CheckActivityExpired()
  if self.activityInst then
    return self.activityInst.status == ActivityEnum.ActivityStatus.Expired
  end
  return false
end

return UMG_Activity_PetCollectTemplate_C

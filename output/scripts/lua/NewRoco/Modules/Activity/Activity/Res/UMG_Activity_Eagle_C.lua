local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local UMG_Activity_Eagle_C = Base:Extend("UMG_Activity_Eagle_C")

function UMG_Activity_Eagle_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_LEGENDARY_CHALLENGE
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.particularsBtn = self.ParticularsBtn
  uiElements.bgImage = self.BG
  return uiElements
end

function UMG_Activity_Eagle_C:OnConstruct()
  Base.OnConstruct(self)
  self.bNeedPlayFinishAnim = false
  self.bTaskSubActivityDone = false
  self.SlotImageWidgetArray = {
    self.NRCImage_47,
    self.NRCImage_6,
    self.NRCImage_13
  }
  self.SlotNameWidgetArray = {
    self.name_1,
    self.name_2,
    self.name_3
  }
  self.DailyDropMaxNum = 0
  self.TodayDropNum = 0
  self.MyDropActivityId = nil
end

function UMG_Activity_Eagle_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  self:OnAddEventListener()
  self:AddButtonListener(self.Button1, self.OnButton1Click)
  self:AddButtonListener(self.Button2, self.OnButton2Click)
  self:AddButtonListener(self.Button3, self.OnButton3Click)
  self:AddButtonListener(self.ExchangeStoreBtn, self.OnClickTopSlotButton)
  self:GetData()
  self:PlayAnimation(self.In)
  self:CheckTaskActivityState()
  if not self.bTaskSubActivityDone or self.bTaskSubActivityDone and self.bNeedPlayFinishAnim then
    self:PlayAnimation(self.In_Add)
  end
  self:UpdateUI()
end

function UMG_Activity_Eagle_C:OnDisable()
  Base.OnDisable(self)
  self:RemoveButtonListener(self.Button1, self.OnButton1Click)
  self:RemoveButtonListener(self.Button2, self.OnButton2Click)
  self:RemoveButtonListener(self.Button3, self.OnButton3Click)
  self:RemoveButtonListener(self.ExchangeStoreBtn)
  self:OnRemoveEventListener()
end

function UMG_Activity_Eagle_C:OnActive()
end

function UMG_Activity_Eagle_C:OnDeactive()
end

function UMG_Activity_Eagle_C:OnAddEventListener()
  self:RegisterEvent(self, ActivityModuleEvent.LegendaryChallengeActivityDataUpdate, self.OnDataUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_Eagle_C", self, TaskModuleEvent.OnTaskUpdated, self.OnTaskUpdated)
  self:RegisterEvent(self, ActivityModuleEvent.RefreshActivityDropData, self.OnRefreshActivityDropData)
  self.Button1.OnPressed:Add(self, self.OnButton1Pressed)
  self.Button1.OnReleased:Add(self, self.OnButton1Released)
  self.Button2.OnPressed:Add(self, self.OnButton2Pressed)
  self.Button2.OnReleased:Add(self, self.OnButton2Released)
  self.Button3.OnPressed:Add(self, self.OnButton3Pressed)
  self.Button3.OnReleased:Add(self, self.OnButton3Released)
end

function UMG_Activity_Eagle_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, ActivityModuleEvent.LegendaryChallengeActivityDataUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.OnTaskUpdated, self.OnTaskUpdated)
  self:UnRegisterEvent(self, ActivityModuleEvent.RefreshActivityDropData)
  self.Button1.OnPressed:Remove(self, self.OnButton1Pressed)
  self.Button1.OnReleased:Remove(self, self.OnButton1Released)
  self.Button2.OnPressed:Remove(self, self.OnButton2Pressed)
  self.Button2.OnReleased:Remove(self, self.OnButton2Released)
  self.Button3.OnPressed:Remove(self, self.OnButton3Pressed)
  self.Button3.OnReleased:Remove(self, self.OnButton3Released)
end

function UMG_Activity_Eagle_C:OnDataUpdate(newData, initUpdate)
  self:GetData()
  self:CheckTaskActivityState()
  if not self:IsAnimationPlaying(self.In) and self.bTaskSubActivityDone and self.bNeedPlayFinishAnim then
    local activityId = self.activityInst:GetActivityId()
    if self.module and self.module.GetActivityAnimFlag and self.module.MarkActivityAnimFlag and activityId then
      self.module:MarkActivityAnimFlag(tostring(activityId), true)
    end
    self:PlayAnimation(self.Get)
  end
  self:UpdateUI()
end

function UMG_Activity_Eagle_C:GetData()
  self.TopSlotData = self.activityInst:GetTopSlotData()
  self.SubSlotDataArray = self.activityInst:GetSubSlotDataArray() or {}
  if self.MyDropActivityId == nil then
    self:GetDropActivityInfo()
  end
  local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(Enum.GoodsType.GT_VITEM, Enum.VisualItem.VI_ACTIVITY_LEGENDARY_POINTS)
  self.Icon1:SetPath(iconPath)
end

function UMG_Activity_Eagle_C:UpdateUI()
  if not self.SubSlotDataArray then
    return
  end
  for slotIndex, subSlotData in ipairs(self.SubSlotDataArray) do
    local legendaryChallengeConf = _G.DataConfigManager:GetLegendaryChallengeConf(subSlotData.baseId)
    if legendaryChallengeConf then
      self.SubSlotDataArray[slotIndex] = subSlotData
      local imageWidget = self.SlotImageWidgetArray[slotIndex]
      if imageWidget then
        imageWidget:SetPath(legendaryChallengeConf.image_path)
      end
      local nameWidget = self.SlotNameWidgetArray[slotIndex]
      if nameWidget then
        nameWidget:SetText(legendaryChallengeConf.slot_des1)
      end
      if 1 == slotIndex then
        self.BgMask1:SetRenderOpacity(0)
        self.Seal:SetRenderOpacity(0)
        if not self:IsAnimationPlaying(self.Get) and not self.bNeedPlayFinishAnim then
          if subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
            self.BgMask1:SetRenderOpacity(1)
            self.Seal:SetRenderOpacity(1)
          else
            self.BgMask1:SetRenderOpacity(0)
            self.Seal:SetRenderOpacity(0)
          end
        end
        local curTaskId = self.activityInst:GetCurTaskId()
        if curTaskId > 0 then
          local taskConf = _G.DataConfigManager:GetTaskConf(curTaskId)
          if taskConf and nameWidget then
            nameWidget:SetText(taskConf.name)
          end
        end
        local iconPath = NPCShopUtils:GetGoodsCurrencyIconByType(legendaryChallengeConf.goods_type, legendaryChallengeConf.goods_id)
        self.Icon:SetPath(iconPath)
      elseif 2 == slotIndex then
        if subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE then
          self.BgMask2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.BiaoqianPanel_83:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.BgMask2:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.BiaoqianPanel_83:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self:UpdateDropCounter()
        end
      elseif 3 == slotIndex then
        if subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE then
          self.BgMask3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.BgMask3:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    end
  end
end

function UMG_Activity_Eagle_C:OnClickSubSlotButton(slotIndex)
  local activityInst = self.activityInst
  if activityInst and activityInst:IsActivityInactive() then
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_Eagle_C:OnClickSubSlotButton_Expired")
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  local subSlotData = self.SubSlotDataArray and self.SubSlotDataArray[slotIndex]
  if subSlotData then
    ActivityUtils.SendTLogActivityButtonAction(self.activityInst:GetActivityId(), slotIndex)
    if subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, subSlotData.des2)
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_Eagle_C:OnClickSubSlotButton_None")
    elseif subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_OPEN then
      if 1 == slotIndex then
        local curTaskId = self.activityInst:GetCurTaskId()
        if curTaskId and curTaskId > 0 then
          _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_Eagle_C:OnClickSubSlotButton_OPEN_1")
          _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.OpenTaskPanel, curTaskId)
        end
      else
        local activityOptionConf = _G.DataConfigManager:GetActivityOptionConf(subSlotData.activityOptionId, true)
        if activityOptionConf then
          local param2 = activityOptionConf.option_param2
          local preCheckPass = true
          if activityOptionConf.option_type == Enum.ActivityOptionType.AOT_WORLD_MAP then
            preCheckPass = ActivityUtils.IsWorldMapTargetExist(tonumber(param2))
          elseif activityOptionConf.option_type == Enum.ActivityOptionType.AOT_WORLD_MAP_REFRESHID then
            preCheckPass = ActivityUtils.IsWorldMapTargetExistByRefreshId(tonumber(param2))
          end
          if not preCheckPass and _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
            _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.fanyingactivity_lock)
            _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_Eagle_C:OnClickSubSlotButton_OPEN_2")
            return
          end
        end
        ActivityUtils.DoActivityOptionCmd(subSlotData.activityOptionId)
        _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_Eagle_C:OnClickSubSlotButton_OPEN_3")
      end
    elseif subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, subSlotData.des3)
      _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_Eagle_C:OnClickSubSlotButton_Done")
    end
  else
    Log.Error("UMG_Activity_Eagle_C:OnClickSubSlotButton invalid subSlotData", slotIndex, #self.SubSlotDataArray)
    Log.Dump(self.SubSlotDataArray, 4, "UMG_Activity_Eagle_C:OnClickSubSlotButton")
  end
end

function UMG_Activity_Eagle_C:OnClickTopSlotButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_Eagle_C:OnClickSubSlotButton_OPEN_2")
  local activityInst = self.activityInst
  if activityInst and activityInst:IsActivityInactive() then
    ActivityUtils.ShowActivityExpiredTips()
    return
  end
  if not self.TopSlotData then
    return
  end
  ActivityUtils.SendTLogActivityButtonAction(self.activityInst:GetActivityId(), 4)
  local activityOptionConf = _G.DataConfigManager:GetActivityOptionConf(self.TopSlotData.activityOptionId, true)
  if activityOptionConf then
    local param2 = activityOptionConf.option_param2
    local preCheckPass = true
    if activityOptionConf.option_type == Enum.ActivityOptionType.AOT_WORLD_MAP then
      preCheckPass = ActivityUtils.IsWorldMapTargetExist(tonumber(param2))
    elseif activityOptionConf.option_type == Enum.ActivityOptionType.AOT_WORLD_MAP_REFRESHID then
      preCheckPass = ActivityUtils.IsWorldMapTargetExistByRefreshId(tonumber(param2))
    end
    if not preCheckPass and _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.fanyingactivity_lock)
      return
    end
  end
  ActivityUtils.DoActivityOptionCmd(self.TopSlotData.activityOptionId)
end

function UMG_Activity_Eagle_C:OnTaskUpdated()
  self.activityInst:RefreshTaskSearchResult()
  self:UpdateUI()
end

function UMG_Activity_Eagle_C:OnButton1Pressed()
  self:PlayAnimation(self.Press_1)
end

function UMG_Activity_Eagle_C:OnButton2Pressed()
  self:PlayAnimation(self.Press_2)
end

function UMG_Activity_Eagle_C:OnButton3Pressed()
  self:PlayAnimation(self.Press_3)
end

function UMG_Activity_Eagle_C:OnButton1Released()
  self:PlayAnimation(self.Up_1)
end

function UMG_Activity_Eagle_C:OnButton2Released()
  self:PlayAnimation(self.Up_2)
end

function UMG_Activity_Eagle_C:OnButton3Released()
  self:PlayAnimation(self.Up_3)
end

function UMG_Activity_Eagle_C:OnButton1Click()
  self:OnClickSubSlotButton(1)
end

function UMG_Activity_Eagle_C:OnButton2Click()
  self:OnClickSubSlotButton(2)
end

function UMG_Activity_Eagle_C:OnButton3Click()
  self:OnClickSubSlotButton(3)
end

function UMG_Activity_Eagle_C:OnAnimationFinished(Anim)
  if Anim == self.In and self.bNeedPlayFinishAnim then
    local activityId = self.activityInst:GetActivityId()
    if self.module and self.module.GetActivityAnimFlag and self.module.MarkActivityAnimFlag and activityId then
      self.bNeedPlayFinishAnim = not self.module:GetActivityAnimFlag(tostring(activityId))
      if self.bNeedPlayFinishAnim then
        self.module:MarkActivityAnimFlag(tostring(activityId), true)
      end
    end
    self:PlayAnimation(self.Get)
    self.bNeedPlayFinishAnim = false
  end
end

function UMG_Activity_Eagle_C:CheckTaskActivityState()
  self.bNeedPlayFinishAnim = false
  self.bTaskSubActivityDone = false
  local subSlotData = self.SubSlotDataArray and self.SubSlotDataArray[1]
  if subSlotData and subSlotData.state == ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_DONE then
    self.bTaskSubActivityDone = true
    local activityId = self.activityInst:GetActivityId()
    if self.module and self.module.GetActivityAnimFlag and self.module.MarkActivityAnimFlag and activityId then
      self.bNeedPlayFinishAnim = not self.module:GetActivityAnimFlag(tostring(activityId))
    end
  end
end

function UMG_Activity_Eagle_C:OnRefreshActivityDropData(sourceActivity, dropData)
  self:UpdateDropCounter()
end

function UMG_Activity_Eagle_C:GetDropActivityInfo()
  local baseIds = self.activityInst:GetPartIds()
  for idx, activityBaseId in ipairs(baseIds) do
    local conf = _G.DataConfigManager:GetActivityConf(activityBaseId, true)
    if conf and conf.activity_type == Enum.ActivityType.ATP_DROP and conf.base_id then
      for idx2, baseIdOfDrop in ipairs(conf.base_id) do
        local activityDropConf = _G.DataConfigManager:GetActivityDropConf(baseIdOfDrop)
        if activityDropConf and activityDropConf.goods_type == Enum.GoodsType.GT_VITEM and activityDropConf.goods_id == Enum.VisualItem.VI_ACTIVITY_LEGENDARY_POINTS and activityDropConf.day_got_limit then
          self.DailyDropMaxNum = activityDropConf.day_got_limit
          self.MyDropActivityId = activityBaseId
          return
        end
      end
    end
  end
end

function UMG_Activity_Eagle_C:UpdateDropCounter()
  if self.MyDropActivityId and 0 ~= self.MyDropActivityId then
    local dropActivityInst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, self.MyDropActivityId, true)
    if dropActivityInst and dropActivityInst.GetAlreadyGetNumByTypeAndId then
      self.TodayDropNum = dropActivityInst:GetAlreadyGetNumByTypeAndId(Enum.GoodsType.GT_VITEM, Enum.VisualItem.VI_ACTIVITY_LEGENDARY_POINTS)
    end
  end
  self.IconDesc:SetText(string.format("%d/%d", self.TodayDropNum or 0, self.DailyDropMaxNum or 0))
end

return UMG_Activity_Eagle_C

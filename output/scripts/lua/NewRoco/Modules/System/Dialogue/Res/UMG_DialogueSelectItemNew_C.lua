require("UnLuaEx")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local DialogueModuleEvent = reload("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local ShowID = RocoEnv.IS_EDITOR or not RocoEnv.IS_SHIPPING and _G.AppMain:HasLaunchParams()
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local UMG_DialogueSelectItemNew_C = Base:Extend("UMG_DialogueSelectItemNew_C")
local TextStyle = {
  [0] = "Normal",
  [1] = "Normal",
  [2] = "Important"
}
local TextStyleSelected = {
  [0] = "NormalSelected",
  [1] = "NormalSelected",
  [2] = "ImportantSelected"
}

function UMG_DialogueSelectItemNew_C:OnConstruct()
  self.option = nil
  self.SelectConf = nil
  self.bIsHovered = false
  self:BindToAnimationStarted(self.Press, {
    self,
    function(caller)
      if not self.bIsHovered then
        self:PlayAnimation(self.Hover_In)
      end
    end
  })
  self:BindToAnimationFinished(self.Press, {
    self,
    function(caller)
      if self.bPendingUpAnim then
        self.bPendingUpAnim = false
        self:PlayAnimation(self.Up)
      end
    end
  })
  self:BindToAnimationStarted(self.Up, {
    self,
    function(caller)
      self:OnItemPreSelected()
      if not self:IsHovered() and self.bIsHovered then
        self:PlayAnimation(self.Hover_Out)
      end
    end
  })
  self:BindToAnimationFinished(self.Up, {
    self,
    function(caller)
      if self.bClickedConfirm then
        self.bClickedConfirm = false
        self:OnSelected()
      end
    end
  })
  self:BindToAnimationStarted(self.Hover_In, {
    self,
    function(caller)
      self:SetTextContent(true)
      self.bIsHovered = true
    end
  })
  self:BindToAnimationFinished(self.Hover_In, {
    self,
    function(caller)
    end
  })
  self:BindToAnimationStarted(self.Hover_Out, {
    self,
    function(caller)
      self:SetTextContent(false)
    end
  })
  self:BindToAnimationFinished(self.Hover_Out, {
    self,
    function(caller)
      self.bIsHovered = false
    end
  })
end

function UMG_DialogueSelectItemNew_C:OnItemPreSelected()
  if self.ParentView then
    local Count = self.ParentView:GetItemCount()
    for i = 0, Count do
      local item = self.ParentView:GetItemByIndex(i)
      if item then
        item:ClearDefaultOptionTimer()
      end
    end
  end
end

function UMG_DialogueSelectItemNew_C:OnItemUpdate(Data, datalist, index)
  local _data = Data.Conf
  self.SelectConf = _data
  self.index = index
  self.option = Data.Option
  local content = _data.text
  local iconPath = _data.select_icon
  local textLevel = _data.color
  local DialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
  if DialogueModule then
    local NewContent = DialogueModule:GetOverrides("SelectText", self.SelectConf.id)
    if not string.IsNilOrEmpty(NewContent) then
      content = NewContent
    end
    local ReplaceSelectView = DialogueModule:GetOverrides("ReplaceSelectView", self.SelectConf.id)
    if ReplaceSelectView then
      local SelectConf = ReplaceSelectView.SelectConf
      local DynamicReplaceLevel = ReplaceSelectView.DynamicReplaceLevel
      content = SelectConf.text
      iconPath = SelectConf.select_icon
      textLevel = DynamicReplaceLevel or SelectConf.color
    end
  end
  if _data.select_mark == Enum.SelectMarkYellow.SMY_ROLE_LEVEL_AWARD then
    if _G.NRCModuleManager:DoCmd(LevelUpUIModuleCmd.CheckIfLevelUpAwardsAvailable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_MAGIC_UP then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsBottleTimeUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRolePowerUpgradeEnable) or _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRoleHpUpgradeEnable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_MAGIC_BOTTLE_TIMES then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsBottleTimeUpgradeEnable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_MAGIC_BOTTLE_VOLUME then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsBottleVolumeUpgradeEnable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_MAGIC_HEART then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRoleHpUpgradeEnable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_JUST_YELLOW then
    textLevel = 2
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_TRAVEL_YELLOW then
    if _G.NRCModuleManager:DoCmd(_G.TravelModuleCmd.IsFinishTravel) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_MAGIC_POWER then
    if _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.IsRolePowerUpgradeEnable) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_SHOP_CONSUMPTION_REWARD then
    local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_TOTAL_CONSUMPTION_REWARD)
    local hasConsumptionReward = false
    if redDotData then
      for i = 1, #redDotData do
        if redDotData[i] and string.match(redDotData[i], "^(.-)%.") == "2001" then
          hasConsumptionReward = true
        end
      end
    end
    if hasConsumptionReward then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_CAMP_LEVELUP then
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_HOME_LEVEL_REWARD then
    local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_HOME_LEVEL_REWARD)
    if redDotData and next(redDotData) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_HOME_ROOM_EXPEND then
    local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_HOME_EXPAND_CONDITION_MET)
    if redDotData and next(redDotData) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_HOME_ROOM_EXPEND_SUCCEED then
    local redDotData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_HOME_EXPAND_FINISH)
    if redDotData and next(redDotData) then
      textLevel = 2
    end
  elseif _data.select_mark == Enum.SelectMarkYellow.SMY_UNCLICKED then
    local select_info = DialogueUtils.GetSelectInfoByID(self.option and self.option.CurrentAction and self.option.CurrentAction.Info, self.SelectConf.id)
    if select_info and not select_info.has_been_selected then
      textLevel = 2
    end
  end
  if ShowID then
    content = string.format("%s(%d)", content, self.SelectConf.id)
  end
  self.Content = content
  self.textLevel = textLevel
  content = string.format("<%s>%s</>", TextStyle[self.textLevel], self.Content)
  self.ItemDesc:SetText(content)
  self.Icon:SetPath(iconPath)
  self.PCKey:SetKeyVisibility(true)
  self.PCKey:SetText(self.index)
  self.ProgressBarBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ProgressBar_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_DialogueSelectItemNew_C:OnMouseEnter(MyGeometry, MouseEvent)
  self:StopAnimation(self.Hover_Out)
  self:PlayAnimation(self.Hover_In)
end

function UMG_DialogueSelectItemNew_C:OnPanelScrolled()
end

function UMG_DialogueSelectItemNew_C:OnMouseLeave(MouseEvent)
  self:StopAnimation(self.Hover_In)
  self:PlayAnimation(self.Hover_Out)
end

function UMG_DialogueSelectItemNew_C:OnButtonPressed()
  Log.Debug("UMG_DialogueSelectItemNew_C:OnButtonPressed, id = ", self.SelectConf and self.SelectConf.id or 0)
  if self:IsAnimationPlaying(self.Press) or self:IsAnimationPlaying(self.Up) then
    return
  end
  self.bClickedConfirm = false
  self:PlayAnimation(self.Press)
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_DialogueSelectItemNew_C:OnButtonClicked()
  Log.Debug("UMG_DialogueSelectItemNew_C:OnButtonClicked, id = ", self.SelectConf and self.SelectConf.id or 0)
  self.bClickedConfirm = true
end

function UMG_DialogueSelectItemNew_C:OnButtonReleased()
  Log.Debug("UMG_DialogueSelectItemNew_C:OnButtonReleased, id = ", self.SelectConf and self.SelectConf.id or 0)
  if self:IsAnimationPlaying(self.Up) then
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  if self:IsAnimationPlaying(self.Press) then
    self.bPendingUpAnim = true
    return UE.UWidgetBlueprintLibrary.Handled()
  end
  self:PlayAnimation(self.Up)
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_DialogueSelectItemNew_C:OnSelected()
  Log.Debug("UMG_DialogueSelectItemNew_C:OnSelected, id = ", self.SelectConf and self.SelectConf.id or 0)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1067, "UMG_DialogueSelectItem_C:OnMouseEnter")
  local Disabled = not self.SelectConf
  local Option = self.option
  if Option and not Disabled then
    Disabled = Option:IsDisableByOnlineMode()
  end
  Disabled = Disabled or _G.DataModelMgr.PlayerDataModel:IsOnlineProcessDisable(self.SelectConf.online_process)
  if Disabled then
    local showTip = ""
    if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      showTip = _G.DataConfigManager:GetLocalizationConf("Error_Code_2161").msg
    else
      showTip = _G.DataConfigManager:GetLocalizationConf("Error_Code_2162").msg
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, showTip)
  else
    if Option and Option:CheckOptionIsBan(true) then
      return
    end
    local dialogueModule = _G.NRCModuleManager:GetModule("DialogueModule")
    dialogueModule:DispatchEvent(DialogueModuleEvent.DialogueSelectFinished, self.SelectConf)
  end
end

function UMG_DialogueSelectItemNew_C:SetTextContent(bIsPress)
  local SetContent = self.Content
  if nil ~= SetContent then
    if bIsPress then
      SetContent = string.format("<%s>%s</>", TextStyleSelected[self.textLevel], self.Content)
      self.ItemDesc:SetText(SetContent)
    else
      SetContent = string.format("<%s>%s</>", TextStyle[self.textLevel], self.Content)
      self.ItemDesc:SetText(SetContent)
    end
  end
end

function UMG_DialogueSelectItemNew_C:SafeSetVisibility(item, visibility)
  if item and item.SetVisibility then
    item:SetVisibility(visibility)
  else
    Log.Warning("UMG_DialogueSelectItem_C:SafeSetVisibility: \229\175\185\232\175\157\233\128\137\233\161\185umg\230\140\135\233\146\136\231\169\186\228\186\134")
  end
end

function UMG_DialogueSelectItemNew_C:OnDestruct()
  self.option = nil
  self.SelectConf = nil
end

function UMG_DialogueSelectItemNew_C:StartDefaultOptionTimer()
  self.ProgressBarBG:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.ProgressBar_0:SetFillAmount(1.0)
  self.ProgressBar_0:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.DefaultOptionTime = math.max(_G.DataConfigManager:GetTaskGlobalConfig("dialogue_default_select_time", true).num, 1000.0) / 1000.0
  self.DefaultOptionTimeRemaining = self.DefaultOptionTime
  self.DefaultOptionTimerStep = 0.05
  self.DefaultOptionTimer = _G.TimerManager:CreateTimer(self, "DialogueDefaultOptionTimer", self.DefaultOptionTime * 2, self.OnDefaultOptionTimer, nil, self.DefaultOptionTimerStep)
end

function UMG_DialogueSelectItemNew_C:ClearDefaultOptionTimer()
  self.ProgressBarBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ProgressBar_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.DefaultOptionTimer then
    _G.TimerManager:RemoveTimer(self.DefaultOptionTimer)
    self.DefaultOptionTimer = nil
  end
end

function UMG_DialogueSelectItemNew_C:OnDefaultOptionTimer()
  self.DefaultOptionTimeRemaining = self.DefaultOptionTimeRemaining - self.DefaultOptionTimerStep
  local Progress = math.clamp(self.DefaultOptionTimeRemaining / self.DefaultOptionTime, 0.0, 1.0)
  self.ProgressBar_0:SetFillAmount(Progress)
  if self.DefaultOptionTimeRemaining < 0.0 then
    self:OnDefaultOptionTimeout()
  end
end

function UMG_DialogueSelectItemNew_C:OnDefaultOptionTimeout()
  self:OnOptionSelect()
end

function UMG_DialogueSelectItemNew_C:OnOptionSelect()
  self:ClearDefaultOptionTimer()
  self:PlayAnimation(self.Press)
  self.bPendingUpAnim = true
  self.bClickedConfirm = true
end

function UMG_DialogueSelectItemNew_C:OnShownByScrollView()
  self:PlayAnimation(self.Hover_Out, self.Hover_Out:GetEndTime())
end

function UMG_DialogueSelectItemNew_C:PlaySelectAnimation()
  self.bPendingUpAnim = true
  self:PlayAnimation(self.Press)
end

return UMG_DialogueSelectItemNew_C
